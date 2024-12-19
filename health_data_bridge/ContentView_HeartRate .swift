import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Health Data")
                .font(.largeTitle)
                .padding()

            // 动态显示心率数据
            Text("Latest Heart Rate: \(healthKitManager.latestHeartRate, specifier: "%.2f") bpm")
                .padding()

            // 授权按钮
            Button(action: {
                healthKitManager.requestAuthorization()
            }) {
                Text("Request HealthKit Authorization")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        // 显式监听数据变化（仅调试用途，可删除）
        .onChange(of: healthKitManager.latestHeartRate) { newValue in
            print("Heart Rate updated: \(newValue)")
        }
    }
}
