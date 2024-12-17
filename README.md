# OSC Interactive Music: Real-Time Data to MIDI Mapping  
# OSC 互动音乐：实时数据映射为 MIDI 音符  

## 项目简介 | Project Overview  
**English**:  
This project demonstrates how real-time data inputs (camera visuals, mouse movements, and health metrics) can dynamically control MIDI music generation using OSC (Open Sound Control). It explores interactive sound mapping, combining user actions, visuals, and biological data into dynamic audio outputs.  

**中文**：  
本项目展示如何通过摄像头数据、鼠标交互及健康数据（如心率和卡路里），实时控制 MIDI 音乐生成，使用 OSC（开放声音控制）协议传输数据。项目探索了用户行为、视觉反馈与生物数据如何结合，创造互动的动态音乐体验。  

---

## 核心功能 | Key Features  
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

## 技术栈 | Technology Stack  
- **Python**: Data input, processing, and OSC message transmission.  
- **OpenCV**: Camera data analysis (brightness and motion).  
- **Pynput**: Mouse movement and click capture.  
- **HealthKit + Xcode**: Transmit heart rate and calorie data from iPhone.  
- **Ableton Live**: Map OSC data to MIDI notes and synth parameters.  

---

## 项目目录 | Project Structure  
```plaintext
osc-interactive-music/
├── src/
│   ├── camera_osc.py         # 摄像头数据到 OSC
│   ├── mouse_osc.py          # 鼠标数据到 OSC
│   ├── healthkit_to_osc/     # 健康数据桥接 (Swift 文件)
│   └── midi_mapper.py        # 数据到 MIDI 映射
├── docs/
│   └── setup_guide.md        # 环境配置指南
├── examples/
│   └── demo_video.mp4        # 演示视频
├── requirements.txt          # Python 依赖包列表
└── README.md                 # 项目说明文件
