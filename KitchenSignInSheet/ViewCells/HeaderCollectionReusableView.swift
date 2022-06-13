//
//  HeaderCollectionReusableView.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class HeaderCollectionReusableView: UICollectionReusableView {
        
    
    static let identifier = "HeaderCollectionReusableView"
    
    
    let sectionTitleCompact = ["Morning",
                              "Afternoon"]
    
    let sectionTitleWeekday = [
            "Morning From 6:00 am To 10:00 am",
            "Noon From 10:00 am to 2:00 pm",
            "Afternoon From 2:00 pm to 6:00 pm",
            "Evening From 5:00 pm to 9:00 pm",
            "Other Time"
            ]
    
    let sectionTitleWeekend = [
            "Morning From 8:00 am To 12:00 pm",
            "Noon From 12:00 pm to 4:00 pm",
            "Afternoon From 4:00 pm to 8:00 pm",
            "Evening From 5:00 pm to 9:00 pm",
            "Other Time"
            ]
    
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "header"
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    
    
    public func config(section: Int){
        let compactMode = UserDefaults.standard.bool(forKey: SettingBundleKeys.CompactModeKey)
        
        backgroundColor = .systemGray4
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        if compactMode{
            if section < self.sectionTitleCompact.count{
                label.text = self.sectionTitleCompact[section]
            }
        }else{
            
            if weekday == 1 || weekday==7{
                if section < self.sectionTitleWeekend.count{
                    label.text = self.sectionTitleWeekend[section]
                }
            }else{
                if section < self.sectionTitleWeekday.count{
                    label.text = self.sectionTitleWeekday[section]
                }
            }
        }
        
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
}


class FooterCollectionReusableView: UICollectionReusableView {
        
    
    static let identifier = "FooterCollectionReusableView"
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Footer"
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    
    
    public func config(){
        backgroundColor = .white
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
}
