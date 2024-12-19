# OSC互动音乐: 实时数据MIDI合成器映射

[ENGLISH VERSION](./README_EN.md)

## 1 简介
本 Demo 以 macOS 为例，展示如何通过 OSC 协议，把摄像头数据、鼠标交互及健康数据（如心率和卡路里）传递到 DAW 实时生成 MIDI 音乐（以 AbletonLive 为例）。项目中的代码仅为简易化的个人思路，除了数据获取，各创作者的关注点可放在如何映射合成器参数与音符编排上，从而拓展编曲与声音设计的新思路。

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

## 3 技术栈

- **Python**: 用 OpenCV 或 Pynput 等方式灵活接收或采集数据，完成逻辑处理，将数据映射到音乐参数值区间，转化为符合 OSC 格式的信号，通过指定路径和端口传输至 DAW 中进行生成。

- **HealthKit + Xcode（非必须）**: 用 Xcode 构建桥接应用，通过 HealthKit 组件获取 AppleWatch 的运动数据，并把数据发送到 Python 的接收地址上，提供额外的数据驱动方式。

- **Ableton Live（个人选择）**: 接收 OS C信号，通过 Max For Live 插件将数据映射到 MIDI 合成器参数，转化为最终音乐效果。

---
## 4 Demo 1：摄像头与鼠标数据

### **4.1 Python 数据抓取与OSC 传输：**

- **涉及组件：**
  pythonosc.udp\_client：实现 OSC 消息的发送，将处理后数据传输至 Ableton。

- 使用 PythonOSC 建立 UDP 通信，将数据实时传输至 Ableton Live。

- **网络配置：**
  - 本地 IP 地址：127.0.0.1（本地设备通信）。
  - UDP 端口：9000（确保 Ableton 监听相同端口）。

### **4.2 摄像头数据映射：**

- 通过 OpenCV 捕捉画面亮度、颜色偏移和运动量，用于生成动态音乐，**映射关系可按照合成器的目标参数自定义设计**。

- **数据映射及区间：**
  - **画面亮度**：映射范围为 [0, 10]，对应 MIDI Program Change 的和弦选择。选择 0-10 的范围是因为此值反映了和弦种类的切换，对应不同音乐情绪的切换。路径：`/brightness`。
  - **颜色偏移**：映射范围为 [-1, 1]，对应滤波器参数变化，用于调整声音的音色特性。此区间直接反映色彩差异强弱，并产生独特的声音纹理。路径：`/color_shift`。
  - **运动量**：映射范围为 [0, 127]，用于触发打击乐的节奏强度（MIDI Velocity）。此区间对应 MIDI 标准的打击力度，能有效控制节奏表现力。路径：`/motion_intensity`。

- **涉及组件：**
  `cv2`：用于捕获视频画面和图像处理，例如计算亮度、检测运动量等。
  `numpy`：用于高效的数学计算，例如计算平均亮度和帧差异。
  `time`：控制脚本运行的时间逻辑，如帧率和延迟。

- **示例代码：[Receive_Camera_Data.py](./osc_midi_scripts/Receive_Camera_Data.py) 

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

### **4.3 鼠标数据映射：**

- 捕获鼠标位置与点击，用于动态生成旋律和音量控制。

- **涉及组件：**
  `pynput.mouse`：用于监听鼠标的移动和点击事件，将鼠标位置和动作映射到音乐参数，如音高和力度。
  `random`：随机生成数据，例如鼠标点击时生成随机的MIDI力度，增加音乐表现力和多样性。

- **数据映射及区间：**
  - **鼠标移动**：映射范围为 [0, 127]，对应 MIDI Note 的音高值。此范围选取是为了贴合 MIDI 标准音符区间，低坐标值映射低音，高坐标值映射高音，路径：`/mouse_position`。
  - **鼠标点击**：映射范围为 [0, 127]，对应 MIDI Velocity（音量强度）。选择该区间是为了控制音符动态表现，与 X 坐标结合生成丰富的旋律，路径：`/trigger_event`。

- **示例代码：[Mouse_Position.py](./osc_midi_scripts/Mouse_Interaction.py)

