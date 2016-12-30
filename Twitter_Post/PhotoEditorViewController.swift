//
//  PhotoEditorViewController.swift
//  Loutude
//
//  Created by Gabor Csontos on 8/26/16.
//  Copyright © 2016 Loutude. All rights reserved.
//

import UIKit
import Photos


@objc public protocol PhotoEditorDelegate {
    
    @objc optional func handleConfirmPhotoButton(_ assetIdentifier: String?)
}


class PhotoEditorViewController: UIViewController {
    

    //delegate to PhotoEditorDelegate
    open weak var delegate: PhotoEditorDelegate?
    
    let imageView = UIImageView()
    var scrollView = UIScrollView()
    var cropOverlay = CropOverlay()
    var cancelButton: UIButton!
    var confirmButton: UIButton!
    var centeringView = UIView()
    
    var allowsCropping: Bool = true
    
    var assetLocalId: String!
    
    
    //filteredImageArray for the colletionView
    var filteredImageArray = [(UIImage,String, CIFilter)]()
    //apply selectedFilter when saving the cropped Photo
    var selectedFilter: CIFilter?
    
    //deleting the original image on cancel
    var deleteTemp: Bool = false

    var dismissAnimated: Bool = true
    
    //collectionView
    lazy var collectionView: UICollectionView = {
        //layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        //collectionView
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset.top = 1
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor(red: 16/255, green: 16/255, blue: 16/255, alpha: 0.4)
        collectionView.register(PhotoEditorCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        return collectionView
    }()

    
    
    
    public init(assetLocalId: String, deleteTempOnCancel: Bool, dismissAnimated: Bool) {
        self.assetLocalId = assetLocalId
        self.dismissAnimated = dismissAnimated
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        setupViews()
        
        scrollView.addSubview(imageView)
        scrollView.delegate = self
        scrollView.maximumZoomScale = 1
        
        cropOverlay.isHidden = true
        
        let spinner = showSpinner()
        
        disable()
        
        _ = SingleImageFetcher()
            .setTargetSize(largestPhotoSize())
            .onSuccess { image, url in
        
                self.configureWithImage(image)
                self.hideSpinner(spinner)
                self.enable()
            }
            .onFailure { error in
                self.hideSpinner(spinner)
            }
            .fetch(assetLocalId)

    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let scale = calculateMinimumScale(view.frame.size)
        let frame = allowsCropping ? cropOverlay.frame : view.bounds
        
        scrollView.contentInset = calculateScrollViewInsets(frame)
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
        centerScrollViewContents()
        centerImageViewOnRotate()
    }
    
    internal func confirmPhoto() {
        
        disable()
        
        imageView.isHidden = true
        
        let spinner = showSpinner()
        
        var fetcher = SingleImageFetcher()
            .onSuccess { image, url in
                //fetched Image is in the right crop
                self.saveImage(image)
                //self.onComplete?(image, self.asset)
               self.hideSpinner(spinner)
            }
            .onFailure { error in
                self.hideSpinner(spinner)
                self.showNoImageScreen(error)
            }
        
        if allowsCropping {
            
            var cropRect = cropOverlay.frame
            cropRect.origin.x += scrollView.contentOffset.x
            cropRect.origin.y += scrollView.contentOffset.y
            
            let normalizedX = cropRect.origin.x / imageView.frame.width
            let normalizedY = cropRect.origin.y / imageView.frame.height
            
            let normalizedWidth = cropRect.width / imageView.frame.width
            let normalizedHeight = cropRect.height / imageView.frame.height
            
            let rect = normalizedRect(CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight), orientation: imageView.image!.imageOrientation)
            
            
            fetcher = fetcher.setCropRect(rect)
            
        }
        
       fetcher = fetcher.fetch(self.assetLocalId)
       
    }
    
    
    func saveImage(_ image: UIImage) {
        
        let spinner = showSpinner()
        
        var saver = ImageSaver()
            
            .onSuccess { image, assetId in
                
                self.hideSpinner(spinner)
                self.enable()
                
                self.dismiss(animated: true, completion: {
                    
                     self.delegate?.handleConfirmPhotoButton?(assetId)
                })
                
            }
            .onFailure { error in
                self.hideSpinner(spinner)
                self.showNoImageScreen(error)
        }
        
      
        saver = saver.save(image, filter: selectedFilter)
        
    }
    

    internal func cancel() {
        
        DispatchQueue.main.async {  self.dismiss(animated: self.dismissAnimated, completion: nil)   }

    }
    

    
    
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    
    func showSpinner() -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView()
        spinner.activityIndicatorViewStyle = .white
        spinner.center = view.center
        spinner.startAnimating()
        
        view.addSubview(spinner)
        view.bringSubview(toFront: spinner)
        
