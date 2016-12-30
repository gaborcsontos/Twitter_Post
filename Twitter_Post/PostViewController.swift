//
//  PostViewController.swift
//  Photo
//
//  Created by Gabor Csontos on 8/31/16.
//  Copyright © 2016 GabeMajorszki. All rights reserved.
//

import UIKit
import Photos

/*
import Nuke
import Locksmith
*/







class PostViewController: UIViewController {
    
    
    
    var headerViewTopAnchor: NSLayoutConstraint?
    var postTextFieldHeightAnchor: NSLayoutConstraint?
    var currentUserSubnameWidthAnchor: NSLayoutConstraint?
    
    let welcomeString: String = "What's happening?"

    //Post contents!!!!!!!!!!!!! this will be sent for the DB!
    var currentUserId: String?
    var userLocation: String? { didSet { setupLocationAdded() } }
    var postText: String?
    var contentAsset: CustomAVAsset? {didSet { setupContentAssetAfterSetted() } }
    var date: Date? //if someone wants to use it -> Easier in the DB to use a Datestamp
 
   
    
    //GMVideoTrimmer
    var videoTrimmerVC: VideoTrimmerViewController!
 
    //PhotoEditorViewController
    var photoEditorVC: PhotoEditorViewController!
    
    
    ///////////////////////////////////CAMERA///////////////////////////////////
    //CameraNavigationController                                            ///
    var camNavigationController = NavigationController()                    ///
                                                                            ///
    //CameraViewController                                                  ///
    lazy var cameraVC: CameraViewController = {                             ///
        let cameraVC = CameraViewController()                               ///
        cameraVC.delegate = self                                            ///
        return cameraVC                                                     ///
    }()                                                                     ///
    ///////////////////////////////////////////////////////////////////////////
    
    
    // modalNavigationController
    var modalNavigationController = FeedNavigationController()
    
    
    //PhotoViewController
    lazy var photoVC: PhotoViewController = {
        let photo = PhotoViewController()
        photo.delegate = self
        return photo
    }()
    
    //locationManager
    var locationManager: LocationManager!
    
    
    
    
    
