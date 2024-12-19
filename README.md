# OSC Interactive Music: Real-Time Data to MIDI Mapping

## 项目简介 | Project Overview

**English**:
This project demonstrates how real-time data inputs (camera visuals, mouse movements, and health metrics) can dynamically control MIDI music generation using OSC (Open Sound Control). It explores interactive sound mapping, combining user actions, visuals, and biological data into dynamic audio outputs.

**中文**:
本项目展示如何通过摄像头数据、鼠标交互及健康数据（如心率和卡路里），实时控制 MIDI 音乐生成，使用 OSC（开放声音控制）协议传输数据。项目探索了用户行为、视觉反馈与生物数据如何结合，创造互动的动态音乐体验。

---

## 核心功能 | Key Features

- **实时数据采集 | Real-Time Data Input**:

  - 摄像头亮度与运动量 | Camera brightness and motion intensity.
  - 鼠标移动与点击 | Mouse movement and clicks.
  - 健康数据：心率与卡路里 | Health metrics: Heart rate and calories burned.

- **OSC 数据传输 | OSC Communication**:

  - 将处理后的数据传输到 Ableton Live 或其他支持 OSC 的软件。
  - Transmit processed data to Ableton Live or other OSC-compatible software.

- **音乐生成 | Music Generation**:

  - 将数据映射为 MIDI 音符、力度和滤波器参数。
  - Map data to MIDI notes, velocity, and filter parameters for dynamic music generation.

---

## 技术栈 | Technology Stack

- **Python**: 数据输入、处理和 OSC 消息传输 | Data input, processing, and OSC message transmission.
- **OpenCV**: 摄像头数据分析 | Camera data analysis (brightness and motion).
- **Pynput**: 鼠标移动和点击捕捉 | Mouse movement and click capture.
- **HealthKit + Xcode**: 从 iPhone 传输心率和卡路里数据 | Transmit heart rate and calorie data from iPhone.
- **Ableton Live**: 映射 OSC 数据到 MIDI 音符和合成器参数 | Map OSC data to MIDI notes and synth parameters.

---

## 项目 1：摄像头与鼠标数据 | Project 1: Camera and Mouse Data

### Python 数据抓取与 OSC 传输 | Python Data Capture and OSC Transmission

#### 涉及组件 | Components

- **pythonosc.udp\_client**: 实现 OSC 消息的发送，将处理后数据传输至 Ableton。
  Implements OSC message sending to transmit processed data to Ableton.
- **网络配置 | Network Configuration**:
  - 本地 IP 地址：127.0.0.1（本地设备通信）。
    Local IP address: 127.0.0.1 (local device communication).
  - UDP 端口：9000（确保 Ableton 监听相同端口）。
    UDP Port: 9000 (ensure Ableton listens on the same port).

#### 摄像头数据映射 | Camera Data Mapping

- **数据映射及区间 | Data Mapping and Range**:
  - **画面亮度 | Brightness**: 映射范围为 [0, 10]，对应 MIDI Program Change 的和弦选择。
    Mapped range [0, 10], corresponds to MIDI Program Change chord selection.
  - **颜色偏移 | Color Shift**: 映射范围为 [-1, 1]，对应滤波器参数变化。
    Mapped range [-1, 1], corresponds to filter parameter changes.
  - **运动量 | Motion Intensity**: 映射范围为 [0, 127]，用于触发打击乐的节奏强度（MIDI Velocity）。
    Mapped range [0, 127], triggers percussion rhythm intensity (MIDI Velocity).

#### 示例代码 | Example Code

\- [Receive\_Camera\_Data.py]\(./Receive\_Camera\_Data.py)

---

## 项目 2：健康数据 | Project 2: Health Data

### 健康数据桥接 | Health Data Integration

#### 核心功能文件 | Key Functional Files

1. **HealthKitManager.swift**: 通过 HealthKit 获取健康数据并通过 UDP 发送至 Python。
2. **ContentView\.swift**: 提供实时 UI，显示健康数据并触发授权逻辑。

---

### Python 数据接收与映射 | Python Data Reception and Mapping

#### 示例代码 | Example Code



---

通过此项目，用户可基于健康数据和互动行为，实时生成动态音乐，为个人创作独特的音频体验。

