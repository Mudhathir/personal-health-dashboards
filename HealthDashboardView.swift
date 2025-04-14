// MARK: - Main SwiftUI View
import SwiftUI  // Import SwiftUI for building the user interface

struct HealthDashboardView: View {  // Define the main view for the dashboard
    @StateObject var healthKitManager = HealthKitManager()  // Create and observe HealthKitManager instance
    
    var body: some View {
        NavigationView {  // Enables navigation UI with a top bar
            VStack(spacing: 20) {  // Main vertical stack with spacing between UI elements
                Text("Personal Health Dashboards")  // Title text
                    .font(.largeTitle)  // Apply large title font
                    .padding()  // Add padding around the title
                
                VStack(alignment: .leading, spacing: 15) {  // Health metrics section
                    HStack {  // Display steps count
                        Text("Steps Today:")  // Label
                        Spacer()  // Push value to the right
                        Text("\(Int(healthKitManager.stepCount))")  // Display step count value
                    }
                    
                    HStack {  // Display heart rate
                        Text("Latest Heart Rate:")  // Label
                        Spacer()
                        Text(String(format: "%.1f bpm", healthKitManager.heartRate))  // Heart rate value
                    }
                    
                    HStack {  // Display dietary energy consumed
                        Text("Dietary Energy:")  // Label
                        Spacer()
                        Text(String(format: "%.0f kcal", healthKitManager.dietaryEnergyConsumed))  // Energy value
                    }

                    VStack(alignment: .leading) {  // Display sleep data
                        Text("Sleep Analysis:")  // Label
                        if healthKitManager.sleepAnalysis.isEmpty {  // Check if data is available
                            Text("No sleep data available.")  // Placeholder text
                                .italic()
                        } else {
                            ForEach(healthKitManager.sleepAnalysis, id: \..uuid) { sample in  // Loop through sleep samples
                                let start = sample.startDate  // Start time of sleep
                                let end = sample.endDate  // End time of sleep
                                Text("From: \(formattedDate(start)) to: \(formattedDate(end))")  // Display sleep times
                                    .font(.caption)  // Smaller font
                            }
                        }
                    }
                }
                .padding()  // Padding around the metrics
                Spacer()  // Push content to the top
            }
            .onAppear {
                healthKitManager.requestAuthorization()  // Request HealthKit access when view loads
            }
            .navigationBarTitle("Dashboard", displayMode: .inline)  // Set navigation bar title
        }
    }
    
    // Helper function to format dates
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short  // e.g. 6/23/21
        formatter.timeStyle = .short  // e.g. 3:45 PM
        return formatter.string(from: date)
    }
}
