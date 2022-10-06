//
//  DJSetTimeView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

protocol DJSetTimeDelegate {
    func addTimeBtnTapped(selectedDate date: Date)
}

//UIView subclass for all screens where DJ must select time of a gig
class DJSetTimeView: UIView {

    @IBOutlet weak var picker: UIDatePicker!
    @IBOutlet weak var confirmBtn: RoundedButton!
    
    var delegate: DJSetTimeDelegate?
    
    override func awakeFromNib() {
        picker.minimumDate = Date()
    }

    
    @IBAction func addTimeBtnTapped(_ sender: Any) {
        //THIS IS RUNNING AND KILLING FUNCTION
        guard delegate != nil else {
            print("delegate is nil")
            return
        }
        
        guard picker != nil else {
            print("picker nil")
            return
        }
        
        let gigDate = picker.date
        print(picker.date.description)
        delegate?.addTimeBtnTapped(selectedDate: gigDate)
    }
}
