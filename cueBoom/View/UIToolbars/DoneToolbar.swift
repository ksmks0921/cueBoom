//
//  DoneToolbar.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/7/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//
import UIKit

protocol DoneToolbarDelegate {
    func doneTapped()
}

class DoneToolbar: UIToolbar {
    
    var doneToolbarDelegate: DoneToolbarDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        print(action)
        
        self.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
    
        self.setItems([flexibleSpace, doneBtn], animated: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func doneTapped() {
        doneToolbarDelegate?.doneTapped()
    }
    
}
