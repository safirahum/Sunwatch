//
//  ContentView.swift
//  Sunwatch Watch App
//
//  Created by Safira Humaira on 14/05/24.
//

import SwiftUI
import HealthKit
import CoreLocation
import Charts

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager.shared
    private var healthStore = HKHealthStore()
    @State private var showReminder = false
    @State private var timer: Timer?
    @State private var remainingTime: TimeInterval?

    var body: some View {
        ScrollView{
                VStack {
                    Text("Current UV Index")
                        .font(.custom("SF Compact", size: 15).weight(.heavy))

                    Gauge(value: weatherManager.currentUVIndex, in: 0...11) {
                        Text("")
                    } currentValueLabel: {
                        Text(String(format: "%.1f", weatherManager.currentUVIndex))
                            .font(.custom("SF Compact", size: 14).bold())
                            .foregroundColor(weatherManager.currentUVIndex > 5 ? .red : .green)
                    } minimumValueLabel: {
                        Text("0")
                            .font(.custom("SF Compact", size: 12))
                    } maximumValueLabel: {
                        Text("11")
                            .font(.custom("SF Compact", size: 12))
                    }
                    .gaugeStyle(CircularGaugeStyle(tint: weatherManager.currentUVIndex > 5 ? Gradient(colors: [.yellow, .orange, .red]) : Gradient(colors: [.green, .blue])))
                    .frame(width: 100, height: 100)
                }

                if weatherManager.currentUVIndex > 5 {
                    Text("UV is high, apply sunscreen.")
                        .foregroundColor(.white)
                        .font(.custom("SF Compact", size: 12))

                    Button(action: {
                        if timer == nil {
                            startTimer()
                            saveSunExposureToHealthKit()
                        } else {
                            timer?.invalidate()
                            timer = nil
                            remainingTime = nil
                        }
                    }) {
                        if let remainingTime = remainingTime {
                            Text(timeString(from: remainingTime))
                                .font(.custom("SF Compact", size: 14))
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Apply")
                                .font(.custom("SF Compact", size: 14))
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    .padding()
                } else {
                    Text("UV is low, stay safe.")
                        .foregroundColor(.green)
                        .font(.custom("SF Compact", size: 13))
                }
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.orange .opacity(0.5), Color.black]), startPoint: .top, endPoint: .bottom))
        .background()
        .onAppear {
            requestHealthKitAuthorization()
            locationManager.updateLocation { location, error in
                if let location = location {
                    weatherManager.fetchWeatherData(for: location)
                }
            }
        }
    }

    func requestHealthKitAuthorization() {
        let readTypes: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .uvExposure)!]
        let writeTypes: Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: .uvExposure)!]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { (success, error) in
            if !success {
                print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    func saveSunExposureToHealthKit() {
        let uvExposureType = HKObjectType.quantityType(forIdentifier: .uvExposure)!
        let now = Date()
        let sample = HKQuantitySample(type: uvExposureType, quantity: HKQuantity(unit: HKUnit.count(), doubleValue: weatherManager.currentUVIndex), start: now, end: now)

        healthStore.save(sample) { success, error in
            if success {
                print("UV exposure data saved to HealthKit.")
            } else if let error = error {
                print("Error saving UV exposure data: \(error.localizedDescription)")
            }
        }
    }

    func startTimer() {
        remainingTime = 3 * 60 * 60 // 3 hours in seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let remainingTime = self.remainingTime, remainingTime > 0 {
                self.remainingTime = remainingTime - 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }

    func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