    //Dismiss button
    lazy var dismissButton: UIImageView = {
        let button = UIImageView()
        button.contentMode = .scaleAspectFill
        button.clipsToBounds = true
        button.image = UIImage(named: "close_tag")
        button.isUserInteractionEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissView)))
        return button
    }()
    
    //Scroll view
    lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = UIColor.white
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        return scroll
    }()
    
    
    //HEADER ContainerView -> currentUser's information
    let headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    
    //imageView
    let currentUserImageView: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 8
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.backgroundColor = .lightGray
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    
    lazy var currentUserName: UILabel = {
        let text = UILabel()
        text.textColor = self.view.tintColor
        text.font = UIFont.boldSystemFont(ofSize: 16)
        text.textAlignment = .left
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
    }()
    
    let currentUserSubname: UILabel = {
        let text = UILabel()
        text.textColor = UIColor.black
        text.font = UIFont.systemFont(ofSize: 14)
        text.textAlignment = .left
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
    }()
    
    lazy var currentUserLocation: UILabel = {
        let text = UILabel()
        text.textColor = UIColor.lightGray
        text.font = UIFont.systemFont(ofSize: 14)
        text.textAlignment = .left
        text.isUserInteractionEnabled = true
        text.translatesAutoresizingMaskIntoConstraints = false
        text.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(deleteUserLocation)))
        return text
    }()

    
    //POST TEXTFIELD
    lazy var postTextField: UITextView = {
        let tf = UITextView()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = UIColor.black
        tf.backgroundColor = .clear
        tf.isScrollEnabled = false
        return tf
    }()

    lazy var postTextFieldPlaceHolder: UITextView = {
        let tf = UITextView()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = UIColor.lightGray
        tf.backgroundColor = .clear
        tf.isScrollEnabled = false
        tf.isEditable = false
        tf.text = self.welcomeString
        return tf
    }()
    
    
    //POST ContentContainerView
    var postContentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    

    lazy var postContentImageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(editPostContent)))
        img.clipsToBounds = true
        img.isUserInteractionEnabled = true
        img.isHidden = true
        return img
    }()
    

    lazy var removeButtonForContent: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(removeContentFromPost)))
        img.image = UIImage(named: "ic_post_delete_asset")
        img.isUserInteractionEnabled = true
        return img
    }()
    
    let playButtonForContentImageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFill
        img.image = UIImage(named: "ic_swipe_play")
        img.isHidden = true
        return img
    }()
    

    

    
    
   
    
    func setupViews(){
        
        //SCROLLVIEW x,y, w, h
        if !scrollView.isDescendant(of: self.view){ self.view.addSubview(scrollView)}
        scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 55).isActive = true
        scrollView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        scrollView.contentSize.width = self.view.frame.width
        scrollView.delegate = self
        
        //DISMISSBUTTON x,y, w, h
        if !dismissButton.isDescendant(of: self.view) { self.view.addSubview(dismissButton) }
        dismissButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10).isActive = true
        dismissButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 30).isActive = true
        dismissButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //HEADER CONTAINER x,y, w, h
        if !headerContainerView.isDescendant(of: self.scrollView) { self.scrollView.addSubview(headerContainerView) }
        headerViewTopAnchor = headerContainerView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: -50)
        headerViewTopAnchor?.isActive = true
        headerContainerView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor, constant: 10).isActive = true
        headerContainerView.rightAnchor.constraint(equalTo: self.dismissButton.leftAnchor, constant: -10).isActive = true
        headerContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //currentUserImage x,y,w,h
        if !currentUserImageView.isDescendant(of: headerContainerView) { headerContainerView.addSubview(currentUserImageView)}
        currentUserImageView.leftAnchor.constraint(equalTo: headerContainerView.leftAnchor).isActive = true
        currentUserImageView.topAnchor.constraint(equalTo: headerContainerView.topAnchor).isActive = true
        currentUserImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        currentUserImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        //currentUserName x,y,w,h
        if !currentUserName.isDescendant(of: headerContainerView) { headerContainerView.addSubview(currentUserName)}
        currentUserName.leftAnchor.constraint(equalTo: currentUserImageView.rightAnchor, constant: 8).isActive = true
        currentUserName.topAnchor.constraint(equalTo: currentUserImageView.topAnchor).isActive = true
        currentUserName.heightAnchor.constraint(equalToConstant: 20).isActive = true
        currentUserName.rightAnchor.constraint(equalTo: self.headerContainerView.rightAnchor).isActive = true
        
        //currentUserSubname x,y,w,h
        if !currentUserSubname.isDescendant(of: headerContainerView) { headerContainerView.addSubview(currentUserSubname)}
        currentUserSubname.leftAnchor.constraint(equalTo: currentUserImageView.rightAnchor,constant: 8).isActive = true
        currentUserSubname.topAnchor.constraint(equalTo: currentUserName.bottomAnchor).isActive = true
        currentUserSubname.heightAnchor.constraint(equalToConstant: 20).isActive = true
        currentUserSubnameWidthAnchor = currentUserSubname.widthAnchor.constraint(equalToConstant: 80)
        currentUserSubnameWidthAnchor?.isActive = true
        
        //currentUserLocation x,y,w,h
        if !currentUserLocation.isDescendant(of: headerContainerView) { headerContainerView.addSubview(currentUserLocation)}
        currentUserLocation.leftAnchor.constraint(equalTo: currentUserSubname.rightAnchor).isActive = true
        currentUserLocation.topAnchor.constraint(equalTo: currentUserName.bottomAnchor).isActive = true
        currentUserLocation.heightAnchor.constraint(equalToConstant: 20).isActive = true
        currentUserLocation.rightAnchor.constraint(equalTo: headerContainerView.rightAnchor,constant: -8).isActive = true
        
        
        //TEXTFIELD x,y,w,h
        if !postTextField.isDescendant(of: self.scrollView) { self.scrollView.addSubview(postTextField) }
        postTextField.topAnchor.constraint(equalTo: self.headerContainerView.bottomAnchor, constant: 30).isActive = true
        postTextField.leftAnchor.constraint(equalTo: self.headerContainerView.leftAnchor, constant: 10).isActive = true
        postTextField.rightAnchor.constraint(equalTo: self.headerContainerView.rightAnchor, constant: -10).isActive = true
        postTextFieldHeightAnchor = postTextField.heightAnchor.constraint(equalToConstant: 40)
        postTextFieldHeightAnchor?.isActive = true
        postTextField.delegate = self
        
        //textfield placeHolder x,y,w,h
        if !postTextFieldPlaceHolder.isDescendant(of: self.scrollView) { self.scrollView.insertSubview(postTextFieldPlaceHolder, belowSubview: postTextField) }
        postTextFieldPlaceHolder.topAnchor.constraint(equalTo: self.headerContainerView.bottomAnchor, constant: 30).isActive = true
        postTextFieldPlaceHolder.leftAnchor.constraint(equalTo: self.headerContainerView.leftAnchor, constant: 10).isActive = true
        postTextFieldPlaceHolder.rightAnchor.constraint(equalTo: self.headerContainerView.rightAnchor, constant: -10).isActive = true
        postTextFieldPlaceHolder.heightAnchor.constraint(equalTo: self.postTextField.heightAnchor).isActive = true
        
        
        //PostContent ContainerView x,y,w,h
        if !postContentContainerView.isDescendant(of: self.scrollView) { self.scrollView.addSubview(postContentContainerView) }
        postContentContainerView.topAnchor.constraint(equalTo: self.postTextField.bottomAnchor, constant: 10).isActive = true
        postContentContainerView.leftAnchor.constraint(equalTo: self.view.leftAnchor,constant: 10).isActive = true
        postContentContainerView.rightAnchor.constraint(equalTo: self.view.rightAnchor,constant: -10).isActive = true
        postContentContainerView.heightAnchor.constraint(equalTo: self.postContentContainerView.widthAnchor).isActive = true
        postContentContainerView.backgroundColor = UIColor.clear
        
        //postContentImagView x,y,w,h
        if !postContentImageView.isDescendant(of: self.postContentContainerView) { self.postContentContainerView.addSubview(postContentImageView) }
        postContentImageView.centerYAnchor.constraint(equalTo: self.postContentContainerView.centerYAnchor).isActive = true
        postContentImageView.centerXAnchor.constraint(equalTo: self.postContentContainerView.centerXAnchor).isActive = true
        postContentImageView.heightAnchor.constraint(equalTo: self.postContentContainerView.heightAnchor).isActive = true
        postContentImageView.widthAnchor.constraint(equalTo: self.postContentContainerView.widthAnchor).isActive = true
        postContentImageView.backgroundColor = UIColor.lightGray
        

        //removeButtonForContent  x,y,w,h
        if !removeButtonForContent.isDescendant(of: self.postContentImageView) { self.postContentImageView.addSubview(removeButtonForContent) }
        removeButtonForContent.topAnchor.constraint(equalTo: self.postContentImageView.topAnchor, constant: 10).isActive = true
        removeButtonForContent.rightAnchor.constraint(equalTo: self.postContentImageView.rightAnchor,constant: -10).isActive = true
        removeButtonForContent.heightAnchor.constraint(equalToConstant: 30).isActive = true
        removeButtonForContent.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        //playButtonForContentImageView x,y,w,h
        if !playButtonForContentImageView.isDescendant(of: self.postContentImageView) { self.postContentImageView.addSubview(playButtonForContentImageView) }
        playButtonForContentImageView.centerYAnchor.constraint(equalTo: self.postContentImageView.centerYAnchor).isActive = true
        playButtonForContentImageView.centerXAnchor.constraint(equalTo: self.postContentImageView.centerXAnchor).isActive = true
        playButtonForContentImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playButtonForContentImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
    
        
        //set scrollView
        setScrollViewHeight()
        
    }
    
    
    
    func setScrollViewHeight(){
        
        if contentAsset != nil {
            
            scrollView.contentSize.height = 20 + 50 + 40 + self.view.frame.width + 200
            
        } else {
            
            scrollView.contentSize.height = CGFloat(20 + 50 + 40)
        }
    }
    
    
    
    func setupKeyBoardObservers(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        
        view.backgroundColor = .white
        
        //views
        setupViews()
        
        //currentUser
        checkCurrentUserAndSetupHeaderViewLabels()
        
        //keyBoard
        setupKeyBoardObservers()
        
        DispatchQueue.main.async {
            //PhotoViewController
             self.setupFeedNavigationControllerAndCheckContent()
        }

        //location
        setupLocationManager()
        
     
     
    }
    
    
    
    func setupContentAssetAfterSetted() {
        
        self.postContentImageView.isHidden = false
        
        checkContentAndSetPostButton()
        
        if self.headerViewTopAnchor?.constant != 0 {
            
            UIView.animate(withDuration: 0.25, animations: {
                self.headerViewTopAnchor?.constant = 0
                self.headerContainerView.alpha = 1
            })
            
            self.view.layoutIfNeeded()
        }
        setScrollViewHeight()
        
        reactOnScroll()
        
    }

   
    
    
    func setupLocationManager(){
        
    locationManager = LocationManager()
        
            .onSuccess { userLocation, location in
                
                guard let userLocation = userLocation else {
                    return
                }
                
                self.userLocation = userLocation
            }
            .onFailure { error in
               print(error)
            }
        
    //here you are able to set you want to show the location by .City or by .SubLocality
    locationManager = locationManager.getLocation(.City)
        
    }
    
    func setupLocationAdded() {
        
        if userLocation != nil {
            //currentUserLocationtext added
             currentUserLocation.text = "• \(userLocation!) •"
            //locationIndicatorColor added
            photoVC.locationIsSetted(bool: true)
        } else {
            //currentUserLocationtext removed
            currentUserLocation.text = nil
            //locationIndicatorColor removed
            photoVC.locationIsSetted(bool: false)
        }
    }
    
    
    func setupFeedNavigationControllerAndCheckContent(){
        
        modalNavigationController = FeedNavigationController(rootViewController: photoVC)
        navigationController?.addChildViewController(modalNavigationController)
        navigationController?.si_presentViewController(toViewController: modalNavigationController, completion:  {

            //content
            self.checkContentAndSetPostButton()
          
        })
    }
    
    
    func reactOnScroll(){
        
        
        self.navigationController?.si_dissmissOnBottom(toViewController: modalNavigationController, completion:  {
            
            self.modalNavigationController.si_delegate?.navigationControllerDidClosed?(navigationController: self.modalNavigationController)
            
        })
        
    }
    
    //Function for setting the post button
    fileprivate func checkContentAndSetPostButton(){
        
        //If the postTextField's text is nil, or there is no content user is not allowed to post
        if self.postTextField.text != "" || self.contentAsset != nil {
            
            self.photoVC.enableDisablePostButton(enable: true)
            
        } else {
            
            self.photoVC.enableDisablePostButton(enable: false)
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        UIApplication.shared.statusBarStyle = .default
        
        //hide the navigationBar
        self.navigationController?.isNavigationBarHidden = true
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        UIApplication.shared.statusBarStyle = .lightContent
    
    }
    
    
}


