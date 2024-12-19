import socket
import threading
from pythonosc.udp_client import SimpleUDPClient
import time

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
root_note = 24  # 默认根音 (C1)
data_received = False  # 是否接收到卡路里数据
running = True  # 控制线程运行状态

# 大三和弦偏移量
major_chord_offsets = [0, 4, 7]
note_index = 0  # 用于选择不同的根音

def send_midi():
    """
    定时发送 MIDI 数据。
    根据 current_interval 调整发送速度。
    """
    global current_interval, root_note, running, note_index, data_received
    while running:
        # 如果没有接收到数据，不发送 MIDI
        if not data_received:
            time.sleep(0.1)
            continue

        # 计算当前和弦音符
        chord_notes = [root_note + offset for offset in major_chord_offsets]

        # 确保每次发送不同音符，循环选择
        note_to_send = chord_notes[note_index]
        client.send_message("/counter", note_to_send)
        print(f"Sent MIDI Note: {note_to_send}")

        # 更新索引
        note_index = (note_index + 1) % len(chord_notes)

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

        # 解析卡路里数据并更新累计值
        if message.startswith("/counter,"):
            try:
                calories = float(message.split(",")[1])
                total_calories += calories
                print(f"Total Calories Burned: {total_calories} kcal")

                # 映射到 MIDI 音符间隔和音高
                current_interval = max(0.1, 10.0 / total_calories)  # 限制最小间隔 0.1 秒
                root_note = int(min(96, 24 + (total_calories / 5) * (96 - 24)))  # 映射为 C1 到 C7 范围
                print(f"Updated interval: {current_interval} seconds, root note: {root_note}")

                # 标记接收到数据
                data_received = True
            except ValueError:
                print("Invalid calorie data")
except KeyboardInterrupt:
    print("Stopping...")
    running = False
    midi_thread.join()
    receive_sock.close()
