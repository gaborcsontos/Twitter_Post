import UIKit

import AVFoundation
import CoreMedia
import Photos


public protocol VideoPreviewLayerProvider: class {
  /**
   The `AVCaptureVideoPreviewLayer` that will be hooked up to the `captureSession`.
   */
  var previewLayer: AVCaptureVideoPreviewLayer { get }
}

public extension VideoPreviewLayerProvider {
  var captureManager: CaptureManager {
    return CaptureManager.sharedManager
  }
}

public protocol VideoDataOutputDelegate: class {
  /**
   Called when the `CaptureManager` outputs a `CMSampleBuffer`.
   - Important: This is **NOT** called on the main thread, but instead on `CaptureManager.kFramesQueue`.
   */
  func captureManagerDidOutput(_ sampleBuffer: CMSampleBuffer)
}

/// Input types for the `AVCaptureSession` of a `CaptureManager`
public enum CaptureSessionInput {
  case video
  case audio
  
  var mediaType: String {
    switch self {
    case .video:
      return AVMediaTypeVideo
    case .audio:
      return AVMediaTypeAudio
    }
  }
}

/// Output types for the `AVCaptureSession` of a `CaptureManager`
public enum CaptureSessionOutput {
  case stillImage
  case videoData
  case movieFile
}

/// Error types for `CaptureManager`
public enum CaptureManagerError: Error {
  case invalidSessionPreset
  case invalidMediaType
  case invalidCaptureInput
  case invalidCaptureOutput
  case sessionNotSetUp
  case missingOutputConnection
  case missingVideoDevice
  case missingMovieOutput
  case missingPreviewLayerProvider
  case cameraToggleFailed
  case focusNotSupported
  case exposureNotSupported
  case flashNotAvailable
  case flashModeNotSupported
  case torchNotAvailable
  case torchModeNotSupported
}

/// Error types for `CaptureManager` related to `AVCaptureStillImageOutput`
public enum StillImageError: Error {
  case noData
  case noImage
}

