//
//  AddNewShiftCollectionViewCell.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 4/11/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class AddNewShiftCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "AddNewShiftCollectionViewCell"
    
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        //imageView.backgroundColor = .yellow
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "plus.circle")
        imageView.tintColor = .systemGray5
        return imageView
    }()
    
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a new shift"
        //label.backgroundColor = .green
        label.textAlignment = .center
        label.clipsToBounds  = true
        label.font = label.font.withSize(18)
        return label
    }()
    
    private let typeLabel : UILabel = {
        let label = UILabel()
        label.text = "openings"
        label.textAlignment = .center
        label.clipsToBounds  = true
        label.font = label.font.withSize(15)
        return label
    }()
    
    private let statusLabel : UILabel = {
        let label = UILabel()
        label.text = "NO CREDIT AVAILABLE"
        label.textAlignment = .center
        label.clipsToBounds  = true
        label.font = label.font.withSize(15)
        return label
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .clear
        contentView.addSubview(nameLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(typeLabel)
        contentView.addSubview(statusLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconImageView.frame = CGRect(x: contentView.frame.size.width / 3,
                                     y: 50,
                                     width: contentView.frame.size.width / 3,
                                     height: contentView.frame.size.width / 3)
        
        nameLabel.frame = CGRect(x: 5, y: contentView.frame.size.height - 100, width: contentView.frame.size.width - 10, height: 40)
        
        typeLabel.frame = CGRect(x: 5, y: contentView.frame.size.height - 60, width: contentView.frame.size.width - 10, height: 20)
        
        statusLabel.frame = CGRect(x: 5, y: (contentView.frame.size.height - 20) / 2, width: contentView.frame.size.width - 10, height: 20)
    }
    
    public func configure(openings: Int){
        nameLabel.text = "Add a new shift"
        iconImageView.isHidden = false
        statusLabel.isHidden = true
        switch openings{
        case 0:
            typeLabel.text = "NO CREDIT AVAILABLE"
        case 1:
            typeLabel.text = "\(openings) credit shift available"
        default:
            typeLabel.text = "\(openings) credit shifts available"
        }
        
    }
    
    
}
