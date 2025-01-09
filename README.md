# OSC互动音乐: 实时数据映射 MIDI 合成器

[ENGLISH VERSION](./README_EN.md)

## 1 简介
本 Demo 以 macOS 为例，展示如何通过 OSC 协议，把摄像头数据、鼠标交互及健康数据（如心率和卡路里）传递到 DAW 实时生成 MIDI 声音（以 AbletonLive 为例）。项目中的代码仅为简易化的个人思路，除了数据获取，各创作者的关注点可放在如何映射合成器参数与音符编排上，从而拓展编曲与声音设计的新思路。

---


## 2 核心功能

- **实时数据采集**:

  - 摄像头画面亮度、色彩偏移与运动量
  - 鼠标移动与点击
  - 健康数据：心率与卡路里

- **OSC 数据传输**:

  - 将处理后的数据传输到 Ableton Live 或其他支持 OSC 的软件。

- **音乐生成**:

  - 将数据映射为 MIDI 音符、力度和滤波器参数。

---


## 3 技术栈与依赖安装

- **Python**: 用 OpenCV 或 Pynput 等方式灵活接收或采集数据，完成逻辑处理，将数据映射到音乐参数值区间，转化为符合 OSC 格式的信号，通过指定路径和端口传输至 DAW 中进行生成。

   - **准备**：执行以下命令安装本次的 Python 依赖。
```python
python3 -m pip install opencv-python python-osc pynput
```


- **HealthKit + Xcode（非必须）**: 用 Xcode 构建桥接应用，通过 HealthKit 组件获取 AppleWatch 的运动数据，并把数据发送到 Python 的接收地址上，提供额外的数据驱动方式。

  - **安装 Xcode**：在 macOS 上通过 App Store 搜索并安装 Xcode。

  - **启用 HealthKit**：打开项目，在 Capabilities 中启用 HealthKit。

  - **运行应用**：连接 iPhone（确保打开开发者模式），选择设备并点击 Run 按钮部署应用。


