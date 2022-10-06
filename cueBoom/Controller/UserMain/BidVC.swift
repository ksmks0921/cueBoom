//
//  BidVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper
import FirebaseFirestore
import FirebaseAuth

class BidVC: UIViewController {
    
    @IBOutlet weak var songTitleLbl: UILabel!
    @IBOutlet weak var artistNameLbl: UILabel!
    @IBOutlet weak var bidField: UITextField!
    @IBOutlet weak var albumArtIV: UIImageView!
    
    var picker: UIPickerView!
    let pickerData = ["2", "3", "4", "5", "6", "7", "8", "9", "10"]
    
    private var _dataFromRequestVC: [Any]!
    public var dataFromRequestVC: [Any] {
        get {
            return _dataFromRequestVC
        } set {
            _dataFromRequestVC = newValue
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        bidField.inputView = picker
        
        let doneToolbar = DoneToolbar(frame: CGRect())
        doneToolbar.doneToolbarDelegate = self
        bidField.inputAccessoryView = doneToolbar
        
        
        
        if let song = _dataFromRequestVC[1] as? Song {
            songTitleLbl.text = song.songTitle
            artistNameLbl.text = song.artistName
            
            if let img = ImageService.shared.pullFromCache(url: song.albumArtUrl) {
                albumArtIV.image = img
            } else {
                ImageService.shared.downloadAlbumArt(url: song.albumArtUrl) { img in
                    DispatchQueue.main.async {
                        self.albumArtIV.image = img
                    }
                }
            }
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bidField.text = "2"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        bidField.resignFirstResponder()
    }
    
    
    @IBAction func confirmBtnTapped() {
        
        guard let confirmRequest = _dataFromRequestVC[0] as? ((Double, @escaping() -> Void) -> Void) else {return}
        guard let bidStr = bidField.text else {return}
        guard let bid = Double(bidStr) else {return}

        confirmRequest(bid) {
            self.performSegue(withIdentifier: "unwindFromBidVCToRequestVC", sender: nil)
        }
        
    }

}

extension BidVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
}

extension BidVC: DoneToolbarDelegate {
    
    func doneTapped() {
        bidField.resignFirstResponder()
        bidField.text = pickerData[picker.selectedRow(inComponent: 0)]
    }
}



