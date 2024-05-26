//
//  LocationManager.swift
//  Sunwatch Watch App
//
//  Created by Safira Humaira on 14/05/24.
//

import CoreLocation
import Combine

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let manager = CLLocationManager()
    typealias LocationUpdateHandler = ((CLLocation?, Error?) -> Void)
    private var didUpdateLocation: LocationUpdateHandler?
    
    @Published var location: CLLocation?
    @Published var locationString: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
    }
    
    public func updateLocation(handler: @escaping LocationUpdateHandler) {
        self.didUpdateLocation = handler
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        
        print("Location updated")
        
        CLLocation(latitude: location?.coordinate.latitude ?? 0.0, longitude: location?.coordinate.longitude ?? 0.0).fetchCityAndCountry { postalCode, city, country, error in
            guard let postalCode = postalCode, let city = city, let country = country, error == nil else { return }
            print(postalCode + ", " + city + ", " + country)
            
            self.locationString = postalCode + ", " + city + ", " + country
            
            print(self.locationString!)
        }
        
        if let handler = didUpdateLocation {
            handler(locations.last, nil)
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let handler = didUpdateLocation {
            handler(nil, error)
        }
    }
}

extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ postalCode: String?, _ city: String?, _ country: String?, _ error: Error?) -> ()) {
        return CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.postalCode, $0?.first?.locality, $0?.first?.country, $1) }
    }
}
