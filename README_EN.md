# OSC Interactive Music: Real-Time Data MIDI Mapping

[中文版](./README.md)

## 1 Introduction

This Demo uses macOS as an example to demonstrate how to transfer camera data, mouse interactions, and health data (e.g., heart rate and calories) to a DAW via the OSC protocol to generate MIDI music in real time (using Ableton Live as an example). The project code is a simplified personal idea, and apart from data acquisition, creators can focus on how to map synthesizer parameters and arrange musical notes, thereby exploring new ideas for music composition and sound design.

---

## 2 Core Features

- **Real-Time Data Collection**:

  - Camera frame brightness, color offset, and motion intensity
  - Mouse movement and clicks
  - Health data: heart rate and calories

- **OSC Data Transmission**:

  - Transmit processed data to Ableton Live or other OSC-compatible software.

- **Music Generation**:

  - Map data to MIDI notes, velocity, and filter parameters.

---

## 3 Tech Stack

- **Python**: Use libraries like OpenCV or Pynput for flexible data reception or acquisition, process the logic, map the data to music parameter ranges, and convert it into OSC-compatible signals for transmission to the DAW via a specified path and port.

- **HealthKit + Xcode (optional)**: Build a bridging app with Xcode to obtain activity data from Apple Watch via the HealthKit component and send the data to Python’s receiving address, providing an additional data-driven approach.

- **Ableton Live (personal choice)**: Receive OSC signals and map them to MIDI synthesizer parameters via Max for Live plugins, converting them into final musical effects.

---

## 4 Demo 1: Camera and Mouse Data

### **4.1 Python Data Capture and OSC Transmission:**

- **Components Involved:**
  pythonosc.udp\_client: Send OSC messages to transmit processed data to Ableton.

- Use PythonOSC to establish UDP communication and transmit data to Ableton Live in real time.

- **Network Configuration:**

  - Local IP Address: 127.0.0.1 (local device communication).
  - UDP Port: 9000 (ensure Ableton listens on the same port).

### **4.2 Camera Data Mapping:**

- Capture frame brightness, color offset, and motion intensity using OpenCV to generate dynamic music. **The mapping relationship can be customized according to the target parameters of the synthesizer.**

- **Data Mapping and Ranges:**

  - **Frame Brightness**: Mapping range is [0, 10], corresponding to chord selection for MIDI Program Change. The range 0-10 reflects the switching of chord types and corresponds to different musical emotions. Path: `/brightness`.
  - **Color Offset**: Mapping range is [-1, 1], corresponding to filter parameter changes to adjust the tonal characteristics of the sound. This range directly reflects the intensity of color differences and creates unique sound textures. Path: `/color_shift`.
  - **Motion Intensity**: Mapping range is [0, 127], used to trigger the intensity of percussion rhythms (MIDI Velocity). This range corresponds to the standard MIDI velocity and effectively controls rhythmic expressiveness. Path: `/motion_intensity`.

- **Components Involved:**
  `cv2`: Used for capturing video frames and image processing, such as calculating brightness and detecting motion intensity.
  `numpy`: Used for efficient mathematical calculations, such as calculating average brightness and frame differences.
  `time`: Controls the time logic of the script, such as frame rate and delays.

- **Sample Code: `Receive_Camera_Data.py`**

