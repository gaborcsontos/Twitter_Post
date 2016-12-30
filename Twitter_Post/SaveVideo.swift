//
//  SaveVideo.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

public typealias SaveVideoSuccess = (String) -> Void
public typealias SaveVideoFailure = (NSError) -> Void


public class SaveVideo: NSObject {
    
    private let errorDomain = "com.zero.singleImageSaver"
    
    private var success: SaveVideoSuccess?
    private var failure: SaveVideoFailure?
    
    private var exportSession: AVAssetExportSession!
    private var tempURL: URL?

    
    public override init() { }
    
    public func onSuccess(_ success: @escaping SaveVideoSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping SaveVideoFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func save(_ avAsset: AVAsset, startTime: CGFloat, stopTime: CGFloat) -> Self {
        _ = PhotoLibraryAuthorizer { error in
            if error == nil {
                self._save(avAsset, startTime: startTime, stopTime: stopTime)
            } else {
                self.failure?(error!)
            }
        }
        return self
        
    }
    
    
    private func _save(_ avAsset: AVAsset, startTime: CGFloat, stopTime: CGFloat) {
        
        self.showLoader()
       
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
            
            self.exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)
            // Implementation continues.
            
            //create new filepath
            let paths = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true)
            
            let documentsDirectory = paths[0] as String
            
            var filePath:String? = nil
            
            repeat {
                filePath =
                "\(documentsDirectory)/IMG_\(randomAlphaNumericString(4)).mp4"
            } while (FileManager.default.fileExists(atPath: filePath!))
            
            
            self.exportSession.outputURL = URL(fileURLWithPath: filePath!)
            self.exportSession.outputFileType = AVFileTypeMPEG4
            self.exportSession.shouldOptimizeForNetworkUse = true
            
            let start = CMTimeMakeWithSeconds(Double(startTime), avAsset.duration.timescale)
            let duration = CMTimeMakeWithSeconds(Double(stopTime - startTime), avAsset.duration.timescale)
            let range = CMTimeRangeMake(start, duration)
            self.exportSession.timeRange = range
            
            
            self.exportSession.exportAsynchronously(completionHandler: {() -> Void in
                
                switch self.exportSession.status {
                    
                case .failed:
                    
                    let error = errorWithKey("error.cant-save-video", domain: self.errorDomain)
                
                    self.hideLoader()
                    self.failure?(error)
                    
                case .cancelled:
                    
                    let error = errorWithKey("error.cancelled-saving-video", domain: self.errorDomain)
                    
                    self.hideLoader()
                    self.failure?(error)
                    
                case .completed:
                    
                    let movieUrl = URL(fileURLWithPath: filePath! as String)
                    var placeHolder: PHObjectPlaceholder?
                    
                    PHPhotoLibrary.shared().performChanges({
                        
                        let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieUrl)
                        
                        if let changeRequest = changeRequest {
                            // maybe set date, location & favouriteness here?
                            placeHolder = changeRequest.placeholderForCreatedAsset
                        }
                        
                    }) { success, error in
                        
                        self.hideLoader()
                        
                        if error != nil {
                            self.failure?(error as! NSError)
                        }
                        
                        if let localIdentifier = placeHolder?.localIdentifier {
                            self.success?(localIdentifier)
                            
                        }
                    }
                    
                default: break
                    
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
            MBProgressHUD.hide(for: currentWindow, animated: false)
        }
        
    }

    fileprivate func showLoader() {
        
        guard let currentWindow = UIApplication.shared.keyWindow?.subviews.last else {
            
            return
        }
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: currentWindow, animated: true)
            hud.label.text = "Saving"
        }
       
    }
}
