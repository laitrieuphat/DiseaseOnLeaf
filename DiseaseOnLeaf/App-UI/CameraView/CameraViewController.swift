//
//  CameraViewController.swift
//  DiseaseOnLeaf
//
//  Created by Lai Minh on 8/11/25.
//

import UIKit
import AVFoundation



/**
 Leaf_Algal
 Leaf_Blight
 Leaf_colletotrichum
 Leaf_Healthy
 Leaf_Phomopsis
 Leaf_Rhizoctonia
 
 chay_la
 dom_la
 gi_sat
 la_khoe
thoi_qua_den
 qua_khoe
 
 */


class CameraViewController: UIViewController {
    
    // MARK: - UI
    private var previewView = UIView()
    private let predictionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.black
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        l.numberOfLines = 0
        l.textAlignment = .left
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.text = "Predictions will appear here"
        return l
    }()
    
    // **[NEW]** FPS Display Label
    private var fpsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.red.withAlphaComponent(0.6)
        l.textColor = .white
        l.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.text = "FPS: -"
        return l
    }()
    
    // MARK: - Camera
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // MARK: - TFLite
    private var interpreterManager: TFLiteInterpreterManager!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupModelAI()
        setupCamera()
        setupUI()
    }
    
    private func setupModelAI() {
        self.interpreterManager = TFLiteInterpreterManager(modelFileName: "efficientnet_b0_aug",
                                                           modelFileType: "tflite")
        self.interpreterManager.loadModel()
        self.interpreterManager.loadLabels()
        self.interpreterManager.previewView = previewView
        self.interpreterManager.predictionLabel = predictionLabel
        self.interpreterManager.fpsLabel = fpsLabel // **[NEW]** Link FPS
        
    }
    
    private func setupUI() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        
        // **[NEW]** Add FPS Label
        view.addSubview(fpsLabel)
        view.addSubview(predictionLabel)
        
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // **[NEW]** Prediction Label Constraints (Top Right)
            predictionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            predictionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            predictionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            // **[NEW]** FPS Label Constraints (Top Left)
            fpsLabel.topAnchor.constraint(equalTo: predictionLabel.bottomAnchor, constant: 5),
            fpsLabel.trailingAnchor.constraint(equalTo: predictionLabel.trailingAnchor, constant: 0),
            fpsLabel.widthAnchor.constraint(equalToConstant: 120),
            fpsLabel.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Select the back camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else{
            print("No back camera.")
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Can't create input from camera")
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Video output
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        let queue = DispatchQueue(label: "videoQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        // Orient preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(previewLayer)
        
        // Connection orientation
        if let connection = dataOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = previewView.bounds
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Run model on each frame
        self.interpreterManager.runModel(on: pixelBuffer)
    }
}

