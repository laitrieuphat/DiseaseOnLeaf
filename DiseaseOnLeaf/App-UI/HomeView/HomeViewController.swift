//
//  HomeViewController.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 10/11/25.
//

import UIKit
import AVFoundation
import TensorFlowLite



class HomeViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - TFLite
    private var interpreterManager: TFLiteInterpreterManager!
    
    // MARK: - Model info
    var modelFileName = "efficientnetb0_durian"
    var modelFileType = "tflite"
    
    let picker = UIImagePickerController()
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImage: UIImage? {
        didSet {
            previewView.image = capturedImage
        }
    }
    
    
    private let predictionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        l.textColor = .black
        l.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.text = "Predictions will appear here"
        return l
    }()
    
    var captureImageBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Chụp ảnh", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var collectImageBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Mở bộ sưu tập", for: .normal)
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var detectImgByCamBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Nhận diện bệnh trên cây", for: .normal)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
  
    var previewView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 15
        return imageView
    }()

    var capturedImageLabel: UILabel = {
        let label = UILabel()
        label.text = "Captured Image"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "DiseaseOnLeaf"
        setupUI()
        picker.sourceType = .camera
        picker.delegate = self
        setupModelAI()
    }
    
    
    private func setupModelAI() {
        self.interpreterManager = TFLiteInterpreterManager(modelFileName: modelFileName, modelFileType: modelFileType)
        self.interpreterManager.loadModel()
        self.interpreterManager.loadLabels()
//        self.interpreterManager.previewView = previewView
    
        
    }
    
       
    func setupUI(){
        view.addSubview(captureImageBtn)
        view.addSubview(collectImageBtn)
        view.addSubview(detectImgByCamBtn)
        view.addSubview(previewView)
        view.addSubview(predictionLabel)
        
        previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80).isActive = true
        previewView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: 450).isActive = true
        
        
        predictionLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 5).isActive = true
        predictionLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        predictionLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        
        detectImgByCamBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        detectImgByCamBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        detectImgByCamBtn.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        detectImgByCamBtn.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        detectImgByCamBtn.heightAnchor.constraint(equalToConstant: 60).isActive = true
        //
        
        collectImageBtn.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        collectImageBtn.bottomAnchor.constraint(equalTo: detectImgByCamBtn.topAnchor, constant: -20).isActive = true
        collectImageBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        collectImageBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
    
        captureImageBtn.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        captureImageBtn.bottomAnchor.constraint(equalTo: detectImgByCamBtn.topAnchor, constant: -20).isActive = true
        captureImageBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        captureImageBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        captureImageBtn.addTarget(self, action: #selector(openCamTapped), for: .touchUpInside)
        detectImgByCamBtn.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        
    }
    
    @objc func cameraButtonTapped() {
        let cameraVC = CameraViewController()
        self.navigationController?.pushViewController(cameraVC, animated: true)
    }
    
    @objc func openCamTapped() {
        present(picker, animated: true, completion: nil)
        
    }

}

extension HomeViewController : UIImagePickerControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            capturedImage = image
            
            
        }
        picker.dismiss(animated: true, completion: nil)
        
    }
}
