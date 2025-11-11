//
//  TFLiteManager.swift
//  DiseaseOnLeaf
//
//  Created by Lai Minh on 10/11/25.
//

import TensorFlowLite
import UIKit
import AVFoundation

class TFLiteInterpreterManager {
    // MARK: - Drawing layers
    private var boundingBoxLayers = [CAShapeLayer]()
    private let labelLayer = CATextLayer()

    // UI references (set these from the owning ViewController)
    var predictionLabel: UILabel?
    var fpsLabel: UILabel?
    var previewView: UIView?
    
    
    private var interpreter: Interpreter?
    private let modelFileName: String
    private let modelFileType: String
    private(set) var labels: [String] = []
    
    
    private let inputWidth = 224
    private let inputHeight = 224
    private let inputChannels = 3
    
    // throttle frames
    private var lastRun: Date = .distantPast
    private let minFrameInterval: TimeInterval = 0.05
    
    
    /// Initializes the interpreter manager with a TFLite model file name and type.
    /// - Parameters:
    ///   - modelFileName: The name of the .tflite file (without extension).
    ///   - modelFileType: The file extension (e.g., "tflite").
    init(modelFileName: String, modelFileType: String = "tflite") {
        self.modelFileName = modelFileName
        self.modelFileType = modelFileType
    }
    
    
     func loadLabels() {
        guard let labelsPath = Bundle.main.path(forResource: "labels", ofType: "txt"),
              let content = try? String(contentsOfFile: labelsPath) else {
            print("Labels not found. Predictions will show indices.")
            return
        }
        labels = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        print("Loaded \(labels.count) labels.")
    }
    
    
    /// Loads the TFLite model and initializes the interpreter.
    /// - Returns: An error if the operation fails.
    func loadModel()  {
        guard let modelPath = Bundle.main.path(forResource: modelFileName, ofType: modelFileType) else {
            return
        }
        
        do {
            // Specify options for the interpreter (e.g., number of threads, delegates)
            var options = Interpreter.Options()
            options.threadCount = 1
            
            // Create the interpreter
            self.interpreter = try Interpreter(modelPath: modelPath, options: options)
            
            // Allocate memory for the model's input tensors
            try interpreter?.allocateTensors()
        
            
        } catch let error {
            print("Failed to load the model: \(error.localizedDescription)")
       
        }
    }
    
    /// Runs inference with a generic input and returns generic output.
    /// NOTE: You will need to customize this method based on your model's specific input and output types (e.g., UIImage, Data, Float array).
    /// - Parameter inputData: The input data prepared as a `Data` or an appropriate type for the model.
    /// - Returns: The output data as a `Data` or an appropriate type, or an error.
    func runInference(inputData: Data) -> Result<Data, Error> {
        guard let interpreter = interpreter else {
            return .failure(NSError(domain: "TFLiteInterpreterManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Interpreter is not initialized."]))
        }
        
