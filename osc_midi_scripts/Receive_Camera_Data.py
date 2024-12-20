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
