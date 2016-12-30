//
//  ConvertSlowMotionVideo.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

public typealias ConvertSlowMoVideoSuccess = (URL) -> Void
public typealias ConvertSlowMoVideoFailure = (NSError) -> Void

class ConvertSlowMotionVideo: NSObject {
    
    
    private let errorDomain = "com.zero.slowMotionVideo"
    
    private var success: ConvertSlowMoVideoSuccess?
    private var failure: ConvertSlowMoVideoFailure?
    
    private var exportSession: AVAssetExportSession!
    private var tempURL: URL?
    
    public override init() { }
    
    public func onSuccess(_ success: @escaping VideoFetcherSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping VideoFetcherFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func convertSlowMotionVideo(_ asset: AVAsset) -> Self {
        _ = PhotoLibraryAuthorizer { error in
            if error == nil {
                self._convertSlowMotionVideo(asset)
            } else {
                self.failure?(error!)
            }
        }
        return self
    }

   
    /// tempFilePath
    fileprivate var tempFilePath: URL = {
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(randomAlphaNumericString(8)).appendingPathExtension("mp4").absoluteString
        if FileManager.default.fileExists(atPath: tempPath) {
            do {
                try FileManager.default.removeItem(atPath: tempPath)
                
            } catch let error as NSError { print(error.localizedDescription)}
        }
        return URL(string: tempPath)!
    }()


    func _convertSlowMotionVideo(_ asset: AVAsset) {
        
    
    let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
            
            self.exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)

            self.exportSession.outputURL = self.tempFilePath
            self.exportSession.outputFileType = AVFileTypeMPEG4
            self.exportSession.shouldOptimizeForNetworkUse = false
          
            self.exportSession.exportAsynchronously(completionHandler: {() -> Void in
                    
                    switch self.exportSession.status {
                    
                    case .failed:
                        
                        let error = errorWithKey("error.cant-convert-video", domain: self.errorDomain)
                        
                        self.hideLoader()
                        self.failure?(error)
                        
                    case .cancelled:
                        
                        let error = errorWithKey("error.cancelled-saving-video", domain: self.errorDomain)
                        
                        self.hideLoader()
                        self.failure?(error)
                        
                    case .completed:
                
                        self.hideLoader()
                        self.success?(self.tempFilePath)
                        
                    default:
                        let error = errorWithKey("error.cant-convert-video", domain: self.errorDomain)
                        self.hideLoader()
                        self.failure?(error)
                    }
                })
            
            //set progressHUD to show converting status
            guard let currentWindow = UIApplication.shared.keyWindow?.subviews.last else {
                
                return
            }
            
            let hud = MBProgressHUD.showAdded(to: currentWindow, animated: true)
            hud.mode = MBProgressHUDMode.annularDeterminate
            hud.label.text = "Converting"
            
            DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                
                
                while self.exportSession.status == .exporting {
                    
                    DispatchQueue.main.sync(execute: {() -> Void in
                        
                        print(self.exportSession.progress)
                        
                        hud.progress = self.exportSession.progress
                    })
                }
                
            })

        }
    }
    
    fileprivate func hideLoader(){
        
        guard let currentWindow = UIApplication.shared.keyWindow?.subviews.last else {
            
            return
        }
        //hide ProgressHUD in the main thread
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: currentWindow, animated: true)
        }
        
    }
    
    
}
