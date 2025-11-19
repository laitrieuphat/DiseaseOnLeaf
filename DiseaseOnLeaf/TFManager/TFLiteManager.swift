//
//  TFLiteManager.swift
//  DiseaseOnLeaf
//
//  Created by Lai Minh on 10/11/25.
//

import TensorFlowLite
import AVFoundation

class TFLiteInterpreterManager {
    // MARK: - Drawing layers
    private var boundingBoxLayers = [CAShapeLayer]()
    private let labelLayer = CATextLayer()
    
    // UI references (set these from the owning ViewController)
    
    var previewView: UIImageView?
    
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
              let content = try? String(contentsOfFile: labelsPath, encoding: .utf8) else {
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
            options.threadCount = 5
            
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
        
        // Defensive check: ensure input data byte count matches expected model input size
        let expectedBytes = inputWidth * inputHeight * inputChannels * MemoryLayout<Float32>.size
        if inputData.count != expectedBytes {
            let msg = "Provided data count \(inputData.count) must match the required count \(expectedBytes). Check image resize scale and input preprocessing."
            print("Failed to run inference: \(msg)")
            return .failure(NSError(domain: "TFLiteInterpreterManager", code: 3, userInfo: [NSLocalizedDescriptionKey: msg]))
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
    
    
    func runModel(pixelBuffer: CVPixelBuffer,
                  completionHandler: @escaping (([Float],_ inferenceTime:Float, _ fps:Double) -> Void)) {
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
                // Output is handled in the background thread below
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let _ = self else { return }
                    
                    // 6. Interpret output as float array
                    let results = [Float](unsafeData: outputData) ?? []
                    completionHandler(results, Float(inferenceTime * 1000), fps)
                    
                    
                }
            case .failure(let error):
                print("Lỗi khi chạy inference: \(error)")
                
            }
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
        UIGraphicsBeginImageContextWithOptions(CGSize(width: inputWidth, height: inputHeight), false, 1.0)
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
            self.drawBoundingBox(cropRect: cropRect,originalSize: CGSize(width: originalWidth, height: originalHeight))
         }
        
        
        print("preprocess(): returning raw RGB data, count=\(rgbArray.count)")
        let data = rgbArray.withUnsafeBufferPointer { Data(buffer: $0) }
        return data
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
    
    // MARK: - Helpers for heatmap generation
    /// Convert a UIImage (assumed already sized to model input) into the raw RGB Float32 Data used by the model.
    private func imageToModelInputData(_ image: UIImage) -> Data? {
        guard let cg = image.cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let colorSpace = cg.colorSpace else { return nil }
        guard let ctx = CGContext(data: &pixelData,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        
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
        let data = rgbArray.withUnsafeBufferPointer { Data(buffer: $0) }
        return data
    }
    
    /// Generate a simple occlusion-based heatmap for a single UIImage. This runs multiple inferences and can be slow.
    /// - Parameters:
    ///   - image: input UIImage (can be any size; it will be resized to model input inside the function)
    ///   - patchSize: occlusion square size in pixels (on model input scale)
    ///   - stride: stride for sliding window (in pixels)
    ///   - completion: called on main thread with the resulting heatmap UIImage sized inputWidth x inputHeight, or nil on failure.
    public func generateOcclusionHeatmap(for image: UIImage, patchSize: Int = 28, stride: Int = 14, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { DispatchQueue.main.async { completion(nil) }; return }
            // Resize to model input size (scale 1.0)
            UIGraphicsBeginImageContextWithOptions(CGSize(width: self.inputWidth, height: self.inputHeight), false, 1.0)
            image.draw(in: CGRect(x: 0, y: 0, width: self.inputWidth, height: self.inputHeight))
            guard let resized = UIGraphicsGetImageFromCurrentImageContext() else { UIGraphicsEndImageContext(); DispatchQueue.main.async { completion(nil) }; return }
            UIGraphicsEndImageContext()
            
            // Get baseline scores
            guard let baselineData = self.imageToModelInputData(resized) else { DispatchQueue.main.async { completion(nil) }; return }
            switch self.runInference(inputData: baselineData) {
            case .failure(_):
                DispatchQueue.main.async { completion(nil) }
                return
            case .success(let outData):
                let baselineScores = [Float](unsafeData: outData) ?? []
                if baselineScores.isEmpty { DispatchQueue.main.async { completion(nil) }; return }
                // choose target class = top1
                let targetIdx = baselineScores.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
                
                let W = self.inputWidth
                let H = self.inputHeight
                var heat = [Float](repeating: 0, count: W * H)
                var counts = [Float](repeating: 0, count: W * H)
                
                // occlusion: slide patch
                for y in Swift.stride(from: 0, to: H, by: stride) {
                    for x in Swift.stride(from: 0, to: W, by: stride) {
                        autoreleasepool {
                            // create occluded image by drawing resized and filling rect
                            UIGraphicsBeginImageContextWithOptions(CGSize(width: W, height: H), false, 1.0)
                            resized.draw(in: CGRect(x: 0, y: 0, width: W, height: H))
                            // use mid-gray fill to occlude
                            UIColor(white: 0.5, alpha: 1.0).setFill()
                            UIRectFill(CGRect(x: x, y: y, width: patchSize, height: patchSize))
                            guard let occluded = UIGraphicsGetImageFromCurrentImageContext() else { UIGraphicsEndImageContext(); return }
                            UIGraphicsEndImageContext()
                            
                            guard let input = self.imageToModelInputData(occluded) else { return }
                            switch self.runInference(inputData: input) {
                            case .failure(_): return
                            case .success(let out):
                                let scores = [Float](unsafeData: out) ?? []
                                if scores.count <= targetIdx { return }
                                let importance = baselineScores[targetIdx] - scores[targetIdx]
                                for py in y..<min(y + patchSize, H) {
                                    for px in x..<min(x + patchSize, W) {
                                        let idx = py * W + px
                                        heat[idx] += importance
                                        counts[idx] += 1
                                    }
                                }
                            }
                        }
                    }
                }
                
                // average
                for i in 0..<heat.count {
                    if counts[i] > 0 { heat[i] /= counts[i] }
                }
                
                // normalize 0..1
                let maxV = heat.max() ?? 1
                let minV = heat.min() ?? 0
                let norm = heat.map { ($0 - minV) / (maxV - minV + 1e-8) }
                
                // create RGBA heatmap image (red=hot)
                var pixels = [UInt8](repeating: 0, count: W * H * 4)
                for i in 0..<(W*H) {
                    let v = UInt8(min(max(norm[i] * 255.0, 0), 255))
                    pixels[i*4 + 0] = v
                    pixels[i*4 + 1] = 0
                    pixels[i*4 + 2] = 255 - v
                    pixels[i*4 + 3] = 160
                }
                guard let cf = CFDataCreate(nil, pixels, pixels.count),
                      let prov = CGDataProvider(data: cf),
                      let cg = CGImage(width: W, height: H, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: W*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: prov, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {return}
                let heatmapImage = UIImage(cgImage: cg)
                DispatchQueue.main.async {
                    completion(heatmapImage)
                }
            }
        }
    }
}
