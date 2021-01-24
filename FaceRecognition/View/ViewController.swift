//
//  ViewController.swift
//  FaceRecognition
//
//  Created by Nicklas Körtge on 20.12.20.
//

import UIKit
import PhotosUI

class ViewController: UIViewController, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var CollectionViewForDetectedPersons: UICollectionView!
    
    let facerecognisor = MLFaceRecognisor.shared
    let coreDataController = CoreDataStorageController<Persons>()
    
    var knownPersons : [Persons] = [Persons]()
    var detectedPersons: [FluctuatingPersonReference] = [FluctuatingPersonReference]()
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Loading known Persones form Database
        if let persons = coreDataController.loadData() as? [Persons] {
            self.knownPersons = persons
        }
        
        self.CollectionViewForDetectedPersons.register(DetectedPersonCollectionViewCell.nib(), forCellWithReuseIdentifier: DetectedPersonCollectionViewCell.identifier())
        self.CollectionViewForDetectedPersons.delegate = self
        self.CollectionViewForDetectedPersons.dataSource = self
        
    }
    
    @IBAction func DetectFacesButtonTapped(_ sender: Any) {
        if let image = self.image {
            self.facerecognisor.detectPersonsFromImage(image: image) { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let detectedPersons):
                    self.detectedPersons = detectedPersons
                    self.CollectionViewForDetectedPersons.reloadData()
                }
            }
        }
        
    }
    
    
    @IBAction func ChooseImageButtonTapped(_ sender: Any) {
        self.selectImageFromLibrary()
    }
    
    func selectImageFromLibrary() {
        if #available(iOS 14, *) {
            let phImagePicker : PHPickerViewController = {
                var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
                config.filter = .images
                config.selectionLimit = 1
                let controller = PHPickerViewController(configuration: config)
                controller.delegate = self
                return controller
            }()
            phImagePicker.delegate = self
            present(phImagePicker, animated: true, completion: nil)
        } else {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - CollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return DetectedPersonCollectionViewCell.getSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return detectedPersons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetectedPersonCollectionViewCell.identifier(), for: indexPath) as! DetectedPersonCollectionViewCell
        
        let name = detectedPersons[indexPath.row].name!
        let image = detectedPersons[indexPath.row].faceImage!.getUIImageReference()!
        
        cell.configure(image: image, name: name)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Type in new Name:", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Input the name here..."
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let name = alert.textFields?.first?.text {
                if let index = self.knownPersons.firstIndex(where: { $0.name == name }) {
                    let selectedPerson = self.detectedPersons[indexPath.row]
                    let existingPerson = self.knownPersons[index]
                    if let newFaceCode = MLFaceRecognisor.faceCodeCombination(baseFaceCode: existingPerson.faceCode!, newFaceCode: selectedPerson.faceCode!) {
                        existingPerson.faceCode = newFaceCode
                    }
                    self.detectedPersons[indexPath.row] = existingPerson.createFluctuatingReference()
                } else {
                    let person = self.detectedPersons[indexPath.row]
                    person.name = name
                    person.makePersistent()
                }
                
                do {
                    try self.coreDataController.saveData()
                } catch let error {
                    print(error)
                }
                
                self.CollectionViewForDetectedPersons.reloadItems(at: [indexPath])
            }
        }))
        self.present(alert, animated: true)
    }
    
}


@available(iOS 13, *)
extension ViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.image = pickedImage
            self.imageView.image = self.image
            dismiss(animated: true, completion: nil)
        } else{
            dismiss(animated: true, completion: nil)
        }
    }
        
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

@available(iOS 14, *)
extension ViewController : PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            return
        }
        
        let imageResult = results[0]
        
        if imageResult.itemProvider.canLoadObject(ofClass: UIImage.self) {
            imageResult.itemProvider.loadObject(ofClass: UIImage.self) { (selectedImage, error) in
                DispatchQueue.main.sync {
                    self.image = selectedImage as? UIImage
                    self.imageView.image = self.image
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            DispatchQueue.main.sync {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

