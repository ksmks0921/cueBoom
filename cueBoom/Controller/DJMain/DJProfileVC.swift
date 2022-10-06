//
//  DJProfileVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit


class DJProfileVC: UIViewController,UINavigationControllerDelegate {
    
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var profileImgV: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var facebookNameField: UITextField!
    @IBOutlet weak var instagramHandleField: UITextField!
    @IBOutlet weak var twitterHandleField: UITextField!
    @IBOutlet weak var inputLine1: UIView!
    @IBOutlet weak var inputLine2: UIView!
    @IBOutlet weak var inputLine3: UIView!
    @IBOutlet weak var inputLine4: UIView!

    var imagePicker: UIImagePickerController!
    var currentlySelectedCat: musicCategory?
        
    @IBOutlet weak var electronicButton: RoundedButton!
    @IBOutlet weak var rbButton: RoundedButton!
    @IBOutlet weak var popButton: RoundedButton!
    @IBOutlet weak var rockButton: RoundedButton!
    @IBOutlet weak var hiphopButton: RoundedButton!
    @IBOutlet weak var countryButton: RoundedButton!
    
    enum CurrentState {
        case editing
        case notEditing
    }
   
    var inputLines = [UIView]()
    var textFields = [UITextField]()
    var rightItem = UIBarButtonItem()
    let bold: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font : UIFont(name: "MavenProBold", size: 24) as Any, NSAttributedString.Key.foregroundColor: UIColor.white]

    let notBold: [NSAttributedString.Key: Any]  = [NSAttributedString.Key.font : UIFont(name: "MavenProRegular", size: 24) as Any, NSAttributedString.Key.foregroundColor: UIColor.white]
    var bool: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        //Text field delegates set in IB
        
        
        //Set input lines hidden initially
        inputLines = [inputLine1, inputLine2, inputLine3, inputLine4]
        setInputLinesToClear()
        textFields = [nameField, facebookNameField, twitterHandleField, instagramHandleField]
        disableTextFields()
        
      //  NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        self.electronicButton.backgroundColor = .lightGray
        self.rockButton.backgroundColor = .lightGray
        self.popButton.backgroundColor = .lightGray
        self.countryButton.backgroundColor = .lightGray
        self.hiphopButton.backgroundColor = .lightGray
        self.rbButton.backgroundColor = .lightGray
        
        self.instagramHandleField.delegate = self
        self.twitterHandleField.delegate = self
        
        //Get profile info and populate text field placeholders
        getProfileInfo()
        
        //Hide back button and implement custom back button with custom action
        navItem.hidesBackButton = true
        let backItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(backTapped))
        backItem.tintColor = UIColor.white
        navItem.leftBarButtonItem = backItem
        
        
        //Create right bar button item
        rightItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(rightBarButtonTapped))
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.white]
        rightItem.setTitleTextAttributes(attrs, for: .normal)
        rightItem.setTitleTextAttributes(attrs, for: .selected)
        navItem.rightBarButtonItem = rightItem //Set right bar button to "Edit" initially
        
        //Configure image picker
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self

        getProfileInfo()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func profilePicTapped(_ sender: Any) {
        guard let title = navItem.rightBarButtonItem?.title, title == "Save" else {return} //Can only upload images in "Edit" mode === title is "Save"
        present(imagePicker, animated: true)
    }
    
    @objc func rightBarButtonTapped() {
        guard let title = navItem.rightBarButtonItem?.title else {return}
        
        if title == "Edit" {
            navItem.rightBarButtonItem?.title = "Save"
            setInputLinesToWhite()
            enableTextFields()
        } else {
            navItem.rightBarButtonItem?.title = "Edit"
            setInputLinesToClear()
            disableTextFields()
            updateInfo()
        }
    }
    
    @objc func backTapped() {
        //TODO: this needs to be an enum
        if rightItem.title == "Edit" { //Not editing -> pop
            navigationController?.popViewController(animated: true)
        } else {
            goBackAlert()
        }
    }
    
    func goBackAlert() {
        let alert = UIAlertController(title: "Go Back?", message: "You will lose any unsaved information.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
           self.navigationController?.popViewController(animated: true)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func updateInfo() {
        guard let name = nameField.text, let fbName = facebookNameField.text, let igHandle = instagramHandleField.text, let twitterHandle = twitterHandleField.text else {return}
    
        UserDefaults.standard.set(name, forKey: DJ_NAME) //Add DJ name to user defaults
        
        var data = [String:Any]()
        
        let group = DispatchGroup()
        group.enter()
        
        if let img = profileImgV.image {
            StorageService.shared.upload(image: img, uid: userService.shared.uid) { url in
                data["djImgUrl"] = url
                ImageService.shared.cacheImg(img: img, url: url)
                UserDefaults.standard.set(url, forKey: DJ_IMG_URL)
                group.leave()
            }
        } else {
            data["djImgUrl"] = ""
            group.leave()
        }

        group.notify(queue: .main) {
            
            if self.currentlySelectedCat != nil {
                data["musicCat"] = self.currentlySelectedCat!.rawValue
            }
            
            data["name"] = name
            data["facebookName"] = fbName
            data["instagramHandle"] = igHandle
            data["twitterHandle"] = twitterHandle
            
            FirestoreService.shared.addDjPublicData(data) { (success) in
                guard success == true else {
                    //TODO: handle error
                    return
                }
            }
        }
    }
    
    
    //Get profile information and use it to populate text field placeholders
    //TODO: split this function up
    func getProfileInfo() {
        print(FirestoreService.shared.REF_CURRENT_DJ_PUBLIC.documentID)
        FirestoreService.shared.getDocumentData(ref: FirestoreService.shared.REF_CURRENT_DJ_PUBLIC) { (data) in
            guard let data = data else {
                return
            }
            
            let profile = DjProfile(profileData: data, uid: userService.shared.uid)
            
            if profile.musicType != nil {
                self.resetButtons(buttonCat: profile.musicType!)
            }
            
            self.nameField.text = profile.name
            self.facebookNameField.text = profile.facebookName
            self.instagramHandleField.text = profile.instagramHandle
            self.twitterHandleField.text = profile.twitterHandle
            
            if profile.djImgUrl == "" { return }
            
            if profile.djImgUrl != nil {
                StorageService.shared.download(url: profile.djImgUrl!) { image in
                    if let image = image {
                        self.profileImgV.image = image
                    }
                }
            }
        }
    }
    
    func resetButtons(buttonCat: musicCategory) {
        switch buttonCat {
            
            case .RB:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hiphopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = TEALISH
            case .country:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = TEALISH
                self.hiphopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            case .electronic:
                self.electronicButton.backgroundColor = TEALISH
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hiphopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            case .hiphop:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hiphopButton.backgroundColor = TEALISH
                self.rbButton.backgroundColor = .lightGray
            case .pop:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = .lightGray
                self.popButton.backgroundColor = TEALISH
                self.countryButton.backgroundColor = .lightGray
                self.hiphopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray
            case .rock:
                self.electronicButton.backgroundColor = .lightGray
                self.rockButton.backgroundColor = TEALISH
                self.popButton.backgroundColor = .lightGray
                self.countryButton.backgroundColor = .lightGray
                self.hiphopButton.backgroundColor = .lightGray
                self.rbButton.backgroundColor = .lightGray

        }
    }
    
    func disableTextFields() {
        self.electronicButton.isEnabled = false
        self.rockButton.isEnabled = false
        self.popButton.isEnabled = false
        self.countryButton.isEnabled = false
        self.hiphopButton.isEnabled = false
        self.rbButton.isEnabled = false
        
        for field in textFields {
            field.isEnabled = false
        }
    }
    
    func enableTextFields() {
        self.electronicButton.isEnabled = true
        self.rockButton.isEnabled = true
        self.popButton.isEnabled = true
        self.countryButton.isEnabled = true
        self.hiphopButton.isEnabled = true
        self.rbButton.isEnabled = true
        
        for field in textFields {
            field.isEnabled = true
        }
    }
    
    func setInputLinesToClear() {
        for line in inputLines {
            line.backgroundColor = UIColor.clear
        }
    }
    
    func setInputLinesToWhite() {
        for line in inputLines {
            line.backgroundColor = UIColor.white
        }
    }
    
    @IBAction func rockTapped(_ sender: Any) {
        self.currentlySelectedCat = .rock
        resetButtons(buttonCat: .rock)
    }
    
    @IBAction func hiphopTapped(_ sender: Any) {
        self.currentlySelectedCat = .hiphop
        resetButtons(buttonCat: .hiphop)
    }
    
    @IBAction func countryTapped(_ sender: Any) {
        self.currentlySelectedCat = .country
        resetButtons(buttonCat: .country)
    }
    
    @IBAction func popTapped(_ sender: Any) {
        self.currentlySelectedCat = .pop
        resetButtons(buttonCat: .pop)
    }
    
    @IBAction func electronicTapped(_ sender: Any) {
        self.currentlySelectedCat = .electronic
        resetButtons(buttonCat: .electronic)
    }
    
    @IBAction func rbTapped(_ sender: Any) {
        self.currentlySelectedCat = .RB
        resetButtons(buttonCat: .RB)
    }
    
}

//MARK: - UIImagePickerControllerDelegate
extension DJProfileVC: UIImagePickerControllerDelegate {
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage {
            profileImgV.image = image
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            profileImgV.image = image
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension DJProfileVC: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -150)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        UIView.animate(withDuration: 0.25) {
            self.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
}
