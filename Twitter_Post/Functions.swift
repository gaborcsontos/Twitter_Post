//
//  Functions.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/15/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import Photos

//check PhotoIsAllowed
public func PhotoAutorizationStatusCheck() -> Bool {
    
    let status = PHPhotoLibrary.authorizationStatus()
    switch status {
    case .authorized:
        return true
    case .denied, .restricted,.notDetermined:
        PHPhotoLibrary.authorizationStatus()
        return false
        
    }
}

//AlertView on Controller
public func showAlertViewWithTitleAndText(_ title: String?, message: String, vc: UIViewController) {
    
    let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    ac.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) in
      
    }))
    
    vc.present(ac, animated: true, completion: nil)
}

//AlertView to open Settings
public func alertViewToOpenSettings(_ title: String?, message: String) {
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (UIAlertAction) in
        openApplicationSettings()
    }))
        
    alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
    
    let alertWindow = UIWindow(frame: UIScreen.main.bounds)
    alertWindow.rootViewController = UIViewController()
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    alertWindow.makeKeyAndVisible()
    alertWindow.rootViewController?.present(alertController, animated: true, completion: nil)
}

//Open settings function
public func openApplicationSettings() {
    let urlObj = NSURL.init(string:UIApplicationOpenSettingsURLString)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(urlObj as! URL, options: [ : ], completionHandler: { Success in
            
            })
        } else {
            let success = UIApplication.shared.openURL(urlObj as! URL)
            print("Open \(urlObj): \(success)")
        }
}

public func hideStatusBar(_ yOffset: CGFloat) {
    
    let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as! UIWindow
    statusBarWindow.frame = CGRect(x: 0, y: yOffset, width: statusBarWindow.frame.size.width, height: statusBarWindow.frame.size.height)
}

