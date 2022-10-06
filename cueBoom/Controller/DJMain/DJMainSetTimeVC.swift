//
//  DJMainSetTimeVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class DJMainSetTimeVC: UIViewController {
    
    var _session: Session!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Load DJSetTime nib
        let nib = Bundle.main.loadNibNamed("DJSetTimeView", owner: self, options: nil)?.first as! DJSetTimeView
        nib.frame = view.frame
        nib.delegate = self
        view.addSubview(nib)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.customMakeOpaque()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        navigationController?.customMakeTranslucent()
//    }
    
    
    func confirmationAlert(time: String) {
        let alert = UIAlertController(title: "Confirm Time", message: "Please confirm the selected date and time: \(time)", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Change", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            print("Time confirmed")
            self.performSegue(withIdentifier: "toConfirm", sender: self._session)
            
        }))
        
        
        present(alert, animated: true, completion: nil)
    }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let dest = segue.destination as? DJMainConfirmGigVC {
                if let session = sender as? Session {
                    print("DATE: \(session.startTime.description)")
                    dest._session = session
                }
            }
        }
    
}

extension DJMainSetTimeVC: DJSetTimeDelegate {
    func addTimeBtnTapped(selectedDate date: Date) {
        guard _session != nil else {
            return
        }

        //Add start time of session to _session
        _session.startTime = Timestamp(date: date) // MARK: _session is nil but this code still runs?
        let endTime = date.addingTimeInterval(TimeInterval(43200))
        _session.endTime = Timestamp(date: endTime)
        //Present alert
        confirmationAlert(time: FormatDate.shared.getString(date))
    }
}
