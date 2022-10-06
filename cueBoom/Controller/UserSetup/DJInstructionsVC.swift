//
//  DJInstructionsVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/30/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJInstructionsVC: UIViewController {

    private var _venueName: String!
    var venueName: String {
        get {
            return _venueName
        } set {
            _venueName = newValue
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }

    @IBAction func findDJBtnTapped(_ sender: Any) {
        guard _venueName != nil else {return}
        
        performSegue(withIdentifier: "toFindDJ", sender: _venueName)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FindDJVC {
            if let venueName = sender as? String {
                destination.venueName = venueName
            }
        }
    }
  

}
