# OSC Interactive Music: Real-Time Data to MIDI Mapping

## OSC 互动音乐：实时数据映射为 MIDI 音符

### 项目简介 | Project Overview

**English**:

This project demonstrates how real-time data inputs (camera visuals, mouse movements, and health metrics) can dynamically control MIDI music generation using OSC (Open Sound Control). It explores interactive sound mapping, combining user actions, visuals, and biological data into dynamic audio outputs.

**中文**：

本项目展示如何通过摄像头数据、鼠标交互及健康数据（如心率和卡路里），实时控制 MIDI 音乐生成，使用 OSC（开放声音控制）协议传输数据。项目探索了用户行为、视觉反馈与生物数据如何结合，创造互动的动态音乐体验。

---

### 核心功能 | Key Features

- **实时数据采集 | Real-Time Data Input**:
  - Camera brightness, motion intensity (摄像头亮度与运动量)
  - Mouse movement and clicks (鼠标移动与点击)
  - Health metrics: Heart rate, calories (健康数据：心率与卡路里)

- **OSC 数据传输 | OSC Communication**:
  - Transmit processed data to Ableton Live or other OSC-compatible software.
  - 将处理后的数据传输到 Ableton Live 或其他支持 OSC 的软件。

- **音乐生成 | Music Generation**:
  - Map data to MIDI notes, velocity, and filter parameters.
  - 将数据映射为 MIDI 音符、力度和滤波器参数，实现动态音乐生成。

---

### 技术栈 | Technology Stack

- **Python**: Data input, processing, and OSC message transmission.
- **OpenCV**: Camera data analysis (brightness and motion).
- **Pynput**: Mouse movement and click capture.
- **HealthKit + Xcode**: Transmit heart rate and calorie data from iPhone.
- **Ableton Live**: Map OSC data to MIDI notes and synth parameters.

---

## 项目 1：摄像头与鼠标数据

### Python 数据抓取与 OSC 传输

#### 涉及组件
- **pythonosc.udp_client**: 实现 OSC 消息的发送，将处理后数据传输至 Ableton。
- **网络配置**:
  - 本地 IP 地址：127.0.0.1（本地设备通信）。
  - UDP 端口：9000（确保 Ableton 监听相同端口）。

#### 摄像头数据映射

- **数据映射及区间**:
  - **画面亮度**: 映射范围为 [0, 10]，对应 MIDI Program Change 的和弦选择。
  - **颜色偏移**: 映射范围为 [-1, 1]，对应滤波器参数变化。
  - **运动量**: 映射范围为 [0, 127]，用于触发打击乐的节奏强度（MIDI Velocity）。

#### 示例代码
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

try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # 转为灰度图
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # 1. **亮度映射**: 计算平均亮度
        avg_brightness = np.mean(gray)
        client.send_message(OSC_ADDRESS_BRIGHTNESS, avg_brightness)
        print(f"Brightness: {avg_brightness}")

        # 2. **颜色偏移映射**: 计算 RGB 分布偏移
        avg_color = frame.mean(axis=(0, 1))  # 获取 RGB 三通道平均值
        color_shift = avg_color[2] - avg_color[0]  # 红色与蓝色通道的差异
        client.send_message(OSC_ADDRESS_COLOR_SHIFT, color_shift)
        print(f"Color Shift (Red-Blue): {color_shift}")

        # 3. **运动量映射**: 通过帧差异检测运动强度
        if prev_frame is not None:
            frame_diff = cv2.absdiff(prev_frame, gray)  # 计算当前帧与前一帧的差异
            motion_intensity = np.sum(frame_diff) / (frame_diff.shape[0] * frame_diff.shape[1])
            client.send_message(OSC_ADDRESS_MOTION_INTENSITY, motion_intensity)
            print(f"Motion Intensity: {motion_intensity}")

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

---

### 鼠标数据映射

- **捕获鼠标位置，用于动态生成旋律和音量控制**

#### 示例代码
```python
from pynput import mouse
from pythonosc.udp_client import SimpleUDPClient
import random

# 配置 OSC 客户端
LOCAL_IP = "127.0.0.1"
LOCAL_PORT = 8000
client = SimpleUDPClient(LOCAL_IP, LOCAL_PORT)

# 回调函数：鼠标移动
def on_move(x, y):
    note = int((x / 1920) * 127)
    client.send_message("/mouse/x", note)
    print(f"Mouse moved to ({x}, {y}) -> Note: {note}")

# 回调函数：鼠标点击
def on_click(x, y, button, pressed):
    if pressed:
        velocity = random.randint(0, 127)
        client.send_message("/trigger_event", velocity)
        print(f"Mouse clicked at ({x}, {y}) -> Random Velocity: {velocity}")

with mouse.Listener(on_move=on_move, on_click=on_click) as listener:
    listener.join()
```

---

## 项目 2：健康数据 | Project 2: Health Data

### 健康数据桥接 | Health Data Bridging

