//
//  CameraManager.swift
//  FaceDetection
//
//  Created by kazuya.shida on 2019/07/13.
//  Copyright © 2019 mani3. All rights reserved.
//

import UIKit
import AVFoundation

import RxRelay

class CameraManager: NSObject {

  fileprivate let previewView: PreviewView
  fileprivate let session: AVCaptureSession = AVCaptureSession()
  fileprivate lazy var videoDataOutput = AVCaptureVideoDataOutput()
  
  fileprivate var permissionStatus: AVAuthorizationStatus = .authorized
  fileprivate let sessionQueue: DispatchQueue = DispatchQueue(label: "sessionQueue")

  let pixelBufferRelay = BehaviorRelay<CVPixelBuffer?>(value: nil)
  
  init(previewView: PreviewView) {
    self.previewView = previewView
    super.init()
    
    session.sessionPreset = .hd1920x1080
    self.previewView.session = session
    
    /// Request permission
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      break
    case .notDetermined:
      self.sessionQueue.suspend()
      AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted) in
        if !granted {
          self?.permissionStatus = .denied
        }
        self!.sessionQueue.resume()
      })
      break
    default:
      permissionStatus = .denied
      break
    }

    sessionQueue.async {
      guard self.permissionStatus == .authorized else {
        return
      }
      self.session.beginConfiguration()
      self.addVideoDeviceInput()
      self.addVideoDeviceOutput()
      self.session.commitConfiguration()
    }
  }
  
  fileprivate func addVideoDeviceInput() {
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      fatalError("Cannot get input device")
    }
    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
    
    do {
      let videoDeviceInput = try AVCaptureDeviceInput(device: device)
      if session.canAddInput(videoDeviceInput) {
        session.addInput(videoDeviceInput)
      }
    } catch {
      fatalError("Cannot add video device input: \(error.localizedDescription)")
    }
  }
  
  fileprivate func addVideoDeviceOutput() {
    let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
    videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    videoDataOutput.videoSettings = [
      String(kCVPixelBufferPixelFormatTypeKey): kCMPixelFormat_32BGRA
    ]
    if session.canAddOutput(videoDataOutput) {
      session.addOutput(videoDataOutput)
      videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
    }
  }
  
  func startSession() {
    sessionQueue.async {
      switch self.permissionStatus {
      case .authorized:
        self.addObservers()
        self.session.startRunning()
        break
      default:
        break
      }
    }
  }
  
  func stopSession() {
    sessionQueue.async {
      if self.permissionStatus == .authorized {
        self.session.stopRunning()
        self.removeObservers()
      }
    }
  }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
    guard let imagePixelBuffer = pixelBuffer else {
      return
    }
    pixelBufferRelay.accept(imagePixelBuffer)
  }
}

// MARK: - Observer

extension CameraManager {
  
  private func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: session)
    NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: session)
    NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: session)
  }
  
  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionRuntimeError, object: session)
    NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionWasInterrupted, object: session)
    NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionInterruptionEnded, object: session)
  }
  
  @objc func sessionRuntimeError(notification: Notification) {
    NSLog("%@: %@", #function, notification.description)
  }
  
  @objc func sessionWasInterrupted(notification: Notification) {
    NSLog("%@: %@", #function, notification.description)
  }
  
  @objc func sessionInterruptionEnded(notification: Notification) {
    NSLog("%@: %@", #function, notification.description)
  }
}
