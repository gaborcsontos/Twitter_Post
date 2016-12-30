//
//  CameraViewController.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit



extension CameraViewController: PhotoEditorDelegate, VideoTrimmerDelegate {
    
    public func handleConfirmPhotoButton(_ assetIdentifier: String?) {
        
        DispatchQueue.main.async {
            self.parent?.navigationController?.mi_dismissModalView(completion: {
                self.delegate?.sendAssetIdToPostViewController(assetIdentifier)
            })
        }
    }
    
    public func handleVideoConfirmButton(_ assetIdentifier: String?) {
        
        DispatchQueue.main.async {
            self.parent?.navigationController?.mi_dismissModalView(completion: {
                self.delegate?.sendAssetIdToPostViewController(assetIdentifier)
            })
        }
    }
   
}




protocol CameraViewControllerDelegate {
    
    func sendAssetIdToPostViewController(_ assetIdentifier: String?)
}


extension CameraViewController: CaptureButtonDelegate {
    
    
    public func didStartCapturing() {
        self.animateButtonDismiss(true)
        captureManager.startRecording()
    }
    
    
    public func didFinishCapturing() {
        //fetch video
        self.animateButtonDismiss(false)
        
        captureManager.stopVideoRecording() { (url, error) in
            if error == nil {
                 self.openVideoEditor(url, animatedDismiss: false)
            } else {
                print("error")
            }
        }
    }
    
    
    public func didPictureTaken() {
        //fetch picture
        captureManager.captureStillImage() { (assetId, error) in
            if error == nil {
                 self.openPhotoEditor(assetId, deleteTempOnCancel: true, animatedDismiss: false)
            } else {
                print("error")
            }
           
        }
    }
    
  
    
}

