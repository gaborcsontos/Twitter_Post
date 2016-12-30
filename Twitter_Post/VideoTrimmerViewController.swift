//
//  GMVideoTrimmer.swift
//  Photo
//
//  Created by Gabor Csontos on 8/30/16.
//  Copyright © 2016 GabeMajorszki. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import AssetsLibrary
import MobileCoreServices


@objc public protocol VideoTrimmerDelegate {
    
    @objc optional func handleVideoConfirmButton(_ assetIdentifier: String?)
    
}


extension VideoTrimmerViewController: ICGVideoTrimmerDelegate {
    
    func trimmerView(_ trimmerView: ICGVideoTrimmerView, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        if startTime != self.startTime {
            //then it moved the left position, we should rearrange the bar
            self.seekVideoToPos(startTime)
        }
        self.startTime = startTime
        self.stopTime = endTime
    }

}



class VideoTrimmerViewController: UIViewController {
 
    var isPlaying = false
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var videoPlaybackPosition: CGFloat!
    
    var playbackTimeCheckerTimer: Timer!
    
    var trimmerView: ICGVideoTrimmerView!
    var videoPlayer = UIView()
    var videoLayer = UIView()
    
    var exportSession: AVAssetExportSession!
    var asset: AVAsset!

    var startTime: CGFloat!
    var stopTime: CGFloat!

    var dismissAnimated: Bool = true
    
    var assetLocalId: String?
    var tempURL: URL?
    
    var error: NSError?
    
    weak var delegate: VideoTrimmerDelegate?
    
    
    var playButton = UIImageView()
    var confirmButton: UIButton!
    var cancelButton: UIButton!
    
    
    
