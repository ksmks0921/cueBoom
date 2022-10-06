//
//  customSearchBar.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/11/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class CustomSearchBar: UISearchBar {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        customizeSearchBar()
    
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        customizeSearchBar()
    }
    
    @objc func doneBtnTapped() {
        resignFirstResponder()
        showsCancelButton = false
    }
    
    func customizeSearchBar() {
        //Add "Done" toolbar item above keyboard
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let doneBtn = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneBtnTapped))
        toolBar.setItems([flexibleSpace, doneBtn], animated: true)
        inputAccessoryView = toolBar
        
        //Remove gray background
        backgroundImage = UIImage()
        
        
        if let textField = value(forKey: "searchField") as? UITextField {
            //Round search bar text field border
            textField.layer.cornerRadius = 15
            //Add border around search bar text field
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = UIColor.black.cgColor
            //Search bar text field font
            textField.font = UIFont(name: "Roboto", size: 17)
            //Text field cursor color
            textField.tintColor = UIColor.black
            
        }
                
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
