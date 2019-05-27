//
//  SimilarImageService.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO
import ReactiveSwift
import Result

struct PhotoResult {
    var id: String
    var results: [(offset: Int, element: Double)]
}

// MARK: SimilarImageServiceInputs

protocol SimilarImageServiceInputs {
    func analyze(rawPhoto: RawPhoto)
}

// MARK: SimilarImageServiceOutputs

protocol SimilarImageServiceOutputs {
    var similarImageResultSignal: Signal<PhotoResult, NoError> { get }
}

// MARK: SimiliarImageServiceType

protocol SimilarImageServiceType {
    var inputs: SimilarImageServiceInputs { get }
    var outputs: SimilarImageServiceOutputs { get }
}

final class SimilarImageService: SimilarImageServiceType, SimilarImageServiceInputs, SimilarImageServiceOutputs {
    
    typealias Dependency = ()

    let queue = OperationQueue()
    
    // Init
    init(dependency: Dependency) {

        let model = try! VNCoreMLModel(for: MyImageSimilarityModel().model)
        
        let similarImgageResultIO = Signal<PhotoResult, NoError>.pipe()
        similarImageResultSignal = similarImgageResultIO.output
        
        analyzeIO.output.observeValues { rawPhoto in
            // analyze image here
            // PerformRequests
            func updateImageSimilarity(for rawPhoto: RawPhoto, request: VNCoreMLRequest) {
                print("Classifying...")
                let image = rawPhoto.image
                let orientation = CGImagePropertyOrientation(image.imageOrientation)
                guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
                
//                DispatchQueue.global(qos: .background).async {
                    let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
                    do {
                        try handler.perform([request])
                    } catch {
                        /*
                         This handler catches general image processing errors. The `classificationRequest`'s
                         completion handler `processClassifications(_:error:)` catches errors specific
                         to processing that request.
                         */
                        print("Failed to perform classification.\n\(error.localizedDescription)")
                    }
//                }
            }
            
            func processQuery(for request: VNRequest, error: Error?, k: Int = 10) {
                DispatchQueue.main.async {
                    guard let results = request.results else {
                        print("Unable to rank image.\n\(error!.localizedDescription)")
                        return
                    }
                    
                    let queryResults = results as! [VNCoreMLFeatureValueObservation]
                    let distances = queryResults.first!.featureValue.multiArrayValue!
                    
                    // Create an array of distances to sort
                    let numReferenceImages = distances.shape[0].intValue
                    var distanceArray = [Double]()
                    for r in 0..<numReferenceImages {
                        distanceArray.append(Double(truncating: distances[r]))
                    }

                    let sorted = distanceArray.enumerated().sorted(by: {$0.element < $1.element})
                    let knn = sorted[..<min(k, numReferenceImages)]
                    
                    print(knn)
                    let result = Array(knn)
                    let photoResult = PhotoResult(id: rawPhoto.id, results: result)
                    similarImgageResultIO.input.send(value: photoResult)
                }
            }
            
            let request = VNCoreMLRequest(model: model, completionHandler: { (requst, error) in
                processQuery(for: requst, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            
            updateImageSimilarity(for: rawPhoto, request: request)
        }
    }
    
    // MARK: SimilarImageAdapterType
    
    var inputs: SimilarImageServiceInputs { return self }
    var outputs: SimilarImageServiceOutputs { return self }
    
    // MARK: SimilarImageServiceInputs
    
    private let analyzeIO = Signal<RawPhoto, NoError>.pipe()
    func analyze(rawPhoto: RawPhoto) {
        analyzeIO.input.send(value: rawPhoto)
    }
    
    // MARK: SimilarImageServiceOutputs
    let similarImageResultSignal: Signal<PhotoResult, NoError>
}
