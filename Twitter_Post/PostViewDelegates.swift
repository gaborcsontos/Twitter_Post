//
//  PostViewDelegates.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/23/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation


//MARK: GMVideoTrimmerDelegate, GMPhotoEditorDelegate, CameraViewControllerDelegate
extension PostViewController: VideoTrimmerDelegate,PhotoEditorDelegate,CameraViewControllerDelegate {
    //Video
    func handleVideoConfirmButton(_ assetIdentifier: String?) { self.loadAVAsset(assetIdentifier) }
    //Photo
    func handleConfirmPhotoButton(_ assetIdentifier: String?) { self.loadAVAsset(assetIdentifier)  }
    //Camera
    func sendAssetIdToPostViewController(_ assetIdentifier: String?) { self.loadAVAsset(assetIdentifier) }
    
}

extension PostViewController: LocationPickerControllerDelegate {
    
    func removeLocation() {
        self.removeLocation()
    }//to remove location String

    
    func addPlace(_ place: String?){
        guard let place = place  else {
            return
        }
        self.userLocation = place
    }//to add location String {
    
}
//MARK: POSTLIBRARYVIEW DELEGATE
extension PostViewController: PhotoViewControllerDelegate {
    
    //PhotoLibraryView location button touch delegate
    
    func openLocationView() {
        /*
        print("open location picker")
        //Here you can add other location picker such as watsonbox 's google_places_autocomplete
        //https://github.com/watsonbox/ios_google_places_autocomplete
        
        showAlertViewWithTitleAndText("Open locationPicker", message: "Here you can add other location picker such as watsonbox 's google_places_autocomplete", vc: self)
        */
        
        let locationPicker = GooglePlacePicker(currentLocation: self.userLocation)
        locationPicker.delegate = self
        let nav = UINavigationController(rootViewController: locationPicker)
        self.present(nav, animated: true, completion: nil)

    }
    
    //PhotoLibraryView camera button touch delegate
    func openCameraView() {
        
        postTextField.resignFirstResponder()
        
        DispatchQueue.main.async {
            
            self.camNavigationController = NavigationController(rootViewController: self.cameraVC)
            self.navigationController?.addChildViewController(self.camNavigationController)
            self.navigationController?.mi_presentViewController(toViewController: self.camNavigationController)
        }
        
    }
    
    //PhotoLibraryView photo button touch delegate
    func openPhotoView() {
        
        self.navigationController?.si_showFullScreen(toViewController: self.modalNavigationController, completion:  {
            
            self.modalNavigationController.si_delegate?.navigationControllerDidSpreadToEntire?(navigationController: self.modalNavigationController)
            
        })
        postTextField.resignFirstResponder()
    
    }
    
    
    func openPhotoOrVideoEditor(_ mediaType: CustomAVAsset.MediaType?, assetIdentifier: String?) {
        
        guard let mediaType = mediaType, let assetIdentifier = assetIdentifier else {
            //error
            return
        }
        
        switch mediaType {
        case .photo: openPhotoEditor(assetIdentifier, deleteTempOnCancel: false, animatedDismiss: true)
        case .video: openVideoEditor(assetIdentifier, deleteTempOnCancel: false, animatedDismiss: true)
        }
    }
    
    
}




