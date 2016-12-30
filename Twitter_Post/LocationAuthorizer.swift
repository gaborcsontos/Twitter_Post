//
//  LocationAuthorizer.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/23/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//
import MapKit
import CoreLocation

public typealias LocationAuthorizerCompletion = (NSError?) -> Void

class LocationAuthorizer {
    
    private let errorDomain = "com.zero.location"
    
    private let completion: LocationAuthorizerCompletion
    
    private let locationManager =  CLLocationManager()
    
     init(completion: @escaping LocationAuthorizerCompletion) {
        self.completion = completion
        
        let status = CLLocationManager.authorizationStatus()
        handleAuthorization(status: status)
    }
    
    func onDeniedOrRestricted(completion: LocationAuthorizerCompletion) {
        let error = errorWithKey("error.access-denied", domain: errorDomain)
        completion(error)
    }
   
    
    func handleAuthorization(status: CLAuthorizationStatus) {
        
        switch status {
        
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.completion(nil)
            }
            break
        case .notDetermined,.denied, .restricted:
            DispatchQueue.main.async {
                self.onDeniedOrRestricted(completion: self.completion)
            }
            break
        }
    }
}
