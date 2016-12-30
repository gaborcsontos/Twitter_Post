//
//  PhotoViewController.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/23/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import UIKit
import Photos




protocol PhotoViewControllerDelegate: class {
    
    //header button delegates
    
    func openCameraView()
    func openPhotoView()
    func openLocationView()
    func handlePostButton()
    func openPhotoOrVideoEditor(_ mediaType: CustomAVAsset.MediaType?, assetIdentifier: String?)
}


class PhotoViewController: UIViewController {
    
    //delegates
    weak var delegate: PhotoViewControllerDelegate?
    weak var postViewController: PostViewController?
    
    
    //avAsset
    var avAssetIdentifiers = [String]()
    
    
    //selectedMediaType -> Fetching Camera Roll,Favoutires, Selfies or Videos
    var selectedMediaType: MediaTypes = MediaTypes.CameraRoll {
        
        didSet {
            //by selectedMediaType
            switch selectedMediaType {
            case .CameraRoll: grabPhotosAndVideos(.smartAlbumUserLibrary)
            case .Favourites: grabPhotosAndVideos(.smartAlbumFavorites)
            case .Selfies: grabPhotosAndVideos(.smartAlbumSelfPortraits)
            case .Videos: grabPhotosAndVideos(.smartAlbumVideos)
            }
        }
    }

    
    //titleView
    var titleView: UIView!
    
    
    //fullView
    var fullView: UIView!
    //navbarMenu
    var dropDownTitle: DropdownTitleView!
    var navigationBarMenu: DropDownMenu!
    //closeButton
    var closeButton: UIButton!
    
    
    //closedView
    var closedView: UIView!
    var locationButton: UIButton!
    var photoButton: UIButton!
    var cameraButton: UIButton!
    var postButton: UIButton!
    //separatorView
    var titleViewSeparator: UIView!
    
    
    //emptyDataSet Strings
    var emptyPhotos: Bool = false
    var emptyImgName: String = "ic_enable_photo"
    var emptyTitle: String = "Please enable your photo access"
    var emptyDescription: String = "In iPhone settings tap \(Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String)\n and turn on Photo access."
    var emptyBtnTitle: String = "Open settings."
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // MARK: Views .collectionView                                                                 //
    //  CollectionView is responsible to show the photos and videos in its cells.
    // After fetching AVAssets from phones memory it create an AVASset which is used to help indentified the mediaType for editing and adding to the CreatePostViewController
    //
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    lazy var collectionView: UICollectionView = {
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsetsMake(1, 0, 0, 0)
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AVAssetCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = UIColor.white
        collectionView.showsVerticalScrollIndicator = true
        
        //setup emptyDataSource
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
        collectionView.isScrollEnabled = false
        
        return collectionView
    }()

    
      
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        if let nc = self.navigationController as? FeedNavigationController {
            nc.si_delegate = self
            nc.fullScreenSwipeUp = true
            
            
            //setup the NavigationBar headers
            titleView = UIView(frame: CGRect(x: 0, y: 0, width: nc.navigationBar.frame.width, height: nc.navigationBar.frame.height))
            titleView.backgroundColor = .white
            
            setupHeaders()
            
            nc.navigationBar.addSubview(titleView)
            view.center = nc.navigationBar.center
            
        }
        
        setupCollectionView()
        
        //fast check and grabPhotos from CameraRoll(default value)
        PHPhotoLibrary.requestAuthorization() { status in
            switch status {
            case .authorized: self.grabPhotosAndVideos(.smartAlbumUserLibrary)
            default:
                //set the PhotoViewController's view on the bottom of the Screen if the PhotoAccess check failed
                DispatchQueue.main.async {
                    
                    if let parentVC = self.navigationController?.parent?.childViewControllers.first as? PostViewController {
                        parentVC.reactOnScroll()
                        
                        self.collectionView.reloadEmptyDataSet()
                    }
                }
            }
        }
        
