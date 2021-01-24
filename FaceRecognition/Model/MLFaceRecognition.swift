//
//  MLFaceRecognition.swift
//  Travellout
//
//  Created by Nicklas Körtge on 23.07.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import Vision
import MLKit
import TensorFlowLite

enum FaceRecognisorError : Error {
    case getFaceImages(message: String)
    case convertFaceImageToFaceModelInput(message: String)
    
}


class MLFaceRecognisor {
    static let shared = MLFaceRecognisor()
    
    private var facedetectorOptions : FaceDetectorOptions
    private let facedetector : FaceDetector
    private let faceNetModel = FaceNetModel()

    
    private init() {
        facedetectorOptions = FaceDetectorOptions()
        facedetectorOptions.performanceMode = .accurate
        facedetectorOptions.landmarkMode = .none
        facedetectorOptions.classificationMode = .none
        facedetectorOptions.isTrackingEnabled = false
        facedetectorOptions.minFaceSize = 0.4
        facedetector = FaceDetector.faceDetector(options: facedetectorOptions)
        
        faceNetModel.prepare()
    }
    
    // MARK: - FaceNetModel
    private class FaceNetModel {
        enum FaceNetModelError: Error {
            case interpreterNotInitilized
            case faceModelOutputWasNil
            case invalidOutputShape
        }
        
        var interpreter: Interpreter?
    
