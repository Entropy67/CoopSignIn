//
//  CrewCollectionViewCell.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/22/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class CrewCollectionViewCell: UICollectionViewCell {
    
    static public let  identifier = "CrewCollectionViewCell"
    
    public var textLabel: UILabel = {
        let label = UILabel()
        
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 10
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(textLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = bounds
    }
    
    func config(crew:Crew, selectedCrew: String){
        
        textLabel.text = crew.name
        if selectedCrew == crew.name{
            textLabel.textColor = MyColor.first_text_color
            textLabel.backgroundColor = MyColor.first_color
        }else{
            textLabel.textColor = MyColor.second_text_color
            textLabel.backgroundColor = MyColor.second_color
        }
        
    }
}