```python
import cv2
from pythonosc.udp_client import SimpleUDPClient
import numpy as np
import time

# Configure OSC Client
LOCAL_IP = "127.0.0.1"  # Local loopback address
LOCAL_PORT = 8000       # OSC receiving port
client = SimpleUDPClient(LOCAL_IP, LOCAL_PORT)

# Initialize Camera
cap = cv2.VideoCapture(0)

# Define OSC Addresses
OSC_ADDRESS_BRIGHTNESS = "/brightness"
OSC_ADDRESS_COLOR_SHIFT = "/color_shift"
OSC_ADDRESS_MOTION_INTENSITY = "/motion_intensity"

# Initialize Previous Frame (for Motion Detection)
prev_frame = None

try:
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Convert to Grayscale
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # 1. **Brightness Mapping**: Calculate Average Brightness
        avg_brightness = np.mean(gray)
        client.send_message(OSC_ADDRESS_BRIGHTNESS, avg_brightness)
        print(f"Brightness: {avg_brightness}")

        # 2. **Color Offset Mapping**: Calculate RGB Distribution Offset
        avg_color = frame.mean(axis=(0, 1))  # Get average values for RGB channels
        color_shift = avg_color[2] - avg_color[0]  # Difference between red and blue channels
        client.send_message(OSC_ADDRESS_COLOR_SHIFT, color_shift)
        print(f"Color Shift (Red-Blue): {color_shift}")

        # 3. **Motion Intensity Mapping**: Detect Motion Intensity via Frame Differences
        if prev_frame is not None:
            frame_diff = cv2.absdiff(prev_frame, gray)  # Calculate difference between current and previous frames
            motion_intensity = np.sum(frame_diff) / (frame_diff.shape[0] * frame_diff.shape[1])
            client.send_message(OSC_ADDRESS_MOTION_INTENSITY, motion_intensity)
            print(f"Motion Intensity: {motion_intensity}")

        prev_frame = gray  # Update Previous Frame

        # Display Frames
        cv2.imshow('Camera Feed', frame)

        # Press 'q' to Exit
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except KeyboardInterrupt:
    print("Stopped sending OSC messages.")

finally:
    cap.release()
    cv2.destroyAllWindows()
```

### **4.3 Mouse Data Mapping:**

- Capture mouse position and clicks to dynamically generate melodies and control volume.

- **Components Involved:**
  `pynput.mouse`: Listens to mouse movements and click events, mapping mouse position and actions to musical parameters such as pitch and velocity.
  `random`: Randomly generates data, e.g., MIDI velocity during mouse clicks, to enhance musical expressiveness and diversity.

- **Data Mapping and Ranges:**

  - **Mouse Movement**: Mapping range is [0, 127], corresponding to MIDI Note pitch values. This range is chosen to align with the standard MIDI note range, where lower coordinate values map to lower pitches and higher values map to higher pitches. Path: `/mouse_position`.
  - **Mouse Clicks**: Mapping range is [0, 127], corresponding to MIDI Velocity (volume intensity). This range is chosen to control the dynamic performance of notes, generating rich melodies in combination with the X-coordinate. Path: `/trigger_event`.

- **Sample Code: `mouse_interaction.py`**

```python
from pynput import mouse
from pythonosc.udp_client import SimpleUDPClient
import random

# Configure OSC Client
LOCAL_IP = "127.0.0.1"  # Local loopback address
LOCAL_PORT = 8000       # Port for Ableton
client = SimpleUDPClient(LOCAL_IP, LOCAL_PORT)

# Screen Dimensions (Adjust to your screen resolution)
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

# Callback Function: Mouse Movement
def on_move(x, y):
    # Map Mouse X Coordinate to MIDI Note Number (0–127)
    note = int((x / SCREEN_WIDTH) * 127)
    # Send OSC Message to /counter
    client.send_message("/counter", note)
    print(f"Mouse moved to ({x}, {y}) -> Note: {note}")

# Callback Function: Mouse Click
def on_click(x, y, button, pressed):
    if pressed:
        # Generate Random MIDI Velocity (0–127) on Mouse Click
        velocity = random.randint(0, 127)
        # Send OSC Message to /trigger_event
        client.send_message("/trigger_event", velocity)
        print(f"Mouse clicked at ({x}, {y}) -> Random Velocity: {velocity}")

# Monitor Mouse Activity
with mouse.Listener(on_move=on_move, on_click=on_click) as listener:
    listener.join()
```

### **4.4 Ableton Live MIDI Generation:**

- **OSC Reception and Configuration:** Use the Max for Live OSC Receiver plugin to set up the listening address and port, integrating Python-sent data into Ableton.

- **OSC-to-MIDI Plugin**: Use a custom MIDI Effect plugin in Max for Live to directly convert OSC parameters into MIDI Notes or other dynamic parameter values. For example:
  Generate MIDI Notes from OSC data range [0, 127] and constrain them to a specified scale (e.g., C Major).
  Utilize MIDI Effects functionalities like Scale to ensure notes conform to musical tonality.

