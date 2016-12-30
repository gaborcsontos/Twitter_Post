//
//  RequestAVAssetData.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/29/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import Photos


public typealias RequestAVAssetDataSuccess = (_ image: Data?, _ video: Data?) -> Void
public typealias RequestAVAssetDataFailure = (NSError) -> Void


public class RequestAVAssetData: NSObject {
    
    private var imageScaleSize:CGFloat = 0.6
    private var success: RequestAVAssetDataSuccess?
    private var failure: RequestAVAssetDataFailure?
    
    private var exportSession:AVAssetExportSession!
    
    private let errorDomain = "com.zero.requestAVASSET"
    
    public override init() { }
    
    public func onSuccess(_ success: @escaping RequestAVAssetDataSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping RequestAVAssetDataFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func getAVAsset(_ localId: String) -> Self {
        _ = PhotoLibraryAuthorizer { error in
            if error == nil {
                self._getAVAsset(localId)
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
    
    
    
    private func _getAVAsset(_ avAssetLocalIdentifier: String) {
    
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let manager = PHImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [avAssetLocalIdentifier], options: nil)
        guard let asset = assets.firstObject
            else { return  }

        if asset.mediaType == .image {
            
            manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: requestOptions, resultHandler: {
                
                image,error  in
                
                if let imageData = UIImageJPEGRepresentation(image!, self.imageScaleSize) {
                    self.success?(imageData, nil)
                    
                } else {
                    let error = errorWithKey("error.cancelled-saving-video", domain: self.errorDomain)
                    self.failure?(error)

                }
            })
        }
    
        if asset.mediaType == .video {
            
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .current//.original
            options.deliveryMode = .mediumQualityFormat
            

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (AVAsset, AVAudio, info) in
                let getUrlAsset = AVAsset as! AVURLAsset
                let dataURL = getUrlAsset.url
                let data = NSData(contentsOf: dataURL)
                
                print("File size before compression: \(Double(data!.length / 1048576)) mb")
                
                    self.exportAndReduceMovieSize(AVAsset!, completion: { (data) in
                        
                        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: requestOptions, resultHandler: {
                            
                            image,error  in
                            
                            if let imageData = UIImageJPEGRepresentation(image!, self.imageScaleSize) {
                               self.success?(imageData, data as Data?)
                            } else {
                                self.success?(nil, data as Data?)
                            }
                        })
                    })

            })
        }
        
    }

func exportAndReduceMovieSize(_ asset: AVAsset,  completion:  @escaping (NSData?) -> Void) {
    
    let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    
    if compatiblePresets.contains(AVAssetExportPreset640x480) || compatiblePresets.contains(AVAssetExportPresetLowQuality){
        
        self.exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset640x480)
        self.exportSession.outputURL = self.tempFilePath
        self.exportSession.outputFileType = AVFileTypeMPEG4
        self.exportSession.shouldOptimizeForNetworkUse = true
        self.exportSession.exportAsynchronously(completionHandler: { () -> Void in
            
            switch self.exportSession.status {
                
            case .failed: print("failed")
            case .completed:
    
                    let data = NSData(contentsOf: self.tempFilePath)
                     print("File size after compression: \(Double(data!.length / 1048576)) mb")
                    completion(data)
            default: break
            }
            
            //set progressHUD to show converting status
            guard let currentWindow = UIApplication.shared.keyWindow?.subviews.last else {
                
                return
            }
            
            // KVNProgress.show(CGFloat(self.exportSession.progress), status: "Exposting...", on: currentWindow)
            print(self.exportSession.progress)
            
            while self.exportSession.status == .exporting {
                
           
            }
        })

    }

}
}
