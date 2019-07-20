//
//  ViewController.swift
//  FaceDetection
//
//  Created by kazuya.shida on 2019/07/12.
//  Copyright © 2019 mani3. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class ViewController: UIViewController {
  let dispose = DisposeBag()
  
  @IBOutlet weak var previewView: PreviewView!
  lazy var manager = CameraManager(previewView: previewView)
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let model = FaceDetectionModel(filename: "mobilenet_ssd_320x320")
    manager.pixelBufferRelay.asObservable()
      .map { model.inference(pixelBuffer: $0) }
      .bind(to: previewView.rx.prediction)
      .disposed(by: dispose)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    manager.startSession()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    manager.stopSession()
  }
}

