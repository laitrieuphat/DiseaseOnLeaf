//
//  HomeViewController.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 10/11/25.
//

import UIKit
import AVFoundation
import TensorFlowLite
import CoreVideo
import PhotosUI

class HomeViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - TFLite
    private var interpreterManager: TFLiteInterpreterManager!
    
    // MARK: - Model info
    var pickerCaptureImg:UIImagePickerController?
    var pickerChooseGallary:PHPickerViewController?
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImage: UIImage? {
        didSet {
            previewView.image = capturedImage
        }
    }
    
    var activityIndicator:UIActivityIndicatorView = {
        var spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .white
        spinner.hidesWhenStopped = true
        return spinner
    }()
    
    
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
        button.setTitle("Capture Image", for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var collectImageBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Open Gallary", for: .normal)
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var detectImgByCamBtn: UIButton = {
        let button = UIButton()
        button.setTitle("Camera detect real time ", for: .normal)
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
        imageView.image = nil
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
        title = "Plant Disease Detection System"
        setupUI()
        setupModelAI()
        configurePickerControllers()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .mint
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupModelAI() {
        self.interpreterManager = TFLiteInterpreterManager(modelFileName: "efficientnet_b0_aug",
                                                           modelFileType: "tflite")
        self.interpreterManager.loadModel()
        self.interpreterManager.loadLabels()
        self.interpreterManager.previewView = self.previewView
    }
    
    private func configurePickerControllers() {
        // Initialize UIImagePickerController for capturing images
        pickerCaptureImg = UIImagePickerController()
        pickerCaptureImg?.sourceType = .camera
        pickerCaptureImg?.delegate = self
        
        // Initialize PHPickerViewController for selecting images from the gallery
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images // Filter to show only images
        configuration.selectionLimit = 1 // Allow only one image selection
        pickerChooseGallary = PHPickerViewController(configuration: configuration)
        pickerChooseGallary?.delegate = self
    }

    
    
    func setupUI(){
        view.addSubview(captureImageBtn)
        view.addSubview(collectImageBtn)
        view.addSubview(detectImgByCamBtn)
        view.addSubview(previewView)
        view.addSubview(predictionLabel)
        
        // Add the activity indicator to the previewView hierarchy
        previewView.addSubview(activityIndicator)
        
        
        previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80).isActive = true
        previewView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: 450).isActive = true
        
        activityIndicator.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: previewView.centerYAnchor).isActive = true
        
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
        
        collectImageBtn.addTarget(self, action: #selector(openGalleryTapped), for: .touchUpInside)
        captureImageBtn.addTarget(self, action: #selector(openCamTapped), for: .touchUpInside)
        detectImgByCamBtn.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        
    }
    
    @objc func cameraButtonTapped() {
        let cameraVC = CameraViewController()
        cameraVC.interpreterManager = self.interpreterManager
        self.navigationController?.pushViewController(cameraVC, animated: true)
    }
    
    @objc func openCamTapped() {
        guard let pickerCaptureImg = pickerCaptureImg else {return}
        present(pickerCaptureImg, animated: true, completion: nil)
        
    }
    
    @objc func openGalleryTapped() {
        guard let pickerChooseGallary = pickerChooseGallary else {return}
        present(pickerChooseGallary , animated: true)
    }
    
    func showLoadingSpinner() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
    }
    
    func hideLoadingSpinner() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
}

extension HomeViewController : UIImagePickerControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        // You can add any other actions here, such as logging the cancellation
        print("Image picker was cancelled.")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        // Chuyển sang pixel buffer và gọi model trên background queue
        guard let pixelBuffer = selectedImage.convertToBuffer() else {return}
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.showLoadingSpinner()
            strongSelf.interpreterManager.runModel(pixelBuffer: pixelBuffer) { results, inferenceTimeMs, fps  in
                DispatchQueue.main.async {
                    strongSelf.handleDataFromModel(results: results, inferenceTime: Float(inferenceTimeMs), fps: fps)
                    strongSelf.capturedImage = selectedImage
                    strongSelf.hideLoadingSpinner()
                }
            }
        }
    }
}

extension HomeViewController: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let itemProvider = results.first?.itemProvider else { return }
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let strongSelf = self else { return }
                    if let image = image as? UIImage,
                       let pixelBuffer = image.convertToBuffer() {
                        strongSelf.showLoadingSpinner()
                        strongSelf.interpreterManager.runModel(pixelBuffer: pixelBuffer) { results, inferenceTime, fps  in
                            
                            // Hiển thị ảnh chụp lên UI ngay (nếu có)
                            DispatchQueue.main.async {
                                strongSelf.capturedImage = image
                                strongSelf.handleDataFromModel(results: results,
                                                               inferenceTime: Float(inferenceTime),
                                                               fps: Double(fps))
                                strongSelf.hideLoadingSpinner()
                            }
                        }
                    } else if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func handleDataFromModel(results: [Float], inferenceTime: Float, fps: Double) {
        // Process results on the main thread
        DispatchQueue.main.async {
            let topResults = results.topK(k: 1)
            
            print("Result: \(topResults)")
            print("Inference Time: \(inferenceTime * 1000) ms, FPS: \(fps)")
            
            var predictionText = "Predictions:\n"
            for (index, score) in topResults {
                let label = self.interpreterManager.labels[index]
                predictionText += "\(label): \(String(format: "%.2f", score * 100))%\n"
            }
            predictionText += String(format: "Inference time: %.2f ms", inferenceTime)
            self.predictionLabel.text = predictionText
        }
    }
}
