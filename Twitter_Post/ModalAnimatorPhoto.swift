//
//  ModalAnimatorPhoto.swift
//  Transition
//
//  Created by Gabor Csontos on 12/22/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit

public class ModalAnimatorPhoto {
    

    public class func present(_ toView: UIView, fromView: UIView, completion: @escaping () -> Void) {
    

        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        var toViewFrame = fromView.bounds.offsetBy(dx: 0, dy: statusBarHeight + fromView.bounds.size.height)
        toViewFrame.size.height = toViewFrame.size.height
        toView.frame = toViewFrame
        
        toView.alpha = 0.0
        
        fromView.addSubview(toView)
        
        UIView.animate(
            withDuration: 0.2,
            animations: { () -> Void in
                
                let statusBarHeight = UIApplication.shared.statusBarFrame.height
                let toViewFrame = fromView.bounds.offsetBy(dx: 0, dy: statusBarHeight + fromView.bounds.size.height / 2.0 + 4)
                toView.frame = toViewFrame
                
                toView.alpha = 1.0
                
        }) { (result) -> Void in
            
            completion()
            
        }

    }
    
    public class func dismiss(_ toView: UIView, fromView: UIView, completion: @escaping () -> Void) {
        
        //Checking PhotoAutorizationStatus
        if PhotoAutorizationStatusCheck() {
            
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                
                let statusBarHeight = UIApplication.shared.statusBarFrame.height
                let toViewFrame = fromView.bounds.offsetBy(dx: 0, dy: statusBarHeight + fromView.bounds.size.height / 2.0 + 4)
            
                toView.frame = toViewFrame
                
            }) { (result) -> Void in
                
                completion()
            }
            
        } else {
            
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                
                let toViewFrame = fromView.bounds.offsetBy(dx: 0, dy: fromView.bounds.size.height - 44)
               
                toView.frame = toViewFrame
                
            }) { (result) -> Void in
                
                completion()
            }

          
        }
        
        
    }
    
    public class func dismissOnBottom(_ toView: UIView, fromView: UIView, completion: @escaping () -> Void) {
        
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            
            let toViewFrame = fromView.bounds.offsetBy(dx: 0, dy: fromView.bounds.size.height - 44)
            toView.frame = toViewFrame
            
        }) { (result) -> Void in
            
            completion()
        }
        
    }

    public class func showOnfullScreen(_ toView: UIView, fromView: UIView, completion: @escaping () -> Void) {
        
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            
            let toViewFrame = fromView.bounds.offsetBy(dx: 0, dy: statusBarHeight)
            toView.frame = toViewFrame
            
        }) { (result) -> Void in
            
            completion()
        }
        
    }
    
}
