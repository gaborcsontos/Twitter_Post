//
//  PostButtonDelegate.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/24/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation


//This function is responsible to send the post
//It creates a NewPost class which is responsible to upload the requested datas to the server
/*
 it contains { userId, location(optional), text, contentId(image, video) }
 --it could also contain Date as well or anything you wish
 
*/







extension PostViewController {
    
    
    func handlePostButton() {
        
        guard let userId = currentUserId  else {
            print("You should login again")
            return
        }
        
        let post = NewPost()
        post.userId = userId
        post.location = self.userLocation
        post.text = self.postText
        post.contentId = self.contentAsset?.identifier
        
        var uploadPost = PostUpload()
            
            .onSuccess {
                
                KVNProgress.showSuccess()
                
               
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    showAlertViewWithTitleAndText(nil, message: "Your post uploaded sucessfully.", vc: self)
                    
                })
                
                //delegate to refresh the collectionView???
                //self.dismissView()
            }
            
            .onFailure { error in
                
                alertViewToOpenSettings("Uploading error", message: error.localizedDescription)
        }
        
        uploadPost = uploadPost.upload(post)
        
        postTextField.resignFirstResponder()
        
        
        
//        showAlertViewWithTitleAndText("Your post starting to upload with\n userid: \(post.userId)\n from \(post.location)", message: "Post contains: \n text: \(post.text)\n and \n content with Id: \(post.contentId) \n(which will be extract whilst uploading)", vc: self)
        
        
    }
 
}
