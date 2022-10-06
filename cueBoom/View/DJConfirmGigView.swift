//
//  ConfirmGigView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

enum BackSegue: String {
    case time = "time"
    case venue = "venue"
}

protocol ConfirmGigDelegate {
    func venueTapped(segue: BackSegue)
    func dateTimeTapped(segue: BackSegue)
    func addGigTapped(eventDetails: String?)
    func toggledOnline(online: Bool)
}

class DJConfirmGigView: UIView, UITextFieldDelegate {

    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var dateTimeLbl: UILabel!
    @IBOutlet weak var confirmBtn: RoundedButton!
    @IBOutlet weak var onlineToggle: UISwitch!
    
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var onlineInfoField: CustomTextField!
    @IBOutlet weak var bottomLineLbl: UIView!
    
    var delegate: ConfirmGigDelegate!
    var currentView: UIViewController?
    
    func configureView(session: Session) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing))
        self.addGestureRecognizer(tapGesture)
        
        venueNameLbl.text = session.venueName
        var dateTime = session.startTime.dateValue() 
        dateTimeLbl.text = dateTime.getCustomTimeString()
    }
    
    @IBAction func venueTapped(_ sender: Any) {
        delegate.venueTapped(segue: .venue)
    }
    
    @IBAction func dateTimeTapped(_ sender: Any) {
        delegate.dateTimeTapped(segue: .time)
    }
    
    @IBAction func addGigBtnTapped() {
        guard onlineInfoField.text != nil && onlineInfoField.text != "" else {
            delegate.addGigTapped(eventDetails: nil)
            return
        }
        
        delegate.addGigTapped(eventDetails: self.onlineInfoField.text)
    }
    
    @IBAction func onlineToggled(_ sender: Any) {
        delegate.toggledOnline(online: self.onlineToggle.isOn)
        
        if self.onlineToggle.isOn == true {
            UIView.animate(withDuration: 0.5) {
                self.instructionsLabel.transform = CGAffineTransform(translationX: 0, y: 200)
                self.instructionsLabel.alpha = 0
                self.onlineInfoField.alpha = 1
                self.bottomLineLbl.alpha = 1
            }
        } else if self.onlineToggle.isOn == false {
            UIView.animate(withDuration: 0.5) {
                self.instructionsLabel.transform = CGAffineTransform(translationX: 0, y: 0)
                self.instructionsLabel.alpha = 1
                self.onlineInfoField.alpha = 0
                self.bottomLineLbl.alpha = 0
            }
        }
    }
    
    @IBAction func questionTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Online Event", message: "Online events can be seen by anyone around the United States. They can be hosted on online platforms, just let your fans know where to find you! (Example: 'Find me on insta live @YOURUSERNAME')", preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default, handler: nil)
        
        alert.addAction(closeAction)
        self.currentView?.present(alert, animated: true)
    }
}
