//
//  PreviewView.swift
//  FaceDetection
//
//  Created by kazuya.shida on 2019/07/13.
//  Copyright © 2019 mani3. All rights reserved.
//

import UIKit
import AVFoundation

import RxSwift
import RxCocoa

class PreviewView: UIView {
  
  let lineWidth: CGFloat = 3
  var faces: [FaceDetectionModel.Face] = []
  
  var session: AVCaptureSession? {
    get {
      return (layer as? AVCaptureVideoPreviewLayer)?.session
    }
    set {
      (layer as? AVCaptureVideoPreviewLayer)?.session = newValue
//      if let layer = self.layer as? AVCaptureVideoPreviewLayer {
//        layer.videoGravity = AVLayerVideoGravity.resizeAspect
//      }
    }
  }
  
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    layer.sublayers?
      .filter { $0.name == "box" }
      .forEach { $0.removeFromSuperlayer() }
    
    for face in faces {
      
      let l = rectangle(color: UIColor(red: 175/255, green: 223/255, blue: 228/255, alpha: 1), face: face)
      self.layer.addSublayer(l)
    }
  }
  
  override class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }
  
  func rectangle(color: UIColor, face: FaceDetectionModel.Face) -> CALayer {
    let path = UIBezierPath(rect: face.bbox(
      w: frame.size.width, h: frame.size.height))
    path.lineWidth = lineWidth
    let layer = CAShapeLayer()
    layer.name = "box"
    layer.fillColor = UIColor.clear.cgColor
    layer.strokeColor = color.cgColor
    layer.lineWidth = lineWidth
    layer.lineJoin = CAShapeLayerLineJoin.miter
    layer.path = path.cgPath
    return layer
  }
}

extension Reactive where Base: PreviewView {
  
  var prediction: Binder<FaceDetectionModel.Prediction?> {
    return Binder(self.base) { (base, prediction) in
      print(prediction)
      base.faces = prediction?.faces ?? []
      base.setNeedsDisplay()
    }
  }
}
