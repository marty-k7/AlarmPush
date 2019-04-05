//
//  AlarmViewController.swift
//  AlarmPush
//
//  Created by Martynas Klastaitis  on 02/04/2019.
//  Copyright © 2019 bajoraiciuprodukcija. All rights reserved.
//

import UIKit


class AlarmViewController: UITableViewController, UIImagePickerControllerDelegate {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var caption: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tapToSelectImage: UILabel!
    
    var alarm: Alarm!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = alarm.name
        name.text = alarm.name
        caption.text = alarm.caption
        datePicker.date = alarm.time
        
        if alarm.image.count > 0 {
            // if we have an image, try to load it
            let imageFilename = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            imageView.image = UIImage(contentsOfFile: imageFilename.path)
            tapToSelectImage.isHidden = true
        }
        
    }
    
   
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        alarm.time = datePicker.date
        save()
    }
    //MARK: - Image uplaoding
    
    @IBAction func imageViewTapped(_ sender: UIImageView) {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        present(vc, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //dismiss the image picker
        dismiss(animated: true)
        //fetch the image that was picker
        guard let img = info[.originalImage] as? UIImage else {return}
        let fm = FileManager()
        if alarm.image.count > 0 {
            //the alarm already has an image, so delete it
            do {
                let currentImg = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
                if fm.fileExists(atPath: currentImg.path) {
                    try fm.removeItem(at: currentImg)
                }
                } catch {
                    print("Failed to remove current image")
                }
            }
        do {
            //generate a new filename for the image
            alarm.image = "\(UUID().uuidString).jpg"
            //write the new image to the documents directory
            let newPatch = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            let jpeg = img.jpegData(compressionQuality: 0.8)
            try jpeg?.write(to: newPatch)
            save()
        } catch {
            print("Fialed to save new image")
        }
        imageView.image = img
        tapToSelectImage.isHidden = true
    }
    
    @objc func save() {
        NotificationCenter.default.post(name: Notification.Name("save"), object: nil)
    }

   
}
//MARK: - TextFieldDelegate methods

extension AlarmViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        alarm.name = name.text!
        alarm.caption = caption.text!
        title = alarm.name
        save()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension AlarmViewController: UINavigationControllerDelegate {
    
}
