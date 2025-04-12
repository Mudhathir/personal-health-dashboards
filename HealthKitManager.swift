import Foundation                // Provides essential data types and utilities
import HealthKit                 // Integrates HealthKit to access health data
import Combine                   // Enables reactive programming for SwiftUI updates

class HealthKitManager: ObservableObject {  // Class to manage HealthKit operations, observable for UI updates
    let healthStore = HKHealthStore()         // Instance to interact with HealthKit
    
    // Published properties that update the UI when changed
    @Published var stepCount: Double = 0.0                      // Stores today's step count
    @Published var heartRate: Double = 0.0                        // Stores the latest heart rate reading
    @Published var sleepAnalysis: [HKCategorySample] = []         // Stores sleep analysis samples
    @Published var dietaryEnergyConsumed: Double = 0.0            // Stores dietary energy consumed in kilocalories
    
    // Define HealthKit data types for the metrics we want to read
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!               // Step count data type
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!            // Heart rate data type
    let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!              // Sleep analysis data type
    let dietaryEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!  // Dietary energy data type
    
    // Request authorization to access HealthKit data
    func requestAuthorization() {
        let healthDataToRead: Set<HKObjectType> = [stepType, heartRateType, sleepType, dietaryEnergyType]  // Data types we intend to read
        let healthDataToWrite: Set<HKSampleType> = []   // No data is being written in this case
        
        // Request permission from the user to access the specified data types
        healthStore.requestAuthorization(toShare: healthDataToWrite, read: healthDataToRead) { success, error in
            if let error = error {  // Check for errors during authorization
                print("Authorization error: \(error.localizedDescription)")  // Print error details
                return
            }
            if success {  // If authorization is successful
                DispatchQueue.main.async {
                    // Fetch the health data once the authorization has been granted
                    self.fetchTodayStepCount()          // Fetch today's step count
                    self.fetchLatestHeartRate()          // Fetch the most recent heart rate
                    self.fetchSleepAnalysis()            // Fetch sleep analysis data
                    self.fetchDietaryEnergyConsumed()    // Fetch today's dietary energy consumed
                }
            }
        }
    }
    
    // Fetch the cumulative step count for today
    func fetchTodayStepCount() {
        let startOfDay = Calendar.current.startOfDay(for: Date())    // Determine the start of the current day
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)  // Predicate from start of day to now
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
            guard let statistics = statistics, let sum = statistics.sumQuantity() else {  // Ensure data exists
                print("No step count data available: \(error?.localizedDescription ?? "unknown error")")  // Print error if data is missing
                return
            }
            DispatchQueue.main.async {
                self.stepCount = sum.doubleValue(for: HKUnit.count())  // Update stepCount with the retrieved value
            }
        }
        healthStore.execute(query)  // Execute the query on HealthKit
    }
    
    // Fetch the most recent heart rate sample
    func fetchLatestHeartRate() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)  // Sort by most recent end date
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())  // Set a start date (yesterday)
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictStartDate)  // Predicate from yesterday to now
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], let sample = samples.first else {  // Get the first available sample
                print("No heart rate sample: \(error?.localizedDescription ?? "unknown error")")  // Log error if necessary
                return
            }
            DispatchQueue.main.async {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))  // Update heartRate with the latest reading
            }
        }
        healthStore.execute(query)  // Execute the query on HealthKit
    }
    
    // Fetch sleep analysis data (e.g., from last night)
    func fetchSleepAnalysis() {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return }  // Calculate the start of yesterday
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)  // Predicate covering the last 24 hours
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else {  // Ensure sleep