- **Synthesizer Parameter Mapping:** After ensuring note generation, use Ableton's Map function to assign other OSC parameters to target MIDI note parameters or synthesizer parameters. For example:

  - **Frame Brightness** mapped to MIDI synthesizer filter frequency (Path: `/brightness`).
  - **Mouse Clicks** mapped to MIDI note intensity (Path: `/trigger_event`).

Through the above steps, Ableton Live can receive and process OSC signals in real time, converting multi-source data into rich musical expressions.

---

## 5 Demo 2: Health Data

### 5.1 Health Data Bridging:

- **Xcode App Development:**

  - Download and install Xcode, create a new iOS project, and select SwiftUI as the UI building tool.
  - Enable the HealthKit framework in project settings and ensure the necessary permissions are added. Create a `HealthKitManager.swift` file to retrieve calorie data.
  - Authorize users to read health data, ensuring privacy compliance.
  - Build the front-end interface in the original `ContentView.swift` to display real-time activity data and trigger authorization logic.
  - Connect the iPhone to Mac via a data cable, trust the computer on the iPhone as prompted, and enable Developer Mode under "Settings > Privacy & Security > Developer Mode."
    Open Xcode, click "Device and Simulators" in the top menu, ensure the iPhone is correctly connected and displayed in the device list, and complete the configuration as prompted.
    Select iPhone in the Xcode target device menu and click "Run" to deploy the app to the iPhone for testing.
  - After running, UDP protocol can send calorie data to the planned Python module for subsequent processing.

- **Correctly Configure HealthKit Permissions in Info.plist**

  - **Locate the Info.plist File**:
    - Open Xcode and select your project name in the left **Project Navigator**.
    - Select **TARGETS** > your app target (e.g., `HealthKitCyclingApp`).
    - Click the **Info** tab at the top.
  - **Add Necessary Permission Descriptions**:
    Under **Custom iOS Target Properties**, manually add the following two items:
    - `NSHealthShareUsageDescription`  **Value**: This app requires access to your health data to display health data information.
    - `NSHealthUpdateUsageDescription`  **Value**: This app requires permission to update your health data.

- **Core Functionality Files:**

  - **`HealthKitManager.swift`**: Responsible for retrieving calorie or heart rate data via the HealthKit framework and sending it to the Python receiver via UDP. The UDP IP address is set to the Mac's IP address (e.g., `192.168.1.142`), ensuring that the iPhone and Mac are on the same network. Below is the core example:

  - **Tips:**
    Ensure that the IP address (oscHost) set in `HealthKitManager` matches your Mac’s actual local network IP address rather than the local loopback `127.0.0.1`, as this would point to the iPhone itself.

  - **Sample Code: `HealthKitManager_CaloriesBurned.swift`**

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

- **`ContentView.swift`**: Provides a real-time UI to display calorie data and trigger HealthKit authorization.
- **Sample Code: `ContentView_CaloriesBurned.swift`**

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

### **5.2 Python Data Reception, OSC Transmission, and Mapping**

- **Data Reception**

  - **Method:** Use Python's Socket module to set up a UDP server that listens on port 8000 and receives calorie data from Swift.
  - **Message Format:** Swift sends messages via the OSC protocol in the format /counter,\<calories>, which Python parses to extract calorie values.
  - **Components Involved:**
    `socket` is used to receive health data and establish a UDP server for data streaming.

