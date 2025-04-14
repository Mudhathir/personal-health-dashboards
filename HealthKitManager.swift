// MARK: - HealthKit Manager
import Foundation  // Basic Swift utilities
import HealthKit  // Apple HealthKit framework
import Combine  // Enable observable properties in SwiftUI

class HealthKitManager: ObservableObject {  // Observable class to manage health data
    let healthStore = HKHealthStore()  // HealthKit interface

    @Published var stepCount: Double = 0.0  // Steps taken today
    @Published var heartRate: Double = 0.0  // Latest heart rate
    @Published var sleepAnalysis: [HKCategorySample] = []  // Sleep data
    @Published var dietaryEnergyConsumed: Double = 0.0  // Energy consumed in kcal

    // Define HealthKit data types
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let dietaryEnergyType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!

    // Request access to HealthKit data
    func requestAuthorization() {
        let readTypes: Set<HKObjectType> = [stepType, heartRateType, sleepType, dietaryEnergyType]

        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            if let error = error {
                print("Authorization error: \(error.localizedDescription)")
                return
            }
            if success {
                DispatchQueue.main.async {
                    self.fetchTodayStepCount()
                    self.fetchLatestHeartRate()
                    self.fetchSleepAnalysis()
                    self.fetchDietaryEnergyConsumed()
                }
            }
        }
    }

    // Fetch today's step count
    func fetchTodayStepCount() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
            guard let sum = stats?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.stepCount = sum.doubleValue(for: HKUnit.count())
            }
        }
        healthStore.execute(query)
    }

    // Fetch latest heart rate sample
    func fetchLatestHeartRate() {
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        healthStore.execute(query)
    }

    // Fetch recent sleep analysis
    func fetchSleepAnalysis() {
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let results = samples as? [HKCategorySample] else { return }
            DispatchQueue.main.async {
                self.sleepAnalysis = results
            }
        }
        healthStore.execute(query)
    }

    // Fetch dietary energy consumed
    func fetchDietaryEnergyConsumed() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: dietaryEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
            guard let sum = stats?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.dietaryEnergyConsumed = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        healthStore.execute(query)
    }
}

// MARK: - SwiftUI Preview
struct HealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDashboardView()
    }
}
