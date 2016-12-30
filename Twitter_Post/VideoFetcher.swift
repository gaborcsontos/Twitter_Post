//
//  VideoFetcher.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

public typealias VideoFetcherSuccess = (URL) -> Void
public typealias VideoFetcherFailure = (NSError) -> Void


public class VideoFetcher {
    
    private let errorDomain = "com.zero.singleImageSaver"
    
    private var success: VideoFetcherSuccess?
    private var failure: VideoFetcherFailure?
    
    public init() { }
    
    public func onSuccess(_ success: @escaping VideoFetcherSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping VideoFetcherFailure) -> Self {
        self.failure = failure
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
        
        
        let manager = PHImageManager()
        
        let requestOptions = PHVideoRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        
       
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        guard let asset = assets.firstObject
                
        else {
            let error = errorWithKey("error.cant-fetch-video", domain: errorDomain)
            failure?(error)
            return
        }
            
            
        manager.requestAVAsset(forVideo: asset, options: nil) { (videoAsset, audioMix, info) -> Void in
                
            DispatchQueue.main.async(execute: { () -> Void in
                    
                    if let asset = videoAsset {
                        
                        if asset.isKind(of: AVComposition.self) {
                            
                            print("slow motion video to convert")
                            
                            //compress video to be able to play
                            var converter = ConvertSlowMotionVideo()
                                
                                .onSuccess { url in
                                    
                                    self.success?(url)
                                    
                                }
                                .onFailure { error in
                                    self.failure?(error)
                            }
                            converter = converter.convertSlowMotionVideo(asset)

                            return
                            
                        } else if asset.isKind(of: AVURLAsset.self){
                            
                            if let url = asset as? AVURLAsset {
                                
                            self.success?(url.url)
                                
                            } else {
                                
                                let error = errorWithKey("error.cant-fetch-video", domain: self.errorDomain)
                                self.failure?(error)
                            }
                            
                        } else {
                            
                            print("unkown")
                        }
                        
                    } else {
                        let error = errorWithKey("error.cant-fetch-video", domain: self.errorDomain)
                        self.failure?(error)
                    }
                })
            }
        }

    
    
    
    
}