- **Ableton Live（个人选择）**: 接收 OSC 信号，通过 Max For Live 插件将数据映射到 MIDI 合成器参数，转化为最终音乐效果。

  - **安装 Ableton Live**：从 [Ableton 官网](https://www.ableton.com/) 下载并安装 Ableton Live（建议使用 Suite 版本，包含 Max for Live 功能）。

  - **启用 Max for Live**：在 **Preferences > Licenses/Maintenance** 中确保 **Max for Live** 已启用。

  - **加载 Max for Live 插件**： 以下是一些示例插件，可以帮助你快速实现 OSC 数据接收和转换。
    - [**OSC Receiver (OSC In)**](https://maxforlive.com/library/device/7752/osc-receiver-osc-in)：一个简单的 OSC 数据接收插件，用于监听指定端口的 OSC 消息。
    - [**Simple OSC to MIDI**](https://maxforlive.com/library/device/987/simple-osc-to-midi)：将接收的 OSC 数据映射为 MIDI 音符或参数，用于实时音乐生成。
    - [**Connection Kit**](https://github.com/Ableton/m4l-connection-kit)：Ableton 官方发布的工具包，包含多个 OSC 和 MIDI 工具，可以连接传感器、控制器等多种设备，拓展更多互动应用场景。
   
---


## 4 Demo 1：摄像头与鼠标数据

### **4.1 Python 数据抓取与OSC 传输：**

- **涉及组件：**
  pythonosc.udp\_client：实现 OSC 消息的发送，将处理后数据传输至 Ableton。

- 使用 PythonOSC 建立 UDP 通信，将数据实时传输至 Ableton Live。

- **网络配置：**
  - 本地 IP 地址：127.0.0.1（本地设备通信）。
  - UDP 端口：8000（确保 Ableton 轨道插件的监听端口相同即可）。


### **4.2 摄像头数据映射：**

- 通过 OpenCV 捕捉画面亮度、颜色偏移（即冷暖）和运动量（即镜头变化程度），用于生成动态音乐，**映射关系可按照合成器的目标参数自定义设计**。

- **数据映射及区间：**
  - **画面亮度**：从 `[0, 255]` 映射到 `[0, 127]`，适合控制旋律动态，**本案例用于生成 MIDI，并对应音高，亮度越高音高越高**，路径 `/brightness`。  
  - **颜色偏移**：从 `[-255, 255]` 映射到 `[0, 127]`，适合控制音色变化，**本案例用于滤波器调节，颜色偏暖可对应柔和音色，偏冷可对应硬朗音色**，路径 `/color_shift`。  
  - **运动量**：从 `[0, 255]` 映射到 `[0, 127]`，**本案例用于另一轨的点缀音效音色，运动量高对应较强的动态音效，运动量低对应较弱的动态音效**，路径 `/motion_intensity`。

- **涉及组件：**
  `cv2`：用于捕获视频画面和图像处理，例如计算亮度、检测运动量等。
  `numpy`：用于高效的数学计算，例如计算平均亮度和帧差异。
  `time`：控制脚本运行的时间逻辑，如帧率和延迟。

- **示例代码**：[Receive_Camera_Data.py](./osc_midi_scripts/Receive_Camera_Data.py) 

```python
import cv2
from pythonosc.udp_client import SimpleUDPClient
import numpy as np
import time

# 配置 OSC 客户端
LOCAL_IP = "127.0.0.1"  # 本地回环地址
LOCAL_PORT = 8000       # OSC 接收端口
client = SimpleUDPClient(LOCAL_IP, LOCAL_PORT)

# 初始化摄像头
cap = cv2.VideoCapture(0)

# 定义 OSC 地址
OSC_ADDRESS_BRIGHTNESS = "/brightness"
OSC_ADDRESS_COLOR_SHIFT = "/color_shift"
OSC_ADDRESS_MOTION_INTENSITY = "/motion_intensity"

# 初始化前一帧（用于运动检测）
prev_frame = None

def normalize(value, old_min, old_max, new_min=0, new_max=127):
    """将值归一化到指定范围 0-127"""
    return new_min + (value - old_min) * (new_max - new_min) / (old_max - old_min)

try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # 转为灰度图
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # 1. **亮度映射**: 计算平均亮度
        avg_brightness = np.mean(gray)
        normalized_brightness = normalize(avg_brightness, 0, 255)  # 灰度范围是 [0, 255]
        client.send_message(OSC_ADDRESS_BRIGHTNESS, normalized_brightness)
        print(f"Brightness: {normalized_brightness}")

        # 2. **颜色偏移映射**: 计算 RGB 分布偏移
        avg_color = frame.mean(axis=(0, 1))  # 获取 RGB 三通道平均值
        color_shift = avg_color[2] - avg_color[0]  # 红色与蓝色通道的差异
        normalized_color_shift = normalize(color_shift, -255, 255)  # 假定颜色差异范围是 [-255, 255]
        client.send_message(OSC_ADDRESS_COLOR_SHIFT, normalized_color_shift)
        print(f"Color Shift (Red-Blue): {normalized_color_shift}")

        # 3. **运动量映射**: 通过帧差异检测运动强度
        if prev_frame is not None:
            frame_diff = cv2.absdiff(prev_frame, gray)  # 计算当前帧与前一帧的差异
            motion_intensity = np.sum(frame_diff) / (frame_diff.shape[0] * frame_diff.shape[1])  # 平均差异
            normalized_motion_intensity = normalize(motion_intensity, 0, 255)  # 差异范围是 [0, 255]
            client.send_message(OSC_ADDRESS_MOTION_INTENSITY, normalized_motion_intensity)
            print(f"Motion Intensity: {normalized_motion_intensity}")

        prev_frame = gray  # 更新前一帧

        # 显示画面
        cv2.imshow('Camera Feed', frame)

        # 按 'q' 键退出
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except KeyboardInterrupt:
    print("Stopped sending OSC messages.")

finally:
    cap.release()
    cv2.destroyAllWindows()
```


### **4.3 鼠标数据映射：**

- 捕获鼠标位置与点击，用于动态生成旋律和音量控制。

- **涉及组件：**
  `pynput.mouse`：用于监听鼠标的移动和点击事件，将鼠标位置和动作映射到音乐参数，如音高和力度。
  `random`：随机生成数据，例如鼠标点击时生成随机的MIDI力度，增加音乐表现力和多样性。

- **数据映射及区间：**
  - **鼠标移动**：映射范围为 [0, 127]，对应 MIDI Note 的音高值。此范围选取是为了贴合 MIDI 标准音符区间，低坐标值映射低音，高坐标值映射高音，路径：`/mouse_position`。
  - **鼠标点击**：映射范围为 [0, 127]，对应 MIDI Velocity（音量强度）。选择该区间是为了控制音符动态表现，与 X 坐标结合生成丰富的旋律，路径：`/trigger_event`。

- **示例代码**：[Mouse_Interaction.py](./osc_midi_scripts/Mouse_Interaction.py)

```python
from pynput import mouse
from pythonosc.udp_client import SimpleUDPClient
import random

# 配置 OSC 客户端
LOCAL_IP = "127.0.0.1"  # 本地回环地址
LOCAL_PORT = 8000       # OSC 接收端口
client = SimpleUDPClient(LOCAL_IP, LOCAL_PORT)

# 屏幕的宽高（根据你的屏幕分辨率调整）
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

# 回调函数：鼠标移动
def on_move(x, y):
    # 将鼠标的 X 坐标映射为 MIDI 音符编号 (0–127)
    note = int((x / SCREEN_WIDTH) * 127)
    # 发送 OSC 消息到 /mouse_position
    client.send_message("/mouse_position", note)
    print(f"Mouse moved to ({x}, {y}) -> Note: {note}")

# 回调函数：鼠标点击
def on_click(x, y, button, pressed):
    if pressed:
        # 鼠标点击时随机生成 MIDI 力度 (0–127)
        velocity = random.randint(0, 127)
        # 发送 OSC 消息到 /trigger_event
        client.send_message("/trigger_event", velocity)
        print(f"Mouse clicked at ({x}, {y}) -> Random Velocity: {velocity}")

# 监听鼠标活动
with mouse.Listener(on_move=on_move, on_click=on_click) as listener:
    listener.join()
```


### **4.4 Ableton Live MIDI生成（摄像头信息生成宇宙音效为例）：**

- **OSC接收与配置：** 使用 Max for Live 的 OSC Receiver 插件设置监听地址和端口，将 Python 发送的数据接入 Ableton。

- **OSC到MIDI的插件**： 使用 Max for Live 中的自定义 MIDI Effect 插件，将 OSC 参数直接转换为 MIDI Note 或其他动态参数值。例如：
  根据 OSC 数据范围 [0, 127]，生成 MIDI Note 并限制在指定音阶内（如 C 大调）。
  可利用Midi Effects的各种功能完善音乐性，如用 Scale 功能确保音符符合音乐调性。

- **合成器参数映射：** 在确保了音符生成后，可利用 Ableton 的 Map 功能，将其他 OSC 参数映射到目标 MIDI 音符参数或合成器参数上。例如：
  - **画面亮度**映射至 MIDI 合成器滤波器频率（路径：`/brightness`）。
  - **鼠标点击**映射至 MIDI 音符强度（路径：`/trigger_event`）。

通过以上步骤，Ableton Live 能够接收和实时处理 OSC 信号，将多源数据转化为丰富的音乐表现形式。

---


## 5 Demo 2：健康数据


### 5.1 健康数据桥接：

- **Xcode App 开发：**

  - 下载并安装 Xcode，创建一个新的 iOS 项目，选择 SwiftUI 作为界面构建工具。

  - 在项目设置中启用 HealthKit 框架，确保添加所需权限。通过创建一个`HealthKitManager.swift` 文件完成对健康数据的获取，本 Demo 以获取卡路里数据为例。

  - 授权用户读取健康数据，确保隐私合规性。

  - 在原始的 `ContentView.swift` 中构建前端界面，显示实时运动数据并触发授权逻辑。

   - 将 iPhone 使用数据线连接到 Mac，在 iPhone 上按照提示信任计算机，并在“设置 > 隐私与安全 > 开发者模式”中启用开发者模式。
    打开 Xcode，点击顶部菜单中的“设备和模拟器”（Device and Simulators），确保 iPhone 已正确连接并显示在设备列表中，依据提示完成配置。
    在 Xcode 的目标设备菜单中选择 iPhone，点击“运行”（Run）按钮，将应用部署到 iPhone 进行测试。

   - 运行后就可过 UDP 协议将卡路里数据发送至计划的 Python 模块以供后续处理。

- **在 Info.plist 中正确配置 HealthKit 权限**

   - **找到 Info.plist 文件**：
    - 打开 Xcode，在左侧的 **Project Navigator** 中选择你的项目名称。
    - 选择 **TARGETS** > 你的应用 Target（例如 `HealthKitCyclingApp`）。
    - 点击顶部的 **Info** 标签。

   - **添加必要的权限描述**：
    在 **Custom iOS Target Properties** 下，手动添加以下两项：
    - `NSHealthShareUsageDescription`  **值**: 该应用需要访问您的健康数据，以显示健康数据信息。
    - `NSHealthUpdateUsageDescription`  **值**: 该应用需要访问权限以更新您的健康数据。

- **核心功能文件：**
  - **`HealthKitManager.swift`**: 负责通过 HealthKit 框架获取卡路里或心率数据，并通过 UDP 将数据发送至 Python 接收端。UDP 的 IP 地址设置为Mac的IP地址（`192.168.1.142` 为我 Mac 的地址），确保 iPhone 和 Mac 处于同一网络环境。以下为核心实例：
    - **Tips：**
    确保你在 HealthKitManager 中设置的 IP 地址 (oscHost) 为你 Mac 的实际局域网 IP 地址，而不是本地回路 127.0.0.1，因为这会指向 iPhone 自身。

    - **示例代码**：[HealthKitManager_CaloriesBurned.swift](./health_data_bridge/HealthKitManager_CaloriesBurned.swift)
```swift
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
    private let oscHost = "192.168.1.142" // 根据你的需求修改 IP
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


```

  - **`ContentView.swift`**: 提供实时 UI，显示卡路里数据并触发 HealthKit 授权。
    - **示例代码**：[ContentView_CaloriesBurned.swift](./health_data_bridge/ContentView_CaloriesBurned.swift)

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var isSessionActive = false // 标记是否正在进行会话

    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Session")
                .font(.largeTitle)
                .padding()

            // 显示当前会话的累计卡路里消耗
            Text("Session Calories Burned: \(healthKitManager.sessionCalories, specifier: "%.2f") kcal")
                .padding()
                .font(.title2)

            HStack(spacing: 20) {
                // 开始会话按钮
                Button(action: {
                    if !isSessionActive {
                        healthKitManager.requestAuthorization()
                        healthKitManager.startSession()
                        isSessionActive = true
                    }
                }) {
                    Text("Start Session")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isSessionActive ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isSessionActive) // 防止重复开始

                // 停止会话按钮
                Button(action: {
                    if isSessionActive {
                        healthKitManager.stopSession()
                        isSessionActive = false
                    }
                }) {
                    Text("Stop Session")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isSessionActive ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isSessionActive) // 仅在会话进行中可用
            }
            .padding()

            // 手动增加 1 kcal 的按钮
            Button(action: {
                healthKitManager.addManualCalories(1.0)
            }) {
                Text("Manually Add 1 kcal")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .padding()
        .onChange(of: healthKitManager.sessionCalories) { newValue in
            print("Session Calories updated: \(newValue)")
        }
    }
}
```
  - 除此之外，还提供同步心率的 swift 文件，以供创作者自行尝试。[HealthKitManager_HeartRate.swift](./health_data_bridge/HealthKitManager_HeartRate.swift)  [ContentView_HeartRate.swift](./health_data_bridge/ContentView_HeartRate.swift)



### **5.2 Python 数据接收、OSC传输与映射**

- **数据接收**

  - **方式：** Python 使用 Socket 模块搭建 UDP 服务器，监听端口 9000，接收来自 Swift 端的卡路里数据。

  - **消息格式：** Swift 端通过 OSC 协议发送消息，格式为 `/counter,\<calories>`，Python 解析后提取卡路里值。

  - **涉及组件：** 
    `socket` 用于接收健康数据，通过 UDP 协议建立服务器监听数据流。

- **数据传输**

  - 通过 PythonOSC 将接收的数据以同样的 OSC 协议转发到指定的目标端口（默认示例为 Ableton Live 的 9000 端口，OSC 路径为 `/counter`），为 MIDI 映射建立前置条件。

  - **目标地址：** 默认使用 本地回路地址 (127.0.0.1)，但可以根据需求自由定义为任何目标地址，实现跨设备或网络的传输。

  - **涉及组件：**
    `threading` 用于创建独立线程，以并行方式发送 MIDI 音符数据，不阻塞主程序运行。
    `pythonosc.udp\_client` 实现 OSC 消息的发送，将映射后的健康数据传输至目标设备或软件（如 Ableton Live）。

- **数据映射：**
  - **涉及组件：**
    `time` 控制数据发送频率，通过指数平滑算法动态调整时间间隔，确保发送频率更加平滑且符合卡路里变化趋势。
    `random` 生成随机 MIDI 音符，从属七和弦中随机挑选，并避免连续重复音符。
     **更多卡路里消耗对应更高的音符，同时音符播放越密集，反映运动的动态变化。**

  - **卡路里到 MIDI 音符的映射：**
    - 卡路里范围：[0, 100] kcal。
    - MIDI 音符范围：[21 (A0), 108 (C8)]。
    - 映射公式：`midi_note = int(21 + (calories / 100) * (108 - 21))`。

  - **时间间隔映射：**
    - 初始时间间隔：5 秒。
    - 指数平滑公式：`smooth_interval = (1 - ALPHA) * smooth_interval + ALPHA * (5.0 / (calories + 1))`。
    - 限制范围：`interval = max(0.1, smooth_interval)`。

- **示例代码**：[Receive_Calories_Burned.py](./osc_midi_scripts/Receive_Calories_Burned.py)
```python
import socket
import threading
from pythonosc.udp_client import SimpleUDPClient
import time
import random  # 用于随机选择音符

# -----------------------
# 全局变量
# -----------------------
running = True                # 控制线程运行状态
current_calories = 0.0        # 当前卡路里值
root_note = 21                # 初始音符 (Grand Piano 的最低音 A0)
last_note = None              # 记录上一次发送的音符，防止重复

# 发送音符间隔相关：初始间隔 5s，使用指数平滑
smooth_interval = 5.0         # 平滑用的临时变量
current_interval = 5.0        # 实际控制的发送间隔
ALPHA = 0.1                   # 平滑因子（0~1之间，越小越平缓）

# 属七和弦偏移量（根音、大三度、纯五度、小七度）
dominant_seventh_offsets = [0, 4, 7, 10]

# -----------------------
# Socket 配置
# -----------------------
# 设置接收卡路里数据的 Socket
receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
receive_sock.bind(("0.0.0.0", 9000))  # 监听 9000 端口

# 设置 Ableton 的 OSC 客户端
ABLETON_IP = "127.0.0.1"  # 本地回环地址
ABLETON_PORT = 8000       # Ableton 接收 OSC 的端口
client = SimpleUDPClient(ABLETON_IP, ABLETON_PORT)

def map_calories_to_midi(calories):
    """
    将卡路里值映射到 Grand Piano 的 MIDI 音符范围。
    - 卡路里范围: 0~100
    - MIDI 范围: 21~108 (A0 ~ C8)
    """
    midi_note = int(21 + (calories / 100) * (108 - 21))
    return min(max(midi_note, 21), 108)  # 限制范围在 [21, 108]

def send_midi():
    """
    在单独线程中定时发送 MIDI 数据。
    根据 current_interval 调整发送速度（睡眠时间）。
    """
    global running, current_calories, root_note, last_note
    while running:
        # 这里不再判断 current_calories == 0
        # 如果你希望 0 时不发音，可自行加逻辑
        chord_notes = [root_note + offset for offset in dominant_seventh_offsets]

        # 随机选择一个音符发送
        available_notes = [note for note in chord_notes if note != last_note]
        if not available_notes:
            available_notes = chord_notes
        note_to_send = random.choice(available_notes)
        last_note = note_to_send

        # 发送到 Ableton
        client.send_message("/counter", note_to_send)
        print(f"Sent MIDI Note: {note_to_send} (cal: {current_calories}, interval: {current_interval:.2f}s)")

        time.sleep(current_interval)

# 启动线程发送 MIDI 数据
midi_thread = threading.Thread(target=send_midi)
midi_thread.start()

print("Listening for calorie data on port 8000...")

try:
    while True:
        # 接收卡路里数据
        data, addr = receive_sock.recvfrom(1024)
        message = data.decode('utf-8')
        print(f"Received message: {message} from {addr}")

        # 解析卡路里数据并更新当前值
        if message.startswith("/counter,"):
            try:
                calories = float(message.split(",")[1])
                current_calories = calories
                print(f"Current Calories: {current_calories} kcal")

                # (1) 计算原始的目标间隔
                target_interval = 5.0 / (current_calories + 1)

                # (2) 用指数平滑让间隔更柔和
                # 注意，这里直接用全局的 smooth_interval / current_interval，
                # 不要再写 global，否则报 SyntaxError
                smooth_interval = (1 - ALPHA) * smooth_interval + ALPHA * target_interval
                # 限制最小间隔 0.1s
                current_interval = max(0.1, smooth_interval)

                # (3) 更新根音
                root_note = map_calories_to_midi(current_calories)

                print(f"Updated interval: {current_interval:.2f}s, root note: {root_note}")

            except ValueError:
                print("Invalid calorie data")

except KeyboardInterrupt:
    print("Stopping...")
    running = False
    midi_thread.join()
    receive_sock.close()
```

最后再次回到Ableton Live的OSC功能，可参考 Demo1 的操作思路。
