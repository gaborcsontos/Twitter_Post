//
//  CaptureButton.swift
//  Loutude
//
//  Created by Gabor Csontos on 11/26/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit


@objc public protocol CaptureButtonDelegate {
    @objc optional func didStartCapturing()
    @objc optional func didFinishCapturing()
    @objc optional func didPictureTaken()
}

open class CaptureButton: UIView {
    
    //here you are able to change the colors or the timeInterval of the recording duration
    open var barWidth: CGFloat = 4
    open var barColor: UIColor = UIColor.red
    open var captureButtonBackgroundColor: UIColor = UIColor(white: 1, alpha: 0.4)
    open var captureMainButtonColor: UIColor = UIColor(white: 0.0, alpha: 0.6)
    open var startAngle: CGFloat = -90
    open var timePeriod: TimeInterval = 15 //recording duration!
    
    weak var delegate: CaptureButtonDelegate?
  
    
    var timePeriodTimer: Timer?
    var circleLayer: CAShapeLayer?
    var isFinished = true
    
    var captureHoldingButton: UIView!
    var captureButton: UIView!
    
        
    public func SetupButton(_ view: UIView, width: CGFloat, cgPoint: CGPoint, delegate: CaptureButtonDelegate?)  {
        
        self.delegate = delegate
        self.frame = CGRect(x: cgPoint.x, y: cgPoint.y, width: width, height: width)
        
        if !self.isDescendant(of: view) { view.addSubview(self) }
        self.backgroundColor = .clear
        
        
        captureHoldingButton = createView(cornerRadius: width, bcgColor: captureButtonBackgroundColor)
        captureHoldingButton.frame = CGRect(x: 0, y: 0, width: width, height: width)
        if !captureHoldingButton.isDescendant(of: self) { self.addSubview(captureHoldingButton) }
        captureHoldingButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        captureButton = createView(cornerRadius: width * 0.6, bcgColor: captureMainButtonColor)
        captureButton.frame = CGRect(x: width * 0.2, y: width * 0.2, width: width * 0.6, height: width * 0.6)
        if !captureButton.isDescendant(of: self) { self.addSubview(captureButton) }
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(capturePhotoGesture(_:))))
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(captureVideoGesture(_:))))
    }
    
    
    public func capturePhotoGesture(_ gesture: UITapGestureRecognizer) {
        
        //animate the gesture
        
        animatePictureTaking()
        
        self.delegate?.didPictureTaken?()
        
    }
    
    
   public func captureVideoGesture(_ gesture: UILongPressGestureRecognizer) {
        
        
        //animate the gesture
        if gesture.state == .began { animateWithCircle() }
        
        if gesture.state == .ended {
            
            //animate
            stopAnimateButton()
            
            if !isFinished {
                isFinished = true
                self.delegate?.didFinishCapturing?()
            }
            
            reset()
          
        }
    }
 

    func createCircleAndAnimate(){
        
        //changing barColor to self.tintColor
        barColor = self.tintColor
        
        
        isFinished = false
        reset()
        
        self.delegate?.didStartCapturing?()
        
        timePeriodTimer = Timer.schedule(delay: timePeriod) { [weak self] (timer) -> Void in
            self?.timePeriodTimer?.invalidate()
            self?.timePeriodTimer = nil
            self?.isFinished = true
            self?.delegate?.didFinishCapturing?()
            self?.reset()
            self?.stopAnimateButton()
        }
        
        let center = self.center()
        var radius = self.radius()
        radius = radius - (barWidth / 2)
        
        circleLayer = CAShapeLayer()
        circleLayer!.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: degreesToRadians(startAngle), endAngle: degreesToRadians(startAngle + 360), clockwise: true).cgPath
        circleLayer!.fillColor = UIColor.clear.cgColor
        circleLayer!.strokeColor = barColor.cgColor
        circleLayer!.lineWidth = barWidth
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = timePeriod
        animation.isRemovedOnCompletion = true
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        circleLayer!.add(animation, forKey: "drawCircleAnimation")
        self.layer.addSublayer(circleLayer!)
    }
    
    

    
    func reset()
    {
        timePeriodTimer?.invalidate()
        timePeriodTimer = nil
        circleLayer?.removeAllAnimations()
        circleLayer?.removeFromSuperlayer()
        circleLayer = nil
    }
    
 
    // MARK: - Private
    
    fileprivate func center() -> CGPoint
    {
        return CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
    }
    
    fileprivate func radius() -> CGFloat
    {
        let center = self.center()
        
        return min(center.x, center.y)
    }
    
    fileprivate func degreesToRadians (_ value: CGFloat) -> CGFloat { return value * CGFloat(M_PI) / CGFloat(180.0) }


    
    fileprivate func createView(cornerRadius: CGFloat, bcgColor: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = bcgColor
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius / 2
        view.isUserInteractionEnabled = true
        return view
    }
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame) }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

//Animations
extension CaptureButton {
    
    func animateWithCircle() {
        
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: {
            
            self.captureButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.captureHoldingButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.layoutIfNeeded()
        }, completion: {
            
            (value: Bool) in
            
            self.createCircleAndAnimate()
            
        })
        
    }
    
    func stopAnimateButton(){
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.captureButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.captureHoldingButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.layoutIfNeeded()
        })
    }
    
    
    fileprivate func animatePictureTaking(){
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseIn], animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (true) in
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: [.curveEaseIn], animations: {
                self.captureButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
        }
    }
    
}
