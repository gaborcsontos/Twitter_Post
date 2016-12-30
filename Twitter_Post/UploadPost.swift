//
//  PostUpload.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/29/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import Alamofire


public var ServerURL: String = "YOUR PHP ADDRESS"



public typealias PostUploadSuccess = () -> Void
public typealias PostUploadFailure = (NSError) -> Void



public class PostUpload: NSObject {
    
    private var success: PostUploadSuccess?
    private var failure: PostUploadFailure?
    
    
    public override init() { }
    
    public func onSuccess(_ success: @escaping PostUploadSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(_ failure: @escaping PostUploadFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func upload(_ post: NewPost) -> Self {
        
        self._upload(post)
        
        return self
    }

    private func _upload(_ post: NewPost) {
    
        var parameters: Parameters = [
            "user_id": post.userId,
            "posttype": "0",
            ]
        parameters["posttext"] = post.text
        parameters["location"] = post.location
        
       
        //if it has image, mp4 (content)
        if let assetId = post.contentId {
            
            var reqAVAsset = RequestAVAssetData()
                
                .onSuccess { (imageData, videoData) in
                    
                   self.startUploading(parameters, imgData: imageData, videoData: videoData)
                  
                }
                
                .onFailure { error in
                    
                    self.failure?(error)
                    return

            }
            
            reqAVAsset = reqAVAsset.getAVAsset(assetId)
            
        } else {
            
             self.startUploading(parameters, imgData: nil, videoData: nil)
        }
        
    }

    
func startUploading(_ parameters: Parameters, imgData: Data?, videoData: Data?) {
    
        guard let currentWindow = UIApplication.shared.keyWindow?.subviews.last else {
        
            return
        }
    
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            if let videoData = videoData {
                multipartFormData.append(videoData, withName: "file[]", fileName: "file.mp4", mimeType: "video/mp4")
            }
            
            if let imageData = imgData {
                multipartFormData.append(imageData, withName: "file[]", fileName: "file.jpg", mimeType: "image/jpg")
            }
        
            
            for (key, value) in parameters {
                
                let newValue = (value as! String).data(using: .utf8)!
                
                multipartFormData.append(newValue, withName: key)
                
            }}, to:  ServerURL , method: .post, headers: ["Authorization": "auth_token"],
                
                encodingCompletion: { encodingResult in
                    
                    switch encodingResult {
                        
                    case .success(let upload, _, _):
                        
                        upload.uploadProgress(closure: { (Progress) in
                            
                            KVNProgress.show(CGFloat(Float(Progress.fractionCompleted)), status: "Posting...", on: currentWindow)
                            
                        })
                        
                        upload.responseJSON { response in
                            
                            print(response.request as Any)  // original URL request
                            print(response.response as Any) // URL response
                            print(response.data as Any)     // server data
                            print(response.result)   // result of response serialization
                            
                            KVNProgress.dismiss()
                            KVNProgress.showSuccess()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                KVNProgress.dismiss()
                                self.success?()
                            })
                          
                           
                           
                        }
                        
                    case .failure(let encodingError):
                        KVNProgress.showError()
                        self.failure?(encodingError as NSError)
                }
            })
    }


}


