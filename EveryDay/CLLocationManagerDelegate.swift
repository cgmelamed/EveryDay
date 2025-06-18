//
//  CLLocationManagerDelegate.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/28/24.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI
import Photos
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var locationDescription: String?
    
    private let locationManager = CLLocationManager()
    private var completionHandler: ((String?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func requestLocation(completion: @escaping (String?) -> Void) {
        print("Location request received")
        completionHandler = completion
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            print("Location services enabled")
            locationManager.startUpdatingLocation()
        } else {
            print("Location services disabled")
            completion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("Location updated: \(location)")
            currentLocation = location
            getLocationDescription()
        }
    }
    
    private func getLocationDescription() {
        guard let location = currentLocation else {
            print("No current location available")
            completionHandler?(nil)
            return
        }
        
        print("Getting location description...")
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                self.completionHandler?(nil)
            } else if let placemark = placemarks?.first {
                if let city = placemark.locality, let state = placemark.administrativeArea {
                    print("Location description: \(city), \(state)")
                    self.completionHandler?("\(city), \(state)")
                } else if let country = placemark.country {
                    print("Location description: \(country)")
                    self.completionHandler?(country)
                } else {
                    print("Unknown location")
                    self.completionHandler?("Unknown")
                }
            } else {
                print("No placemarks found")
                self.completionHandler?(nil)
            }
            
            self.locationManager.stopUpdatingLocation()
        }
    }
}
