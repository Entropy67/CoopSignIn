//
//  PopupInfoTableViewCell.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class PopupInfoTableViewCell: UITableViewCell {
    static let identifier = "PopupInfoTableViewCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        nameLabel.clipsToBounds = true
        valueLabel.clipsToBounds = true
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func config(key: String, value: String){
        nameLabel.text = key
        nameLabel.textAlignment = .right
        valueLabel.text = value
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 0
        valueLabel.font = .systemFont(ofSize: 17)
        valueLabel.sizeToFit()
        valueLabel.lineBreakMode = .byWordWrapping
    }
    
}