open class CameraViewController: UIViewController,VideoPreviewLayerProvider, NavigationControllerDelegate {
    
    
    var delegate: CameraViewControllerDelegate?
    var cancelButton: UIButton!
    var cameraChanger = UIImageView()
    var cameraFlashButton = UIImageView()
    var captureButton = CaptureButton()
    
    
    fileprivate lazy var viewTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleViewTap(_:)))
        tap.delaysTouchesEnded = false
        return tap
    }()
    
    
    fileprivate lazy var viewDoubleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleViewDoubleTap(_:)))
        tap.delaysTouchesEnded = false
        tap.numberOfTapsRequired = 2
        return tap
    }()
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
     
        if let nc = self.navigationController as? NavigationController {
            nc.mi_delegate = self
            nc.fullScreenSwipeUp = true
            nc.dismissControllSwipeDown = true
        }

        setUpCaptureManager()
        
        setUpGestures()
       
        
        DispatchQueue.main.async {
            self.setupButtons()
        }
        
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
        hideStatusBar(-20)
    
    }

    
    func animateButtonDismiss(_ dismiss: Bool) {
        
        var alpha:CGFloat = 0
        var transformScale:CGFloat = 0.2
        
        if !dismiss { alpha = 1; transformScale = 1 }
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            
            let transform = CGAffineTransform(translationX: transformScale, y: transformScale)
            self.cancelButton.transform = transform
            self.cameraFlashButton.transform = transform
            self.cameraChanger.transform = transform
            
            
        }, completion: { (true) in
            
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseIn, animations: {
                
                self.cancelButton.alpha = alpha
                self.cameraFlashButton.alpha = alpha
                self.cameraChanger.alpha = alpha
                
            }, completion: nil)
           

        })
    }
    
    override open func loadView() {
        view = CapturePreviewView()
    }

    //MARK: VideoPreviewLayerProvider
    
    /**
     The `AVCaptureVideoPreviewLayer` that will be used with the `AVCaptureSession`.
     */
    open var previewLayer: AVCaptureVideoPreviewLayer {
        return view.layer as! AVCaptureVideoPreviewLayer
    }
    
    
    //open PhotoEditor
    func openPhotoEditor(_ assetLocalId: String?, deleteTempOnCancel: Bool, animatedDismiss: Bool) {
        
        guard let assetIdentifier = assetLocalId  else {
            return
        }
        
        let photoEditor = PhotoEditorViewController(assetLocalId: assetIdentifier, deleteTempOnCancel: deleteTempOnCancel, dismissAnimated: animatedDismiss)
        photoEditor.delegate = self
        self.present(photoEditor, animated: false, completion: nil)
    
    }
    
    //open VideoEditor
    func openVideoEditor(_ tempURL: URL?, animatedDismiss: Bool) {
        
        guard let temp = tempURL  else {
            return
        }
        
        let videoEditor = VideoTrimmerViewController(assetLocalId: nil, tempURL: temp, dismissAnimated: false)
        videoEditor.delegate = self
        self.present(videoEditor, animated: false, completion: nil)
        
    }

    
    
    @objc fileprivate func handleViewTap(_ tap: UITapGestureRecognizer) {
        let loc = tap.location(in: self.view)
        do {
            try captureManager.focusAndExposure(at: loc)
            showIndicatorView(at: loc)
        } catch {
            print("Woops, got error: \(error)")
        }
    }
    
    
    fileprivate func setUpGestures() {
        self.view.addGestureRecognizer(viewTap)
        self.view.addGestureRecognizer(viewDoubleTap)
        viewTap.require(toFail: viewDoubleTap)
    }
    
    
    fileprivate func setUpCaptureManager() {
        captureManager.setUp(sessionPreset: AVCaptureSessionPresetHigh,
                             previewLayerProvider: self,
                             inputs: [.video],
                             outputs: [.stillImage])
        { (error) in
            print("Woops, got error: \(error)")
        }
        
        captureManager.startRunning()
    }


    
    private func setupButtons(){
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "ic_close_cam")!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white
        cancelButton = UIButton(type: .system)
        cancelButton.setImage(imageView.image, for: .normal)
        cancelButton.tintColor = .white
        
        
        cameraChanger.isUserInteractionEnabled = true
        cameraChanger.contentMode = .scaleAspectFit
        cameraChanger.image = UIImage(named:"rotate-icon-27813")!.withRenderingMode(.alwaysTemplate)
        cameraChanger.tintColor = .white
        cameraChanger.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cameraDevice)))
        
        
        cameraFlashButton.isUserInteractionEnabled = true
        cameraFlashButton.contentMode = .scaleAspectFit
        cameraFlashButton.image = UIImage(named:"ic_flash_off")
        cameraFlashButton.alpha = 0.8
        cameraFlashButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cameraFlash)))
        
        
        //cancelButton x,y,w,h
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        if !cancelButton.isDescendant(of: self.view) { self.view.addSubview(cancelButton)}
        cancelButton.leftAnchor.constraint(equalTo: self.view.leftAnchor,constant: 18).isActive = true
        cancelButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 15).isActive = true
        cancelButton.action = { [weak self] in self?.cancel() }
        
     
        //capture button
        captureButton.SetupButton(self.view, width: 100, cgPoint: CGPoint(x: self.view.frame.width / 2 - 50, y: self.view.frame.height - 120), delegate: self)
        
        
        //cameraChanger x,y,w,h
        cameraChanger.translatesAutoresizingMaskIntoConstraints = false
        if !cameraChanger.isDescendant(of: self.view){ self.view.addSubview(cameraChanger)}
        cameraChanger.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -32).isActive = true
        cameraChanger.heightAnchor.constraint(equalToConstant: 30).isActive = true
        cameraChanger.widthAnchor.constraint(equalToConstant: 30).isActive = true
        cameraChanger.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor).isActive = true
        
        //cameraFlashButton x,y,w,h
        cameraFlashButton.translatesAutoresizingMaskIntoConstraints = false
        if !cameraFlashButton.isDescendant(of: self.view){ self.view.addSubview(cameraFlashButton)}
        cameraFlashButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 32).isActive = true
        cameraFlashButton.heightAnchor.constraint(equalToConstant: 26).isActive = true
        cameraFlashButton.widthAnchor.constraint(equalToConstant: 26).isActive = true
        cameraFlashButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor).isActive = true
        
    }
    
    @objc fileprivate func handleViewDoubleTap(_ tap: UITapGestureRecognizer) {
        toggleCamera()
    }
    
    
    fileprivate func toggleCamera() {
        captureManager.toggleCamera() { (error) -> Void in
            print("Woops, got error: \(error)")
        }
    }
    
    
    func cameraFlash() {
           let wantsFlash = (captureManager.flashMode == .off)
        do {
            try captureManager.toggleFlash()
            let imageName = wantsFlash ? "ic_flash_on" : "ic_flash_off"
            self.changeFlashButtonWithAnimate(imageName, alpha: 0.8)
        } catch {
            print("Woops, got an error: \(error)")
        }

    }
    
    
    func changeFlashButtonWithAnimate(_ imgname: String, alpha: Double) {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn], animations: {
            self.cameraFlashButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.cameraFlashButton.image = UIImage(named: imgname)
            self.cameraFlashButton.alpha = CGFloat(alpha)
            
        }) { (true) in
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [.curveEaseIn], animations: {
                self.cameraFlashButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
        }
        
        
    }
    
    
    func cameraDevice() {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn], animations: {
            self.cameraChanger.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (true) in
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [.curveEaseIn], animations: {
                self.cameraChanger.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                
            }, completion: nil)
        }
        //change device
        self.toggleCamera()
    }
    
    func cancel(){
        
        DispatchQueue.main.async {
            self.parent?.navigationController?.mi_dismissModalView(completion: nil)
        }
     
    }
    
    /**
     Makes a `FocusIndicatorView` pop up and down at `loc`.
     */
    open func showIndicatorView(at loc: CGPoint) {
        let indicator = FocusIndicatorView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        indicator.center = loc
        indicator.backgroundColor = .clear
        
        self.view.addSubview(indicator)
        
        indicator.popUpDown() { _ -> Void in
            indicator.removeFromSuperview()
        }
    }
    
    
    
}
