//
//  FaceImage.swift
//  Travellout
//
//  Created by Nicklas Körtge on 30.07.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit


class FaceImage {
    private var image : UIImage?
    private var headEulerAngleZ: CGFloat
    
    init (imageOfFace: UIImage, headEulerAngleZ: CGFloat) {
        self.image = imageOfFace
        self.headEulerAngleZ = headEulerAngleZ
    }
    
    func getAligendImage() -> UIImage? {
        let rotatedImage = self.image?.rotate(radians: headEulerAngleZ)
        let resizedImage =  rotatedImage?.resizeImage(targetSize: CGSize(width: 160, height: 160))
        return resizedImage
    }
    
    func getUIImageReference() -> UIImage? {
        return image
    }
    
}
