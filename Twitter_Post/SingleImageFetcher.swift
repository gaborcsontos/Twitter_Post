//
//  SingleImageFetcher.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2016/02/16.
//  Copyright © 2016 zero. All rights reserved.
//

import UIKit
import Photos

public typealias SingleImageFetcherSuccess = (UIImage, URL?) -> Void
public typealias SingleImageFetcherFailure = (NSError) -> Void

public class SingleImageFetcher {
    private let errorDomain = "com.zero.singleImageSaver"
    
    private var success: SingleImageFetcherSuccess?
    private var failure: SingleImageFetcherFailure?
    
    private var targetSize = PHImageManagerMaximumSize
    private var cropRect: CGRect?
    private var assetURL: URL?
    
    public init() { }
    
    public func onSuccess(_ success: @escaping SingleImageFetcherSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping SingleImageFetcherFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func setTargetSize(_ targetSize: CGSize) -> Self {
        self.targetSize = targetSize
        return self
    }
    
    public func setCropRect(_ cropRect: CGRect) -> Self {
        self.cropRect = cropRect
        return self
    }
    
    public func fetch(_ localId: String) -> Self {
        
        _ = PhotoLibraryAuthorizer { error in
            
            if error == nil {
                
                self._fetch(localId)
                
            } else {
                
                self.failure?(error!)
            }
        }
        return self
    }
    
    private func _fetch(_ localId: String) {
    

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject
            else {
                let error = errorWithKey("error.cant-fetch-photo", domain: errorDomain)
                failure?(error)
                return
        }
        

        
        if let cropRect = cropRect {

            options.normalizedCropRect = cropRect
            options.resizeMode = .exact
            
            let targetWidth = floor(CGFloat(asset.pixelWidth) * cropRect.width)
            let targetHeight = floor(CGFloat(asset.pixelHeight) * cropRect.height)
            let dimension = max(min(targetHeight, targetWidth), 1024 *  UIScreen.main.scale)
            
            targetSize = CGSize(width: dimension, height: dimension)
        }
        
        
        //getting the ASSETURL
        PHImageManager.default().requestImageData(for: asset, options: nil, resultHandler: { (data: Data?, identificador: String?, orientaciomImage: UIImageOrientation, info: [AnyHashable: Any]?) -> Void in
            
           
            if let imagePathOpt = info?["PHImageFileURLKey"] as? URL{
                self.assetURL = imagePathOpt
            }
          
        })
        
        //getting the Image
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
     
            if let image = image {
              
                self.success?(image,self.assetURL)
            } else {
                let error = errorWithKey("error.cant-fetch-photo", domain: self.errorDomain)
                self.failure?(error)
            }
        }
    }
}
