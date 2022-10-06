//
//  UserConfirmInfoVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/1/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class UserConfirmInfoVC: UIViewController {
    
    private var _session: Session!
    var session: Session {
        get {
            return _session
        } set {
            _session = newValue
        }
    }
    
    enum backSegue: String {
        case dj = "dj"
        case venue = "venue"
    }
    
    @IBOutlet weak var venueLbl: UILabel!
    @IBOutlet weak var djLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if _session != nil {
            venueLbl.text = _session.venueName
            djLbl.text = _session.djName
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }
    
    @IBAction func confirmInfoBtnTapped(_ sender: Any) {
        guard _session != nil else {return}
        let data: [String:Any] = ["currentSessionId": _session.sessionUid]
        
        //MARK: TERMINATING ERROR
        //uid is not going through on that REF_CURRENT_USER_PRIVATE and so it can't request doc
        FirestoreService.shared.setData(document: FirestoreService.shared.REF_CURRENT_USER_PRIVATE, data: data) {
            userService.shared.currentSession = self.session
            self.performSegue(withIdentifier: "toMain", sender: self._session)
        }
    }
    
    @IBAction func venueViewTapped(_ sender: Any) {
        goBackAlert(backSegue: .venue)
    }
    
    @IBAction func djViewTapped(_ sender: Any) {
        goBackAlert(backSegue: .dj)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? RequestVC else {return}
        guard let session = sender as? Session else {return}
        dest.modalPresentationStyle = .fullScreen
        self.present(dest, animated: true)
    }
    
    func goBackAlert(backSegue: backSegue) {
        let alert = UIAlertController(title: "Go Back?", message: "You will lose any unsaved information.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            switch backSegue {
            case .dj:
                self.performSegue(withIdentifier: "backToDJ", sender: self)
                break
            case .venue:
                for vc in self.navigationController!.viewControllers {
                    if vc.isKind(of: UserFindVenueVC.self) {
                        self.navigationController?.popToViewController(vc, animated: true)
                    }
                }
                break
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
}
