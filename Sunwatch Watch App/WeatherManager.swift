//
//  WeatherManager.swift
//  Sunwatch Watch App
//
//  Created by Safira Humaira on 20/05/24.
//

import Foundation
import WeatherKit
import CoreLocation
import os

@MainActor
class WeatherManager: ObservableObject {
    private let logger = Logger(subsystem: "com.safirahum.Sunwatch1", category: "Model")
    static let shared = WeatherManager()
    private let service = WeatherService.shared

    @Published var currentUVIndex: Double = 7.0  // Mock value for testing
    @Published var hourlyUVData: [HourlyUVIndex] = []

    private init() {}

    func fetchWeatherData(for location: CLLocation) {
        Task {
            do {
                let weather = try await service.weather(for: location)
                self.currentUVIndex = Double(weather.currentWeather.uvIndex.value)
                self.hourlyUVData = weather.hourlyForecast.map { HourlyUVIndex(hour: $0.date, value: Double($0.uvIndex.value)) }
            } catch {
                logger.error("Failed to fetch weather data: \(error.localizedDescription)")
            }
        }
    }
}

struct HourlyUVIndex: Identifiable {
    let id = UUID()
    let hour: Date
    let value: Double
}
