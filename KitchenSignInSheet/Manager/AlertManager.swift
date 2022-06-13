//
//  alertManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/19/22.
//  Copyright © 2022 AMO. All rights reserved.
//


import UIKit


struct AlertMessages{
    
    
    /// MARK: add a new shift alert
    static let addNewShiftAlert = AlertMessageModel(title:  "Alert", message: "Please double check the sign in sheet and make sure your name is not on it before adding a new shift.🧐")
    
    static let addNewShiftFailed = AlertMessageModel(title: "❌ Failed", message: "This is because one of the following reasons: (1)your shift is already on the sign-in sheet; (2)the maximal crew capacity has been reached. Please double check the sign-in form!/n If you find your name on the sign-in sheet, please sign in directly.")
    
    static let addNewShiftSuccess = AlertMessageModel(title: "✅ Success", message: "🎉🎉You have created the shift for")
    
    static let addNewShiftForbidden = AlertMessageModel(title: "Please ask KC for help", message: "You are not allowed to register a shift by yourself. Please ask KC for help.")
    
    
    /// MARK: reload sign in sheet
    static let reloadSignInSheetAlert = AlertMessageModel(title:  "‼️Warning‼️", message: "‼️‼️You are going to remmove all the local data. This includes all sign-in/out information. The sign in sheet will be reloaded. Continue?")
    
    
    /// MARK: recover from Google Drive
    static let recoverFromDriveAlert = AlertMessageModel(title: "Confirm", message: "‼️‼️You are going to remmove all the local data and load the data from the google drive. Continue?")
    
    /// MARK: check and upload
    static let uploadSuccess = AlertMessageModel(title: "🎉Success🎉", message: "Check complete✅. You have upload the spreadsheet to Google Drive🌐 ✅. ")
    
    static let uploadFailed = AlertMessageModel(title: "⚠️⚠️ Upload failed", message: "Check complete✅. But was unable to upload to Google Drive🌐 ❌. Error: ")
    
    static let uploadPreviousDayFailed = AlertMessageModel(title:  "Upload failed", message: "⚠️⚠️Unable to upload yesterday's data to Google Drive. Please upload it to Google Drive manually later! ")
    
    
    /// MARK: download
    static let downloadFailed = AlertMessageModel(title: "❌Error", message: "Failed to download the signin sheet because you haven't signed in the Google account. Please tap Menu -> Sign-in Google Drive. Then refresh the page. Otherwise, you can only use the off-line mode.")
    
    static let noInternetAlert = AlertMessageModel(title: "⚠️No Internet", message: "There is no internet access. Please check the wifi and router. Go ahead and add the shift manually.")
    
    static let noSignInFormAlert = AlertMessageModel(title: "⚠️No Sign-in Form", message: "There is no sign-in sheet on Google Drive. Please contact amo@ucha.coop. Go ahead and add the shift manually.")
    
    /// MARK: offline mode
    static let offlineModeAlert = AlertMessageModel(title: "Offline mode", message: "You are now in offline mode. No need to sign-in any Google account. If you want to use the Google Drive serive, please go to Menu -> Setting and enable Google Drive service.")
}

struct AlertMessageModel{
    let title: String
    let message: String
}



final class AlertManager{
    
    
    static func sendAlert(title: String, message: String, click: String?, inView: UIViewController?, alignment: Allignment = .center, completion: (()->Void)? = nil){
        guard let inView = inView else{
            return
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case .left:
            paragraphStyle.alignment = NSTextAlignment.left
        case .center:
            paragraphStyle.alignment = NSTextAlignment.center
        case .right:
            paragraphStyle.alignment = NSTextAlignment.right
        }
        
        
        let attributedMessageText = NSMutableAttributedString(
            string: message,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ]
        )
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.setValue(attributedMessageText, forKey: "attributedMessage")
        if let click = click {
            alert.addAction(UIAlertAction(title: click, style: UIAlertAction.Style.default, handler: {_ in completion?()}))
        }
        inView.present(alert, animated: true, completion: nil)
    }
    
    static func sendAlertWithCancel(title: String, message: String, click: String?, inView: UIViewController?, completion: (()->Void)? = nil){
        guard let inView = inView else{
            return
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let click = click {
            alert.addAction(UIAlertAction(title: click, style: UIAlertAction.Style.default, handler: {_ in completion?()}))
        }
        inView.present(alert, animated: true, completion: nil)
    }
    
    
    static func sendRedAlert(title: String, message: String, click: String?, inView: UIViewController?, completion: (()->Void)? = nil){
        guard let inView = inView else{
            return
        }
        let attributedTitleString = NSAttributedString(string: title, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 19, weight: .bold), //your font here
            NSAttributedString.Key.foregroundColor : UIColor.systemRed
        ])
        
        let attributedMessageString = NSAttributedString(string: message, attributes: [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17), //your font here
            NSAttributedString.Key.foregroundColor : UIColor.black
        ])
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.setValue(attributedTitleString, forKey: "attributedTitle")
        alert.setValue(attributedMessageString, forKey: "attributedMessage")
        if let click = click {
            alert.addAction(UIAlertAction(title: click, style: UIAlertAction.Style.default, handler: {_ in completion?()}))
        }
        inView.present(alert, animated: true, completion: nil)
    }
    
}


enum Allignment{
    case left
    case center
    case right
}
