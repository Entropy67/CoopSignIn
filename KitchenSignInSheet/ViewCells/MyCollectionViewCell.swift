//
//  MyCollectionViewCell.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit


class FlagButton : UIButton {
    var mem: Member? = nil
    var inView: SecuredViewController? = nil
}


class MyCollectionViewCell: UICollectionViewCell {

    static let identifier = "MyCollectionViewCell"
    
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        //imageView.backgroundColor = .yellow
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let clockButton: FlagButton = {
        let button = FlagButton()
        button.contentMode = .scaleToFill
        button.clipsToBounds = true
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(named: "clock", in: nil, with: ViewController.configuration), for: .normal)
        } else {
            // Fallback on earlier versions
            button.setImage(UIImage(named: "clock"), for: .normal)
        }
        return button
    }()
    
    
    private let flagButton: FlagButton = {
        let button = FlagButton()
        button.contentMode = .scaleToFill
        button.clipsToBounds = true
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(named: "flag.fill", in: nil, with: ViewController.configuration), for: .normal)
        } else {
            // Fallback on earlier versions
            button.setImage(UIImage(named: "flag.fill"), for: .normal)
        }
        button.tintColor = .orange
        return button
    }()
    
    private let noteButton: FlagButton = {
        let button = FlagButton()
        button.contentMode = .scaleToFill
        button.clipsToBounds = true
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(named: "note.text", in: nil, with: ViewController.configuration), for: .normal)
        } else {
            // Fallback on earlier versions
            button.setImage(UIImage(named: "note.text"), for: .normal)
        }
        if #available(iOS 13.0, *) {
            button.tintColor = .systemBrown
        } else {
            // Fallback on earlier versions
            button.tintColor = .brown
        }
        return button
    }()
    
    
    private let checkButton: FlagButton = {
        let button = FlagButton()
        button.contentMode = .scaleToFill
        button.clipsToBounds = true
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(named: "exclamationmark.triangle", in: nil, with: ViewController.configuration), for: .normal)
        } else {
            // Fallback on earlier versions
            button.setImage(UIImage(named: "exclamationmark.triangle"), for: .normal)
        }
        button.tintColor = .systemRed
        return button
    }()
    
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Member Name"
        //label.backgroundColor = .green
        label.textAlignment = .center
        label.clipsToBounds  = true
        label.font = label.font.withSize(22)
        return label
    }()
    
    private let typeLabel : UILabel = {
        let label = UILabel()
        label.text = "Shift type"
        label.textAlignment = .center
        label.clipsToBounds  = true
        label.font = label.font.withSize(15)
        return label
    }()
    
    private let statusLabel : UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.clipsToBounds  = true
        label.font = label.font.withSize(15)
        return label
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = MyColor.second_color
        } else {
            // Fallback on earlier versions
            contentView.backgroundColor = MyColor.second_color_low
        }
        contentView.addSubview(nameLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(typeLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(clockButton)
        contentView.addSubview(noteButton)
        contentView.addSubview(flagButton)
        contentView.addSubview(noteButton)
        contentView.addSubview(checkButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconImageView.frame = CGRect(x: 40, y: 20, width: contentView.frame.size.width - 80, height: contentView.frame.size.height - 120)
        
        nameLabel.frame = CGRect(x: 5, y: contentView.frame.size.height - 100, width: contentView.frame.size.width - 10, height: 40)
        
        typeLabel.frame = CGRect(x: 5, y: contentView.frame.size.height - 60, width: contentView.frame.size.width - 10, height: 20)
        
        statusLabel.frame = CGRect(x: 5, y: contentView.frame.size.height - 30, width: contentView.frame.size.width - 10, height: 20)
        

        clockButton.frame = CGRect(x: 20, y: 20, width: 40, height: 40)
        checkButton.frame = CGRect(x: 20, y: 80, width: 40, height: 40)
        flagButton.frame = CGRect(x: contentView.frame.size.width - 60, y: 20, width: 40, height:40)
        noteButton.frame = CGRect(x: contentView.frame.size.width - 60, y: 80, width: 40, height: 40)
    }
    

    public func configure(mem: Member, checking: Bool, inView: SecuredViewController? = nil){
        
        if mem.notes == ""{
            noteButton.isHidden = true
        }else{
            noteButton.isHidden = false
            noteButton.mem = mem
            noteButton.inView = inView
            noteButton.addTarget(self, action: #selector(didTapNoteButton(sender:)), for: .touchUpInside)
        }
        
        if mem.status.isNormal{
            flagButton.isHidden = true
        }else{
            flagButton.isHidden = false
            flagButton.mem = mem
            flagButton.inView = inView
            flagButton.addTarget(self, action: #selector(didTapYellowFlag(sender:)), for: .touchUpInside)
        }
        
        if mem.status.onBreak{
            clockButton.isHidden = false
            clockButton.tintColor = .black
            clockButton.mem = mem
            clockButton.inView = inView
            clockButton.addTarget(self, action: #selector(didTapClock(sender:)), for: .touchUpInside)
        }else{
            clockButton.isHidden = true
        }
        
        if mem.status.signed{
            iconImageView.image = UIImage(systemName: "person.fill")
        }
        else{
            iconImageView.image = UIImage(systemName: "person")
        }
        
        if mem.status.signedOut, !mem.status.checked{
            if !mem.status.isNormal || mem.shiftType == "Credit"{
                checkButton.isHidden = false
                checkButton.mem = mem
                checkButton.inView = inView
                checkButton.addTarget(self, action: #selector(didTapCheckIcon(sender:)), for: .touchUpInside)
            }else{
                checkButton.isHidden = true
            }
            
            if !PolicyManager.creditShiftMustBeChecked(){
                checkButton.isHidden = true
            }
        }else{
            checkButton.isHidden = true
        }
        
        if checking{ // in the checking states
            if mem.status.checked{
                contentView.backgroundColor = .green
            }else if mem.status.signed, mem.status.signedOut{
                if mem.shiftType == "Credit"{
                    contentView.backgroundColor = .yellow
                }else{
                    if #available(iOS 13.0, *) {
                        contentView.backgroundColor = .systemGray4
                    } else {
                        // Fallback on earlier versions
                        contentView.backgroundColor = .gray
                    }
                }
            }else{
                contentView.backgroundColor = .white
            }
        }else{
            
            if #available(iOS 13.0, *) {
                contentView.backgroundColor = .systemGray6
            } else {
                // Fallback on earlier versions
                contentView.backgroundColor = .lightGray
            }
        }
        
        if mem.status.signed{
            //iconImageView.isHidden = false
            iconImageView.tintColor = mem.color
        }else{
            //iconImageView.isHidden = true
            if #available(iOS 13.0, *) {
                iconImageView.tintColor = .systemGray5
            } else {
                // Fallback on earlier versions
                iconImageView.tintColor = .lightGray
            }
        }
        nameLabel.text  = mem.name
        
        
        
        var typeLabelText = ""
        if mem.role != "Regular"{
            typeLabelText += mem.role
        }
        
        if mem.shiftType != "Regular"{
            typeLabelText += " " + mem.shiftType
            
            if mem.shiftType == "Credit"{
                typeLabelText += " from " + mem.source
            }
        }
        typeLabel.text = typeLabelText
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        var statusLabelText = ""
        if mem.status.signed{
            if mem.status.signedOut{
                statusLabelText = "Signed out at " + formatter.string(from: mem.status.signOut)
            }else  if mem.status.onBreak{
                statusLabelText  = "Breakout from " + formatter.string(from: mem.status.breakOut)
            }else{
                statusLabelText = "Sign in at " + formatter.string(from: mem.status.signIn)
            }
            
        }else if mem.status.noShow{
            statusLabelText = "No-show"
        }
        
        if mem.status.checked{
            statusLabelText += " ✅"
        }
        
        statusLabel.text = statusLabelText
    }
    
    
    @objc func didTapClock(sender:FlagButton){
        guard let mem = sender.mem else{
            return
        }
        
        let minutesLeft = mem.breakTimeLimit - DateManager.getMinutesDiff(start: mem.status.breakOut, end: Date())
        
        AlertManager.sendAlert(title: "Member on break", message: "\(mem.name) breaks from \(DateManager.dateToString(date: mem.status.breakOut)). Minutes left: \(minutesLeft).", click: "OK", inView: sender.inView)
    }
    
    @objc func didTapYellowFlag(sender: FlagButton){
        guard let mem = sender.mem else{
            return
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        
        let attributedMessageText = NSMutableAttributedString(
            string: mem.getYellowFlagInfo(),
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ]
        )
        
        
        let alert = UIAlertController(title: "Flag Info", message: nil, preferredStyle: .alert)
        alert.setValue(attributedMessageText, forKey: "attributedMessage")
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        if let securityManager = sender.inView?.securityManager, !securityManager.lock{
            alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: {_ in
                mem.removeYellowFlag()
                sender.isHidden = true
            }))
        }
        sender.inView?.present(alert, animated: true)
    }
    
    @objc func didTapCheckIcon(sender: FlagButton){
        if sender.mem?.shiftType == "Credit"{
            AlertManager.sendAlert(title: "⚠️Check needed!", message: "This is a credit shift. Please ask the KC to check you out. Otherwise, you won't get credit.\n\(sender.mem?.getTimeStamps() ?? "")", click: "OK",  inView: sender.inView, alignment:.left)
            
        }else{
            AlertManager.sendAlert(title: "⚠️Check needed!", message: "Please ask the KC to check you out. Otherwise, you will be marked as no-show.\n\(sender.mem?.getTimeStamps() ?? "")", click: "OK",  inView: sender.inView, alignment:.left)
        }
    }
    
    @objc func didTapNoteButton(sender: FlagButton){
        guard let mem = sender.mem else{
            return
        }
        
        
        if let securityManager = sender.inView?.securityManager, !securityManager.lock{
            
            AlertManager.sendAlertWithCancel(title: "Note 📝", message: mem.notes, click: "Add", inView: sender.inView, completion: {() in
                let alert = UIAlertController (title: "Note 📝", message: mem.notes, preferredStyle: .alert)
                alert.addTextField { (textField) in
                    textField.placeholder = "Add more notes"
                }
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Add", style: .default, handler: {_ in
                    if let inputNote = alert.textFields![0].text{
                        LogManager.writeLog(info: "add note to member \(mem.name): \(String(describing: inputNote))")
                        mem.addNotes(note: inputNote)
                    }
                }))
                sender.inView?.present(alert, animated: true, completion: nil)
                
            })
        }else{
            AlertManager.sendAlert(title: "Note 📝", message: mem.notes, click: "Dismiss", inView: sender.inView,alignment:.left)
        }
        
    }
}
