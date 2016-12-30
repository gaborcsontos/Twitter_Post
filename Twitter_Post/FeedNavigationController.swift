//
//  FeedNavigationController.swift
//  Transition
//
//  Created by Gabor Csontos on 12/23/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit

@objc public protocol FeedNavigationControllerDelegate {
    @objc optional func navigationControllerDidSpreadToEntire(navigationController: UINavigationController)
    @objc optional func navigationControllerDidClosed(navigationController: UINavigationController)
}


public class FeedNavigationController: UINavigationController {
    
    
    public var si_delegate: FeedNavigationControllerDelegate?
    public var parentNavigationController: UINavigationController?
    
    public var minDeltaUpSwipe: CGFloat = 50
    public var minDeltaDownSwipe: CGFloat = 50
    
    public var fullScreenSwipeUp = true

    var previousLocation = CGPoint.zero
    var originalLocation = CGPoint.zero
    var originalFrame = CGRect.zero
    
    
    override public func viewDidLoad() {
        originalFrame = self.view.frame
        
        //panGesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(FeedNavigationController.handlePanGesture(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        
    }
    


    
    func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        let location = gestureRecognizer.location(in: parent!.view)
        let degreeY = location.y - self.previousLocation.y
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.began:
            
            originalLocation = self.view.frame.origin
            break
            
        case UIGestureRecognizerState.changed:
            
            var frame = self.view.frame
            frame.origin.y += degreeY
            self.view.frame = frame
        
            break
            
        case UIGestureRecognizerState.ended :
            
            if fullScreenSwipeUp &&  originalLocation.y - self.view.frame.minY > minDeltaUpSwipe {
                
                UIView.animate(
                    withDuration: 0.2,
                    animations: { [weak self] in
                        guard let strongslef = self else { return }
                        
                        var frame = strongslef.originalFrame
                        let statusBarHeight = UIApplication.shared.statusBarFrame.height
                        frame.origin.y = statusBarHeight
                        strongslef.view.frame = frame
                        
                        
                    }, completion: { (result) -> Void in
                        
                        UIView.animate(
                            withDuration: 0.1,
                            delay: 0.0,
                            options: UIViewAnimationOptions.curveLinear,
                            animations: { () -> Void in
                              
                        },
                            completion: { [weak self] result in
                                guard let strongslef = self else { return }
                                
                                gestureRecognizer.isEnabled = true
                                strongslef.si_delegate?.navigationControllerDidSpreadToEntire?(navigationController: strongslef)
                                
                            }
                        )
                })
                
            } else {
                
                UIView.animate(
                    withDuration: 0.6,
                    delay: 0.0,
                    usingSpringWithDamping: 0.5,
                    initialSpringVelocity: 0.1,
                    options: UIViewAnimationOptions.curveLinear,
                    animations: { [weak self] in
                        guard let strongslef = self else { return }

                        
                        var frame = strongslef.originalFrame //view.frame
                        frame.origin.y = strongslef.originalLocation.y
                    
                        strongslef.view.frame = frame
                    },
                    
                    completion: { (result) -> Void in
                        
                        gestureRecognizer.isEnabled = true
                        
                })
                
            }
            
            break
            
        default:
            break
            
        }
        
        self.previousLocation = location
        
    }
    
    
    public override var parentTargetView: UIView {
      
        return navigationController!.parentTargetView
    }
    
    public var parentController: UIViewController {

        return navigationController!
    }
    

}