        do {
            // Copy the input data to the input tensor
            try interpreter.copy(inputData, toInputAt: 0)
            
            // Run inference
            try interpreter.invoke()
            
            // Get the output tensor
            let outputTensor = try interpreter.output(at: 0)
            let outputData = outputTensor.data
            
            return .success(outputData)
            
        } catch let error {
            print("Failed to run inference: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    
    func runModel(on pixelBuffer: CVPixelBuffer) {
        // Throttle FPS to reduce CPU
        let now = Date()
        guard now.timeIntervalSince(lastRun) >= minFrameInterval else { return }
        lastRun = now
        
        // Get start time for inference calculation
        let inferenceStartTime = CFAbsoluteTimeGetCurrent()
        
        // Chuyển ảnh thành định dạng đầu vào model cần (crop 1/3 trung tâm, resize 224x224)
        guard let inputData = preprocess(pixelBuffer: pixelBuffer) else { return }
        
        do {
            
            let inferenceEndTime = CFAbsoluteTimeGetCurrent()
            let inferenceTime = inferenceEndTime - inferenceStartTime
            let fps = 1.0 / inferenceTime
            
            switch runInference(inputData: inputData) {
            case .success(let outputData):
                // Inference succeeded
            
                // Output is handled in the background thread below
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self, let interpreter = self.interpreter else { return }
                    
                    do {
                        // 6. Interpret output as float array
                        let results = [Float](unsafeData: outputData) ?? []
                        let topResult = results.topK(k: 1).first
                        
                        print("Inference Time: \(inferenceTime * 1000) ms, FPS: \(fps), Result: \(String(describing: topResult))")
                        
                        // Prepare output text
                        var outputText = ""
                        if let result = topResult {
                            let label: String
                            if result.index < self.labels.count {
                                label = self.labels[result.index]
                            } else {
                                label = "Index \(result.index)"
                            }
                            
                            
                            let confidenceText = String(format: "%.1f", result.score * 100.0)
                            outputText = "\(label) (\(confidenceText)%)"
                        } else {
                            outputText = "No result"
                        }
                        
                        // 7. Update UI on the main thread
                        DispatchQueue.main.async {
                            self.predictionLabel?.text = outputText
                            
                            // **[NEW]** Update FPS Label
                            self.fpsLabel?.text = String(format: "FPS: %.1f", fps)
                        }
                    } catch {
                        print("Lỗi khi xử lý output: \(error)")
                    }
                }
                
            case .failure(let error):
                print("Lỗi khi chạy inference: \(error)")
            default:
                break
            }
            
    
        } catch {
            print("Lỗi khi chạy model: \(error)")
        }
    }
    
    
    // MARK: - Preprocess image (No normalization, only crop + resize)
    private func preprocess(pixelBuffer: CVPixelBuffer) -> Data? {
        let originalWidth = CVPixelBufferGetWidth(pixelBuffer)
        let originalHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        // 1. Calculate center 1/3 crop (box_w, box_h = w//3, h//3)
        let boxW = originalWidth / 3
        let boxH = originalHeight / 3
        let x1 = (originalWidth - boxW) / 2
        let y1 = (originalHeight - boxH) / 2
        let cropRect = CGRect(x: x1, y: y1, width: boxW, height: boxH)
        
        // 2. Crop CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).cropped(to: cropRect)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("ERROR: Failed to create CGImage from cropped CIImage.")
            return nil
        }
        
        // 3. Convert to UIImage and resize to model input size
        let croppedUIImage = UIImage(cgImage: cgImage)
        UIGraphicsBeginImageContext(CGSize(width: inputWidth, height: inputHeight))
        croppedUIImage.draw(in: CGRect(x: 0, y: 0, width: inputWidth, height: inputHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = resizedImage,
              let cgFinal = finalImage.cgImage else {
            print("ERROR: Resize failed.")
            return nil
        }
        
        // 4. Convert to raw RGB data (no normalization)
        let width = cgFinal.width
        let height = cgFinal.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let colorSpace = cgFinal.colorSpace else { return nil }
        guard let context2 = CGContext(data: &pixelData,
                                       width: width,
                                       height: height,
                                       bitsPerComponent: bitsPerComponent,
                                       bytesPerRow: bytesPerRow,
                                       space: colorSpace,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            print("ERROR: CGContext creation failed.")
            return nil
        }
        
        context2.draw(cgFinal, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 5. Convert RGBA -> RGB and cast to Float32 (no normalization)
        var rgbArray = [Float32]()
        rgbArray.reserveCapacity(width * height * 3)
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = Float32(pixelData[i])
            let g = Float32(pixelData[i + 1])
            let b = Float32(pixelData[i + 2])
            rgbArray.append(r)
            rgbArray.append(g)
            rgbArray.append(b)
        }
        
        // 6. Draw bounding box on the screen (Main thread required for UI)
        DispatchQueue.main.async {
            self.drawBoundingBox(cropRect: cropRect,
                                 originalSize: CGSize(width: originalWidth, height: originalHeight))
        }
        
        print("preprocess(): returning raw RGB data, count=\(rgbArray.count)")
        return Data(buffer: UnsafeBufferPointer(start: rgbArray, count: rgbArray.count))
    }
    
    
    // MARK: - Bounding Box Drawing
    private func drawBoundingBox(cropRect: CGRect, originalSize: CGSize) {
        // 1. Remove previous box
        boundingBoxLayers.forEach { $0.removeFromSuperlayer() }
        boundingBoxLayers.removeAll()
        
        // Require previewView to be set by the owner
        guard let previewView = previewView else { return }
        
        // 2. Map the cropRect (based on CVPixelBuffer size) to the previewLayer (screen size)
        // AVMakeRect ensures the mapping respects the aspect ratio of the video layer (resizeAspectFill)
        let videoRect = AVMakeRect(aspectRatio: originalSize, insideRect: previewView.bounds)
        
        // Calculate the scale and offset
        let scaleX = videoRect.width / originalSize.width
        let scaleY = videoRect.height / originalSize.height
        
        // Adjusted rect on screen
        let x = videoRect.origin.x + cropRect.origin.x * scaleX
        let y = videoRect.origin.y + cropRect.origin.y * scaleY
        let w = cropRect.width * scaleX
        let h = cropRect.height * scaleY
        
        let scaledRect = CGRect(x: x, y: y, width: w, height: h)
        
        // 3. Draw the box
        let boxLayer = CAShapeLayer()
        boxLayer.frame = scaledRect
        boxLayer.borderColor = UIColor.yellow.cgColor // Yellow (0, 255, 255 in BGR)
        boxLayer.borderWidth = 3.0
        boxLayer.fillColor = UIColor.clear.cgColor
        
        previewView.layer.addSublayer(boxLayer)
        boundingBoxLayers.append(boxLayer)
    }
}
