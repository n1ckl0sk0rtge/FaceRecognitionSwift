//
//  ImagePickerController.swift
//  Travellout
//
//  Created by Nicklas Körtge on 01.11.20.
//  Copyright © 2020 Nicklas Körtge. All rights reserved.
//

import Foundation
import UIKit
import PhotosUI

class ImagePickerControllerDelegator : NSObject {
    
    
}

@available(iOS 13, *)
extension ImagePickerControllerDelegator : UIImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        <#code#>
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        <#code#>
    }
    
}

@available(iOS 14, *)
extension ImagePickerControllerDelegator : PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        <#code#>
    }
    
    
}
