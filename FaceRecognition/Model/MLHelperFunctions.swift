//
//  MLHelperFunctions.swift
//  Travellout
//
//  Created by Nicklas Körtge on 05.10.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import CoreML
import Vision
import UIKit
import MLKit

enum MLHelperFunctionsError: Error {
    case prepareImageForMLFunctions(message: String)
}

class MLHelper {

    static func prepareImageForMLFunctions(image: UIImage) -> Result<(UIImage, VisionImage), Error> {
        if let imageWithsRGBColorSpace = image.ConvertImageToRGBColorMode() {
                let visionImage = VisionImage(image: imageWithsRGBColorSpace)
                visionImage.orientation = imageWithsRGBColorSpace.imageOrientation
                return .success((imageWithsRGBColorSpace, visionImage))
        } else {
            return .failure(MLHelperFunctionsError.prepareImageForMLFunctions(message: "Error: Could not change color space to sRGB."))
        }
        
    }

}
