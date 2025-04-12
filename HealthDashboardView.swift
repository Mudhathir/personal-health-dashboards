import SwiftUI  // Import SwiftUI for building the user interface

struct HealthDashboardView: View {  // Define the main view for the dashboard
    @StateObject var healthKitManager = HealthKitManager()  // Create and observe HealthKitManager instance
    
    var body: some View {
        NavigationView {  // Enables a navigation bar at the top
            VStack(spacing: 20) {  // Vertical stack with 20 points of spacing between elements
                Text("Personal Health Dashboards")  // Title text
                    .font(.largeTitle)               // Set font size to large title
                    .padding()                       // Add padding around the title
                
                VStack(alignment: .leading, spacing: 15) {  // Group health data items, aligned to the left with spacing of 15
                    HStack {  // Horizontal stack for steps data
                        Text("Steps Today:")                   // Label for steps
                        Spacer()                               // Space between label and value
                        Text("\(Int(healthKitManager.stepCount))")  // Display step count as an integer
                    }
                    
                    HStack {  // Horizontal stack for heart rate data
                        Text("Latest Heart Rate:")                        // Label for heart rate
                        Spacer()                                        // Space between label and value
                        Text(String(format: "%.1f bpm", healthKitManager.heartRate))  // Format and display heart rate
                    }
                    
                    HStack {  // Horizontal stack for dietary energy data
                        Text("Dietary Energy:")                     // Label for energy consumed
                        Spacer()                                   // Space between label and value
                        Text(String(format: "%.0f kcal", healthKitManager.dietaryEnergyConsumed))  // Format and display energy consumed
                    }
                    
                    VStack(alignment: .leading) {  // Vertical stack for sleep analysis data
                        Text("Sleep Analysis:")  // Label for sleep analysis
                        if healthKitManager.sleepAnalysis.isEmpty {  // Check if sleep data is empty
                            Text("No sleep data available.")        // Inform user when data is missing
                                .italic()                             // Italicize the message
                        } else {
                            // Display each sleep sample with start and end times
                            ForEach(healthKitManager.sleepAnalysis, id: \.uuid) { sample in
                                let start = sample.startDate      // Get start date of sleep sample
                                let end = sample.endDate          // Get end date of sleep sample
                                Text("From: \(formattedDate(start)) to: \(formattedDate(end))")  // Format dates for display
                                    .font(.caption)             // Use caption font size
                            }
                        }
                    }
                }
                .padding()  // Add padding around the health data section
                Spacer()     // Add flexible space to push content upward
            }
            .onAppear {
                // When the view appears, request HealthKit permissions and fetch data
                healthKitManager.requestAuthorization()
            }
            .navigationBarTitle("Dashboard", displayMode: .inline)  // Set the navigation bar title
        }
    }
    
    // Helper function to format Date objects into readable strings
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()       // Create a new DateFormatter
        formatter.dateStyle = .short           // Set date style to short (e.g., 6/23/21)
        formatter.timeStyle = .short           // Set time style to short (e.g., 3:45 PM)
        return formatter.string(from: date)    // Return the formatted date string
    }
}

struct HealthDashboardView_Previews: PreviewProvider {  // SwiftUI preview structure
    static var previews: some View {
        HealthDashboardView()  // Preview the HealthDashboardView
    }
}
