//
//  DJSetTimeVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/4/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class DJSetupSetTimeVC: UIViewController {
    
    var _session: Session!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load DJSetTime nib
        let nib = Bundle.main.loadNibNamed("DJSetTimeView", owner: self, options: nil)?.first as! DJSetTimeView
        nib.bounds = self.view.bounds
        nib.delegate = self
        view.addSubview(nib)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }

    @IBAction func unwindFromConfirmVC(segue: UIStoryboardSegue) {
        print(_session.sessionUid)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? DJConfirmInfoVC {
            if let session = sender as? Session {
                dest.session = session
            }
        }
    }
    
    func confirmationAlert(time: String) {
        let alert = UIAlertController(title: "Confirm Time", message: "Please confirm the selected date and time: \(time)", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Change", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "toConfirm", sender: self._session)
        }))
        
    
        present(alert, animated: true, completion: nil)
    }


}

extension DJSetupSetTimeVC: DJSetTimeDelegate {
    
    func addTimeBtnTapped(selectedDate date: Date) {
     
        guard _session != nil else {return}
        
        //Add time of session to _session
        _session.startTime = Timestamp(date: date)
        //Present alert
        confirmationAlert(time: FormatDate.shared.getString(date))
    }
}
