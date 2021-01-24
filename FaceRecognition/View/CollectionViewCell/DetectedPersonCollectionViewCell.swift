//
//  DetectedPersonCollectionViewCell.swift
//  FaceRecognition
//
//  Created by Nicklas Körtge on 20.12.20.
//

import UIKit

class DetectedPersonCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ImageOfPerson: UIImageView!
    @IBOutlet weak var NameOfPerson: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.ImageOfPerson.layer.cornerRadius = self.ImageOfPerson.frame.size.width / 2
        self.ImageOfPerson.clipsToBounds = true
    }
    
    public func configure(image: UIImage, name: String) {
        self.ImageOfPerson.image = image
        self.NameOfPerson.text = name
    }
    
    static func nib() -> UINib {
        return UINib(nibName: "DetectedPersonCollectionViewCell", bundle: nil)
    }
    
    static func identifier() -> String {
        return "DetectedPersonCollectionViewCell"
    }
    
    public static func getSize() -> CGSize {
        return CGSize(width: 100, height: 120)
    }

}
