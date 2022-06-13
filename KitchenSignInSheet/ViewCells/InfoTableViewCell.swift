//
//  InfoTableViewCell.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class InfoTableViewCell: UITableViewCell {

    
    static let identifier = "InfoTableViewCell"
    
    @IBOutlet weak var iconView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!    
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var signLabel: UILabel!
    
    @IBOutlet weak var signInTime: UILabel!
    
    @IBOutlet weak var signOutTimeLabel: UILabel!
    
    
    @IBOutlet weak var breakLabel: UILabel!
    
    @IBOutlet weak var checkLabel: UILabel!
    
    @IBOutlet weak var notesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.clipsToBounds  = true
        timeLabel.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func config(mem: Member?, head: Bool){
        if !head{
            guard let mem = mem else{
                return
            }
            if mem.status.signed{
                iconView.image =  UIImage(systemName: "person.fill")
                signLabel.text = "✓"
            }
            else{
                iconView.image =  UIImage(systemName: "person")
                signLabel.text = ""
                //cell.backgroundColor = .systemPink
            }
            
            
            
            nameLabel.text = mem.name
            
            let formatter = DateFormatter()
            formatter.dateFormat = "hha"
            
            var timeInfo = ""
            
            timeInfo += formatter.string(from: mem.startTime)
            timeInfo += " - "
            timeInfo += formatter.string(from: mem.endTime)
            
            timeLabel.text = timeInfo
            
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "HH:mm"
            
            let formatter3 = DateFormatter()
            formatter3.dateFormat = "HH:mm"
            
            
            if mem.status.signed{
                signInTime.text = formatter2.string(from: mem.status.signIn)
                if mem.status.signOut != Date(timeIntervalSince1970: 0){
                    signOutTimeLabel.text = formatter2.string(from: mem.status.signOut)
                }else{
                    signOutTimeLabel.text = ""
                }
                if mem.status.duration > 0{
                    breakLabel.text = String(mem.status.duration)
                }else{
                    breakLabel.text = ""
                }
                
            }else{
                signInTime.text = ""
                signOutTimeLabel.text = ""
                breakLabel.text = ""
            }
            
            if mem.status.checked{
                checkLabel.text = "✓"
                tintColor = .green
            }else{
                if mem.status.noShow{
                    tintColor = .red
                }
                else if !mem.status.isNormal{
                    tintColor = .systemYellow
                }else{
                    tintColor = .green
                }
                checkLabel.text = ""
            }
            
            let coveredBy = mem.status.coveredBy
            
            if abs(mem.status.fine) > 0.5 {
                if coveredBy != ""{
                    notesLabel.text = "Covered by \(coveredBy). Fine: $\(String(describing: mem.status.fine)), " + mem.notes
                }else{
                    notesLabel.text = "Fine: $\(String(describing: mem.status.fine)), " + mem.notes
                }
            }else{
                if coveredBy != ""{
                    notesLabel.text = "Covered by \(coveredBy)." +  mem.notes
                }else{
                    notesLabel.text = mem.notes
                }
            }
        }else{
            timeLabel.text = "time"
            nameLabel.text = "name"
            signLabel.text = "signed?"
            signInTime.text  = "signIn"
            signOutTimeLabel.text = "signOut"
            breakLabel.text = "break"
            checkLabel.text = "check"
            notesLabel.text = "note"
            backgroundColor = MyColor.first_color
            
            timeLabel.textColor = MyColor.first_text_color
            nameLabel.textColor = MyColor.first_text_color
            signLabel.textColor = MyColor.first_text_color
            signInTime.textColor = MyColor.first_text_color
            signOutTimeLabel.textColor = MyColor.first_text_color
            breakLabel.textColor = MyColor.first_text_color
            checkLabel.textColor = MyColor.first_text_color
            notesLabel.textColor = MyColor.first_text_color
            
            notesLabel.textAlignment = .center
            
        }
    }
    
}
