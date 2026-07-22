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
    var currentLabelDetected: String?
    private lazy var optionalAIModelBtn: UIButton = {
        var config = UIButton.Configuration.bordered()
        config.buttonSize = .mini
        config.cornerStyle = .small
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        
        let button = UIButton(type: .custom)
        button.configuration = config
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // TỰ ĐỘNG TẠO DANH SÁCH MENU TỪ ENUM
        let menuActions = AIModel.allCases.map { model in
            let isSelected = (model == AIManager.shared.currentModel)
            
            return UIAction(
                title: model.rawValue,
                image: UIImage(systemName: model.systemImageName),
                state: isSelected ? .on : .off
            ) { _ in
                // HÀNH ĐỘNG KHI BẤM CHỌN KẾ TIẾP: Cập nhật vào Singleton toàn cục
                AIManager.shared.currentModel = model
            }
        }
        
        button.menu = UIMenu(title: "Chọn Mô Hình AI", children: menuActions)
        return button
    }()
    
    
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
        l.isUserInteractionEnabled = true
        l.translatesAutoresizingMaskIntoConstraints = false
        l.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        l.textColor = .lightGray
        l.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        l.numberOfLines = 0
        l.textAlignment = .center
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.text = "Vui lòng chọn hoặc chụp ảnh để nhận diện"
        return l
    }()
    
    var captureImageBtn: UIButton = {
        // Tạo 1 đối tượng từ Configuration
        var config = UIButton.Configuration.gray()
        config.title = "Chụp ảnh"
        config.image = UIImage(systemName: "camera.fill")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseForegroundColor = .navAppearence
        config.background.backgroundColor = .butonHome
        config.background.cornerRadius = 10
        config.background.strokeColor = .navAppearence
        config.background.strokeWidth = 1.0
        
        // Tạo 1 button với đối tưởng configuration
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var collectImageBtn: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Chọn ảnh"
        config.image = UIImage(systemName: "photo.fill")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseForegroundColor = .navAppearence
        config.background.backgroundColor = .butonHome
        config.background.cornerRadius = 10
        config.background.strokeColor = .navAppearence
        config.background.strokeWidth = 1.0
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var detectImgByCamBtn: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Nhận diện bệnh"
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseForegroundColor = .navAppearence
        config.background.backgroundColor = .butonHome
        config.background.cornerRadius = 10
        config.background.strokeColor = .navAppearence
        config.background.strokeWidth = 1.0
        let button = UIButton(configuration: config, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    
    var previewView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.layer.borderWidth = 0.5
        imageView.image = UIImage(named: "icon_mamxanh")
        return imageView
    }()
        
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hệ Thống Nhận Diện Bệnh Lá"
        setupUI()
        setupModelAI()
        setupNotification()
        configurePickerControllers()
        
    }
    
    private func setupModelAI() {
        let currentModel = AIManager.shared.currentModel
        self.interpreterManager = TFLiteInterpreterManager(modelFileName: currentModel.rawValue,
                                                           modelFileType: "tflite")
        self.interpreterManager.loadModel()
        self.interpreterManager.loadLabels(labelFile: currentModel.labelsFileName)
        self.interpreterManager.previewView = self.previewView
        print("🤖 Model: \(currentModel.rawValue)")
        print("📂 File: \(currentModel.labelsFileName)")
    }
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .navAppearence
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
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
        // attach heatmap overlay to preview
        //        previewView.addSubview(heatmapImageView)
        // allow tapping the preview to toggle the heatmap overlay
        previewView.isUserInteractionEnabled = true
        let heatTap = UITapGestureRecognizer(target: self, action: #selector(tapOnHeatImage))
        previewView.addGestureRecognizer(heatTap)
        view.addSubview(predictionLabel)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        predictionLabel.addGestureRecognizer(tapGesture)
        
        // Add the activity indicator to the previewView hierarchy
        previewView.addSubview(activityIndicator)
        
        
        activityIndicator.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: previewView.centerYAnchor).isActive = true
        
        previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100).isActive = true
        previewView.widthAnchor.constraint(equalToConstant: 350).isActive = true
        previewView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        
        // heatmap overlay fills previewView
        //        heatmapImageView.topAnchor.constraint(equalTo: previewView.topAnchor).isActive = true
        //        heatmapImageView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        //        heatmapImageView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        //        heatmapImageView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor).isActive = true
        
        predictionLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 20).isActive = true
        predictionLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        predictionLabel.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        
        detectImgByCamBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        detectImgByCamBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        detectImgByCamBtn.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
        detectImgByCamBtn.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        detectImgByCamBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        //
        collectImageBtn.trailingAnchor.constraint(equalTo: previewView.trailingAnchor,constant: -10).isActive = true
        collectImageBtn.bottomAnchor.constraint(equalTo: detectImgByCamBtn.topAnchor, constant: -20).isActive = true
        collectImageBtn.widthAnchor.constraint(equalToConstant: 150).isActive = true
        collectImageBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        captureImageBtn.leadingAnchor.constraint(equalTo: previewView.leadingAnchor,constant: 10).isActive = true
        captureImageBtn.bottomAnchor.constraint(equalTo: detectImgByCamBtn.topAnchor, constant: -20).isActive = true
        captureImageBtn.widthAnchor.constraint(equalToConstant: 150).isActive = true
        captureImageBtn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        collectImageBtn.addTarget(self, action: #selector(openGalleryTapped), for: .touchUpInside)
        captureImageBtn.addTarget(self, action: #selector(openCamTapped), for: .touchUpInside)
        detectImgByCamBtn.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        
        setupUINavigationButtonBarItem()
        setupButtonChooseModel()
        
    }
    
    
    private func setupButtonChooseModel(){
        view.addSubview(optionalAIModelBtn)
        optionalAIModelBtn.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
        optionalAIModelBtn.bottomAnchor.constraint(equalTo: previewView.topAnchor, constant: -15).isActive = true
        
        
    }
    
    // 6. Đăng ký nhận thông báo thay đổi dữ liệu
    private func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModelChanged),
            name: AIManager.modelChangedNotification,
            object: nil
        )
    }
    
    private func setupUINavigationButtonBarItem() {
        let logoutButton = UIBarButtonItem(
            image: UIImage(systemName: "rectangle.portrait.and.arrow.right"),
            style: .plain,
            target: self,
            action: #selector(handleLogout)
        )
        
        navigationItem.rightBarButtonItems = [logoutButton]
    }
    
    private func handleDataOutputFromAIModel(results: [Float], inferenceTime: Float, fps: Double) {
        // Process results on the main thread
        DispatchQueue.main.async {
            let topResults = results.topK(k: 1)
            print("Result: \(topResults)")
            print("Inference Time: \(inferenceTime * 1000) ms, FPS: \(fps)")
            
            var predictionText = "Kết quả dự đoán: "
            for (index, score) in topResults {
                let label = self.interpreterManager.arr_labels[index]
                self.currentLabelDetected = label
                predictionText += "\(label)\n "
                predictionText += " \(String(format: "Độ chính xác: %.2f", score * 100))%\n"
            }
            predictionText += String(format: "Thời gian suy luận: %.2f ms", inferenceTime)
            self.predictionLabel.text = predictionText
        }
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
    
    @objc func cameraButtonTapped() {
        let cameraVC = CameraDetectionViewController()
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
    
    @objc func tapOnHeatImage(){
        DispatchQueue.main.async {
            //            self.heatmapImageView.isHidden.toggle()
        }
    }
    
    @objc private func handleLogout() {
        // 1. Hiển thị Alert xác nhận
        let alert = UIAlertController(title: "Đăng xuất", message: "Bạn có chắc chắn muốn thoát?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Thoát ngay", style: .destructive, handler: { _ in
            let loginVC = LoginViewController()
            SceneDelegate.setRootViewController(loginVC)
        }))
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }
    
    
    @objc private func handleModelChanged() {
        DispatchQueue.main.async {
            self.setupModelAI()
        }
    }
    
    @objc func labelTapped(_ sender: UITapGestureRecognizer) {
        print("Label was tapped!")
        if let currentLabelDetected = currentLabelDetected{
            let detailVC = DiseaseDetailViewController()
            detailVC.typeOfDiseaseCurrent = currentLabelDetected    
            self.navigationController?.pushViewController(detailVC, animated: true)
            print("Chuyển sang màn hình chi tiết bệnh: \(currentLabelDetected)")
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
                    strongSelf.handleDataOutputFromAIModel(results: results, inferenceTime: Float(inferenceTimeMs), fps: fps)
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
                                strongSelf.handleDataOutputFromAIModel(results: results,inferenceTime: Float(inferenceTime),fps: Double(fps))
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
}