- **Data Transmission**

  - Use PythonOSC to forward the received data to the specified target port (default example is Ableton Live's port 9000, OSC path `/counter`), creating prerequisites for MIDI mapping.
  - **Target Address:** Default to the local loopback address (127.0.0.1), but it can be freely defined for cross-device or network transmission as needed.
  - **Components Involved:**
    `threading` creates independent threads to send MIDI note data in parallel without blocking the main program.
    `pythonosc.udp_client` sends OSC messages, transmitting mapped health data to the target device or software (e.g., Ableton Live).

- **Data Mapping:**

  - **Components Involved:**
    `time` controls data transmission frequency, e.g., generating specified playback intervals for MIDI data.
    `random` generates random MIDI notes, randomly selecting from chords to avoid repetitive notes.
    **More calories burned correspond to higher notes, and notes are played more densely, reflecting dynamic changes in activity.**

  - **Calorie-to-MIDI Note Mapping:**

    - Calorie Range: [0, 5] kcal.
    - MIDI Note Range: [21 (A0), 108 (C8)].
    - Mapping Formula: `midi_note = int(21 + (calories / 5) * (108 - 21))`.

  - **Interval Mapping:**

    - Calorie Range: [0, 50] kcal.
    - Interval Range: [0.1, 1.0] seconds.
    - Mapping Formula: `interval = max(0.1, 0.5 / calories)`.

- **Sample Code: `Receive_Calories_Burned.py`**

```python
import socket
import threading
from pythonosc.udp_client import SimpleUDPClient
import time
import random  # Used for random note selection

# Set up a socket to receive calorie data
receive_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
receive_sock.bind(("0.0.0.0", 8000))  # Listen on port 8000

# Set up Ableton's OSC client
ABLETON_IP = "127.0.0.1"  # Local loopback address
ABLETON_PORT = 9000       # Ableton's OSC receiving port
client = SimpleUDPClient(ABLETON_IP, ABLETON_PORT)

# Global variables
total_calories = 0.0  # Total calorie consumption
current_interval = 1.0  # Default note interval: 1 second
root_note = 21  # Initial note (lowest note of Grand Piano, A0)
running = True  # Controls the thread running state
last_note = None  # Records the last sent note to avoid repetition

# Dominant seventh chord offsets
dominant_seventh_offsets = [0, 4, 7, 10]  # Root, major third, perfect fifth, minor seventh

def map_calories_to_midi(calories):
    """
    Map calorie values to the MIDI note range of a Grand Piano.
    - Calorie range: 0-50 kcal
    - MIDI range: 21-108
    """
    midi_note = int(21 + (calories / 50) * (108 - 21))
    return min(max(midi_note, 21), 108)  # Limit range to 21-108

def send_midi():
    """
    Send MIDI data at regular intervals.
    Adjust the sending speed based on current_interval.
    """
    global current_interval, root_note, running, last_note
    while running:
        if total_calories == 0:
            time.sleep(0.1)  # Wait for calorie data to accumulate
            continue

        # Calculate current dominant seventh chord notes
        chord_notes = [root_note + offset for offset in dominant_seventh_offsets]

        # Randomly select a note to send, avoiding consecutive repetition of the same note
        available_notes = [note for note in chord_notes if note != last_note]
        if not available_notes:  # If all notes are used, reset
            available_notes = chord_notes
        note_to_send = random.choice(available_notes)
        last_note = note_to_send  # Update the last sent note

        # Send to Ableton
        client.send_message("/counter", note_to_send)
        print(f"Sent MIDI Note: {note_to_send}")

        time.sleep(current_interval)  # Wait for the next playback

# Start a thread to send MIDI data
midi_thread = threading.Thread(target=send_midi)
midi_thread.start()

print("Listening for calorie data on port 8000...")

try:
    while True:
        # Receive calorie data
        data, addr = receive_sock.recvfrom(1024)
        message = data.decode('utf-8')
        print(f"Received message: {message} from {addr}")

        # Parse calorie data and update total value
        if message.startswith("/counter,"):
            try:
                calories = float(message.split(",")[1])
                total_calories += calories
                print(f"Total Calories Burned: {total_calories} kcal")

                # Calculate new MIDI note and interval
                root_note = map_calories_to_midi(total_calories)
                current_interval = max(0.1, 0.5 / total_calories)  # Limit minimum interval to 0.1 seconds
                print(f"Updated interval: {current_interval} seconds, root note: {root_note}")
            except ValueError:
                print("Invalid calorie data")
except KeyboardInterrupt:
    print("Stopping...")
    running = False
    midi_thread.join()
    receive_sock.close()
```

Finally, returning to the OSC functionality in Ableton Live, you can refer to the operational ideas from Demo 1. Based on dynamic data mapping of heart rate and calorie consumption, the music not only responds to personal states but also creates engaging musical interactions.