//MARK: Functions for UIBUTTONS and observers
extension PostViewController {
 
    
    func editPostContent(){
        
        if let asset = self.contentAsset {
            if let type = asset.type, let assetid = asset.identifier {
                switch type {
                case .photo: openPhotoEditor(assetid, deleteTempOnCancel: false, animatedDismiss: true)
                case .video: openVideoEditor(assetid, deleteTempOnCancel: false, animatedDismiss: true)
                }
            }
        }
    }
    
    
    func openPhotoEditor(_ assetLocalId: String?, deleteTempOnCancel: Bool, animatedDismiss: Bool) {
        
        guard let assetIdentifier = assetLocalId  else {
            return
        }
        
        let photoEditor = PhotoEditorViewController(assetLocalId: assetIdentifier, deleteTempOnCancel: false, dismissAnimated: animatedDismiss)
        photoEditor.delegate = self
        self.present(photoEditor, animated: true, completion: nil)
    
    
    }
    
    func openVideoEditor(_ assetLocalId: String?, deleteTempOnCancel: Bool, animatedDismiss: Bool) {
        
        guard let assetIdentifier = assetLocalId  else {
            return
        }
        
        let videoEditor = VideoTrimmerViewController(assetLocalId: assetIdentifier, tempURL: nil, dismissAnimated: animatedDismiss)
        videoEditor.delegate = self
        self.present(videoEditor, animated: true, completion: nil)
        
    }
    
    
    