        func prepare() {
            guard interpreter == nil else { return }
            guard let modelPath = Bundle.main.path(forResource: "facenet", ofType: "tflite") else {
                print("model file not found")
                return
            }
            
            do {
                var options = Interpreter.Options()
                options.threadCount = 1
                interpreter = try Interpreter(modelPath: modelPath, options: options)
            } catch let error {
                print(error)
            }
        }
        
        
        func run(_ input: Data) -> Result<[[Float]], Error> {
            guard let interpreter = interpreter else {
                return .failure(FaceNetModelError.interpreterNotInitilized)
            }
            
        
            do {
                try interpreter.allocateTensors()
                try interpreter.copy(input, toInputAt: 0)
                try interpreter.invoke()
                
                let outputTensor = try interpreter.output(at: 0)
                
                let results: [Float]
                switch outputTensor.dataType {
                    case .uInt8:
                      guard let quantization = outputTensor.quantizationParameters else {
                        print("No results returned because the quantization values for the output tensor are nil.")
                        return .failure(FaceNetModelError.invalidOutputShape)
                      }
                      let quantizedResults = [UInt8](outputTensor.data)
                      results = quantizedResults.map {
                        quantization.scale * Float(Int($0) - quantization.zeroPoint)
                      }
                    case .float32:
                      results = [Float32](unsafeData: outputTensor.data) ?? []
                    default:
                      print("Output tensor data type \(outputTensor.dataType) is unsupported for this example app.")
                        return .failure(FaceNetModelError.invalidOutputShape)
                }
                return .success([results])
            } catch let error {
                print(error)
                return .failure(error)
            }
            
        }
        
    }
    
    
    // MARK: - FaceRecognition Functions
    func detectPersonsFromImage(image: UIImage, completion: @escaping (Result<[FluctuatingPersonReference], Error>) -> Void) {
        let queue = DispatchQueue(label: "extractPersons")
        let group = DispatchGroup()
        
        var foundFaces = [FluctuatingPersonReference]()
        
        group.enter()
        queue.async {
            self.getFaceImages(image: image) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let faceImages):
                    for faceImage in faceImages {
                        group.enter()
                        self.getFaceCode(imageWithFace: faceImage) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success(let facecode):
                                var foundPerson = FluctuatingPersonReference(faceimage: faceImage, faccode: facecode)
                                if let recognisedPerson = self.classify(detectedperson: foundPerson){
                                    foundPerson = recognisedPerson.createFluctuatingReference()
                                }
                                foundFaces.append(foundPerson)
                            }
                            group.leave()
                        }
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main){
            completion(.success(foundFaces))
        }
    }
    
    
    
    func classify(detectedperson: FluctuatingPersonReference) -> Persons? {
        //Prepear data
        let coreDataController = CoreDataStorageController<Persons>()
        let persons = coreDataController.loadData() as! [Persons]
        
        for person in persons {
            // calculate distance between facecodes of code base and new face code
            let distance = MathFunctions.euclidean(a: detectedperson.faceCode!, b: person.faceCode!)
            print("Info: Distance between faceCodes: \(distance)")
            // desission value is 0.9
            if distance < 0.85 {
                // distance less then 0.9, than person is detected
                return person
            }
        }
        
        return nil
    }

    private func getFaceCode(imageWithFace: FaceImage, _ completion: @escaping (Result<[Float32], Error>) -> ()) {
        let queue = DispatchQueue(label: "getFaceCodeDPQ")
        
        queue.async {
            switch self.convertFaceImageToFaceModelInput(image: imageWithFace) {
            case .failure(let error):
                completion(.failure(error))
            case .success(let processedImageContainer):
                DispatchQueue.main.async {
                    let result = self.faceNetModel.run(processedImageContainer)
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let faceNetModelRepresentation):
                        let normedFaceCode = L2Norm.calculate(arr: faceNetModelRepresentation)
                        completion(.success(normedFaceCode[0]))
                    }
                }
            }
        }
    }
    
    private func getFaceImages(image: UIImage, _ completion: @escaping (Result<[FaceImage], Error>) -> ()) {
        let queue = DispatchQueue(label: "getFaceImagesDPQ")
        let group = DispatchGroup()
        
        let coreMLFaceDetector = CoreMLFaceDetector()
        
        let result = MLHelper.prepareImageForMLFunctions(image: image)
        
        switch result {
        case .failure(let error):
            completion(.failure(error))
        case .success((let uimage, let viimage)):
            var faceImages = [FaceImage]()
            
            group.enter()
            queue.async {
                self.facedetector.process(viimage) { faces, error in
                    if let faces = faces, let MLfaces = coreMLFaceDetector.detectFaces(uimage: uimage) {
                        if faces.count >= MLfaces.count {
                            print("Info: Found \(faces.count) faces with MLKit")
                            group.enter()
                            queue.async {
                                for face in faces {
                                    if let imageWithFace = self.extractFaceImageByFrame(image: uimage, faceFrame: face.frame) {
                                        let faceImage = FaceImage(imageOfFace: imageWithFace, headEulerAngleZ: face.headEulerAngleZ * .pi / 180)
                                        faceImages.append(faceImage)
                                    } else {
                                        completion(.failure(FaceRecognisorError.getFaceImages(message: "Error: Could not extract faces from Image.")))
                                    }
                                }
                                group.leave()
                            }
                        } else {
                           //Face detection wit core ML
                            group.enter()
                            queue.async {
                                print("Info: Found \(MLfaces.count) faces with CoreML")
                                for face in MLfaces {
                                    if let imageWithFace = self.extractFaceImageByFrame(image: uimage, faceFrame: face.frame) {
                                        let faceImage = FaceImage(imageOfFace: imageWithFace, headEulerAngleZ: face.headEulerAngleZ * .pi / 180)
                                            faceImages.append(faceImage)
                                    } else {
                                        completion(.failure(FaceRecognisorError.getFaceImages(message: "Error: Could not extract faces from Image.")))
                                    }
                                }
                                group.leave()
                            }
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(.success(faceImages))
            }
        
        }
            
    }
    
    
    // MARK: - Static function
    static func faceCodeCombination(baseFaceCode: [Float32], newFaceCode: [Float32]) -> [Float32]? {
        //values form face code vector which are most be influenced by (sun)glasses
        let glassesMarkerArray = [40, 71, 122, 124]
        
        if baseFaceCode.count == newFaceCode.count {
            var new_vector = [Float32]()
            for i in 0..<baseFaceCode.count {
                if glassesMarkerArray.contains(i)  {
                    let difference = abs(baseFaceCode[i] - newFaceCode[i])
                    // if difference between "glasses-values" are greater then 0.12, than the
                    // person is most likely wear a glass
                    if difference > 0.12 {
                        // "glasses-values" of base vector will not be edit
                        // sunglasses will not have an impact on classify a person
                        new_vector.append(baseFaceCode[i])
                        continue
                    }
                    new_vector.append((baseFaceCode[i] + newFaceCode[i]) / 2)
                } else {
                    new_vector.append((baseFaceCode[i] + newFaceCode[i]) / 2)
                }
            }
            return new_vector
        } else {
            return nil
        }
    }
    
    
    
    
    // MARK: - Private Functions
    
    private func addFaceMarker(image : UIImage, frame: CGRect) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        //Defines the scalefactor
        var scalefactor : CGFloat = 1.0
        if image.size.height > image.size.width {
            scalefactor = image.size.height
        } else {
            scalefactor = image.size.width
        }
        
        let color = UIColor.red
        color.setStroke()
        
        image.draw(at: CGPoint.zero)
        
        let rectanglePath = UIBezierPath(rect: frame)
        rectanglePath.lineWidth = 0.005 * scalefactor // Bazel of 5px by 1000px picture
        rectanglePath.stroke()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func extractFaceImageByFrame(image: UIImage, faceFrame: CGRect) -> UIImage? {
        let rgb_image = RGBAImage(image: image)!
        
        let frame_width = Int(faceFrame.width)
        let frame_height = Int(faceFrame.height)
        let frame_x = Int(faceFrame.minX)
        let frame_y = Int(faceFrame.minY)
        
        
        let faceImageData = UnsafeMutablePointer<Pixel>.allocate(capacity: frame_width * frame_height)
        let faceImagePixelpointer = UnsafeMutableBufferPointer<Pixel>(start: faceImageData, count: frame_width * frame_height)
        
        for y in frame_y..<(frame_y + frame_height) {
            for x in frame_x..<(frame_x + frame_width) {
                let grep_index = y * rgb_image.width + x
                let pixel = rgb_image.pixels[grep_index]
                let insert_index = (y - frame_y) * frame_width + (x - frame_x)
                faceImagePixelpointer[insert_index] = pixel
            }
        }
        
        let rgb_faceImage = RGBAImage(width: frame_width, height: frame_height, pixels: faceImagePixelpointer)!
        if let faceImage = rgb_faceImage.toUIImage() {
            return faceImage
        } else {
            return nil
        }
    }
    
    private func convertFaceImageToFaceModelInput(image: FaceImage) -> Result<Data, Error> {
        if let faceimage = image.getAligendImage() {
            if faceimage.size != CGSize(width: 160, height: 160) {
                return .failure(FaceRecognisorError.convertFaceImageToFaceModelInput(message: "Error: FaceImage does not match the required size."))
            } else {
                let rgb_image = RGBAImage(image: faceimage)!
                
                //Claculate mean
                var mean_sum : Float32 = 0
                for y in 0..<160 {
                    for x in 0..<160 {
                        let grep_index = y * 160 + x
                        let pixel = rgb_image.pixels[grep_index]
                        
                        let red = Float32(Int(pixel.red))
                        let green = Float32(Int(pixel.green))
                        let blue = Float32(Int(pixel.blue))
                        
                        mean_sum += (red + green + blue)
                    }
                }
                let mean = mean_sum / 25600
                
                //calculate std
                var std_sum : Float32 = 0
                for y in 0..<160 {
                    for x in 0..<160 {
                        let grep_index = y * 160 + x
                        let pixel = rgb_image.pixels[grep_index]
                        
                        let red = Float32(Int(pixel.red))
                        let green = Float32(Int(pixel.green))
                        let blue = Float32(Int(pixel.blue))
                        
                        std_sum += (powf(abs(red - mean),2) + powf(abs(green - mean),2) + powf(abs(blue - mean),2))
                    }
                }
                let std = sqrtf(std_sum / 25600)
                
                var pixelData = Data()
                
                for y in 0..<160 {
                    for x in 0..<160 {
                        let grep_index = y * 160 + x
                        let pixel = rgb_image.pixels[grep_index]

                        let red = (Float32(Int(pixel.red)) - mean) / std
                        let green = (Float32(Int(pixel.green)) - mean) / std
                        let blue = (Float32(Int(pixel.blue)) - mean) / std
                        
                        let rd = Data(red.bytes)
                        pixelData.append(rd)
                        let gd = Data(green.bytes)
                        pixelData.append(gd)
                        let bd = Data(blue.bytes)
                        pixelData.append(bd)
                    }
                }
                
                return .success(pixelData)
            }
        } else {
            return .failure(FaceRecognisorError.convertFaceImageToFaceModelInput(message: "Error: Could not get FaceImage reference to original Image"))
        }
    }
    
}


// MARK: - Extensions

extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
    #if swift(>=5.0)
    self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    #else
    self = unsafeData.withUnsafeBytes {
      .init(UnsafeBufferPointer<Element>(
        start: $0,
        count: unsafeData.count / MemoryLayout<Element>.stride
      ))
    }
    #endif  // swift(>=5.0)
  }
}

extension Float {
   var bytes: [UInt8] {
       withUnsafeBytes(of: self, Array.init)
   }
}