- **Xcode App 开发 | Xcode App Development:**

  - 下载并安装 Xcode，创建一个新的 iOS 项目，选择 SwiftUI 作为界面构建工具。
    Download and install Xcode, create a new iOS project, and select SwiftUI as the interface framework.

  - 在项目设置中启用 HealthKit 框架，确保添加所需权限。通过创建一个`HealthKitManager.swift` 文件完成对卡路里数据的获取。
    Enable the HealthKit framework in project settings and ensure required permissions are added. Use a `HealthKitManager.swift` file to retrieve calorie data.

  - 授权用户读取健康数据，确保隐私合规性。
    Authorize user access to health data while ensuring privacy compliance.

  - 在原始的 `ContentView.swift` 中构建前端界面，显示实时卡路里消耗并触发授权逻辑。
    Build a frontend interface in the original `ContentView.swift` to display real-time calorie consumption and trigger authorization logic.

  - 将 iPhone 使用数据线连接到 Mac，在 iPhone 上按照提示信任计算机，并在“设置 > 隐私与安全 > 开发者模式”中启用开发者模式。
    Connect the iPhone to the Mac via a data cable, trust the computer on the iPhone, and enable Developer Mode under "Settings > Privacy & Security."

    打开 Xcode，点击顶部菜单中的“设备和模拟器”（Device and Simulators），确保 iPhone 已正确连接并显示在设备列表中，依据提示完成配置。
    Open Xcode, click "Devices and Simulators" in the top menu, and ensure the iPhone is connected and displayed in the device list. Follow the prompts to complete the configuration.

    在 Xcode 的目标设备菜单中选择 iPhone，点击“运行”（Run）按钮，将应用部署到 iPhone 进行测试。
    Select the iPhone in Xcode's target device menu, click "Run," and deploy the app to the iPhone for testing.

  - 运行后就可过 UDP 协议将卡路里数据发送至计划的 Python 模块以供后续处理。
    Once running, calorie data can be sent over UDP to a designated Python module for further processing.



- **核心功能文件 | Core Functional Files:**

  - `HealthKitManager.swift`: 负责通过 HealthKit 框架获取卡路里数据，并通过 UDP 将数据发送至 Python 接收端。UDP 的 IP 地址设置为Mac的IP地址（`192.168.1.142` 为我 Mac 的地址），确保 iPhone 和 Mac 处于同一网络环境。
    Responsible for retrieving calorie data via the HealthKit framework and sending it to the Python receiver through UDP. The UDP IP address is set to the Mac's IP address (`192.168.1.142` in my case), ensuring both the iPhone and Mac are on the same network.

  - **Tips:**
    确保你在 HealthKitManager 中设置的 IP 地址 (oscHost) 为你 Mac 的实际局域网 IP 地址，而不是本地回路 127.0.0.1，因为这会指向 iPhone 自身。
    Ensure that the IP address (oscHost) set in HealthKitManager is the actual LAN IP address of your Mac, not the local loopback 127.0.0.1, as that will point to the iPhone itself.

```swift
import Foundation
import HealthKit
import Network

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var latestCaloriesBurned: Double = 0.0

    private var connection: NWConnection?
    private let oscHost = "192.168.1.142"
    private let oscPort: UInt16 = 8000

    init() {
        setupConnection()
    }

    func setupConnection() {
        connection = NWConnection(host: NWEndpoint.Host(oscHost), port: NWEndpoint.Port(rawValue: oscPort)!, using: .udp)
        connection?.start(queue: .main)
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        healthStore.requestAuthorization(toShare: nil, read: [energyType]) { success, _ in
            if success {
                self.startCaloriesQuery()
            }
        }
    }

    func startCaloriesQuery() {
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKObserverQuery(sampleType: energyType, predicate: nil) { _, _, _ in
            self.fetchLatestCaloriesBurned()
        }
        healthStore.execute(query)
    }

    func fetchLatestCaloriesBurned() {
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKSampleQuery(sampleType: energyType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.latestCaloriesBurned = sample.quantity.doubleValue(for: .kilocalorie())
                self.sendCaloriesToOSC(self.latestCaloriesBurned)
            }
        }
        healthStore.execute(query)
    }

    func sendCaloriesToOSC(_ calories: Double) {
        guard let connection = connection else { return }
        let message = "/counter,\(calories)"
        connection.send(content: message.data(using: .utf8), completion: .contentProcessed { _ in })
    }
}
```

  - `ContentView.swift`****:** 提供实时 UI，显示卡路里数据并触发 HealthKit 授权。
     Provides a real-time UI to display calorie data and trigger HealthKit authorization.

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack {
            Text("Calories Burned")
                .font(.largeTitle)

            Text("\(healthKitManager.latestCaloriesBurned, specifier: \"%.2f\") kcal")
                .padding()

            Button("Request Authorization") {
                healthKitManager.requestAuthorization()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
```




ABLETON_PORT = 9000
client = SimpleUDPClient(ABLETON_IP, ABLETON_PORT)

def map_calories_to_midi(calories):
    midi_note = int(21 + (calories / 50) * (108 - 21))
    return min(max(midi_note, 21), 108)

def send_midi():
    global running
    while running:
        time.sleep(1)  # 模拟发送数据
```
通过Ableton Live的OSC功能，这些数据可以轻松映射到MIDI参数中。更多细节可参考项目1的操作。

