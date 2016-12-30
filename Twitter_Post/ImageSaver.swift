//
//  ImageSaver.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit
import Photos


public typealias ImageSaverSuccess = (UIImage, String) -> Void
public typealias ImageSaverFailure = (NSError) -> Void

public class ImageSaver: NSObject {
    
    private let errorDomain = "com.zero.singleImageSaver"
    
    private var success: ImageSaverSuccess?
    private var failure: ImageSaverFailure?
    

    private var targetSize = PHImageManagerMaximumSize
    private var cropRect: CGRect?
    
    public override init() { }
    
    public func onSuccess(_ success: @escaping ImageSaverSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping SingleImageFetcherFailure) -> Self {
        self.failure = failure
        return self
    }


    public func save(_ image: UIImage?,filter: CIFilter?) -> Self {
        _ = PhotoLibraryAuthorizer { error in
            if error == nil {
                self._save(image,filter: filter)
            } else {
                self.failure?(error!)
            }
        }
        return self
    }
    
    private func _save(_ image: UIImage?, filter: CIFilter?) {
        
        guard var image = image else {
            let error = errorWithKey("error.cant-save-photo", domain: errorDomain)
            failure?(error)
            return
        }
        
        if let filter = filter {
            image = FilteredImageBuilder(image: image).image(image: image, withFilter: filter).0
            
        }
        
        DispatchQueue.main.async {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            
        }
       
    }
    
    
   @objc private func image(_ image:UIImage!,didFinishSavingWithError error:Error!,contextInfo:UnsafeRawPointer) {
        
        if error == nil {
            

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            guard let asset = assets.firstObject
                else {
                    let error = errorWithKey("error.cant-fetch-photo", domain: errorDomain)
                    failure?(error)
                    return
            }

            PHImageManager.default().requestImage(for: asset, targetSize: image.size, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image {
                    self.success?(image, asset.localIdentifier)
                } else {
                    let error = errorWithKey("error.cant-fetch-photo", domain: self.errorDomain)
                    self.failure?(error)
                }
            }

            
           
            
        } else {
            
            let error = errorWithKey("error.cant-fetch-photo", domain: self.errorDomain)
            self.failure?(error)
        }
    }

}