open class CaptureManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
  
  public static let sharedManager = CaptureManager()
  
  public typealias ErrorCompletionHandler = (Error) -> Void
  public typealias ImageCompletionHandler = (UIImage) -> Void
  public typealias ImageErrorCompletionHandler = (String?, Error?) -> Void
  public typealias VideoErrorCompletionHandler = (URL?, Error?) -> Void
    
    
    
  fileprivate static let kFramesQueue = "com.ZenunSoftware.GNCam.FramesQueue"
  fileprivate static let kSessionQueue = "com.ZenunSoftware.GNCam.SessionQueue"
  
  public let framesQueue: DispatchQueue
  public let sessionQueue: DispatchQueue
  
  fileprivate let captureSession: AVCaptureSession
  public fileprivate(set) var didSetUp = false
  
  public var isRunning: Bool {
    return captureSession.isRunning
  }
  
  public var captureSessionPreset: String? {
    return captureSession.sessionPreset
  }
  
  fileprivate var audioDevice: AVCaptureDevice?
  fileprivate var videoDevice: AVCaptureDevice?
  public fileprivate(set) var videoDevicePosition = AVCaptureDevicePosition.back
  
  fileprivate var videoInput: AVCaptureDeviceInput?
  fileprivate var audioInput: AVCaptureDeviceInput?
  
  fileprivate var stillImageOutput: AVCaptureStillImageOutput?
  fileprivate var videoDataOutput: AVCaptureVideoDataOutput?
  fileprivate var movieFileOutput: AVCaptureMovieFileOutput?

  private var videoCompletion: VideoErrorCompletionHandler?
    
    
  public weak var dataOutputDelegate: VideoDataOutputDelegate?
  fileprivate(set) weak var previewLayerProvider: VideoPreviewLayerProvider?
  
    
  /// The `AVCaptureVideoOrientation` that corresponds to the current device's orientation.
  public var desiredVideoOrientation: AVCaptureVideoOrientation {
    switch UIDevice.current.orientation {
    case .portrait, .portraitUpsideDown, .faceUp, .faceDown, .unknown:
      return .portrait
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    }
  }
  
    
    /// tempFilePath
    fileprivate var tempFilePath: URL = {
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempMovie").appendingPathExtension("mp4").absoluteString
        if FileManager.default.fileExists(atPath: tempPath) {
            do {
                try FileManager.default.removeItem(atPath: tempPath)
            } catch { }
        }
        return URL(string: tempPath)!
    }()

    
  /// The `AVCaptureFlashMode` of `videoDevice`
  public var flashMode: AVCaptureFlashMode {
    return videoDevice?.flashMode ?? .off
  }
  
  /// The `AVCaptureTorchMode` of `videoDevice`
  public var torchMode: AVCaptureTorchMode {
    return videoDevice?.torchMode ?? .off
  }
  
  /** Returns the `AVAuthorizationStatus` for the `mediaType` of `input`.
   
   - parameter input: The `CaptureSessionInput` to inspect the status of.
  */
  public func authorizationStatus(forInput input: CaptureSessionInput) -> AVAuthorizationStatus {
    let mediaType = input.mediaType
    return AVCaptureDevice.authorizationStatus(forMediaType: mediaType)
  }
  
  /// Determines whether or not images taken with front camera are mirrored. Default is `true`.
  public var mirrorsFrontCamera = true
  
  //MARK: Init
  
  override init() {
    framesQueue = DispatchQueue(label: CaptureManager.kFramesQueue)
    sessionQueue = DispatchQueue(label: CaptureManager.kSessionQueue)
    captureSession = AVCaptureSession()
    
    AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (alowedAccess) -> Void in
        })

    super.init()
  }
  

  //MARK: Set Up
  
  /**
   Set up the AVCaptureSession.
   
   - Important: Recreates inputs/outputs based on `sessionPreset`.
   
   - parameter sessionPreset: The `sessionPreset` for the `AVCaptureSession`.
   - parameter inputs: A mask of options of type `CaptureSessionInputs` indicating what inputs to add to the `AVCaptureSession`.
   - parameter outputs: A mask of options of type `CaptureSessionOutputs` indicating what outputs to add to the `AVCaptureSession`.
   - parameter errorHandler: A closure of type `(Error) -> Void`. Called on the **main thread** if anything performed inside of `sessionQueue` thread throws an error.
   
   - Throws: `CaptureManagerError.invalidSessionPreset` if `sessionPreset` is not valid.
   */
  public func setUp(sessionPreset: String,
                  previewLayerProvider: VideoPreviewLayerProvider?,
                  inputs: [CaptureSessionInput],
                  outputs: [CaptureSessionOutput],
                  errorHandler: @escaping ErrorCompletionHandler)
  {
    func setUpCaptureSession() throws {
      captureSession.beginConfiguration()
      
      try self.setSessionPreset(sessionPreset)
      self.videoDevice = try self.desiredDevice(withMediaType: AVMediaTypeVideo)
      
      self.removeAllInputs()
      try self.addInputs(inputs)
      
      self.removeAllOutputs()
      try self.addOutputs(outputs)
      
      didSetUp = true
      
      captureSession.commitConfiguration()
    }
    
    if let layerProvider = previewLayerProvider {
      layerProvider.previewLayer.session = self.captureSession
      layerProvider.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      self.previewLayerProvider = layerProvider
    }
    
    sessionQueue.async {
      do {
        try setUpCaptureSession()
      } catch let error {
        DispatchQueue.main.async {
          errorHandler(error)
        }
      }
    }
  }
  
  //MARK: I/O
  
  /// Add the corresponding `AVCaptureInput` for each `CaptureSessionInput` in `inputs`.
  fileprivate func addInputs(_ inputs: [CaptureSessionInput]) throws {
    for input in inputs {
      try addInput(input)
    }
  }
  
  /// Add the corresponding `AVCaptureInput` for `input`.
  fileprivate func addInput(_ input: CaptureSessionInput) throws {
    switch input {
    case .video:
      try addVideoInput()
    case .audio:
      try addAudioInput()
      break
    }
  }
  
  /// Remove the corresponding `AVCaptureInput` for `input`.
  fileprivate func removeInput(_ input: CaptureSessionInput) {
    switch input {
    case .video:
      if let videoInput = videoInput {
        captureSession.removeInput(videoInput)
      }
    case .audio:
      if let audioInput = audioInput {
        captureSession.removeInput(audioInput)
      }
      break
    }
  }
  
  /// Remove all inputs from `captureSession`
  fileprivate func removeAllInputs() {
    if let inputs = captureSession.inputs as? [AVCaptureInput] {
      for input in inputs {
        captureSession.removeInput(input)
      }
    }
  }
  
  /// Add the corresponding `AVCaptureOutput` for each `CaptureSessionInput` in `outputs`.
  fileprivate func addOutputs(_ outputs: [CaptureSessionOutput]) throws {
    for output in outputs {
      try addOutput(output)
    }
  }
  
  /// Add the corresponding `AVCaptureOutput` for `outputs`.
  fileprivate func addOutput(_ output: CaptureSessionOutput) throws {
    switch output {
    case .stillImage:
      try addStillImageOutput()
    case .videoData:
      try addVideoDataOutput()
    case .movieFile:
      try addMovieFileOutput()
    }
  }
  
  /// Remove the corresponding `AVCaptureSessionOutput` for `output`.
  fileprivate func removeOutput(_ output: CaptureSessionOutput) {
    switch output {
    case .stillImage:
      if let stillImageOutput = stillImageOutput {
        captureSession.removeOutput(stillImageOutput)
      }
    case .videoData:
      if let videoDataOutput = videoDataOutput {
        captureSession.removeOutput(videoDataOutput)
      }
    case .movieFile:
      if let movieFileOutput = movieFileOutput {
        captureSession.removeOutput(movieFileOutput)
      }
    }
  }
  
  /// Remove all outputs from `captureSession`
  fileprivate func removeAllOutputs() {
    if let outputs = captureSession.outputs as? [AVCaptureOutput] {
      for outputs in outputs {
        captureSession.removeOutput(outputs)
      }
    }
  }
  
  //MARK: Actions
  
  /// Start running the `AVCaptureSession`.
  public func startRunning(_ errorHandler: ErrorCompletionHandler? = nil) {
    sessionQueue.async {
      if (!self.didSetUp) {
        errorHandler?(CaptureManagerError.sessionNotSetUp)
        return
      }
      if (self.captureSession.isRunning) { return }
      self.captureSession.startRunning()
    }
  }
  
  /// Stop running the `AVCaptureSession`.
  public func stopRunning() {
    sessionQueue.async {
      if (!self.captureSession.isRunning) { return }
      self.captureSession.startRunning()
    }
  }
    
    
    /**
     Check camera is available.
     - return a Bool value to not able to capture piture or video
     */
    private func checkCameraIsAvailable() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch status {
        case .authorized: return true
        case .notDetermined: AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: nil)
            return false
        case .denied: print("denied")
            alertViewToOpenSettings("Camera access denied", message: "Please enable your camera access in the settings.")
            return false
        case .restricted:
            return false
        }
    }
  
    /**
     Check microfon is available.
     - return a Bool value to not able to capture video without microfone
     */
    
    fileprivate func checkMicAvailable() -> Bool  {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.granted:
            print("Permission granted")
            return true
        case AVAudioSessionRecordPermission.denied:
            print("Pemission denied")
            alertViewToOpenSettings("Microfon access denied", message: "Please enable your microfon access in the settings to be able to capture videos.")
            ///here an alertView for the microfon denied!!!
            return false
        case AVAudioSessionRecordPermission.undetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (alowedAccess) -> Void in
            })
            print("Request permission here")
            return false
        default:
            return false
        }
    }

    
    fileprivate func checkPhotoIsEnabled() -> Bool {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            return true
        case .denied:
            alertViewToOpenSettings("Photo access denied", message: "Please enable your photo access in the settings to be able to capture videos.")
            ///here an alertView for the microfon denied!!!
            return false
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() { status in
            
            }
            return false
        case .restricted:
            return false
        default:
            return false
        }
    }
    
  /**
   Capture a still image.
   - parameter completion: A closure of type `(UIImage?, Error?) -> Void` that is called on the **main thread** upon successful capture of the image or the occurence of an error.
   */
  public func captureStillImage(_ completion: @escaping ImageErrorCompletionHandler) {
    
    
    if checkCameraIsAvailable() != true {
        return
    }
    
    
    sessionQueue.async {
        
        guard let imageOutput = self.stillImageOutput,
            let connection = imageOutput.connection(withMediaType: AVMediaTypeVideo) else
        {
            DispatchQueue.main.async {
                completion(nil, CaptureManagerError.missingOutputConnection)
            }
            return
        }
        
    connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
      

      imageOutput.captureStillImageAsynchronously(from: connection) { (sampleBuffer, error) -> Void in
        if (sampleBuffer == nil || error != nil) {
          DispatchQueue.main.async {
            completion(nil, error)
          }
          return
        }
        
        guard let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer!, previewPhotoSampleBuffer: nil)  else {
          DispatchQueue.main.async {
            completion(nil, StillImageError.noData)
          }
          return
        }
        
        guard let image = UIImage(data: data) else {
          DispatchQueue.main.async {
            completion(nil, StillImageError.noImage)
          }
          return
        }
    
        var saver = ImageSaver()
            
            .onSuccess { image, assetId in
                
                completion(assetId, nil)
                
            }
            .onFailure { error in
                
        }
        saver = saver.save(image, filter:  nil)

      }
      
    }
    
  }
  

    
   
    /**
     Start recording a video.
     */
    public func startRecording() {
        
        if !checkCameraIsAvailable() || !checkMicAvailable() || !checkPhotoIsEnabled(){
            return
        }
      
        if let output = _getMovieOutput() {
            output.startRecording(toOutputFileURL: tempFilePath, recordingDelegate: self)
        }
    }
    
    /**
     Stop recording a video. Save it to the cameraRoll and give back the url.
     */
    public func stopVideoRecording(_ completion: @escaping VideoErrorCompletionHandler) {
     
        //no photoaccess no record :(
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            completion(nil, NSError(domain: "no photoaccess", code: 1, userInfo: nil))
            return
        }
        //no mic allowed no record :(
        if AVAudioSession.sharedInstance().recordPermission() != .granted {
            completion(nil, NSError(domain: "no photoaccess", code: 1, userInfo: nil))
            return
        }
        
        if let runningMovieOutput = movieFileOutput {
            if runningMovieOutput.isRecording {
                videoCompletion = completion
                runningMovieOutput.stopRecording()
             //   videoCompletion = nil
            }
        }
    }

    
    fileprivate func _getMovieOutput() -> AVCaptureMovieFileOutput? {
        
        var shouldReinitializeMovieOutput = movieFileOutput == nil
        if !shouldReinitializeMovieOutput {
            if let connection = movieFileOutput!.connection(withMediaType: AVMediaTypeVideo) {
                
                //set the orientation
                connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue)!
               // connection.videq
                shouldReinitializeMovieOutput = shouldReinitializeMovieOutput || !connection.isActive
            }
        }
        
        if shouldReinitializeMovieOutput {
            movieFileOutput = AVCaptureMovieFileOutput()
            movieFileOutput!.movieFragmentInterval = kCMTimeInvalid
            
            if captureSession.canAddOutput(movieFileOutput) {
                
                //check mic and add -> mic has to be enabled!
                if checkMicAvailable() != true {
                    return nil
                }
                
                let mic = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
                if let validMic = self._deviceInputFromDevice(mic) {
                    self.captureSession.addInput(validMic)
                }
                
                captureSession.beginConfiguration()
                captureSession.addOutput(movieFileOutput)
                captureSession.commitConfiguration()
            }
        }
        return movieFileOutput!
    }
    
    fileprivate func _deviceInputFromDevice(_ device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let outError {
            print(outError)
            return nil
        }
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    open func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        captureSession.beginConfiguration()
        
        if flashMode == .on {
            do {
                try self.setTorch(.on)
            } catch {
                print("Woops, got an error: \(error)")
            }
        }

        //flash mode!!!
        captureSession.commitConfiguration()
    }
    
    
    var isVideoToSave = false
    
    open func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        do {
            try self.setTorch(.off)
        } catch {
            print("Woops, got an error: \(error)")
        }
        
        //flash mode!!!
        if (error != nil) {
           print("error")
            
        } else {
            
            //if you want to save the captured video anyway
            if !isVideoToSave{
                
              self.videoCompletion?(outputFileURL, error)
                
            } else {
            
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                saveVideoToLibrary(outputFileURL)
            }
            else {
                
                PHPhotoLibrary.requestAuthorization({ (autorizationStatus) in
                    if autorizationStatus == .authorized {
                        self.saveVideoToLibrary(outputFileURL)
                        }
                    })
                }
            }
        }
    }
    
   
    
    fileprivate func saveVideoToLibrary(_ fileURL: URL) {
      
        
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            
        }) { success, error in
            
            self.videoCompletion?(fileURL, error)

        }
       
    }
    
   
    
    public enum CameraFlashMode: Int {
        case off, on, auto
    }
    
    
    fileprivate func _updateTorch(_ flashMode: CameraFlashMode) {
        captureSession.beginConfiguration()
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        for  device in devices!  {
            let captureDevice = device as! AVCaptureDevice
            if (captureDevice.position == AVCaptureDevicePosition.back) {
                let avTorchMode = AVCaptureTorchMode(rawValue: flashMode.rawValue)
                if (captureDevice.isTorchModeSupported(avTorchMode!)) {
                    do {
                        try captureDevice.lockForConfiguration()
                    } catch {
                        return;
                    }
                    captureDevice.torchMode = avTorchMode!
                    captureDevice.unlockForConfiguration()
                }
            }
        }
        captureSession.commitConfiguration()
    }


    
    
  /**
   Toggles the position of the camera if possible.
   - parameter errorHandler: A closure of type `Error -> Void` that is called on the **main thread** if no opposite device or input was found.
   */
  public func toggleCamera(_ errorHandler: @escaping ErrorCompletionHandler) {
    let position = videoDevicePosition.flipped()
    
    guard let device = try? desiredDevice(withMediaType: AVMediaTypeVideo, position: position) else {
      DispatchQueue.main.async {
        errorHandler(CaptureManagerError.cameraToggleFailed)
      }
      return
    }
    
    if (device == videoDevice) {
      DispatchQueue.main.async {
        errorHandler(CaptureManagerError.cameraToggleFailed)
      }
      return
    }
    
    sessionQueue.async {
      do {
        self.videoDevicePosition = position
        self.captureSession.beginConfiguration()
        self.removeInput(.video)
        self.videoDevice = device
        try self.addInput(.video)
        self.captureSession.commitConfiguration()
      } catch let error {
        DispatchQueue.main.async {
          errorHandler(error)
        }
      }
    }
    
  }
  
  /**
   Sets the `AVCaptureFlashMode` for `videoDevice`.
   - parameter mode: The `AVCaptureFlashMode` to set.
   - parameter errorHandler: A closure of type `Error -> Void` that is called on the **main thread** if an error occurs while setting the `AVCaptureFlashMode`.
   */
  public func setFlash(_ mode: AVCaptureFlashMode, errorHandler: ErrorCompletionHandler? = nil) throws {
    guard let videoDevice = videoDevice else {
      throw CaptureManagerError.missingVideoDevice
    }
    
    sessionQueue.async {
      do {
        try videoDevice.lockForConfiguration()
        if (!videoDevice.hasFlash || !videoDevice.isFlashAvailable) { throw CaptureManagerError.flashNotAvailable }
        if (!videoDevice.isFlashModeSupported(mode)) { throw CaptureManagerError.flashModeNotSupported }
        videoDevice.flashMode = mode
        videoDevice.unlockForConfiguration()
      }
      catch let error {
        DispatchQueue.main.async {
          errorHandler?(error)
        }
      }
    }
    
  }
  
  /**
   Toggles the `AVCaptureFlashMode` for `videoDevice`.
   - Important: If the current `AVCaptureFlashMode` is set to `.auto`, this will set it to `.on`.
  */
  public func toggleFlash(errorHandler: ErrorCompletionHandler? = nil) throws {
    return try setFlash(flashMode.flipped(), errorHandler: errorHandler)
  }
  
  /**
   Sets the `AVCaptureTorchMode` for `videoDevice`.
   - parameter mode: The `AVCaptureTorchMode` to set.
   - parameter errorHandler: A closure of type `Error -> Void` that is called on the **main thread** if an error occurs while setting the `AVCaptureTorchMode`.
   */
  public func setTorch(_ mode: AVCaptureTorchMode, errorHandler: ErrorCompletionHandler? = nil) throws {
    guard let videoDevice = videoDevice else {
      throw CaptureManagerError.missingVideoDevice
    }
    
    sessionQueue.async {
      do {
        try videoDevice.lockForConfiguration()
        if (!videoDevice.hasTorch || !videoDevice.isTorchAvailable) { throw CaptureManagerError.torchNotAvailable }
        if (!videoDevice.isTorchModeSupported(mode)) { throw CaptureManagerError.torchModeNotSupported }
        videoDevice.torchMode = mode
        videoDevice.unlockForConfiguration()
      }
      catch let error {
        DispatchQueue.main.async {
          errorHandler?(error)
        }
      }
    }
    
  }
  
  /**
   Toggles the `AVCaptureTorchMode` for `videoDevice`.
   - Important: If the current `AVCaptureTorchMode` is set to `.auto`, this will set it to `.on`.
   */
  public func toggleTorch(errorHandler: ErrorCompletionHandler? = nil) throws {
    return try setTorch(torchMode.flipped(), errorHandler: errorHandler)
  }
  
  /**
   Focuses the camera at `pointInView`.
   - parameter pointInView: The point inside of the `AVCaptureVideoPreviewLayer`.
   - parameter errorHandler: A closure of type `Error -> Void` that is called on the **main thread** if no device or previewLayerProvider was found or if we failed to lock the device for configuration.
   - Important: Do not normalize! This method handles the normalization for you. Simply pass in the point relative to the preview layer's coordinate system.
   */
  public func focusAndExposure(at pointInView: CGPoint, errorHandler: ErrorCompletionHandler? = nil) throws {
    guard let device = self.videoDevice else {
      throw CaptureManagerError.missingVideoDevice
    }
    
    guard let previewLayerProvider = previewLayerProvider else {
      throw CaptureManagerError.missingPreviewLayerProvider
    }
    
    let point = previewLayerProvider.previewLayer.pointForCaptureDevicePoint(ofInterest: pointInView)
    
    let isFocusSupported = device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus)
    let isExposureSupported = device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose)
    
    sessionQueue.async {
      do {
        try device.lockForConfiguration()
        if (isFocusSupported) {
          device.focusPointOfInterest = point
          device.focusMode = .autoFocus
        }
        if (isExposureSupported) {
          device.exposurePointOfInterest = point
          device.exposureMode = .autoExpose
        }
        device.unlockForConfiguration()
      } catch let error {
        DispatchQueue.main.async {
          errorHandler?(error)
        }
      }
      
    }
  }
  
  //MARK: AVCaptureVideoDataOutputSampleBufferDelegate
  
  public func captureOutput(_ captureOutput: AVCaptureOutput!,
                            didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                            from connection: AVCaptureConnection!)
  {
    self.dataOutputDelegate?.captureManagerDidOutput(sampleBuffer)
  }
  
  //MARK: Helpers
  
  /// Asynchronously refreshes the videoOrientation of the `AVCaptureVideoPreviewLayer`.
  public func refreshOrientation() {
    sessionQueue.async {
      self.previewLayerProvider?.previewLayer.connection.videoOrientation = self.desiredVideoOrientation
    }
  }
  
  /**
   Create `videoInput` and add it to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureInput` if the input cannot be added to `captureSession`.
   */
  fileprivate func addVideoInput() throws {
    videoInput = try AVCaptureDeviceInput(device: videoDevice)
    try addCaptureInput(videoInput!)
  }
  
  /**
   Create `audioInput` and add it to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureInput` if the input cannot be added to `captureSession`.
  */
  fileprivate func addAudioInput() throws {
    let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
    audioInput = try AVCaptureDeviceInput(device: audioDevice)
    try addCaptureInput(audioInput!)
  }
  
  /**
   Add `input` to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureInput` if the input cannot be added to `captureSession`.
   */
  fileprivate func addCaptureInput(_ input: AVCaptureInput) throws {
    if (!captureSession.canAddInput(input)) {
      throw CaptureManagerError.invalidCaptureInput
    }
    captureSession.addInput(input)
  }
  
  /**
   Create `stillImageoutput` and add it to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureOutput` if the output cannot be added to `captureSession`.
   */
  fileprivate func addStillImageOutput() throws {
    stillImageOutput = AVCaptureStillImageOutput()
    stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
    try addCaptureOutput(stillImageOutput!)
  }
  
  /**
   Create `videoDataOutput` and add it to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureOutput` if the output cannot be added to `captureSession`.
   */
  fileprivate func addVideoDataOutput() throws {
    videoDataOutput = AVCaptureVideoDataOutput()
    videoDataOutput?.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): UInt(kCVPixelFormatType_32BGRA)]
    videoDataOutput?.setSampleBufferDelegate(self, queue: framesQueue)
    try addCaptureOutput(videoDataOutput!)
  }
  
  /**
   Create `movieFileOutput` and add it to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureOutput` if the output cannot be added to `captureSession`.
   */
  fileprivate func addMovieFileOutput() throws {
    movieFileOutput = AVCaptureMovieFileOutput()
    try addCaptureOutput(movieFileOutput!)
  }
  
  /**
   Add `output` to `captureSession`.
   - Throws: `CaptureManagerError.invalidCaptureOutput` if the output cannot be added to `captureSession`.
   */
  fileprivate func addCaptureOutput(_ output: AVCaptureOutput) throws {
    if (!captureSession.canAddOutput(output)) {
      throw CaptureManagerError.invalidCaptureOutput
    }
    captureSession.addOutput(output)
  }
  
  /**
   Set the sessionPreset for the AVCaptureSession.
   - Throws: `CaptureManager.invalidSessionPresent` if `sessionPreset` is not valid.
   */
  fileprivate func setSessionPreset(_ preset: String) throws {
    if !captureSession.canSetSessionPreset(preset) {
      throw CaptureManagerError.invalidSessionPreset
    }
    
    captureSession.sessionPreset = preset
  }
  
  /**
   Find the first `AVCaptureDevice` of type `type`. Return default device of type `type` if nil.
   
   - parameter type: The media type, such as AVMediaTypeVideo, AVMediaTypeAudio, or AVMediaTypeMuxed.
   - parameter position: The `AVCaptureDevicePosition`. If nil, `videoDevicePosition` is used.
   - Throws: `CaptureManagerError.invalidMediaType` if `type` is not a valid media type.
   - Returns: `AVCaptureDevice?`
   */
  fileprivate func desiredDevice(withMediaType type: String, position: AVCaptureDevicePosition? = nil) throws -> AVCaptureDevice? {
  
    guard let devices = AVCaptureDevice.devices(withMediaType: type) as? [AVCaptureDevice] else {
      throw CaptureManagerError.invalidMediaType
    }
    
    return devices.filter{$0.position == position ?? videoDevicePosition}.first ?? AVCaptureDevice.defaultDevice(withMediaType: type)
  }
  
}

protocol Flippable {
  mutating func flip()
  func flipped() -> Self
}

extension AVCaptureDevicePosition: Flippable {
  
  mutating func flip() {
    if (self == .back) {
      self = .front
    } else {
      self = .back
    }
  }
  
  func flipped() -> AVCaptureDevicePosition {
    var copy = self
    copy.flip()
    return copy
  }
  
}

extension AVCaptureFlashMode: Flippable {
  
  mutating func flip() {
    if (self == .on) {
      self = .off
    } else {
      self = .on
    }
  }
  
  internal func flipped() -> AVCaptureFlashMode {
    var copy = self
    copy.flip()
    return copy
  }
  
}

extension AVCaptureTorchMode: Flippable {
  
  mutating func flip() {
    if (self == .on) {
      self = .off
    } else {
      self = .on
    }
  }
  
  internal func flipped() -> AVCaptureTorchMode {
    var copy = self
    copy.flip()
    return copy
  }
  
}