        //setupDropDownMenuTitle -> Last view, because of the collectionView
        setupDropDownMenuTitle()
    
    }
    
    fileprivate func setupButtons(_ withImage: String, selector: Selector) -> UIButton {
        
        let button = UIButton(type: .system)
        let imageView = UIImageView()
        imageView.image = UIImage(named: withImage)!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.lightGray
        button.setImage(imageView.image, for: .normal)
        button.tintColor = UIColor.lightGray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: selector, for: .touchUpInside)
        
        return button
    }
    
    func setupHeaders() {
        
        setupClosedHeader()
        setupFullHeader()
    }
    
    func setupClosedHeader(){
        
        locationButton = setupButtons("ic_location", selector: #selector(handleLocationBtn))
        photoButton = setupButtons("ic_photos", selector: #selector(handlePhotoBtn))
        cameraButton = setupButtons("ic_photo_camera", selector: #selector(handleCameraBtn))
        
        postButton = UIButton(type: .system)
        postButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        postButton.setTitle("POST", for: UIControlState())
        postButton.setTitle("POST", for: .disabled)
        postButton.setTitleColor(.white, for: UIControlState())
        postButton.setTitleColor(UIColor.lightGray, for: .disabled)
        postButton.isEnabled = false
        postButton.layer.cornerRadius = 4
        postButton.layer.borderWidth = 1
        postButton.translatesAutoresizingMaskIntoConstraints = false
        postButton.addTarget(self, action: #selector(handlePostBtn), for: .touchUpInside)
        
        
        //closedView x,y,w,h
        closedView = UIView()
        closedView.translatesAutoresizingMaskIntoConstraints = false
        if !closedView.isDescendant(of: titleView) { titleView.addSubview(closedView) }
        closedView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
        closedView.widthAnchor.constraint(equalTo:  titleView.widthAnchor).isActive = true
        closedView.heightAnchor.constraint(equalTo: titleView.heightAnchor).isActive = true
        closedView.backgroundColor = .white
        
        //location btn x,y,w,h
        if !locationButton.isDescendant(of: closedView) { closedView.addSubview(locationButton) }
        locationButton.leftAnchor.constraint(equalTo: closedView.leftAnchor,constant: 12).isActive = true
        locationButton.centerYAnchor.constraint(equalTo: closedView.centerYAnchor).isActive = true
        locationButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        locationButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //photo btn x,y,w,h
        if !photoButton.isDescendant(of: closedView) { closedView.addSubview(photoButton) }
        photoButton.leftAnchor.constraint(equalTo: locationButton.rightAnchor,constant: 22).isActive = true
        photoButton.centerYAnchor.constraint(equalTo: closedView.centerYAnchor).isActive = true
        photoButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        photoButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //camera btn x,y,w.h
        if !cameraButton.isDescendant(of: closedView) { closedView.addSubview(cameraButton) }
        cameraButton.leftAnchor.constraint(equalTo: photoButton.rightAnchor,constant: 22).isActive = true
        cameraButton.centerYAnchor.constraint(equalTo: closedView.centerYAnchor).isActive = true
        cameraButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        cameraButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //post btn x,y,w,h
        if !postButton.isDescendant(of: closedView) { closedView.addSubview(postButton) }
        postButton.leftAnchor.constraint(equalTo: closedView.rightAnchor,constant: -72).isActive = true
        postButton.centerYAnchor.constraint(equalTo: closedView.centerYAnchor).isActive = true
        postButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        postButton.heightAnchor.constraint(equalToConstant: 26).isActive = true
        enableDisablePostButton(enable: false)
        
        
        //titleViewSeparator x,y,w,h
        titleViewSeparator = UIView()
        titleViewSeparator.translatesAutoresizingMaskIntoConstraints = false
        closedView.addSubview(titleViewSeparator)
        titleViewSeparator.leftAnchor.constraint(equalTo: closedView.leftAnchor).isActive = true
        titleViewSeparator.centerXAnchor.constraint(equalTo: closedView.centerXAnchor).isActive = true
        titleViewSeparator.widthAnchor.constraint(equalTo: closedView.widthAnchor).isActive = true
        titleViewSeparator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        titleViewSeparator.topAnchor.constraint(equalTo: closedView.topAnchor).isActive = true
        titleViewSeparator.backgroundColor = UIColor(white: 0.7, alpha: 0.8)


    }
    
    func setupFullHeader(){
        //fullView x,y,w,h
        fullView = UIView()
        fullView.translatesAutoresizingMaskIntoConstraints = false
        if !fullView.isDescendant(of: titleView) { titleView.addSubview(fullView) }
        fullView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
        fullView.widthAnchor.constraint(equalTo:  titleView.widthAnchor).isActive = true
        fullView.heightAnchor.constraint(equalTo: titleView.heightAnchor).isActive = true
        fullView.backgroundColor = .white
        fullView.alpha = 0
        
        //closeHeaderView Dismiss btn x,y,w,h
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: titleView.frame.height))
        closeButton.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        fullView.addSubview(closeButton)
        
        //closeHeaderView Title x,y,w,h
        //dropDownTitle x,y,w,h
        dropDownTitle = DropdownTitleView()
        dropDownTitle.titleLabel.textAlignment = .center
        dropDownTitle.addTarget(self,action: #selector(self.willToggleNavigationBarMenu),for: .touchUpInside)
        dropDownTitle.title = MediaTypes.CameraRoll.rawValue //default title
        dropDownTitle.translatesAutoresizingMaskIntoConstraints = false
        if !dropDownTitle.isDescendant(of: fullView) { fullView.addSubview(dropDownTitle) }
        dropDownTitle.centerXAnchor.constraint(equalTo: fullView.centerXAnchor).isActive = true
        dropDownTitle.centerYAnchor.constraint(equalTo: fullView.centerYAnchor).isActive = true
        dropDownTitle.widthAnchor.constraint(equalToConstant: 120).isActive = true
        dropDownTitle.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
    }

    
    func setupDropDownMenuTitle(){
        //DropDownMenuBar setup
        prepareNavigationBarMenu(MediaTypes.CameraRoll.rawValue)
        updateMenuContentOffsets()
        navigationBarMenu.container = view
       
    }
    
    func setupCollectionView() {
        //collectionView x,y,w,h
        if !collectionView.isDescendant(of: self.view) { self.view.addSubview(collectionView) }
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.self.collectionView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.collectionView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.collectionView.isScrollEnabled = false
    }
    
    
    //fetch photos or videos by PHAssetCollectionSubtype , setted by DropDownTitleView
    func grabPhotosAndVideos(_ subType: PHAssetCollectionSubtype){
        
        
        self.avAssetIdentifiers.removeAll()
        
        let fetchOptions = PHFetchOptions()
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subType, options: fetchOptions)
        
        fetchResult.enumerateObjects({ (collection, start, stop) in
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            assets.enumerateObjects({ (object, count, stop) in
                
        
                self.avAssetIdentifiers.append(object.localIdentifier)
                
                DispatchQueue.main.async {
                    //reload collectionView
                    self.collectionView.reloadData()
                    
                    if self.avAssetIdentifiers.count == 0 {
                        //if avAsset count is nil -> There is no Photos to load
                    
                        
                        //change emptyView for making selfies
                        self.emptyPhotos = true
                        self.emptyImgName = "ic_selfie_dribbble"
                        self.emptyTitle = "You don't have any photos"
                        self.emptyDescription = "Let's give a try, and make some selfies about you."
                        self.emptyBtnTitle = "Open camera."
                        
                        //Here you can make more specific messages based on PHAssetCollectionSubtype
                        switch subType {
                        case .smartAlbumVideos:
                            self.emptyImgName = "ic_selfie_dribbble"
                            self.emptyTitle = "You don't have any videos"
                            self.emptyDescription = "Capture some moments to share."
                        case .smartAlbumFavorites:
                            self.emptyImgName = "ic_selfie_dribbble"
                            self.emptyTitle = "No favoutires:("
                            self.emptyDescription = "In Photos you can easily make your fav album."
                        case .smartAlbumSelfPortraits:
                           break //etc
                        case .smartAlbumUserLibrary:
                            break //etc
                        default: break
                        }

                        
                        self.collectionView.reloadEmptyDataSet()
                        
                        //set the view on the bottom
                    }
                }
            })
            
            if self.avAssetIdentifiers.count == 0 {
                
                DispatchQueue.main.async {
                    
                    if let parentVC = self.navigationController?.parent?.childViewControllers.first as? PostViewController {
                        parentVC.reactOnScroll()
                    }
                }
            }
        })
        
    }
    
    

    //Color indicator if the location is setted or not
    func locationIsSetted(bool: Bool) {
        
        if bool {
            self.locationButton.tintColor = self.view.tintColor
        } else {
            self.locationButton.tintColor = UIColor.lightGray
        }
    }
    
    func closeView(){
        
        //set the dropDownTitle to false to avoid UI crash
        if self.dropDownTitle.isUp {
            self.dropDownTitle.toggleMenu()
            self.navigationBarMenu.hide(withAnimation: false)
        }

        //set scrollView to default
        self.collectionView.isScrollEnabled = false
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
      
        
        DispatchQueue.main.async {
            self.parent?.navigationController?.si_dismissModalView(toViewController: self.parent!, completion: {
                
                if let nc = self.navigationController as? FeedNavigationController {
                    nc.si_delegate?.navigationControllerDidClosed?(navigationController: nc)
                    
                }
            })

        }
        
    }
}






extension PhotoViewController: FeedNavigationControllerDelegate {
    
    // MARK: - FeedNavigationControllerDelegate
    func navigationControllerDidSpreadToEntire(navigationController: UINavigationController) {
        print("spread to the entire")
        
        //set scrollView's scrolling
        self.collectionView.isScrollEnabled = true
      
        
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {
                        
              self.fullView.alpha = 1
                        
        }, completion: nil)
        
    }
    
    func navigationControllerDidClosed(navigationController: UINavigationController) {
        print("decreased on the view")
        
        
        //set the dropDownTitle to false to avoid UI crash
        if self.dropDownTitle.isUp {
            self.dropDownTitle.toggleMenu()
            self.navigationBarMenu.hide(withAnimation: false)
        }
        
        //set scrollView to default
        self.collectionView.isScrollEnabled = false
        self.collectionView.setContentOffset(self.collectionView.contentOffset, animated: false)
      
        
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {
                        
                        self.fullView.alpha = 0
                        
        }, completion: nil)
    }

}





