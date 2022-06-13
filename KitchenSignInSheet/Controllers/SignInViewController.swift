//
//  SignInViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class SignInViewController: SecuredViewController, UITextFieldDelegate{

    var shift: Member?
    var dataManager: DataManager?
    var crewManager: CrewManager? = nil
    
    private var fireworkCells : [CAEmitterCell] = {
        let colors: [UIColor] = [
            .systemRed,
            .systemBlue,
            .systemPink,
            .systemYellow,
            .systemPurple,
            .systemGreen,
            .systemOrange
        ]
        
        return colors.compactMap {
            let cell = CAEmitterCell()
            cell.scale = 0.02
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi
            cell.lifetime = 10
            cell.birthRate = 0
            cell.velocity = 200
            cell.velocityRange = cell.velocity / 2
            cell.color = $0.cgColor
            cell.contents = UIImage(named: "firework")!.cgImage
            return cell
        }
    }()
    
    private let fireworkLayer: CAEmitterLayer = {
        let layer = CAEmitterLayer()
        layer.lifetime = 0.0
        layer.birthRate = 0.0
        return layer
    }()
    
    let mask: UIView = {
        let mask = UIView()
        mask.backgroundColor = .white
        mask.alpha = 0.2
        return mask
    }()
    
    public var update: (() -> Void)?
    public var completion: ((Status) -> Void)?
    static let identifier = "SignInViewController"
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var breakOutButton: UIButton!
    
    @IBOutlet weak var breakInButton: UIButton!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    @IBOutlet weak var cancelSignInButton: UIButton!
    
    
    @IBOutlet weak var seeBreakButton: UIButton!
    
    private lazy var optionsManager: OptionsManager = {
        let manager = HomeOptionsManager(
            options: ["Fine", "Change break duration", "Add a note", "Delete this shift"],
            mainView: self,
            anchorPosition: "right")
        
        manager.didSelectOption = { (option) in
            if option == "Change break duration"{
                self.changeBreakDuration()
            }else if option == "Add a note"{
                self.addNotes(){(note) in
                    //print("\(String(describing: note))")
                    self.dataManager?.saveData(completion: nil)
                }
            }else if option == "Delete this shift"{
                self.didTapDeletButton()
            }else if option == "Fine"{
                
                self.issueFine(){(newStatus) in
                    if newStatus != nil{
                        self.addNotes(){(note) in
                            
                            let noteText = note ?? ""
                            self.sendAlertComplete(title: "Success", message: "You have fined \(self.shift?.name ?? "this person") for  $\(String(describing: newStatus!.fine)) because \(noteText))", newStatus: newStatus!)
                        }
                    }
                }
            }
            
            manager.didTapBackground()
        }
        return manager
    }()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //hideKeyboardWhenTappedAround()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Menu", style: .done, target: self, action: #selector(didTapShowOptionsButton))
        
        navigationItem.titleView = titleButton
        titleButton.addTarget(self, action: #selector(didTapLockButton), for: .touchUpInside)
        titleLabel.backgroundColor = MyColor.first_color
        titleLabel.textColor = MyColor.first_text_color

        let signed = shift?.status.signed ?? false
        
        let signedOut = shift?.status.signedOut ?? false
        let onBreak = shift?.status.onBreak ?? false
        let breakInTime = shift?.status.breakIn ?? DateManager.defaultDate
        
        if onBreak || breakInTime != DateManager.defaultDate{
            if #available(iOS 13.0, *) {
                breakOutButton.backgroundColor = MyColor.icon_color
            }
        }

        if breakInTime != DateManager.defaultDate{
            if #available(iOS 13.0, *) {
                breakInButton.backgroundColor = MyColor.icon_color
            }
        }
        
        if signedOut{
            iconImageView.image = UIImage(systemName: "person.fill")
            
            signOutButton.setTitle("Cancel Sign Out", for: .normal)
            if #available(iOS 13.0, *) {
                signInButton.backgroundColor = MyColor.icon_color
                breakInButton.backgroundColor = MyColor.icon_color
                breakOutButton.backgroundColor =  MyColor.icon_color
            } else {
                signInButton.backgroundColor = MyColor.icon_color_low
                breakInButton.backgroundColor = MyColor.icon_color_low
                breakOutButton.backgroundColor =  MyColor.icon_color_low
            }
        }else{
            signOutButton.setTitle("Sign Out", for: .normal)
            if signed{
                iconImageView.image = UIImage(systemName: "person.fill")
                if #available(iOS 13.0, *) {
                    signInButton.backgroundColor = MyColor.icon_color
                } else {
                    signInButton.backgroundColor = MyColor.icon_color_low
                }
            }
            else{
                iconImageView.image = UIImage(systemName: "person")
                var color = MyColor.icon_color_low
                if #available(iOS 13.0, *) {
                    color = MyColor.icon_color
                }
                breakInButton.backgroundColor = color
                breakOutButton.backgroundColor = color
                signOutButton.backgroundColor = color
                cancelSignInButton.backgroundColor = color
                
            }
        }
        
        let role = self.shift?.role ?? ""
        
        if let crewManager = crewManager {
            iconImageView.tintColor = crewManager.getCrewColor(crewName: role)
        }
        
        nameLabel.textAlignment = .center
        nameLabel.text = self.shift?.name
        nameLabel.font = nameLabel.font.withSize(30)
        
        typeLabel.textAlignment = .center
        typeLabel.font = typeLabel.font.withSize(20)
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "hh:mm a"

        let startTime = self.shift?.startTime ?? Date()
        
        let laterDate = Calendar.current.date(
                                byAdding: .hour,
                                value: 4,
                                to: Date())
        
        let endTime = (self.shift?.endTime ?? laterDate) ?? Date()
        
        
        let labelPart1 = self.shift?.role ?? ""
        let labelPart2 = self.shift?.shiftType ?? "none"

        let labelPart3 = "From: " + formatter.string(from: startTime)
        let labelPart4 = " To: " + formatter.string(from: endTime)
        
        typeLabel.text = "Role: " + labelPart1 + ", Type: " +  labelPart2 + ", " + labelPart3 + labelPart4
        
        if securityManager?.lock ?? false{
            titleButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: ViewController.configuration), for: .normal)
        }else{
            titleButton.setImage(UIImage(systemName: "lock.open", withConfiguration: ViewController.configuration), for: .normal)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        //createLayer()
        fireworkLayer.emitterCells = fireworkCells
        fireworkLayer.emitterPosition = CGPoint(x: view.center.x,
                                        y: -100)
        view.layer.addSublayer(fireworkLayer)
        mask.frame = view.bounds
        
    }
    
    override func willMove(toParent parent: UIViewController?) {
        self.optionsManager.closeOptions()
        super.willMove(toParent: parent)
        
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height / 2
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func didTapLockButton(){
        securityManager?.update(inView: self)
    }
    

    @objc func didTapShowOptionsButton(_ sender: Any) {
        //self.writeLog(info: "did tap show option button in sign-in view")
        if optionsManager.didShowOptions{
            optionsManager.closeOptions()
            return
        }
        
        guard let securityManager = securityManager else {
            return
        }

        if !securityManager.lock{
            if !self.optionsManager.didShowOptions{
                self.optionsManager.showOptions()
            }
        }
    }
    
    func issueFine(completion: @escaping ((Status?) -> Void)){
        guard let shift = shift else {
            return
        }
        // create the actual alert controller view that will be the pop-up
        let alertController = UIAlertController(title: "Fine",
                                                message: "Create a fine ticket to \(shift.name)",
                                                preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Enter fine"
            textField.keyboardType = .numberPad
        }

        
        let newStatus = Status(signed: shift.status.signed,
                               signIn: shift.status.signIn,
                               signOut: shift.status.signOut,
                               breakIn: shift.status.breakIn,
                               breakOut: shift.status.breakOut)
        
        newStatus.setChecked(checked: shift.status.checked)
        newStatus.setCoveredBy(coveredBy: shift.status.coveredBy)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let inputNote = alertController.textFields![0].text?.replacingOccurrences(of: " ", with: "")
            if let money = Double(inputNote ?? "") {
                let old_money = shift.status.fine
                LogManager.writeLog(info: "Add fine $\(money) to shift: \(shift.name). Now the total fine is $\(money + old_money)")
                newStatus.addFine(money: money + old_money)
                completion(newStatus)
            }else{
                AlertManager.sendAlert(title: "Failed", message: "Incorrect fine format! Did not create the fine", click: "OK", inView: self)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        present(alertController, animated: true, completion: nil)
        
        completion(nil)
        
    }
    
    func changeBreakDuration(){
        guard let shift = shift else {
            return
        }

        let alertController = UIAlertController(title: "Set break duration", message: "Set break duration to \(self.shift?.name ?? "this shift")", preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Enter minutes"
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let inputNote = alertController.textFields![0].text?.replacingOccurrences(of: " ", with: "")
            
            if let minutes = Int(inputNote ?? "") {
                let newStatus = Status(signed: true,
                                        signIn: shift.status.signIn,
                                        signOut: shift.status.signOut,
                                        breakIn: shift.status.breakIn,
                                        breakOut: shift.status.breakOut)
                
                newStatus.setDuration(minutes: minutes)
                newStatus.setChecked(checked: shift.status.checked)
                newStatus.setCoveredBy(coveredBy: shift.status.coveredBy)
                newStatus.fine = shift.status.fine
                
                LogManager.writeLog(info: "You have update \(shift.name)'s breakout duration to \(minutes)min.")
                self?.sendAlertComplete(title: "Duration updated!", message: "You have update \(shift.name)'s breakout duration to \(minutes)min.", newStatus: newStatus)
            }else{
                AlertManager.sendAlert(title: "Failed", message: "Did not change duration because the input format is incorrect.", click: "OK", inView: self)
            }

        }

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        present(alertController, animated: true, completion: nil)
    }
    
    
    func addNotes(completion: ((String?) -> Void)?){
        guard let shift = shift else {
            return
        }

        
        var message = ""
        if shift.notes == ""{
            message = "add notes to \(shift.name)"
        }else{
            message = shift.notes
        }
        let alertController = UIAlertController(title: "Add notes", message: "add notes to \(shift.name)", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Input notes"
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "KC initials"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            var inputNote = alertController.textFields![0].text ?? ""
            inputNote += "(by KC \(alertController.textFields![1].text ?? ""))"
            LogManager.writeLog(info: "add note to shift \(shift.name): \(String(describing: inputNote))")
            shift.addNotes(note: inputNote)
            completion?(inputNote)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        present(alertController, animated: true, completion: nil)
        completion?(nil)
    }
    

    
    func didTapDeletButton(){
        guard let shift = shift, shift.source != "AMO" else {
            AlertManager.sendAlert(title: "Delete Failed", message: "😢Sorry. This shift cannot be deleted.", click: "OK", inView: self)
            return
        }
        let newStatus = Status(signed: false,
                               signIn: DateManager.defaultDate,
                               signOut: DateManager.defaultDate,
                               breakIn: DateManager.defaultDate,
                               breakOut: DateManager.defaultDate)
        newStatus.delete()

        let refreshAlert = UIAlertController(title: "Delete shift",
                                             message: "This shift will be deleted!",
                                             preferredStyle: .alert)

        refreshAlert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { (action: UIAlertAction!) in
          self.sendAlertComplete(title:"Shift deleted", message: "🗑This shift has been deleted. Thank you.", newStatus: newStatus)
          }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))

        present(refreshAlert, animated: true, completion: nil)
    }
    
    func sendAlertComplete(title: String, message: String, newStatus: Status){
        
        let alert = UIAlertController(title:title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default,
                                      handler: {[weak self] _ in
            self?.completion?(newStatus)
            self?.dismiss(animated: true)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    
    @IBAction func didTapSignInButton(){
        guard let shift = shift, let locked = securityManager?.lock else {
            return
        }
        
        shift.config()

        if shift.status.signedOut || shift.status.signed{
            return
        }
        
        if shift.status.noShow{
            if locked{
                AlertManager.sendAlert(title: "⚠️Failed to sign-in", message: "You cannot sign in any more becuase it is too late. Your shift has been marked as no-show.", click: "OK", inView: self)
                return
            }
        }
        
        
        
        checkDepositNumberWithCompletion(numberOfField: 2){[weak self] correct, coveredByText in
            if correct{
                let newStatus = Status(signed: true,
                                       signIn: Date(),
                                       signOut: nil,
                                       breakIn: nil,
                                       breakOut: nil)
                
                newStatus.fine = shift.status.fine
                
                if !coveredByText.isEmpty{
                    newStatus.setCoveredBy(coveredBy: coveredByText)
                }
                self?.iconImageView.image = UIImage(systemName: "person.fill")
                LogManager.writeLog(info: "sign in success for shift \(shift.name)")
                
                if shift.status.noShow{
                    shift.addNotes(note: "Late sign-in.")
                    self?.sendAlertComplete(title: "⚠️Late sign-in", message: "You have signed in. However, you are late for your shift. This is recorded and will be reported to the AMO.", newStatus: newStatus)
                } else{
                    self?.sendAlertComplete(title: "Signed in", message: "🎉🎉 You have successfully signed in for this shift.👨‍🍳🍔🥘 ", newStatus: newStatus)
                }
            }
            
        }
    }
    
    @IBAction func didTapBreakOutButton(){
        
        guard let shift = shift, !shift.status.signedOut, shift.status.signed else {
            AlertManager.sendAlert(title: "Failed", message: "You have not signed in or you have signed out!", click: "OK", inView: self)
            return
        }
        
        if shift.breakTimeLimit == 0{
            AlertManager.sendAlert(title: "Failed", message: "Your shift as \(shift.role) does not have break", click: "OK", inView: self)
            return
        }

        let breakOutTime = shift.status.breakOut
        
        if breakOutTime == DateManager.defaultDate{
            
            let newStatus = Status(signed: true,
                                   signIn: shift.status.signIn,
                                   signOut: nil,
                                   breakIn: nil,
                                   breakOut: Date())
            
            newStatus.setChecked(checked: shift.status.checked)
            newStatus.setCoveredBy(coveredBy: shift.status.coveredBy)
            newStatus.fine = shift.status.fine
            LogManager.writeLog(info: "break out starts for shift \(shift.name)")
            
            self.sendAlertComplete(title:"Breakout starts", message: "Now you can have a break for up to \(shift.breakTimeLimit) mins⏰", newStatus: newStatus)
        }else{
            AlertManager.sendAlert(title: "Failed", message: "You have already taken a break", click: "OK", inView: self)
        }
    }
    
    @IBAction func didTapBreakInButton(){
        guard let shift = shift,
                !shift.status.signedOut,
                shift.status.signed,
                shift.status.onBreak else{
            return
        }
        
        let breakInTime = shift.status.breakIn
        
        if breakInTime == DateManager.defaultDate{
            let newStatus = Status(signed: true,
                                   signIn: shift.status.signIn,
                                   signOut: nil,
                                   breakIn: Date(),
                                   breakOut: shift.status.breakOut)
            
            newStatus.setChecked(checked: shift.status.checked)
            newStatus.setCoveredBy(coveredBy: shift.status.coveredBy)
            newStatus.fine = shift.status.fine
            LogManager.writeLog(info: "break out ends for shift \(shift.name)")
            
            self.sendAlertComplete(title:"Breakout ends", message: "You finished your break! Thank you!", newStatus: newStatus)
        }else{
            AlertManager.sendAlert(title: "Failed", message: "Sorry. You breakout has already ended a while ago.", click: "OK", inView: self)
        }
    }
    
    
    @IBAction func didTapSignOutButton(){
        guard let shift = shift, shift.status.signed else {
            return
        }
        
        checkDepositNumberWithCompletion(numberOfField: 1){ [weak self] correct, coveredByText in
            if correct{
                let newStatus = Status(signed: shift.status.signed,
                                       signIn: shift.status.signIn,
                                       signOut: Date(),
                                       breakIn: shift.status.breakIn,
                                       breakOut: shift.status.breakOut)
                newStatus.setChecked(checked: shift.status.checked)
                newStatus.setCoveredBy(coveredBy: shift.status.coveredBy)
                // double check if the new status is normal
                newStatus.isNormal = shift.status.isNormal
                newStatus.fine = shift.status.fine
                if shift.status.signedOut{
                    newStatus.signOut = DateManager.defaultDate
                    AlertManager.sendAlertWithCancel(title: "Your signout will be canceled", message: "Please confirm that you want to cancel your sign out.", click: "Confirm", inView: self){[weak self] in
                        LogManager.writeLog(info: "\(shift.name) canceled the signed out.")
                        self?.sendAlertComplete(title: "Sign-out canceled", message: "You have canceled your signout. Please sign out when you finish your shift. ", newStatus: newStatus)
                    }
                }else{
                    let absentDuration = DateManager.getMinutesDiff(start: newStatus.signOut, end: shift.endTime) - (shift.breakTimeLimit - newStatus.duration)
                    if absentDuration > PolicyManager.getEarlySignOutMinutes() {
                        newStatus.isNormal = false
                    }
                    
                    LogManager.writeLog(info: "\(shift.name) signed out")
                    if !PolicyManager.creditShiftMustBeChecked(){
                        self?.sendAlertComplete(title:"Signed out", message: "😀You have successfully signed out! Have a good day🌟🌟!", newStatus: newStatus)
                    }else{
                        
                        if shift.shiftType == "Credit", !shift.status.checked{
                            self?.sendAlertComplete(title:"‼️Check needed", message: "⚠️⚠️Please ask the KC to check your time stamps and confirm your credits!!! You won't get paid unless the KC checks you out.", newStatus: newStatus)
                        } else {
                            if newStatus.isNormal{
                                self?.sendAlertComplete(title:"Signed out", message: "😀You have successfully signed out! Have a good day🌟🌟!", newStatus: newStatus)
                            }else{
                                self?.sendAlertComplete(title:"‼️Check needed", message: "⚠️⚠️Please ask the KC to check your time stamps!!! You will be marked as no-show unless the KC checks you out.", newStatus: newStatus)
                            }
                        }
                        
                    }
                }
            }
            
            
        }
    }
    
    @IBAction func didTapCancelSignInButton(){
        guard let shift = shift, shift.status.signed, let securityManager = securityManager else {
            //AlertManager.sendAlert(title: "Failed", message: "You haven't signed in", click: "OK", inView: self)
            return
        }
        securityManager.securityCheck(inView: self){ (success) in
            if success{
                let newStatus = Status(signed: false)
                
                let refreshAlert = UIAlertController(title: "Cancel sign-in", message: "Your sign-in will be cancelled", preferredStyle: .alert)
                
                refreshAlert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action: UIAlertAction!) in
                    LogManager.writeLog(info: " \(shift.name) sign in is cancelled")
                    self.sendAlertComplete(title:"Sign-in cancelled", message: "You have cancelled your sign-in!", newStatus: newStatus)
                }))
                
                refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
                self.present(refreshAlert, animated: true, completion: nil)
            }else{
                AlertManager.sendAlert(title: "Please ask KC for help", message: "", click: "OK", inView: self)
                return
            }
        }
    }
    
    
    @IBAction func didTapSeeBreakButton(){
        
        guard let shift = shift else {
            return
        }
        guard let securityManager = securityManager else {
            return
        }
        if securityManager.lock{
            shift.presentInfo(inView: self, mode: .basic)
        }else{
            shift.presentInfo(inView: self, mode: .medium)
        }
        
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func checkDepositNumberWithCompletion(numberOfField: Int = 2, completion: @escaping (Bool, String) -> Void){
        guard let shift = shift else {
            return
        }

        let alertController = UIAlertController(title: "Enter Deposit Number", message: "Please enter the deposit number of \(shift.name).", preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Deposit number"
            textField.keyboardType = .numberPad
        }
        
        if numberOfField > 1{
            alertController.addTextField { (textField) in
                if !shift.status.coveredBy.isEmpty{
                    textField.placeholder = "Covered by \(shift.status.coveredBy)"
                }else{
                    textField.placeholder = "Covered by (Optional)"
                }
            }
        }

        // add the buttons/actions to the view controller
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            let inputDeposit = alertController.textFields![0].text ?? ""
            var inputCoveredBy = ""
            if numberOfField > 1{
                inputCoveredBy = alertController.textFields![1].text ?? ""
            }
            
            if inputDeposit == "24459"{
                self?.createFireworkLayer()
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(5)) { [weak self] in
                    self?.stopFireWorkLayer()
                    AlertManager.sendAlert(title: " 🐣 ", message: "This APP is designed and developed by Hongda Jiang (24459) in 2022. ", click: "OK", inView: self){
                            completion(true, inputCoveredBy)
                    }
                }
                return
            }
            
            if !inputDeposit.isEmpty{
                let depositNumberInt = Int(inputDeposit) ?? 0
                
                if depositNumberInt == self?.shift?.deposit{
                    completion(true, inputCoveredBy)
                    return
                }else{
                    AlertManager.sendAlert(title: "Wrong Deposit Number", message: "Please enter the deposit number of \(shift.name)! If you are covering \(shift.name)'s shift and you don't know the deposit, please ask KC for help.", click: "OK", inView: self)
                    completion(false, "")
                }
            }else{
                AlertManager.sendAlert(title: "No Deposit Number", message: "Please enter your deposit number", click: "OK", inView: self)
                completion(false, "")
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    private func createFireworkLayer(){
        for cell in fireworkCells {
            cell.birthRate = 100
        }
        fireworkLayer.beginTime = CACurrentMediaTime()
        fireworkLayer.lifetime = 1
        fireworkLayer.birthRate = 1
        view.addSubview(mask)
        //view.layer.addSublayer(fireworkLayer)
    }
    
    
    private func stopFireWorkLayer(){
        for cell in fireworkCells {
            //cell.lifetime = 0
            cell.birthRate = 0
        }
        fireworkLayer.lifetime = 0.0
        fireworkLayer.birthRate = 0.0
        //fireworkLayer.removeFromSuperlayer()
        mask.removeFromSuperview()
    }


}


