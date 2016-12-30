//
//  GooglePlacesAutocomplete.swift
//  GooglePlacesAutocomplete
//
//  Created by Howard Wilson on 10/02/2015.
//  Copyright (c) 2015 Howard Wilson. All rights reserved.
//
//
//  Created by Dmitry Shmidt on 6/28/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.

import UIKit
import CoreLocation

public enum PlaceType: CustomStringConvertible {
    case all
    case geocode
    case address
    case establishment
    case regions
    case cities
    
    public var description : String {
        switch self {
        case .all: return ""
        case .geocode: return "geocode"
        case .address: return "address"
        case .establishment: return "establishment"
        case .regions: return "(regions)"
        case .cities: return "(cities)"
        }
    }
}

public typealias GooglePlaceSelectedClosure = (_ place: PlaceDetails) -> Void

open class Place: NSObject {
    open let id: String
    open let desc: String?
    open let name: String?
    open var apiKey: String?
    
    override open var description: String {
        get { return desc! }
    }

    
    public init(id: String, terms: [String]?) {
        self.id = id
        if let terms = terms{
            self.name = terms.first
            var tmpTerms = terms
            if terms.count > 0{
                tmpTerms.remove(at: 0)
                self.desc = tmpTerms.joined(separator: ",")
            }else{
                self.desc = ""
            }
        }else{
            self.name = ""
            self.desc = ""
        }
    }
    
    convenience public init(prediction: [String: AnyObject], apiKey: String?) {

        var terms = [String]()

        if let items = prediction["terms"] as? [[String: AnyObject]]{
            for item in items{
                
                if let value = item["value"] as? String{
                    terms.append(value)
                }
                
            }
        }

        self.init(
            id: prediction["place_id"] as! String,
            terms: terms
        )
        
        self.apiKey = apiKey
    }
    
    /**
    Call Google Place Details API to get detailed information for this place
    
    Requires that Place#apiKey be set
    
    :param: result Callback on successful completion with detailed place information
    */
    open func getDetails(_ result: @escaping (PlaceDetails) -> ()) {
        GooglePlaceDetailsRequest(place: self).request(result)
    }
}


open class PlaceDetails: CustomStringConvertible {
    open let name: String
    open let formattedAddress: String
    open let formattedPhoneNo: String?
    open let coordinate: CLLocationCoordinate2D
    
    open var streetNumber           = ""
    open var route                  = ""
    open var locality               = ""
    open var subLocality            = ""
    open var administrativeArea     = ""
    open var administrativeAreaCode = ""
    open var subAdministrativeArea  = ""
    open var postalCode             = ""
    open var country                = ""
    open var ISOcountryCode         = ""
    open var state                  = ""
    
    let raw: [String: AnyObject]
    
    init(json: [String: AnyObject]) {
        func component(_ component: String, inArray array: [[String: AnyObject]], ofType: String) -> String{
            for item in array {
                let types = item["types"] as! [String]
                if let type = types.first{
                    if type == component {
                        if let value = item[ofType] as! String?{
                           
                           return value
                        }
                    }
                }
            }
            
            return ""
            
        }
        
        let result = json["result"] as! [String: AnyObject]
        
        name = result["name"] as! String
        formattedAddress = result["formatted_address"] as! String
        formattedPhoneNo = result["formatted_phone_number"] as? String
        
        let geometry = result["geometry"] as! [String: AnyObject]
        let location = geometry["location"] as! [String: AnyObject]
        let latitude = location["lat"] as! CLLocationDegrees
        let longitude = location["lng"] as! CLLocationDegrees
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        
//        let addressComponents = result["address_components"] as! [[String: AnyObject]]
//        
//        streetNumber = component("street_number", inArray: addressComponents, ofType: "short_name")
//        route = component("route", inArray: addressComponents, ofType: "short_name")
//        subLocality = component("subLocality", inArray: addressComponents, ofType: "long_name")
//        locality = component("locality", inArray: addressComponents, ofType: "long_name")
//        postalCode = component("postal_code", inArray: addressComponents, ofType: "long_name")
//        administrativeArea = component("administrative_area_level_1", inArray: addressComponents, ofType: "long_name")
//        subAdministrativeArea = component("administrative_area_level_2", inArray: addressComponents, ofType: "long_name")
//        country = component("country", inArray: addressComponents, ofType: "long_name")
//        ISOcountryCode = component("country", inArray: addressComponents, ofType: "short_name")
        
        raw = json
        

    }
    
    open var description: String {
        return "\nPlace: \(name).\nAddress: \(formattedAddress).\ncoordinate: (\(coordinate.latitude), \(coordinate.longitude))\nPhone No.: \(formattedPhoneNo)\n"
    }
    

}