        return spinner
    }
    
    func hideSpinner(_ spinner: UIActivityIndicatorView) {
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }
    
    func disable() {
        confirmButton.isEnabled = false
    }
    
    func enable() {
        confirmButton.isEnabled = true
    }
    
    func showNoImageScreen(_ error: NSError) {
        
//        let permissionsView = PermissionsView(frame: view.bounds)
//        
//        let desc = localizedString("error.cant-fetch-photo.description")
//        
//        permissionsView.configureInView(view, title: error.localizedDescription, descriptiom: desc, completion: cancel)
    }

    
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let scale = calculateMinimumScale(size)
        var frame = view.bounds
        
        if allowsCropping {
            frame = cropOverlay.frame
            let centeringFrame = centeringView.frame
            var origin: CGPoint
            
            if size.width > size.height { // landscape
                let offset = (size.width - centeringFrame.height)
                let expectedX = (centeringFrame.height/2 - frame.height/2) + offset
                origin = CGPoint(x: expectedX, y: frame.origin.x)
            } else {
                let expectedY = (centeringFrame.width/2 - frame.width/2)
                origin = CGPoint(x: frame.origin.y, y: expectedY)
            }
            
            frame.origin = origin
        } else {
            frame.size = size
        }
        
        coordinator.animate(alongsideTransition: { context in
            self.scrollView.contentInset = self.calculateScrollViewInsets(frame)
            self.scrollView.minimumZoomScale = scale
            self.scrollView.zoomScale = scale
            self.centerScrollViewContents()
            self.centerImageViewOnRotate()
        }, completion: nil)
    }
    
    private func configureWithImage(_ image: UIImage) {
        if allowsCropping {
            cropOverlay.isHidden = false
        } else {
            cropOverlay.isHidden = true
        }
        
        
        setupCollectionView(image)
        imageView.image = image
        imageView.sizeToFit()
        view.setNeedsLayout()
    }
    
    private func calculateMinimumScale(_ size: CGSize) -> CGFloat {
        var _size = size
        
        if allowsCropping {
            _size = cropOverlay.frame.size
        }
        
        guard let image = imageView.image else {
            return 1
        }
        
        let scaleWidth = _size.width / image.size.width
        let scaleHeight = _size.height / image.size.height
        
        var scale: CGFloat
        
        if allowsCropping {
            scale = max(scaleWidth, scaleHeight)
        } else {
            scale = min(scaleWidth, scaleHeight)
        }
        
        return scale
    }
    
    private func calculateScrollViewInsets(_ frame: CGRect) -> UIEdgeInsets {
        let bottom = view.frame.height - (frame.origin.y + frame.height)
        let right = view.frame.width - (frame.origin.x + frame.width)
        let insets = UIEdgeInsets(top: frame.origin.y, left: frame.origin.x, bottom: bottom, right: right)
        return insets
    }
    
    private func centerImageViewOnRotate() {
        if allowsCropping {
            let size = allowsCropping ? cropOverlay.frame.size : scrollView.frame.size
            let scrollInsets = scrollView.contentInset
            let imageSize = imageView.frame.size
            var contentOffset = CGPoint(x: -scrollInsets.left, y: -scrollInsets.top)
            contentOffset.x -= (size.width - imageSize.width) / 2
            contentOffset.y -= (size.height - imageSize.height) / 2
            scrollView.contentOffset = contentOffset
        }
    }
    
    private func centerScrollViewContents() {
        let size = allowsCropping ? cropOverlay.frame.size : scrollView.frame.size
        let imageSize = imageView.frame.size
        var imageOrigin = CGPoint.zero
        
        if imageSize.width < size.width {
            imageOrigin.x = (size.width - imageSize.width) / 2
        }
        
        if imageSize.height < size.height {
            imageOrigin.y = (size.height - imageSize.height) / 2
        }
        
        imageView.frame.origin = imageOrigin
    }

    
    

    
    func setupCollectionView(_ image: UIImage) {
        
        //CollectionView x,y,w,h
        if !collectionView.isDescendant(of: self.view) { self.view.addSubview(collectionView) }
        collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        collectionView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalTo: self.view.heightAnchor,multiplier: 0.2).isActive = true
        
        //Create FilteredImagesArray
        filteredImageArray.removeAll()
         
        filteredImageArray = FilteredImageBuilder(image: image).imagesWithDefaultFilters()
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    
    }


    
    func setupViews() {
    
        
        //scrollView x,y,w,h
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        if !scrollView.isDescendant(of: self.view){ self.view.addSubview(scrollView)}
        scrollView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        scrollView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
       
    
        //cropOverlay x,y,w,h
        cropOverlay.translatesAutoresizingMaskIntoConstraints = false
        if !cropOverlay.isDescendant(of: self.view){ self.view.addSubview(cropOverlay)}
        cropOverlay.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        cropOverlay.heightAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        cropOverlay.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        cropOverlay.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        setupButtons()
    }

    func setupButtons() {
        
        //cancelButton
        cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelButton.contentHorizontalAlignment = .left
        
        //confirmButton
        confirmButton = UIButton()
        confirmButton.setTitle("Done", for: .normal)
        confirmButton.setTitleColor(UIColor.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        confirmButton.contentHorizontalAlignment = .right
        
        confirmButton.action = { [weak self] in self?.confirmPhoto() }
        cancelButton.action = { [weak self] in self?.cancel() }
        
        //confirmButton x,y,w,h
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        if !confirmButton.isDescendant(of: self.view) { self.view.addSubview(confirmButton) }
        confirmButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10).isActive = true
        confirmButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 12).isActive = true
        confirmButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        confirmButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        //dismissButton x,y,w,h
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        if !cancelButton.isDescendant(of: self.view) { self.view.addSubview(cancelButton) }
        cancelButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10).isActive = true
        cancelButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 12).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    

   
    

}
    
    
extension PhotoEditorViewController: UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PhotoEditorCollectionViewCell
        cell.filteredPhoto.image = self.filteredImageArray[indexPath.row].0
        cell.filterLabel.text = self.filteredImageArray[indexPath.row].1
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredImageArray.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoEditorCollectionViewCell
        imageView.image = cell.filteredPhoto.image
        selectedFilter = self.filteredImageArray[indexPath.row].2
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height = collectionView.bounds.height - 1
        let width = height * 0.8
        return CGSize(width: width, height: height)
    }
}

