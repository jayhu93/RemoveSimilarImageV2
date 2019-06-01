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
    var timestamp: Date
}

// MARK: SimilarImageServiceInputs

protocol SimilarImageServiceInputs {
    func analyze(rawPhotos: [RawPhoto])
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
    
    typealias Dependency = (LocalDatabaseType)

    let dispatchGroup = DispatchGroup()
    
    // Init
    init(dependency: Dependency) {

        let (localDatabase) = dependency

        let model = try! VNCoreMLModel(for: MyImageSimilarityModel().model)
        
        let similarImgageResultIO = Signal<PhotoResult, NoError>.pipe()
        similarImageResultSignal = similarImgageResultIO.output
        
        // TODO: Make this reactive

        analyzeIO.output.observeValues { rawPhotos in
            var photoResults = [PhotoResult]()
            // analyze image here
            // PerformRequests

            for rawPhoto in rawPhotos {
                let request = VNCoreMLRequest(model: model, completionHandler: { (requst, error) in
                    self.dispatchGroup.enter()
                    let k = 10
                    let request = requst
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
                        let photoResult = PhotoResult(id: rawPhoto.id, results: result, timestamp: rawPhoto.timestamp)
                        photoResults.append(photoResult)
                        self.dispatchGroup.leave()
                    }
                })
                request.imageCropAndScaleOption = .centerCrop

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

            self.dispatchGroup.notify(queue: DispatchQueue.global(qos: .background)) {
                let photoObjects = photoResults.map { photoResult -> PhotoObject in
                    let photoObject = PhotoObject()
                    photoObject.id = photoResult.id
                    photoObject.timestamp = photoResult.timestamp
                    let similarArray = photoResult.results.map { $0.offset }
                    photoObject.similarArray.append(objectsIn: similarArray)
                    return photoObject
                }
                localDatabase.inputs.addPhotoObjects(photoObjects)
            }

        }
    }
    
    // MARK: SimilarImageAdapterType
    
    var inputs: SimilarImageServiceInputs { return self }
    var outputs: SimilarImageServiceOutputs { return self }
    
    // MARK: SimilarImageServiceInputs
    
    private let analyzeIO = Signal<[RawPhoto], NoError>.pipe()
    func analyze(rawPhotos: [RawPhoto]) {
        analyzeIO.input.send(value: rawPhotos)
    }
    
    // MARK: SimilarImageServiceOutputs
    let similarImageResultSignal: Signal<PhotoResult, NoError>
}
