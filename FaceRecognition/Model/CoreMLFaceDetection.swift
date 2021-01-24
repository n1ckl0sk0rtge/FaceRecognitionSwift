//
//  CoreMLFaceDetection.swift
//  Travellout
//
//  Created by Nicklas Körtge on 31.10.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Vision

struct CoreMLFace {
    var frame : CGRect
    var headEulerAngleZ : CGFloat
}

class CoreMLFaceDetector {
    private var detectedFacesAsObservations = [VNFaceObservation]()
    
    func faceDetectionRequest() -> VNDetectFaceLandmarksRequest {
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { [weak self] request, error in
            self?.handleDetection(request: request, errror: error)
        })
        return faceLandmarksRequest
        
    }

    func detectFaces(uimage: UIImage) -> [CoreMLFace]? {
        if let ciimage = CIImage(image: uimage) {
            let handler = VNImageRequestHandler(ciImage: ciimage, orientation: CGImagePropertyOrientation(rawValue: UInt32(uimage.imageOrientation.rawValue))!)
            do {
                var faces = [CoreMLFace]()
                try handler.perform([self.faceDetectionRequest()])
                for observations in detectedFacesAsObservations {
                    faces.append(CoreMLFace(frame: getFrameOfFace(observation: observations, image: uimage), headEulerAngleZ: getHeadEulerAngleZ(observation: observations, image: uimage)))
                }
                return faces
            } catch {
                print("Failed to perform detection .\n\(error.localizedDescription)")
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func handleDetection(request: VNRequest, errror: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else {
            fatalError("unexpected result type!")
        }
        self.detectedFacesAsObservations = observations
    }
        
    private func getFrameOfFace(observation: VNFaceObservation, image: UIImage) -> CGRect {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -image.size.height)
        let translate = CGAffineTransform.identity.scaledBy(x: image.size.width, y: image.size.height)
        let facebounds = observation.boundingBox.applying(translate).applying(transform)
        return facebounds
    }
    
    private func getHeadEulerAngleZ(observation: VNFaceObservation, image: UIImage) -> CGFloat {
        
        var facelefteyeCenterPoint : CGPoint?
        var facerighteyeCenterPoint : CGPoint?
        
        if let facerighteyePoints = observation.landmarks?.rightEye?.pointsInImage(imageSize: image.size) {
            facerighteyeCenterPoint = calculateCenterOfPoints(points: facerighteyePoints)
        }
        
        if let facelefteyePoints = observation.landmarks?.leftEye?.pointsInImage(imageSize: image.size) {
            facelefteyeCenterPoint = calculateCenterOfPoints(points: facelefteyePoints)
        }
        
        if facerighteyeCenterPoint != nil && facelefteyeCenterPoint != nil {
            let angleRadians = atan2(facelefteyeCenterPoint!.x - facerighteyeCenterPoint!.x , facelefteyeCenterPoint!.y - facerighteyeCenterPoint!.y)
            return angleRadians * 180 / .pi - 90
        }
        return 0.0
    }
    
    private func calculateCenterOfPoints(points: [CGPoint]) -> CGPoint {
        var xValueSUM : CGFloat = 0.0
        var yValueSUM : CGFloat = 0.0
        
        for point in points {
            xValueSUM += point.x
            yValueSUM += point.y
        }
        
        let count = CGFloat(points.count)
        return CGPoint(x: xValueSUM / count, y: yValueSUM / count)
    }

}
