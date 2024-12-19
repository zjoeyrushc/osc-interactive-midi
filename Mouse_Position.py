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
