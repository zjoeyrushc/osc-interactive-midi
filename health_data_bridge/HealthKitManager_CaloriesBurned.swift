import Foundation
import HealthKit
import Network

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    // 我们只统计“本次会话”的累计值
    @Published var sessionCalories: Double = 0.0
    
    private var sessionStartTime: Date?
    private var lastSentCalories: Double? // 上次发送的卡路里值，nil 表示尚未发送过
    
    // UDP 相关
    private var connection: NWConnection?
    private let oscHost = "192.168.50.192" // 根据你的需求修改 IP
    private let oscPort: UInt16 = 9000
    
    // 定时器
    private var timer: Timer?

    init() {
        setupConnection()
    }

    func setupConnection() {
        connection = NWConnection(
            host: NWEndpoint.Host(oscHost),
            port: NWEndpoint.Port(rawValue: oscPort)!,
            using: .udp
        )
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connection ready on \(self.oscHost):\(self.oscPort)")
            case .failed(let error):
                print("Connection failed: \(error.localizedDescription)")
            default:
                break
            }
        }
        connection?.start(queue: .main)
    }

    // --------------------------------------
    // MARK: - 请求授权
    // --------------------------------------
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return
        }
        
        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let typesToRead: Set<HKObjectType> = [activeEnergyBurnedType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted")
            } else {
                print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // --------------------------------------
    // MARK: - 开始会话：记录起点 & 启动监听
    // --------------------------------------
    func startSession() {
        sessionStartTime = Date()  // 从现在开始统计
        sessionCalories = 0.0      // 重置
        lastSentCalories = nil     // 重置记录的上次发送值
        
        // 启动 Observer Query
        startObserverQuery()
        
        // 启动定时器，每隔 5 秒查一次，作为兜底
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.sessionStartTime else { return }
            
            self.fetchAccumulatedCalories(since: startTime) { value in
                print("Periodic fetch: \(value) kcal")
            }
        }
    }
    
    func stopSession() {
        timer?.invalidate()
        timer = nil
        sessionStartTime = nil
    }

    // --------------------------------------
    // MARK: - Observer Query: 监听底层写入事件
    // --------------------------------------
    private func startObserverQuery() {
        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKObserverQuery(sampleType: activeEnergyBurnedType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }

            guard let self = self, let startTime = self.sessionStartTime else { return }
            
            // 主动触发数据更新
            self.fetchAccumulatedCalories(since: startTime) { value in
                print("Observer fetch: \(value) kcal")
            }
            
            completionHandler() // 告诉系统观察已经处理完成
        }
        
        healthStore.execute(query)
    }

    // --------------------------------------
    // MARK: - 查询：自定义起点 -> 现在
    // --------------------------------------
    func fetchAccumulatedCalories(since startTime: Date, completion: @escaping (Double) -> Void) {
        let now = Date()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startTime,
            end: now,
            options: .strictStartDate
        )
        
        let activeEnergyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKStatisticsQuery(
            quantityType: activeEnergyBurnedType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            
            // 如果 result 或 sumQuantity() 为空，就把卡路里设为 0
            let kcalValue: Double
            if let result = result, let sum = result.sumQuantity() {
                kcalValue = sum.doubleValue(for: .kilocalorie())
            } else {
                kcalValue = 0
            }
            
            DispatchQueue.main.async {
                self.sessionCalories = kcalValue

                // ----------------------------------------
                // 强制“只要是 0，就发送”，
                // 非 0 时，只有当变化或初次发送才发送
                // ----------------------------------------
                if kcalValue == 0 {
                    print("===> [Always send 0] lastSentCalories: \(String(describing: self.lastSentCalories)), current: \(kcalValue)")
                    self.sendCaloriesToOSC(kcalValue)
                    self.lastSentCalories = kcalValue
                } else if self.lastSentCalories == nil || kcalValue != self.lastSentCalories {
                    print("===> [Send changed value] lastSentCalories: \(String(describing: self.lastSentCalories)), current: \(kcalValue)")
                    self.sendCaloriesToOSC(kcalValue)
                    self.lastSentCalories = kcalValue
                } else {
                    print("===> [No send] lastSentCalories: \(String(describing: self.lastSentCalories)), current: \(kcalValue)")
                }
                
                completion(kcalValue)
            }
        }
        
        healthStore.execute(query)
    }
    
    // --------------------------------------
    // MARK: - 发送数据到 Python (OSC)
    // --------------------------------------
    func sendCaloriesToOSC(_ calories: Double) {
        guard let connection = connection else {
            print("Connection not established")
            return
        }

        let oscMessage = "/counter,\(calories)"
        guard let messageData = oscMessage.data(using: .utf8) else {
            print("Failed to encode OSC message")
            return
        }

        connection.send(content: messageData, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send OSC message: \(error.localizedDescription)")
            } else {
                print("Sent session-based kcal to OSC: \(oscMessage)")
            }
        })
    }
    // --------------------------------------
    // MARK: - 手动增加 kcal
    // --------------------------------------
    func addManualCalories(_ calories: Double) {
        DispatchQueue.main.async {
            self.sessionCalories += calories
            self.sendCaloriesToOSC(self.sessionCalories)
            print("Manually added \(calories) kcal. New sessionCalories: \(self.sessionCalories)")
        }
    }
}

