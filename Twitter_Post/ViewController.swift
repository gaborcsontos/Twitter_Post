//
//  ViewController.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/15/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//




/*
THANKS FOR DOWNLOADING AND USING TWITTER_POST CONTROLLER.
 
GITHUB:
 
 https://github.com/csontosgabor

Dribbble:
 https://dribbble.com/gaborcsontos
 
 
*/


/*
 
 Don't forget to add these lines into your Info.plist !!!
 
Privacy - Location When in Use Usage Description ------ We need to access your location.
Privacy - Camera Usage Description ------               We need to access your camera.
Privacy - Photo Library Usage Description -----         We need to access your photos.


 */


import UIKit


internal var greetingsText: String = "Thanks for using TWITTER_POST. \n github: \n  https://github.com/csontosgabor"


class ViewController: UIViewController {
    
    
    let label: UITextView = {
        
        let label = UITextView()
        label.text = greetingsText
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.isScrollEnabled = false
        label.isEditable = false
        label.dataDetectorTypes = .link
        return label
        
    }()
    
    
    lazy var postBtn: UIButton = {
        
        let button = UIButton(type: .system)
        let imageView = UIImageView()
        
        imageView.image = UIImage(named: "ic_post")!.withRenderingMode(.alwaysOriginal)
        button.setImage(imageView.image, for: .normal)
        button.tintColor = UIColor.clear
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(_openpostController(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    
    
    
    func _openpostController(_ sender: UIButton) {
        let nav = UINavigationController(rootViewController: PostViewController())
        self.present(nav, animated: true, completion: nil)
        
    }
    
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        //label x,y,w,h
        if !label.isDescendant(of: self.view) { self.view.addSubview(label) }
        label.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -100).isActive = true
        label.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        
        //postBtn x,y,w,h
        if !postBtn.isDescendant(of: self.view) { self.view.addSubview(postBtn) }
        postBtn.widthAnchor.constraint(equalToConstant: 50).isActive = true
        postBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        postBtn.topAnchor.constraint(equalTo: self.label.bottomAnchor,constant: 12).isActive = true
        postBtn.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        
    }
    
}