// MARK: - GooglePlacesAutocomplete
open class GooglePlacesSearchController: UISearchController, UISearchBarDelegate {
    
    var gpaViewController: GooglePlacesAutocompleteContainer!
    
    fileprivate var googleSearchBar: UISearchBar?
  
    
    
    convenience public init(apiKey: String, placeType: PlaceType = .all, searchBar: UISearchBar? = nil, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, radius: CLLocationDistance = 0) {
        assert(!apiKey.isEmpty, apiKey)
        
        let gpaViewController = GooglePlacesAutocompleteContainer(
            apiKey: apiKey,
            placeType: placeType,
            coordinate: coordinate,
            radius: radius
        )
        
        self.init(searchResultsController: gpaViewController)
        
        self.googleSearchBar = searchBar
        
        self.gpaViewController = gpaViewController
        self.view.backgroundColor = .white
        self.searchResultsUpdater = gpaViewController
        self.hidesNavigationBarDuringPresentation = false
      //  self.dimsBackgroundDuringPresentation = false
        self.searchBar.placeholder = "Enter Address"
    }
    
    override open var searchBar: UISearchBar { get {
        return googleSearchBar ?? super.searchBar
        }
    }
    
    open func didSelectGooglePlace(_ completion : @escaping GooglePlaceSelectedClosure){
        gpaViewController.closure = completion
    }
}

// MARK: - GooglePlacesAutocompleteContainer
open class GooglePlacesAutocompleteContainer: UITableViewController, UISearchResultsUpdating {

    var closure: GooglePlaceSelectedClosure?
    fileprivate var apiKey: String?
    fileprivate var places = [Place]()
    fileprivate var placeType: PlaceType = .all
    fileprivate var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    fileprivate var radius: Double = 0.0
    
    var emptyImgName = "ic_search"
    var emptyTitle = "Search for places and tag yourself"
    var emptyDescription = ""
    
    weak var googleDelegate: GoogleDelegate?
    
    convenience init(apiKey: String, placeType: PlaceType = .all, coordinate: CLLocationCoordinate2D, radius: Double) {
        
        self.init()
        self.apiKey = apiKey
        self.placeType = placeType
        self.coordinate = coordinate
        self.radius = radius
    }
    
//    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIContentSizeCategoryDidChangeNotification, object: nil)
//    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(GooglePlaceTableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        //FIXME: Dynamic fonts updating
        //Dynamic fonts observer
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("noteDynamicTypeSettingChanged"), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

//    func noteDynamicTypeSettingChanged() { // UIContentSizeCategoryDidChangeNotification
//        tableView.reloadData()
//    }
}

// MARK: - GooglePlacesAutocompleteContainer
private class GooglePlaceTableViewCell: UITableViewCell {
    
    var nameLabel = UILabel()
    var addressLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = UITableViewCellSelectionStyle.gray
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.textColor = UIColor.black
        nameLabel.backgroundColor = UIColor.white
        nameLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        
        addressLabel.textColor = UIColor(hue: 0.9972, saturation: 0, brightness: 0.54, alpha: 1.0)
        addressLabel.backgroundColor = UIColor.white
        addressLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.footnote)
        addressLabel.numberOfLines = 0
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        
        let viewsDict = [
            "name" : nameLabel,
            "address" : addressLabel
        ]
        

        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[name]-[address]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[name]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[address]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
extension GooglePlacesAutocompleteContainer{
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! GooglePlaceTableViewCell
        
        // Get the corresponding candy from our candies array
        let place = self.places[(indexPath as NSIndexPath).row]
        
        // Configure the cell
        cell.nameLabel.text = place.name

        cell.addressLabel.text = place.description
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let place = places[(indexPath as NSIndexPath).row]
        
        self.dismiss(animated: false , completion: {
               self.googleDelegate?.addPlace(place.name)
        })
     
        
//        place.getDetails {[unowned self] details in
//            
//            self.closure?(details)
//            
//        }
    }
}

