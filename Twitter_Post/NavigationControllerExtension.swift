//
//  NavigationControllerExtension.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/23/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation

enum InternalStructureViewType:Int {
    case ToView = 900, ScreenShot = 910, Overlay = 920
}

public extension UINavigationController {
    
    var parentTargetView: UIView {
        return view
    }
    
    
    func mi_presentViewController(toViewController:UIViewController) {
        
        toViewController.beginAppearanceTransition(true, animated: true)
        ModalAnimator.present(toView: toViewController.view, fromView: parentTargetView) { [weak self] in
            guard let strongslef = self else { return }
            toViewController.endAppearanceTransition()
            toViewController.didMove(toParentViewController: strongslef)
        
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UINavigationController.overlayViewDidTap))
        let overlayView = ModalAnimator.overlayView(fromView: parentTargetView)
        overlayView!.addGestureRecognizer(tapGestureRecognizer)
        
    }
    

    
    func mi_dismissModalView(completion: (() -> Void)?) {
        
        willMove(toParentViewController: nil)
        
        ModalAnimator.dismiss(
            fromView: parentTargetView,
            presentingViewController: visibleViewController) { _ in
                
                completion?()
                self.visibleViewController?.removeFromParentViewController()
        }
        
    }
    
    func overlayViewDidTap(gestureRecognizer: UITapGestureRecognizer) {
        
        
        parentTargetView.isUserInteractionEnabled = false
        willMove(toParentViewController: nil)
        
        ModalAnimator.dismiss(
            fromView: parentTargetView,
            presentingViewController: visibleViewController) { _ in
                
                self.visibleViewController?.removeFromParentViewController()
                self.parentTargetView.isUserInteractionEnabled = true
                
        }
        
    }
    
    func mi_dismissDownSwipeModalView(completion: (() -> Void)?) {
        
        willMove(toParentViewController: nil)
     
        ModalAnimator.dismiss(
            fromView: view.superview ?? parentTargetView,
            presentingViewController: visibleViewController) { _ in
             
                completion?()

                UIView.animate(withDuration: 0.25, animations: {
                     hideStatusBar(0)
                })
               
                
                self.removeFromParentViewController()
                
                
              
        }
        
    }
    
    
}

