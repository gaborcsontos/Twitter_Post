//
//  GooglePlacePicker.swift
//  GoogleLocationPicker
//
//  Created by Gabor Csontos on 9/4/16.
//  Copyright © 2016 GabeMajorszki. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


/*
 
 Don't forget to add these lines into your Info.plist !!!
 
 Privacy - Location When in Use Usage Description ------ We need to access your location.
 
 */


//Here you can ask your unique GoogleApiKey from Google
////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////


//FROM GOOGLE YOU CAN ASK AN API KEY FROM THIS LINK:
//https://developers.google.com/maps/documentation/ios-sdk/get-api-key

public var GoogleMapsAPIServerKey = "AIzaSyDRwuyhNzcXy7TZSGUGUp8P81zxyxdNNdE" //YOUR PRIVATE API KEY


////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////






//LocationPickerController delegate
protocol LocationPickerControllerDelegate: class {
     func removeLocation() //to remove location String
     func addPlace(_ place: String?) //to add location String
}


extension GooglePlacePicker: GoogleDelegate {
    
    func addPlace(_ place: String?) {
        self.tagUserPlace(place)
    }
}
class GooglePlacePicker: UITableViewController,CLLocationManagerDelegate {
    
    
    private let poweredByIcon = UIImage(named: "powered_by_google_on_white")

    //loaded places provided by Google
    var places = [PlaceDetails]()
    
    //current place provided by CoreLocation
    var locationManager: LocationManager!
    var currentPlace: String?
    var currentCLLocation: CLLocation?
    
    
    
    lazy var controller: GooglePlacesSearchController = {
        let controller = GooglePlacesSearchController(
    apiKey: GoogleMapsAPIServerKey, placeType: PlaceType.all)
        controller.gpaViewController.googleDelegate = self
        return controller
    }()
    
    
    weak var delegate: LocationPickerControllerDelegate?
    
    lazy var leftBarButton : UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Remove", style: .plain, target: self, action: #selector(self.remove))
        return button
    }()
    
    lazy var rightBarButton : UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.done))
        return button
    }()
    
    
    
    
    func tagPlace(place: PlaceDetails?){
        
        guard let place = place else {
            return
        }
        
        /*
        print(place.name)
        print(place.country)
        print(place.coordinate)
        //etc etc etc
         */
    
        tagUserPlace(place.name)

    }
    

    
    //remove button
    func remove(){
        
        self.dismiss(animated: true, completion: {
            
            self.delegate?.removeLocation()
        })
      
    }
    
    //done button
    func done(){
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //tag place
    func tagUserPlace(_ place: String?) {
        
        self.dismiss(animated: true, completion: {
            
            self.delegate?.addPlace(place)
        })
        
    }
    
    
   
    
    //getting the currentLocation
    public init(currentLocation: String?) {
        self.currentPlace = currentLocation
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        self.title = "Tag location"
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(LocationTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.register(CurrentLocationTableViewCell.self, forCellReuseIdentifier: "location")
        let backView = UIView(frame: self.tableView.bounds)
        backView.backgroundColor =  UIColor.white// or whatever color
        self.tableView.backgroundView = backView
    
        
        //hide the separator
        for parent in self.navigationController!.navigationBar.subviews {
            for childView in parent.subviews {
                if(childView is UIImageView) {
                    childView.isHidden = true
                }
            }
        }
        
        self.definesPresentationContext = true
        controller.hidesNavigationBarDuringPresentation = true
        controller.dimsBackgroundDuringPresentation = false
        controller.searchBar.sizeToFit()
        controller.searchBar.barTintColor = UIColor.white
        controller.searchBar.searchBarStyle = .minimal
        controller.searchBar.backgroundColor = .white
        
        
        for subView in controller.searchBar.subviews {
            if let textField = subView as? UITextField {
                textField.textColor = UIColor.blue
            }
        }
        
        controller.searchBar.layer.borderWidth = 0
        self.tableView.tableHeaderView = controller.searchBar
        
        //tableViewFooter
        let footer = UIImageView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 50))
        footer.contentMode = .center
        footer.image = poweredByIcon
        self.tableView.tableFooterView = footer
        
        
        //fetchLocationsNearby
        setupLocationManager()
    }
    
    func setupLocationManager(){
        
        
        locationManager = LocationManager()
            
            .onSuccess { place, location in
                
                guard let place = place, let location = location else {
                    return
                }
                
                //already choosed from CoreLocation or from GooglePlacePicker
                if self.currentPlace != nil {
                   self.currentPlace = place
                }
               
                self.currentCLLocation = location
                
                //fetch the currentPlaces
                self.fetchPlaces(location.coordinate.latitude, longitude: location.coordinate.longitude, radius: 500, key: GoogleMapsAPIServerKey)
            }
            .onFailure { error in
                print(error)
        }
        
        //here you are able to set you want to show the location by .City or by .SubLocality
        locationManager = locationManager.getLocation(.City)
        
    }
    func fetchPlaces(_ latitude: Double, longitude: Double, radius: Double, key: String){
        
            self.places.removeAll() //remove the fetched places

            let url = URL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=\(radius)&key=\(key)")
          
            let request = URLRequest(url: url!)
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
                
                do {
                    
                        if let data = data,
                        
                        let json = try? JSONSerialization.jsonObject(with: data, options: [] ) as? [String: Any] {
                        
                        for case let result in json!["results"] as! [Dictionary<String, AnyObject>] {
                            
                            var pName : String?
                            var pFormattedAddress: String?
                            var pGeometry: [String: AnyObject]?
                            
                            if let name: String = result["name"] as? String {
                                pName = name
                            }
                            
                            if let vicinity = result["vicinity"] as? String {
                                pFormattedAddress = vicinity
                            }
                            
                            if let geometry = result["geometry"] as? NSDictionary {
                                pGeometry = geometry as? [String : AnyObject]
                            }
                            
                            if let name = pName, let formattedAddress = pFormattedAddress, let geometry = pGeometry {
                                
                                let jsonObject: [String: NSDictionary] = [
                                    "result": [
                                        "name": name,
                                        "formatted_address": formattedAddress,
                                        "formatted_phone_number": "",
                                        "geometry": geometry]
                                ]
                                
                                  //here you can filter the nearest places
                                let place = PlaceDetails(json: jsonObject)
                                self.places.append(place)

                            }
                            
                        }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }

                        
                    }
                }
            })
        
            task.resume()
    }
    

    
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            
            return 1
            
        } else {
            
            return places.count
            
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath as NSIndexPath).section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "location", for: indexPath) as! CurrentLocationTableViewCell
            cell.placeName.text = currentPlace
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LocationTableViewCell
            let place = places[indexPath.row]
            cell.place = place
            if let location = currentCLLocation {
            cell.distance.text = getDistance(location, placeLocation: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
            }
            return cell
        }
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath as NSIndexPath).section == 0 {
            
            let cell = tableView.cellForRow(at: indexPath) as! CurrentLocationTableViewCell
            tagUserPlace(cell.placeName.text)
            
        } else {
            
            let cell = tableView.cellForRow(at: indexPath) as! LocationTableViewCell
            tagPlace(place: cell.place)
        }
    }
    
    
}







