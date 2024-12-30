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