    func dismissKeyboard() {
        self.postTextField.resignFirstResponder()
    }
    
    func removeContentFromPost(){
        
        contentAsset = nil //set the contentAsset for nil
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: .curveEaseIn, animations: {
            
            self.postContentImageView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            self.postContentImageView.isHidden = true
            
        }) { (true) in
            
            self.postContentImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
      
        checkContentAndSetPostButton()
        setScrollViewHeight()
        
    }
    
    func deleteUserLocation(){
        
        //set userLocation to nil
        self.userLocation = nil
    }
    
    
    //dismissView
    func dismissView(){
        
        postTextField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
        
    }

    
    //KeyBoard observers
    func handleKeyboardWillShow(_ notification: Notification){
        
    
        UIView.animate(withDuration: 0.25, animations: {
            
            self.headerViewTopAnchor?.constant = 0
            self.headerContainerView.alpha = 1
            
            self.view.layoutIfNeeded()
        })
        
        
        self.navigationController?.si_dismissModalView(toViewController: modalNavigationController, completion:  {
            
            self.modalNavigationController.si_delegate?.navigationControllerDidClosed?(navigationController: self.modalNavigationController)
            
        })

    }
    
    
    func handleKeyboardWillHide(_ notification: Notification){
        
        UIView.animate(withDuration: 0.25, animations: {
            
            //set header animation based on content
            if (self.postTextField.text == "" && self.contentAsset == nil) {
                self.headerViewTopAnchor?.constant = -50
                self.headerContainerView.alpha = 0
            } else {
                self.headerViewTopAnchor?.constant = 0
                self.headerContainerView.alpha = 1
            }
            
            self.view.layoutIfNeeded()
        })
        
        self.navigationController?.si_dismissModalView(toViewController: modalNavigationController, completion:  {
            
            self.modalNavigationController.si_delegate?.navigationControllerDidClosed?(navigationController: self.modalNavigationController)
            
        })
    }
    
}






