import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Health Data")
                .font(.largeTitle)
                .padding()

            // 动态显示卡路里消耗数据
            Text("Latest Calories Burned: \(healthKitManager.latestCaloriesBurned, specifier: "%.2f") kcal")
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
        .onChange(of: healthKitManager.latestCaloriesBurned) { newValue in
            print("Calories Burned updated: \(newValue)")
        }
    }
}
