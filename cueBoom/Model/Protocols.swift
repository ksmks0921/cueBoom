//
//  Protocols.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

protocol GigCellDelegate {
    func editBtnTapped(session: Session)
}

protocol DjMapDelegate {
    func didSelectVenue(session: Session)
    func didGetSessions(_ sessions: [Session])
}

protocol NibLoadable {}
import UIKit
extension NibLoadable {
    func addNib(nibName: String, vc: UIViewController, frame: CGRect) -> UIView {
        let nib = Bundle.main.loadNibNamed(nibName, owner: vc, options: nil)?.first as! UIView
        nib.frame = frame
        vc.view.addSubview(nib)
        return nib
    }
}


