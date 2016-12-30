//
//  LocationManager.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//


import CoreLocation
import MapKit


public typealias LocationManagerSuccess = (String?, CLLocation?) -> Void
public typealias LocationManagerFailure = (NSError) -> Void


public class LocationManager: NSObject, CLLocationManagerDelegate {
    
    public enum Location: Int {
        case City
        case SubLocality
    }
    
    private let errorDomain = "com.zero.locationManager"
    
    private var success: LocationManagerSuccess?
    private var failure: LocationManagerFailure?
    
    //Location Manager
    private let locationManager = CLLocationManager()

    private var location: Location = Location.City
    
    public override init() { }
    
    
    public func onSuccess(_ success: @escaping LocationManagerSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping LocationManagerFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func getLocation(_ sybType: Location) -> Self {
        
        _ = LocationAuthorizer { error in
            
            if error == nil {
                
                //set the locationType to City or SubLocality
                self.location = sybType
                self._getLocation()
                
            } else {
                if CLLocationManager.locationServicesEnabled() {
                    self.locationManager.requestWhenInUseAuthorization()
                    self._getLocation()
                    
                } else {
                     self.failure?(error!)
                }
               
              
            }
        }
        return self
    }
    
    func _getLocation() {
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
        
    }
    


    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){

        
        if let location = locations.first {
            
        self.locationManager.stopUpdatingLocation()
            
            let geocoder = CLGeocoder()
            
            let userlocation = location.coordinate
            
            geocoder.reverseGeocodeLocation(CLLocation(latitude: userlocation.latitude,longitude: userlocation.longitude), completionHandler: {
                
                placemarks, error in
                
                if (error != nil) {
                    
                    let error = errorWithKey("error.cant-get-location", domain: self.errorDomain)
                    self.failure?(error)
                    
                    return
                }
                
                if placemarks!.count > 0 {
                    
                    let placemark = CLPlacemark(placemark: placemarks![0] as CLPlacemark)
                    
                    switch self.location {
                    case .City: self.success?(placemark.locality, location)
                    case .SubLocality: self.success?(placemark.subLocality, location)
                    }
                } else {
                    let error = errorWithKey("error.cant-get-location", domain: self.errorDomain)
                    self.failure?(error)
                }
            })
            
        } else {
            
            let error = errorWithKey("error.cant-get-location", domain: self.errorDomain)
            self.failure?(error)
        }
        
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
     //   self.locationManager.stopUpdatingLocation()
        let error = errorWithKey("error.cant-get-location", domain: self.errorDomain)
        self.failure?(error)
    }
    
    
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted, .notDetermined:
            let error = errorWithKey("error.cant-get-location", domain: self.errorDomain)
            self.failure?(error)
            
            return
        default:
        break//    self.locationManager.startUpdatingLocation()
        }
    }
}


//distance manager
internal func getDistance(_ currentLocation: CLLocation, placeLocation: CLLocation) -> String {
    let distanceInMeters = placeLocation.distance(from: currentLocation)
    let formatter = MKDistanceFormatter()
    formatter.unitStyle = .abbreviated
    let distanceString = formatter.string(fromDistance: distanceInMeters)
    
    return distanceString
}
