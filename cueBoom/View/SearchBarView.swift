//
//  SearchBarView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/21/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class SearchBarView: UIView {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var view: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
  
        
        //Remove gray background
        searchBar.backgroundImage = UIImage()
        
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
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

}
