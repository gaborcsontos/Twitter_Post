//
//  GMDropDownMenuTitleView.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/15/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit

open class DropdownTitleView : UIControl {
    
    open static var iconSize = CGSize(width: 12, height: 12)
    
    
    open lazy var menuDownImageView: UIImageView = {
        let menuDownImageView = UIImageView(image: self.imageNamed("chevron-up"))
        menuDownImageView.image = menuDownImageView.image!.withRenderingMode(.alwaysTemplate)
        menuDownImageView.tintColor = .black
        menuDownImageView.frame.size = DropdownTitleView.iconSize
        menuDownImageView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        return menuDownImageView
    }()
    open lazy var menuUpImageView: UIImageView = {
        let menuUpImageView = UIImageView(image: self.imageNamed("chevron-up"))
        menuUpImageView.image = menuUpImageView.image!.withRenderingMode(.alwaysTemplate)
        menuUpImageView.tintColor = .black
        menuUpImageView.frame.size = DropdownTitleView.iconSize
        
        return menuUpImageView
    }()
    open lazy var imageView: UIView = {
        // For flip animation, we need a container view
        let imageView = UIView(frame: CGRect(origin: CGPoint.zero, size: DropdownTitleView.iconSize))
        
        imageView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        
        return imageView
    }()
    
    
    open lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)
        titleLabel.textColor = UIColor.black
        titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        
        return titleLabel
    }()
    open var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            
            titleLabel.sizeToFit()
            layoutSubviews()
         //   sizeToFit()
            
        }
    }
    open var isUp: Bool { return menuUpImageView.superview != nil }
    
    // MARK: - Initialization
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
   
    override open func awakeFromNib() {
        setUp()
    }
    
    func setUp() {
        
        imageView.addSubview(menuDownImageView)
        
        addSubview(titleLabel)
        addSubview(imageView)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(DropdownTitleView.toggleMenu))
        
        isUserInteractionEnabled = true
        addGestureRecognizer(recognizer)
        
    }
    
    func imageNamed(_ name: String) -> UIImage {
        let bundle = Bundle(for: type(of: self))
        return UIImage(named: name, in: bundle, compatibleWith: nil)!
    }
    
    // MARK: - Layout
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: imageView.frame.maxX, height: frame.size.height)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.center.x = frame.width / 2
        titleLabel.center.y = frame.height / 2
        
        imageView.frame.origin.x = titleLabel.frame.maxX + 4
        imageView.center.y = frame.height / 2
    }
    
    // MARK: - Actions
    
    @IBAction open func toggleMenu() {
        let viewToReplace = isUp ? menuUpImageView : menuDownImageView
        let replacementView = isUp ? menuDownImageView : menuUpImageView
        let options = isUp ? UIViewAnimationOptions.transitionFlipFromTop : UIViewAnimationOptions.transitionFlipFromBottom
        
        sendActions(for: .touchUpInside)
        
        UIView.transition(from: viewToReplace,
                          to: replacementView,
                          duration: 0.4,
                          options: options,
                          completion: { (Bool) in self.sendActions(for: .valueChanged) })
    }
    
    
}

