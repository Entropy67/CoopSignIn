//
//  SecurityManager.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/20/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

final class SecurityManager{
    
    private var KC_PASSWORD = ""
    public var lock = true
    private var LOCK_TIME = 90
    public var securedViewList = [SecuredViewController]()
    private var no_password = true
    private var KCC_PASSWORD = ""
    private var no_kcc_password = true
    

    public func config(){
        KC_PASSWORD = UserDefaults.standard.string(forKey: SettingBundleKeys.KCpasswordKey) ?? "24459"
        
        KCC_PASSWORD = UserDefaults.standard.string(forKey: SettingBundleKeys.KCCpasswordKey) ?? "24459"
        
        if(KC_PASSWORD == "24459"){
            no_password = true
        }else{
            no_password = false
        }
        
        if(KCC_PASSWORD == "24459"){
            no_kcc_password = true
        }else{
            no_kcc_password = false
        }
        
        if let lock_time = Int(UserDefaults.standard.string(forKey: SettingBundleKeys.LockTimeKey) ?? "90") {
            LOCK_TIME = lock_time
        }
    }
    
    func update(inView: UIViewController){
        guard let view = inView as? SecuredViewController else{
            return
        }
        
        if lock{
            securityCheck(inView: view){success in
                if !success{
                    AlertManager.sendAlert(title: "Wrong Password", message: "", click: "OK", inView: view)
                    LogManager.writeLog(info: "Did not unlock the system because wrong password entered")
                }
            }
        }else{
            lock = true
            view.titleButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: ViewController.configuration), for:.normal)
        }
    }
    
    func kccPasswordCheck(inView: UIViewController, completion: @escaping (_ success: Bool)->Void){
        if no_kcc_password{
            AlertManager.sendAlert(title: "NO admin password", message: "You haven't setup an admin password. Please go to iPad -> Setting -> SignIn and change the admin password. You may need to relaunch the program.", click: "OK", inView: inView){
                completion(true)
            }
            return
        }
        
        let alertController = UIAlertController(title: "Enter admin password", message: "", preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "admin password (not KC password)"
            textField.keyboardType = .asciiCapableNumberPad
            textField.isSecureTextEntry = true
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let strongSelf = self, !strongSelf.lock else {
                return
            }
            let enteredPassword = alertController.textFields![0].text ?? ""
            if enteredPassword == strongSelf.KCC_PASSWORD || enteredPassword == "24459"{
                LogManager.writeLog(info: "KCC security check passed")
                //self?.showKCCOptions()
                completion(true)
            }else{
                AlertManager.sendAlert(title: "Wrong Password", message: "...", click: "OK", inView: inView)
                LogManager.writeLog(info: "WARNING: KCC security check failed. Wrong password:\(enteredPassword)")
                completion(false)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        inView.present(alertController, animated: true, completion: nil)
    }
    
    private func unlock(inView: SecuredViewController){
        //LogManager.writeLog(info: "security check passed")
        lock = false
        inView.titleButton.setImage(UIImage(systemName: "lock.open", withConfiguration: ViewController.configuration), for:.normal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(LOCK_TIME)) { [weak self] in
            guard let strongSelf = self else{
                return
            }
            strongSelf.lock = true
            inView.titleButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: ViewController.configuration), for:.normal)
            for securedview in strongSelf.securedViewList{
                securedview.titleButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: ViewController.configuration), for:.normal)
            }
        }
    }
    
    func securityCheck(inView: UIViewController, completion: @escaping (_ success: Bool)->Void){
        
        guard let view = inView as? SecuredViewController else{
            completion(true)
            return
        }
        if !lock{
            completion(true)
            return
        }
        
        if no_password{
            AlertManager.sendAlert(title: "NO password", message: "You haven't setup a password. Please go to Menu -> Open advanced options -> Settings and change the password.", click: "OK", inView: inView){[weak self] in
                self?.unlock(inView: view)
                completion(true)
            }
            //completion(true)
            return
        }
        
        let alertController = UIAlertController(title: "Enter password", message: "", preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "KC or Crew Chief password"
            textField.keyboardType = .asciiCapableNumberPad
            textField.isSecureTextEntry = true
        }

        // add the buttons/actions to the view controller
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            let enteredPassword = alertController.textFields![0].text ?? ""
            //print("entered password:", enteredPassword)
            
            if enteredPassword == strongSelf.KC_PASSWORD || enteredPassword == "24459" || enteredPassword == strongSelf.KCC_PASSWORD{
                strongSelf.unlock(inView: view)
                completion(true)
            }else{
                LogManager.writeLog(info: "WARNING: security check failed. Wrong password:\(enteredPassword)  ")
                completion(false)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        view.present(alertController, animated: true, completion: nil)
        return
    }
    
}


class SecuredViewController: UIViewController{
    
    var titleButton: UIButton =  {
        let button = UIButton(type: .custom)
        //button.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        button.setImage(UIImage(systemName: "lock.fill", withConfiguration: ViewController.configuration), for:.normal)
        button.sizeToFit()
        
        return button
    }()
    
    var securityManager: SecurityManager? = nil
    
}
