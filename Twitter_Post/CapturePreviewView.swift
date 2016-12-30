//
//  CapturePreviewView.swift
//  Giffy
//
//  Created by Gonzalo Nunez on 8/20/15.
//  Copyright (c) 2015 Gonzalo Nunez. All rights reserved.
//

import UIKit
import AVFoundation

/**
 A UIView subclass that overrides the default `layerClass` with `AVCaptureVideoPreviewLayer.self`.
*/
open class CapturePreviewView: UIView {
  
  override open class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setUp()
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setUp()
  }
  
  fileprivate func setUp() {
    backgroundColor = .black
  }
  
}
