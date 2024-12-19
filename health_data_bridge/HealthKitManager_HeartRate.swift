import Foundation
import HealthKit
import Network

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var latestHeartRate: Double = 0.0

    // 创建 UDP 连接
    private var connection: NWConnection?
    private let oscHost = "192.168.1.142" // 本地地址
    private let oscPort: UInt16 = 8000 // 与 Python 的接收端端口一致

    init() {
        setupConnection()
    }

    func setupConnection() {
        connection = NWConnection(host: NWEndpoint.Host(oscHost), port: NWEndpoint.Port(rawValue: oscPort)!, using: .udp)
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

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

        let typesToRead: Set<HKObjectType> = [heartRateType]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted")
                self.startHeartRateQuery()
            } else {
                print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func startHeartRateQuery() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { _, completionHandler, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }

            self.fetchLatestHeartRate()
            completionHandler()
        }

        healthStore.execute(query)
    }

    func fetchLatestHeartRate() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let results = results as? [HKQuantitySample], let sample = results.first else {
                print("No heart rate data found")
                return
            }

            DispatchQueue.main.async {
                self.latestHeartRate = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                print("Latest heart rate: \(self.latestHeartRate) bpm")
                self.sendHeartRateToOSC(self.latestHeartRate)
            }
        }

        healthStore.execute(query)
    }

    func sendHeartRateToOSC(_ heartRate: Double) {
        guard let connection = connection else {
            print("Connection not established")
            return
        }

        // OSC 消息格式
        let oscMessage = "/counter,\(heartRate)"  // 正确格式，匹配 Python 脚本"
        guard let messageData = oscMessage.data(using: .utf8) else {
            print("Failed to encode OSC message")
            return
        }

        connection.send(content: messageData, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send OSC message: \(error.localizedDescription)")
            } else {
                print("Sent heart rate OSC message: \(oscMessage)")
            }
        })
    }
}