//MARK:  - UIBUTTON FUNCTIONS

extension PhotoViewController {
    
    func handleLocationBtn(_ sender: UIButton){
        
        delegate?.openLocationView()
        
    }
    
    func handlePhotoBtn(_ sender: UIButton){
        
        delegate?.openPhotoView()
        
    }
    
    func handleCameraBtn(_ sender: UIButton){
        
        delegate?.openCameraView()
        
    }
    
    func handlePostBtn(_ sender: UIButton){
        
        delegate?.handlePostButton()
        
    }
    
    
    //setting the PostButton color if post contains text or content
    func enableDisablePostButton(enable: Bool){
        
        if enable {
            postButton.isEnabled = true
            postButton.layer.borderColor = self.view.tintColor.cgColor
            postButton.backgroundColor = self.view.tintColor
            
        } else {
            postButton.isEnabled = false
            postButton.layer.borderColor = UIColor.lightGray.cgColor
            postButton.backgroundColor = .clear
        }
    }
}


extension PhotoViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return avAssetIdentifiers.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AVAssetCollectionViewCell
        
        cell.assetID = self.avAssetIdentifiers[indexPath.row]
        cell.tag = (indexPath as NSIndexPath).row
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! AVAssetCollectionViewCell
        // recognize the assetType and send the localidentifier to open the VideoTrimmer of PhotoEditor
        delegate?.openPhotoOrVideoEditor(cell.asset?.type, assetIdentifier: cell.asset?.identifier)
        
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.frame.width / 3 - 1
        return CGSize(width: width, height: width)
        
    }
}


extension PhotoViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: emptyImgName)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18),
            NSForegroundColorAttributeName: UIColor.darkGray
        ]
        
        return NSAttributedString(string: emptyTitle, attributes: attribs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = NSLineBreakMode.byWordWrapping
        para.alignment = NSTextAlignment.center
        
        let attribs = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 14),
            NSForegroundColorAttributeName: UIColor.lightGray,
            NSParagraphStyleAttributeName: para
        ]
        
        return NSAttributedString(string: emptyDescription, attributes: attribs)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        
        let attribs = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
            NSForegroundColorAttributeName: view.tintColor
        ]
        
        return NSAttributedString(string: emptyBtnTitle, attributes: attribs)
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        
        if !emptyPhotos {
            getAccessForSettings()
        } else {
            //shot some new pics
            openCameraView()
        }
    }

    func openCameraView(){
        self.delegate?.openCameraView()
    }
    
    func getAccessForSettings(){
        //Open App's settings
      openApplicationSettings()
    }
}