    public init(assetLocalId: String?, tempURL: URL?, dismissAnimated: Bool) {
        self.assetLocalId = assetLocalId
        self.tempURL = tempURL
        self.dismissAnimated = dismissAnimated
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
    func loadAVAsset(_ identifier: String?){
        
        guard let localidentifier = identifier else {
            return
        }
        
        
        var fetcher = VideoFetcher()
            .onSuccess { url in
                //loading asset
                DispatchQueue.main.async {
                      self.loadVideo(url)
                }
              
                
            }
            .onFailure { error in
                self.error = error
                showAlertViewWithTitleAndText("Ups", message: error.localizedDescription, vc: self)
        }
        
        fetcher = fetcher.fetch(localidentifier)
      
    }
    


    
    func loadVideo(_ url: URL?) {
        
        self.videoLayer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        
        guard let url = url else {
            return
        }
        
        self.asset = AVAsset(url: url)
        self.createTrimmerView(self.asset)
      
        
        let item = AVPlayerItem(asset: self.asset)
        self.player = AVPlayer(playerItem: item)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer.frame = self.videoLayer.frame
     
        
        self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspectFill
        self.player!.actionAtItemEnd = .none
        
        self.videoLayer.layer.addSublayer(self.playerLayer!)
        
        self.videoPlaybackPosition = 0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapOnVideoLayer))
        self.view.addGestureRecognizer(tap)
        self.tapOnVideoLayer(tap)
        
        
        DispatchQueue.main.async {
            
            // set properties for trimmer view
            self.trimmerView.themeColor = .white
            self.trimmerView.asset = self.asset
            self.trimmerView.showsRulerView = true
            self.trimmerView.trackerColor = .white
            self.trimmerView.delegate = self
            
            // important: reset subviews
            self.trimmerView.resetSubviews()
            
        }
    }

    func tapOnVideoLayer(_ tap: UITapGestureRecognizer) {
        
        if self.isPlaying == false {
            
            self.player.play()
            showHidePlayButton(show: false)
            self.startPlaybackTimeChecker()
            
        } else {
            
            self.player.pause()
            showHidePlayButton(show: true)
            self.stopPlaybackTimeChecker()
        }
       
        self.isPlaying = !self.isPlaying
        self.trimmerView.hideTracker(!self.isPlaying)
    }

    func startPlaybackTimeChecker() {
        
        self.stopPlaybackTimeChecker()
        
        self.playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(onPlaybackTimeCheckerTimer), userInfo: nil, repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        
        if (self.playbackTimeCheckerTimer != nil) {
            self.playbackTimeCheckerTimer.invalidate()
            self.playbackTimeCheckerTimer = nil
        }
    }
    
    // MARK: - PlaybackTimeCheckerTimer
    func onPlaybackTimeCheckerTimer() {
        
        self.videoPlaybackPosition = CGFloat(CMTimeGetSeconds(self.player.currentTime()))
        self.trimmerView.seek(toTime: CGFloat(CMTimeGetSeconds(self.player.currentTime())))
        
        if self.videoPlaybackPosition >= self.stopTime {
            
            self.videoPlaybackPosition = self.startTime
            self.seekVideoToPos(self.startTime)
            self.trimmerView.seek(toTime: self.startTime)
        }
    }
    
    func seekVideoToPos(_ pos: CGFloat) {
        
        self.videoPlaybackPosition = pos
        let time = CMTimeMakeWithSeconds(Double(self.videoPlaybackPosition), self.player.currentTime().timescale)
        self.player.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        setupView()
        
        //load by assetId
        if let asset = assetLocalId {
             loadAVAsset(asset)
        }
        
        //load by tempurl -> cameraView or slowMotionVideo
        if let tempurl = tempURL {
            loadVideo(tempurl)
        }
       
    }
    
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    
    
    func setupView() {
        
        
        //videoPlayer x,y,w,h
        if !videoPlayer.isDescendant(of: self.view) { self.view.addSubview(videoPlayer) }
        videoLayer.frame = self.view.frame
        videoPlayer.backgroundColor = UIColor.black
        
        //videoLayer x,y,w,h
        if !videoLayer.isDescendant(of: self.videoPlayer) { self.videoPlayer.addSubview(videoLayer) }
        videoLayer.frame = self.view.frame
        videoPlayer.backgroundColor = UIColor.clear
        
        //playButton x,y,w,h
        if !playButton.isDescendant(of: self.view) { self.view.addSubview(playButton) }
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        playButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playButton.contentMode = .scaleAspectFill
        playButton.image = UIImage(named: "ic_swipe_play")
        playButton.isHidden = true
        

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
        
        confirmButton.action = { [weak self] in self?.confirmVideo() }
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
    
    
    
    func confirmVideo(){
        
        //if no changes ->
      //  if CGFloat(self.asset.duration) == self.startTime && startTime == 0 {}
        
        var save = SaveVideo()
            
            .onSuccess { assetId in
                
                DispatchQueue.main.async {
                    
                    self.delegate?.handleVideoConfirmButton?(assetId)
                    self.cancel()

                }
            }
            
            .onFailure { error in
                
                self.error = error
                showAlertViewWithTitleAndText("Ups", message: error.localizedDescription, vc: self)
        }
        
        save = save.save(self.asset, startTime: startTime, stopTime: stopTime)

    }
    

    
    func cancel() {
        
        self.dismiss(animated: self.dismissAnimated, completion: {
         
            if self.error == nil {  self.player.pause() ; self.trimmerView.resetSubviews()  }
            
        })
       
    }
    
    
    func createTrimmerView(_ asset: AVAsset!){
        
        trimmerView = ICGVideoTrimmerView(frame: CGRect(x: 0, y: self.view.frame.height - 100, width: self.view.frame.width, height: 100), asset: asset)
        if !trimmerView.isDescendant(of: self.view) { self.view.addSubview(trimmerView) }
        
    }
    
    
    func showHidePlayButton(show: Bool){
        
        if show == false {
            
            UIView.animate(withDuration: 0.2, animations: { 
                self.playButton.isHidden = true
            })
            
        } else {
            
            UIView.animate(withDuration: 0.2, animations: { 
                self.playButton.isHidden = false
            })
        }
    }
    

}
