//
//  LocationTableViewCell.swift
//  GoogleLocationPicker
//
//  Created by Gabor Csontos on 10/9/16.
//  Copyright © 2016 GabeMajorszki. All rights reserved.
//

import UIKit


class LocationTableViewCell: UITableViewCell {
    
    
    var place: PlaceDetails? {
        
        didSet {
            
            if let place = place {
                placeName.text = place.name
                address.text = place.formattedAddress
            }
        }
    }
    
    
    
    let placeName: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let address: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let distance: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.white
        label.textAlignment = .right
        return label
    }()
    
    func setupView(){
        
        selectionStyle = .none
        
        //placename x,y,h,w
        if !placeName.isDescendant(of: self) { self.addSubview(placeName) }
        placeName.topAnchor.constraint(equalTo: self.topAnchor,constant: 5).isActive = true
        placeName.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 12).isActive = true
        placeName.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        placeName.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //distance x,y,h,w
        if !distance.isDescendant(of: self) { self.addSubview(distance) }
        distance.topAnchor.constraint(equalTo: self.topAnchor,constant: 5).isActive = true
        distance.rightAnchor.constraint(equalTo: self.rightAnchor,constant: -12).isActive = true
        distance.widthAnchor.constraint(equalToConstant: 60).isActive = true
        distance.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //address x,y,h,w
        if !address.isDescendant(of: self) { self.addSubview(address) }
        address.topAnchor.constraint(equalTo: placeName.bottomAnchor,constant: 2).isActive = true
        address.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 12).isActive = true
        address.rightAnchor.constraint(equalTo: distance.leftAnchor,constant: -5).isActive = true
        address.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

