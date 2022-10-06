//
//  DJSetupProfileVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/3/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJSetupProfileVC: UIViewController,UINavigationControllerDelegate {
    
    @IBOutlet weak var facebookNameField: UITextField!
    @IBOutlet weak var instagramHandleField: UITextField!
    @IBOutlet weak var twitterHandleField: UITextField!
    @IBOutlet weak var profileImgV: UIImageView!

    //Cat Buttons
    @IBOutlet weak var rockButton: RoundedButton!
    @IBOutlet weak var hipHopButton: RoundedButton!
    @IBOutlet weak var countryButton: RoundedButton!
    @IBOutlet weak var rbButton: RoundedButton!
    @IBOutlet weak var electronicButton: RoundedButton!
    @IBOutlet weak var popButton: RoundedButton!
    
    var catButtons: [UIButton]?
    var imagePicker: UIImagePickerController!
    private var currentlySelectedCat: musicCategory?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.catButtons = [rockButton, hipHopButton, countryButton, rbButton, electronicButton, popButton]
        
        //"Done" button above keyboard
        let title = "Done"
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(doneTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        doneButton.tintColor = UIColor.blue
        toolBar.setItems([flexibleSpace, doneButton], animated: true)
        facebookNameField.inputAccessoryView = toolBar
        instagramHandleField.inputAccessoryView = toolBar
        twitterHandleField.inputAccessoryView = toolBar
        
        //Configure image picker
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func imgUploadTap(_ sender: UITapGestureRecognizer) {
        present(imagePicker, animated: true)
    }
    
    @IBAction func addProfileBtnTapped(_ sender: Any) {
        guard let profileImg = profileImgV.image else {
            Alerts.shared.ok(viewController: self, title: "Profile Picture", message: "Upload a picture to continue.")
            return
        }
        
        guard self.currentlySelectedCat != nil else {
            Alerts.shared.ok(viewController: self, title: "Music Genre", message: "Please pick a genre to continue.")
            return
        }
        
        var data = [String:Any]()
        
        let group = DispatchGroup()
        group.enter()
        
        StorageService.shared.upload(image: profileImg, uid: userService.shared.uid) { url in
            data["djImgUrl"] = url
            
            //UPDATE FIREBASE WITH URL
            let urlData = ["djImgUrl" : url]
            FirestoreService.shared.setData(document: FirestoreService.shared.REF_CURRENT_DJ_PUBLIC, data: urlData) {
                print("HEHE")
            }
            
            ImageService.shared.cacheImg(img: profileImg, url: url)
            UserDefaults.standard.set(url, forKey: DJ_IMG_URL)
            group.leave()
        }
        
        group.notify(queue: .main) {
            
            let fbName = self.facebookNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let igHandle = self.instagramHandleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let twitterHandle = self.twitterHandleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            data["facebookName"] = fbName
            data["instagramHandle"] = igHandle
            data["twitterHandle"] = twitterHandle
            data["musicCat"] = self.currentlySelectedCat!.rawValue
            
            FirestoreService.shared.addDjPublicData(data) { (success) in
                guard success == true else {
                    //TODO: handle error
                    return
                }
                
                USER_DEFAULTS.set(true, forKey: DID_COMPLETE_DJ_ONBOARDING)
                
                self.performSegue(withIdentifier: "toAddGig", sender: nil)
            }
        }
    }
    
    @objc func doneTapped() {
        view.endEditing(true)
    }
    
    @IBAction func rockTapped(_ sender: Any) {
        self.currentlySelectedCat = musicCategory.rock
        resetButtons(buttonCat: .rock)
    }
    
    @IBAction func hipHopTapped(_ sender: Any) {
        self.currentlySelectedCat = musicCategory.hiphop
        resetButtons(buttonCat: .hiphop)
    }
    
    @IBAction func countryTapped(_ sender: Any) {
        self.currentlySelectedCat = musicCategory.country
        resetButtons(buttonCat: .country)
    }
    
    @IBAction func rbTapped(_ sender: Any) {
        self.currentlySelectedCat = musicCategory.RB
        resetButtons(buttonCat: .RB)
    }
    
    @IBAction func electronicTapped(_ sender: Any) {
        self.currentlySelectedCat = musicCategory.electronic
        resetButtons(buttonCat: .electronic)
    }
    
    @IBAction func popTapped(_ sender: Any) {
        self.currentlySelectedCat = musicCategory.pop
        resetButtons(buttonCat: .pop)
    }
    
    func resetButtons(buttonCat: musicCategory) {
        switch buttonCat {
            case .RB:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hipHopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = TEALISH
            case .country:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = TEALISH
                self.hipHopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            case .electronic:
                self.electronicButton.backgroundColor = TEALISH
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hipHopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            case .hiphop:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hipHopButton.backgroundColor = TEALISH
                self.rbButton.backgroundColor = .lightGray
            case .pop:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = TEALISH
                self.countryButton.backgroundColor = .lightGray
                self.hipHopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            case .rock:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = TEALISH
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hipHopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            default:
                print("broken")
        }
    }
    
}

//MARK: - UIImagePickerControllerDelegate
extension DJSetupProfileVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage {
            profileImgV.image = image
            imagePicker.dismiss(animated: true, completion: nil)
        } else {
            print("ERROR")
            return
        }
    }
}
