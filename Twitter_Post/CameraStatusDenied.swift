//
//  CameraStatusDenied.swift
//  Loutude
//
//  Created by Gabor Csontos on 8/11/16.
//  Copyright © 2016 Loutude. All rights reserved.
//

import UIKit


///CameraStatusDenied for Indicating if the User declined the Photo access


class CameraStatusDenied: UIView {
    
    
    
    let imgView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = UIImage(named: "ic_enable_photo")
        return image
    }()
    
    
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Please enable your camera/photo access"
        titleLabel.textColor = UIColor.darkGray
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    

    let alertLabel : UILabel = {
        let alertLabel = UILabel()
        alertLabel.text = "In iPhone settings, tap (*your app name)\n and turn on Camera/Photo access."
        alertLabel.numberOfLines = 2
        alertLabel.textColor = UIColor.lightGray
        alertLabel.font = UIFont.systemFont(ofSize: 14)
        alertLabel.textAlignment = .center
        return alertLabel
    }()
    
    lazy var alertButton: UIButton = {
        
        let alertButton = UIButton()
        alertButton.setTitle("Open Settings", for: UIControlState())
        alertButton.setTitleColor(UIColor.blue, for: UIControlState())
        alertButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        alertButton.addTarget(self, action: #selector(getAccessForSettings(_:)), for: .touchUpInside)
        
        return alertButton
    }()
    
    func setupView(parentVC: UIView){
        
        self.backgroundColor = UIColor.white
        
    
        if !self.isDescendant(of: parentVC){ parentVC.addSubview(self)}
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: parentVC.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: parentVC.centerYAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: parentVC.heightAnchor).isActive = true
        self.widthAnchor.constraint(equalTo: parentVC.widthAnchor).isActive = true
        
        
        if !imgView.isDescendant(of: self){ self.addSubview(imgView)}
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        imgView.topAnchor.constraint(equalTo: self.topAnchor, constant: 100).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: 40 * 1.5).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: 40 * 1.5).isActive = true
        
        
        if !titleLabel.isDescendant(of: self){ self.addSubview(titleLabel)}
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 5).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        
        if !alertLabel.isDescendant(of: self){ self.addSubview(alertLabel)}
        alertLabel.translatesAutoresizingMaskIntoConstraints = false
        alertLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5).isActive = true
        alertLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        alertLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        alertLabel.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        
        if !alertButton.isDescendant(of: self){ self.addSubview(alertButton)}
        alertButton.translatesAutoresizingMaskIntoConstraints = false
        alertButton.topAnchor.constraint(equalTo: alertLabel.bottomAnchor, constant: 5).isActive = true
        alertButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        alertButton.widthAnchor.constraint(equalToConstant: 120).isActive = true
        alertButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
    
    
    
    func getAccessForSettings(_ sender: UIButton){
        //Open App's settings
        let urlObj = NSURL.init(string:UIApplicationOpenSettingsURLString)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(urlObj as! URL, options: [ : ], completionHandler: { Success in
                
            })
        } else {
            let success = UIApplication.shared.openURL(urlObj as! URL)
            print("Open \(urlObj): \(success)")
        }
    }
    
    
    //Show or Remove from the parentView
    func show(show: Bool, parentVC: UIView, imagename: String?,title: String?, alert: String?) {
        
        if show {
            
            
            DispatchQueue.main.sync(execute: {
                
                setupView(parentVC: parentVC)

            })
            
            if let newimagename = imagename {
                self.imgView.image = UIImage(named: newimagename)
            }
            
            if let newtitle = title {
                self.titleLabel.text = newtitle
            }
            
            if let newalert = alert {
                self.alertLabel.text = newalert
            }
            
        } else {
            
            DispatchQueue.main.sync(execute: {
                
                if self.isDescendant(of: parentVC) { self.removeFromSuperview() }
                
            })
            
            
        }
    }
}