//MARK: Functions
extension PostViewController {
    
    
    //Setup the currentuser's main data's such as username, userimage
    //it could be loaded by keyChain 

    
    func checkCurrentUserAndSetupHeaderViewLabels(){
        
        //this data will be loaded from keychain!!!
        /*
        if let dictionary = Locksmith.loadDataForUserAccount("useraccount") as? [String: AnyObject] {
            
            if let name = dictionary["name"] as? String {
            
                self.currentUserName.text = name }
            
            if let username = dictionary["username"] as? String {
                
                let size: CGSize = username.size(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14.0)])
                self.currentUserSubnameWidthAnchor?.constant = size.width + 5
                self.currentUserSubname.text = username
            }
            
            if let id = dictionary["user_id"] as? String, let imageURL = dictionary["user_image"] as? String {
                
                self.currentUserId = id
                
                let url = profileImagesURL +  "/" + id + "/" + imageURL
                Nuke.loadImage(with: URL(string: url)!, into: currentUserImageView)
            }
        }
 */
        self.currentUserId = "E8JTKBOknSNpX7dcXc3lgDrClB22"
        self.currentUserName.text = "@stevejobs"
        self.currentUserSubname.text = "Steve Jobs"
        self.currentUserImageView.image = UIImage(named:"jobs")
        
    }
    

    
    