// MARK: - GooglePlacesAutocompleteContainer (UISearchBarDelegate)
extension GooglePlacesAutocompleteContainer: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count > 0 {
            self.places = []
        } else {
            getPlaces(searchText)
           
        }
      
    }
    fileprivate func escape(_ string: String) -> String {
//        let legalURLCharactersToBeEscaped: CFStringRef = ":/?&=;+!@#$()',*"
      //  return (string as NSString).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        return (string as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
//        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
    /**
    Call the Google Places API and update the view with results.
    
    :param: searchString The search query
    */
    fileprivate func getPlaces(_ searchString: String) {
       
       
        
        var params = [
            "input": escape(searchString),
            "types": placeType.description,
            "key": apiKey ?? ""
        ]
   
        if CLLocationCoordinate2DIsValid(self.coordinate) {

            params["location"] = "\(coordinate.latitude),\(coordinate.longitude)"
            if radius > 0{
                params["radius"] = "\(radius)"
            }
        
        }
        
        GooglePlacesRequestHelpers.doRequest(
            "https://maps.googleapis.com/maps/api/place/autocomplete/json",
            params: params
           
            ) { json in
                
                    if let predictions = json["predictions"] as? Array<[String: Any]> {
                        
                       
                        
                        self.places = predictions.map { (prediction: [String: Any]) -> Place in
                            return Place(prediction: prediction as [String : AnyObject], apiKey: self.apiKey)
                        }
                    }
                
                if let predictions = json["predictions"] as? [[String: AnyObject]] {
                
                    self.places = predictions.map { (prediction: [String: AnyObject]) -> Place in
                        return Place(prediction: prediction, apiKey: self.apiKey)
                    }
                
                    self.tableView.reloadData()
               }
        }
    }
}
extension GooglePlacesAutocompleteContainer
{
    @objc(updateSearchResultsForSearchController:) public func updateSearchResults(for searchController: UISearchController)
    {
        if let searchText = searchController.searchBar.text , searchText.characters.count > 0 {
            getPlaces(searchText)
        }
        else {
            self.places = []
        }
    }
}
// MARK: - GooglePlaceDetailsRequest
class GooglePlaceDetailsRequest {
    let place: Place
    
    init(place: Place) {
        self.place = place
    }
    
    func request(_ result: @escaping (PlaceDetails) -> ()) {
        
        GooglePlacesRequestHelpers.doRequest(
            
            "https://maps.googleapis.com/maps/api/place/details/json",
            params: [
                "placeid": place.id,
                "key": place.apiKey ?? ""
            ]
            ) { json in
                
                result(PlaceDetails(json: json as! [String: AnyObject]))
        }
    }
}

// MARK: - GooglePlacesRequestHelpers
class GooglePlacesRequestHelpers {
    /**
    Build a query string from a dictionary
    
    :param: parameters Dictionary of query string parameters
    :returns: The properly escaped query string
    */
    fileprivate class func query(_ parameters: [String: String]) -> String {
        var components: [(String, String)] = []
        
        for key in Array(parameters.keys).sorted() {
            let value: String! = parameters[key]
          
            components += [(key, "\(value!)")]
      
        }
        
        return components.map{"\($0)=\($1)"}.joined(separator: "&")
    }
    
    fileprivate class func doRequest(_ urlString: String, params: [String: String], success: @escaping (NSDictionary) -> ()) {
        
        let urlString = "\(urlString)?\(query(params as [String : String]))"
        
        if let url = URL(string: urlString){
            
            let request = URLRequest(url: url)
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                
                
                do {
                    if let data = data,
                       
                        let _ = try? JSONSerialization.jsonObject(with: data, options: [] ) as? [String: Any] {
                    
                    }
                }
                 self.handleResponse(data, response: response, error: error as NSError!, success: success)
            })

            
            task.resume()
        }
    }
    
    fileprivate class func handleResponse(_ data: Data!, response: URLResponse!, error: NSError!, success: @escaping (NSDictionary) -> ()) {
        if let error = error {
            print("GooglePlaces Error: \(error.localizedDescription)")
            return
        }
        
        if response == nil {
            print("GooglePlaces Error: No response from API")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                print("GooglePlaces Error: Invalid status code \(httpResponse.statusCode) from API")
                return
            }
        }
        
    
        let json: NSDictionary?
        do {
            json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
        }
        catch {
            json = nil
            print("GooglePlaces Error")
            return
        }
        
        if let status = json?["status"] as? String {
            if status != "OK" {
                print("GooglePlaces API Error: \(status)")
                return
            }
        }
        
        // Perform table updates on UI thread
        DispatchQueue.main.async(execute: {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            success(json!)
        })
    }
}



extension GooglePlacesAutocompleteContainer: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
   
    
    public func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    public func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: emptyImgName)
    }
    
    public func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: UIColor.darkGray
        ]
        
        return NSAttributedString(string: emptyTitle, attributes: attribs)
    }
    
//    public func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
//        
//        
//        let para = NSMutableParagraphStyle()
//        para.lineBreakMode = NSLineBreakMode.byWordWrapping
//        para.alignment = NSTextAlignment.center
//        
//        let attribs = [
//            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
//            NSForegroundColorAttributeName: UIColor.lightGray,
//            NSParagraphStyleAttributeName: para
//        ]
//        
//        return NSAttributedString(string: emptyDescription, attributes: attribs)
//    }

    
   
}

protocol GoogleDelegate: class {
    func addPlace(_ place: String?)
}
