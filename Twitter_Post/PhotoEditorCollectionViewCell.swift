//
//  PhotoEditorCollectionViewCell.swift
//  Loutude
//
//  Created by Gabor Csontos on 10/9/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit


class PhotoEditorCollectionViewCell: UICollectionViewCell {
    
    
    let filterLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    var filteredPhoto: UIImageView = {
        let image = UIImageView()
        image.layer.borderColor = UIColor(white: 1.0, alpha: 0.4).cgColor
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 8
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    
    func setupView(){
        
        if !self.isDescendant(of: filteredPhoto){ self.addSubview(filteredPhoto)}
        
        filteredPhoto.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        filteredPhoto.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.6).isActive = true
        filteredPhoto.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.6).isActive = true
        filteredPhoto.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        if !self.isDescendant(of: filterLabel){ self.addSubview(filterLabel)}
        filterLabel.topAnchor.constraint(equalTo: filteredPhoto.bottomAnchor).isActive = true
        filterLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        filterLabel.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        filterLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            filteredPhoto.layer.borderWidth = isSelected ? 2 : 0
        }
    }

}
























