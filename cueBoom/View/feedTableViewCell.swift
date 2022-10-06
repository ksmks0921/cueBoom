//
//  feedTableViewCell.swift
//  cueBoom
//
//  Created by Charles Oxendine on 7/22/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseStorage

final class feedTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var djNameLbl: UILabel!
    @IBOutlet weak var eventInfoLbl: UILabel!
    
    var currentSession: Session?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setCell(session: Session) {
        self.djNameLbl.text = session.djName
        self.eventInfoLbl.text = session.eventInfo
        self.profileImage.layer.cornerRadius = self.profileImage.frame.height/2
        self.currentSession = session
        self.getImage()
    }
    
    private func getImage() {
        guard currentSession?.djUid != nil else { return }
        
        let storage = Storage.storage()
        storage.reference(withPath: currentSession!.djUid).getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print(error.localizedDescription)
                self.profileImage.image = CONSTANT.IMG_PLACEHOLDER
            } else {
                self.profileImage.image = UIImage(data: data!)
            }
        }
    }
    
}
