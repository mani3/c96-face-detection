//
//  FaceDetectionModel.swift
//  FaceDetection
//
//  Created by kazuya.shida on 2019/07/13.
//  Copyright © 2019 mani3. All rights reserved.
//

import UIKit
import CoreImage

class FaceDetectionModel: NSObject {

  let tflite: TFLite
  let inputChannels = 3
  let inputWidth = 320
  let inputHeight = 320
  let threshold: Float = 0.5
  
  init(filename: String) {
    tflite = TFLite(fileName: filename)
    super.init()
  }
  
  func inference(pixelBuffer: CVPixelBuffer?) -> Prediction? {
    guard let pixelBuffer = pixelBuffer else {
      return nil
    }
    let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
    let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
    let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    
    let imageChannels = 4
    
    guard let thumbnailPixelBuffer = pixelBuffer.resized(toSize: CGSize(width: inputWidth, height: inputHeight)) else {
      return nil
    }
    
    CVPixelBufferLockBaseAddress(thumbnailPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    
    guard let sourceStartAddrss = CVPixelBufferGetBaseAddress(thumbnailPixelBuffer) else {
      return nil
    }
    
    let inputTensorBaseAddress = tflite.inputTensor(at: 0)
    let inputImageBaseAddress = sourceStartAddrss.assumingMemoryBound(to: UInt8.self)
    
    for y in 0..<inputHeight {
      let tensorInputRow = inputTensorBaseAddress.advanced(by: (y * inputWidth * inputChannels))
      let inputImageRow = inputImageBaseAddress.advanced(by: y * inputWidth * imageChannels)
      
      for x in 0..<inputWidth {
        
        let out_pixel = tensorInputRow.advanced(by: x * inputChannels)
        let in_pixel = inputImageRow.advanced(by: x * imageChannels)
        
        var b = 2
        for c in 0..<inputChannels {
          
          // Pixel values are between 0-255. Model requires the values to be between -1 and 1.
          // We are also reversing the order of pixels since the source pixel format is BGRA, but the model requires RGB format.
          out_pixel[c] = in_pixel[b]
          b = b - 1
        }
      }
    }
    
    let startTime = Date()
    guard tflite.invokeInterpreter() else {
      return nil
    }
    let time = Date().timeIntervalSince(startTime) * 1000
    let bbox = tflite.outputTensor(at: 0)
    let classes = tflite.outputTensor(at: 1)
    let scores = tflite.outputTensor(at: 2)
    let count = tflite.outputTensor(at: 3)
    let totalOutputCount = Int(count.pointee)
    
    let faces: [Face] = (0..<totalOutputCount)
      .map { i in (Float(scores[i]), [bbox[4*i], bbox[4*i+1], bbox[4*i+2], bbox[4*i+3]]) }
      .map { (score, box) in Face(confidence: score, box: box) }
      .filter { face in face.confidence >= threshold }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    return Prediction(time: time, faces: faces)
  }
  
  struct Prediction {
    let time: Double
    let faces: [Face]
  }
  
  struct Face {
    let confidence: Float
    let rect: CGRect
    
    init(confidence: Float, box: [Float]) {
      self.confidence = confidence
      var r = CGRect.zero
      r.origin.y = CGFloat(box[0])
      r.origin.x = CGFloat(box[1])
      r.size.height = CGFloat(box[2]) - r.origin.y
      r.size.width = CGFloat(box[3]) - r.origin.x
      rect = r
    }
    
    func bbox(w: CGFloat, h: CGFloat) -> CGRect {
      return rect.applying(CGAffineTransform(scaleX: w, y: h))
    }
  }
}
