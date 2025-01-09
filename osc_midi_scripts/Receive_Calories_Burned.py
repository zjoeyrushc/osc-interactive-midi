import socket
import threading
from pythonosc.udp_client import SimpleUDPClient
import time
import random  # 用于随机选择音符

# 设置接收卡路里数据的 Socket
receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
receive_sock.bind(("0.0.0.0", 9000))  # 监听 9000 端口

# 设置 Ableton 的 OSC 客户端
ABLETON_IP = "127.0.0.1"  # 本地回环地址
ABLETON_PORT = 8000       # Ableton 接收 OSC 的端口
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
