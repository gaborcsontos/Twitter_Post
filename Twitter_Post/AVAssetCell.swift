//
//  AVAssetCell.swift
//  Loutude
//
//  Created by Gabor Csontos on 11/19/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import Photos


//CustomAVASSET class
class CustomAVAsset {
    
    enum MediaType: Int {
        case video
        case photo
    }
    
    var type: MediaType?
    var identifier: String?
    
    init(type: MediaType?, identifier: String?) {
        self.type = type
        self.identifier = identifier
    }
}


class AVAssetCollectionViewCell: UICollectionViewCell {
    
    var asset: CustomAVAsset?
    
    var assetID: String? {
        
        didSet {
            
            self.duration.isHidden = true
            //set the durationLabel to hidden default
            
            let manager = PHImageManager()
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            if let id = assetID {
                
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: fetchOptions)
    
                guard let asset = fetchResult.firstObject
                    else { return  }

                if asset.mediaType == .image {
                    
                    self.asset = CustomAVAsset(type: .photo, identifier: id)
                    //set the asset Type
                    
                    
                    manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: requestOptions, resultHandler: {
                        
                        
                        image,error  in
                        
                        self.image.image = image
                        
                        if error != nil {
                            

                        }
                    })
                }
                
                if asset.mediaType == .video {
                    
                    var duration: TimeInterval!
                  
                    duration = asset.duration
                    
                    self.asset = CustomAVAsset(type: .video, identifier: id)
                    //set the asset Type
                    
                    manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: requestOptions, resultHandler: {
                        
                        image,error  in
                        
                        if error != nil {
                            
                            //set the image
                            self.image.image = image
                            //set the durationLabel to visible
                            self.duration.isHidden = false
                            
                            self.duration.text = self.stringFromTimeInterval(duration)
                            self.duration.sizeToFit()
                            
                            //here you can implement a AVPlayer as well to play by first tag[0], or if the cell is visible
                            
                        }
                    })
                }
            }
        }
    }

    
    
    func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        // let hours = (interval / 3600)
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    

    var image: UIImageView = {
        let img = UIImageView()
        img.clipsToBounds = true
        img.contentMode = .scaleAspectFill
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    var duration: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    func setupView(){
        
        backgroundColor = UIColor.white
        addSubview(image)
        addSubview(duration)
        
        image.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        image.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        image.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        image.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        
        duration.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -5).isActive = true
        duration.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -5).isActive = true
        duration.heightAnchor.constraint(equalToConstant: 20).isActive = true
        duration.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