    //Load AVASSET
    func loadAVAsset(_ identifier: String?) {
        
        self.contentAsset = nil
        
      
        // if the Photo Access is not allowed it will crash while fetching images and videos
        
        if PhotoAutorizationStatusCheck() {
            
            let manager = PHImageManager()
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            
            if let identifier = identifier {
                
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: fetchOptions)
                
                guard let asset = assets.firstObject
                    else { return }
                
                
                manager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: requestOptions, resultHandler: {
                    
                    image,error  in
                    
                    if error != nil {
                        
                        self.postContentImageView.isHidden = false
                        self.postContentImageView.image = image
                        
                    } else {
                        
                        self.postContentImageView.isHidden = true
                    }
                    
                })
                
                if asset.mediaType == .image {
                    
                    //Loaded asset is: .image
                    
                    //hiding the playButton for the contentImageView
                    self.playButtonForContentImageView.isHidden = true
                    
                    self.contentAsset = CustomAVAsset(type: CustomAVAsset.MediaType(rawValue: 1), identifier: asset.localIdentifier)
                }
                
                
                if asset.mediaType == .video {
                    
                    //Loaded asset is: .video
                    
                    //showing the playButton for the contentImageView
                    playButtonForContentImageView.isHidden = false
                    
                    contentAsset = CustomAVAsset(type: CustomAVAsset.MediaType(rawValue: 0), identifier: asset.localIdentifier)
                }
            }

        } else {
            
            CameraStatusDenied().show(show: true, parentVC: self.postContentContainerView, imagename: nil, title: nil, alert: nil)
            
            
        }
        
            //set PostLibraryViewController on the bottom
            self.reactOnScroll()
        
    }

}


//MARK: - UITEXTVIEWDELEGATE

extension PostViewController: UITextViewDelegate {
    
    
    
    //Function for set the Placeholder text
    fileprivate func setFakePlaceholderVisible(){
        
        if postTextField.text == ""{
            
            postTextFieldPlaceHolder.isHidden = false
            postTextFieldPlaceHolder.text = self.welcomeString
           
        } else {
            
           postTextFieldPlaceHolder.isHidden = true
        }
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {

        //checking the new post's content or text
        checkContentAndSetPostButton()
        
        setFakePlaceholderVisible()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {

        //checking the new post's content or text
        checkContentAndSetPostButton()

        setFakePlaceholderVisible()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        //Setting the new height of the textView and the scrollview
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = textView.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        postTextFieldHeightAnchor?.constant = newFrame.height
        scrollView.contentSize.height = self.view.frame.height + newFrame.height
        
        
        //checking the new post's content or text
        checkContentAndSetPostButton()
        
        setFakePlaceholderVisible()
        

       
    
        if textView.text == "" {
            postText = nil
        } else {
            postText = textView.text
        
        }
    }
    
    //WANTED ENCHANCEMENT --> IMPLEMENT A TAGVIEW BASED ON SERVER REQUEST
    //main logic here.
    //if the user start with a " @" it opens the tagview and the tagview still open until the user is not select a tag--> maybe here it will pass the downloaded(fetched datas to this viewcontroller) and if the user want to click on space it will shake the view that tagged person is not available
    
    

}

//MARK: - UISCROLLVIEWDELEGATE

extension PostViewController: UIScrollViewDelegate {
    
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
        postTextField.resignFirstResponder()
        
        self.reactOnScroll()
        
    }
    
}