```python
from pynput import mouse
from pythonosc.udp_client import SimpleUDPClient
import random

# 配置 OSC 客户端
LOCAL_IP = "127.0.0.1"  # 本地回环地址
LOCAL_PORT = 8000       # 发送到 Ableton 的端口
client = SimpleUDPClient(LOCAL_IP, LOCAL_PORT)

# 屏幕的宽高（根据你的屏幕分辨率调整）
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

# 回调函数：鼠标移动
def on_move(x, y):
    # 将鼠标的 X 坐标映射为 MIDI 音符编号 (0–127)
    note = int((x / SCREEN_WIDTH) * 127)
    # 发送 OSC 消息到 /counter
    client.send_message("/counter", note)
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

### **4.4 Ableton Live MIDI生成：**

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

   - **示例代码：`/HealthKitManager_CaloriesBurned.swift`**
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

  - **`ContentView.swift`**: 提供实时 UI，显示卡路里数据并触发 HealthKit 授权。
   - **示例代码：[ContentView_CaloriesBurned.swift](./ContentView_CaloriesBurned.swift)

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack {
            Text("Calories Burned")
                .font(.largeTitle)

            Text("\(healthKitManager.latestCaloriesBurned, specifier: "%.2f") kcal")
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

### **5.2 Python 数据接收、OSC传输与映射**

- **数据接收**
  - **方式：** Python 使用 Socket 模块搭建 UDP 服务器，监听端口 8000，接收来自 Swift 端的卡路里数据。
  - **消息格式：** Swift 端通过 OSC 协议发送消息，格式为 /counter,\<calories>，Python 解析后提取卡路里值。
  - **涉及组件：** 
    `socket` 用于接收健康数据，通过 UDP 协议建立服务器监听数据流。

- **数据传输**
  - 通过 PythonOSC 将接收的数据以同样的 OSC 协议转发到指定的目标端口（默认示例为 Ableton Live 的 9000 端口，OSC 路径为 /counter），为Midi映射建立前置条件。
  - **目标地址：** 默认使用 本地回路地址 (127.0.0.1)，但可以根据需求自由定义为任何目标地址，实现跨设备或网络的传输。
  - **涉及组件：**
    `threading` 用于创建独立线程，以并行方式发送 MIDI 音符数据，不阻塞主程序运行。
    `pythonosc.udp\_client` 实现 OSC 消息的发送，将映射后的健康数据传输至目标设备或软件（如 Ableton Live）。

- **数据映射：**
  - **涉及组件：**
    `time` 控制数据发送频率，例如为 MIDI 数据生成指定的播放间隔。
    `random` 生成随机 MIDI 音符，从和弦中随机挑选避免重复音符。
     **更多卡路里消耗对应更高的音符，同时音符播放越密集，反映运动的动态变化。**

  - **卡路里到 MIDI 音符的映射：**
    - 卡路里范围：[0, 5] kcal。
    - MIDI 音符范围：[21 (A0), 108 (C8)]。
    - 映射公式：`midi_note = int(21 + (calories / 5) * (108 - 21))`。

  - **时间间隔映射：**
    - 卡路里范围：[0, 50] kcal。
    - 时间间隔范围：[0.1, 1.0] 秒。
    - 映射公式：`interval = max(0.1, 0.5 / calories)`。

- **示例代码：[HealthKitManager_HeartRate.swift](./HealthKitManager_HeartRate.swift)
```python
import socket
import threading
from pythonosc.udp_client import SimpleUDPClient
import time
import random  # 用于随机选择音符

# 设置接收卡路里数据的 Socket
receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
receive_sock.bind(("0.0.0.0", 8000))  # 监听 8000 端口

# 设置 Ableton 的 OSC 客户端
ABLETON_IP = "127.0.0.1"  # 本地回环地址
ABLETON_PORT = 9000       # Ableton 接收 OSC 的端口
client = SimpleUDPClient(ABLETON_IP, ABLETON_PORT)

# 全局变量
total_calories = 0.0  # 累计卡路里消耗
current_interval = 1.0  # 默认音符间隔 1 秒
root_note = 21  # 初始音符 (Grand Piano 的最低音 A0)
running = True  # 控制线程运行状态
last_note = None  # 记录上一次发送的音符，防止重复

# 属七和弦偏移量
dominant_seventh_offsets = [0, 4, 7, 10]  # 根音、大三度、纯五度、小七度

def map_calories_to_midi(calories):
    """
    将卡路里值映射到 Grand Piano 的 MIDI 音符范围。
    - 卡路里范围: 0-50 kcal
    - MIDI 范围: 21-108
    """
    midi_note = int(21 + (calories / 50) * (108 - 21))
    return min(max(midi_note, 21), 108)  # 限制范围在 21-108

def send_midi():
    """
    定时发送 MIDI 数据。
    根据 current_interval 调整发送速度。
    """
    global current_interval, root_note, running, last_note
    while running:
        if total_calories == 0:
            time.sleep(0.1)  # 等待卡路里堆叠数据
            continue

        # 计算当前属七和弦音符
        chord_notes = [root_note + offset for offset in dominant_seventh_offsets]

        # 随机选择一个音符发送，避免连续两次选择同一个音
        available_notes = [note for note in chord_notes if note != last_note]
        if not available_notes:  # 如果所有音符都用过，则重置
            available_notes = chord_notes
        note_to_send = random.choice(available_notes)
        last_note = note_to_send  # 更新上一次发送的音符

        # 发送到 Ableton
        client.send_message("/counter", note_to_send)
        print(f"Sent MIDI Note: {note_to_send}")

        time.sleep(current_interval)  # 等待下一次播放

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

        # 解析卡路里数据并更新累计值
        if message.startswith("/counter,"):
            try:
                calories = float(message.split(",")[1])
                total_calories += calories
                print(f"Total Calories Burned: {total_calories} kcal")

                # 计算新的 MIDI 音符和间隔
                root_note = map_calories_to_midi(total_calories)
                current_interval = max(0.1, 0.5 / total_calories)  # 限制最小间隔 0.1 秒
                print(f"Updated interval: {current_interval} seconds, root note: {root_note}")
            except ValueError:
                print("Invalid calorie data")
except KeyboardInterrupt:
    print("Stopping...")
    running = False
    midi_thread.join()
    receive_sock.close()

```

最后再次回到Ableton Live的OSC功能，可参考 Demo 1的操作思路。基于心跳频率和卡路里消耗的动态数据映射，音乐不仅实现了对个人状态的响应。
