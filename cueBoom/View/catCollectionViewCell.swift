//
//  catCollectionViewCell.swift
//  cueBoom
//
//  Created by Charles Oxendine on 9/6/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit

class catCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroundIMG: UIImageView!
    @IBOutlet weak var catLbl: UILabel!
    
    func setCell(cat: musicCategory, img: UIImage) {
        self.backgroundIMG.image = img
        setView()
        
        switch cat {
        
            case .rock:
                self.catLbl.text = "Rock"
            case .pop:
                self.catLbl.text = "Pop"
            case .hiphop:
                self.catLbl.text = "Hip Hop"
            case .electronic:
                self.catLbl.text = "Electronic"
            case .RB:
                self.catLbl.text = "R&B"
            case .country:
                self.catLbl.text = "Country"
            
        }
    }
    
    func setView() {
    }
    
}

enum musicCategory: Int {
    
    case rock
    case pop
    case hiphop
    case country
    case electronic
    case RB //R&B
    
}
