//
//  CurrentLocationTableViewCell.swift
//  GoogleLocationPicker
//
//  Created by Gabor Csontos on 12/26/16.
//  Copyright © 2016 GabeMajorszki. All rights reserved.
//

import UIKit

class CurrentLocationTableViewCell: UITableViewCell {
    
    var place: PlaceDetails? {
        
        didSet {
            if let place = place {
                placeName.text = place.name
            }
        }
    }
    
    
    let checkMark: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = UIImage(named: "ic_check")
        return image
    }()
    
    
    let placeName: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setupView(){
        selectionStyle = .none
        
        
        //checkMark x,y,h,w
        if !checkMark.isDescendant(of: self) { self.addSubview(checkMark) }
        checkMark.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        checkMark.rightAnchor.constraint(equalTo: self.rightAnchor,constant: -12).isActive = true
        checkMark.widthAnchor.constraint(equalToConstant: 20).isActive = true
        checkMark.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        
        //placename x,y,h,w
        if !placeName.isDescendant(of: self) { self.addSubview(placeName) }
        placeName.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        placeName.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 12).isActive = true
        placeName.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        placeName.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
