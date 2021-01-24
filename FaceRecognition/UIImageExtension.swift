//
//  UIImageExtension.swift
//  Travellout
//
//  Created by Nicklas Körtge on 24.07.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func ConvertImageToRGBColorMode() -> UIImage?{
        let cgi = self.cgImage!
        let cgirgb = cgi.copy(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
        return UIImage(cgImage: cgirgb!)
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: Int(round(size.width * widthRatio)), height: Int(round(size.height * heightRatio)))
        } else {
           newSize = CGSize(width: Int(round(size.width * widthRatio)), height: Int(round(size.height * heightRatio)))
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }
    
}
