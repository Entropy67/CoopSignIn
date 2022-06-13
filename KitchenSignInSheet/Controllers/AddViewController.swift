//
//  AddViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class AddViewController: UIViewController{
    
    public var completion: ((Member) -> Void)?
    public var crewManager: CrewManager? = nil
    var Default_hour: Int = 4
    
    public var signIn = false
    private let signInButton: UIButton = {
       let myButton = UIButton()
        myButton.setTitle("Sign In", for: .normal)
        myButton.backgroundColor = MyColor.first_color
        myButton.setTitleColor(MyColor.first_text_color, for: .normal)
        myButton.layer.cornerRadius = 20
        myButton.titleLabel?.font = myButton.titleLabel?.font.withSize(16)
        return myButton
    }()
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var depositField: UITextField!

    @IBOutlet weak var regularShiftButton: UIButton!
    
    @IBOutlet weak var tempShiftButton: UIButton!
    
    @IBOutlet weak var creditShiftButton: UIButton!
    
    @IBOutlet weak var startTimePicker: UIDatePicker!
    
    @IBOutlet weak var endTimePicker: UIDatePicker!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var typeButtonList = [UIButton]()
    var shiftButtonList = [UIButton]()
    
    var choreShift = "Regular"
    var shiftType = ""
    
    let defaultDate = Date(timeIntervalSince1970: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if signIn{
            title = "Register and Sign In"
        }else{
            title = "Register a shift"
        }
        
        nameField.delegate  = self
        depositField.delegate = self
        depositField.keyboardType = .numberPad
        
        typeButtonList = [regularShiftButton, tempShiftButton, creditShiftButton]
        didTapRegular()
        
        if signIn{
            signInButton.isHidden = false
            drawCross(button: creditShiftButton)
            AlertManager.sendRedAlert(title: "Notice", message: "\n‼️This shift CANNOT be counted as a credit shift or a make-up shift. \n\n‼️This shift CANNOT replace any other shift (e.g. a shift you missed earlier).", click: "I understand", inView: self)
        }else{
            signInButton.isHidden = true
            didTapCredit()
        }
        
        startTimePicker.setDate(Date().nearest30Min, animated: false)
        startTimePicker.addTarget(self, action: #selector(updateStartTime), for: .valueChanged)
        updateEndTime()
        
        collectionView.register(CrewCollectionViewCell.self, forCellWithReuseIdentifier: CrewCollectionViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //hideKeyboardWhenTappedAround()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.signInButton.frame = CGRect(x: self.view.frame.size.width/2 - 80, y:self.view.frame.size.height - 100, width: 160, height: 50)
        self.signInButton.setTitleColor(UIColor.white, for: .normal)
        self.signInButton.addTarget(self, action: #selector(self.didTapSignInButton(sender:)), for: .touchUpInside)
        self.view.addSubview(self.signInButton)
        if !signIn{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        }
        
        if let crewManager = crewManager {
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = 10
            layout.minimumInteritemSpacing = 10
            
            let numCrews = min(Float(crewManager.allElements.count), 5.5)
            let totalWidth = (view.frame.size.width - 350) - (CGFloat(numCrews)) * 10
            
            layout.itemSize = CGSize(width: (totalWidth / CGFloat(numCrews)), height: 50 )
            
            layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            layout.scrollDirection = .horizontal
            collectionView.collectionViewLayout = layout
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    @objc func updateStartTime(_ sender: UIDatePicker){
        updateEndTime()
    }
    
    private func updateEndTime(){
        var hours = Default_hour
        var minutes = 0
        if let crewManager = crewManager {
            hours = Int(crewManager.getCrewHours(crewName: choreShift))
            minutes = crewManager.getCrewMinutes(crewName: choreShift)
        }
        var expectedEndTime = Calendar.current.date(byAdding: .hour, value: hours, to: self.startTimePicker.date) ?? Date()
        expectedEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: expectedEndTime) ?? expectedEndTime
        
        if DateManager.isSameDay(date1: startTimePicker.date, date2: expectedEndTime){
            endTimePicker.setDate(expectedEndTime, animated: true)
        }else{
            endTimePicker.setDate(startTimePicker.date, animated: true)
        }
        
    }
    
    @IBAction func didTapRegular(){
        didTapTypeButton(button: regularShiftButton)
    }
    
    @IBAction func didTapTemp(){
        didTapTypeButton(button: tempShiftButton)
    }
    
    @IBAction func didTapCredit(){
        if !self.signIn{
            didTapTypeButton(button: creditShiftButton)
        }
    }

    func didTapTypeButton(button: UIButton){
        for btn in self.typeButtonList{
            if #available(iOS 13.0, *) {
                btn.backgroundColor = MyColor.second_color
            } else {
                // Fallback on earlier versions
                btn.backgroundColor = MyColor.second_color_low
            }
            btn.setTitleColor(MyColor.second_text_color, for: .normal)
        }
        let type = button.titleLabel?.text ?? ""
        self.shiftType = type
        button.backgroundColor = MyColor.first_color
        button.setTitleColor(MyColor.first_text_color, for: .normal)
    }
    
    private func drawCross(button: UIButton){
        // draw a cross on top of a button
        let buttonFrame = button.frame
        let path = UIBezierPath()
        let buffer = CGFloat(5)
        path.move(to: CGPoint(x: buffer, y: buffer))
        path.addLine(to: CGPoint(x: buttonFrame.width - buffer, y: buttonFrame.height - buffer))
        
        path .move(to: CGPoint(x: buffer, y: buttonFrame.height - buffer))
        path.addLine(to: CGPoint(x: buttonFrame.width - buffer, y: buffer))
        
        path.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        if #available(iOS 13.0, *) {
            shapeLayer.strokeColor = UIColor.systemGray2.cgColor
        } else {
            // Fallback on earlier versions
            shapeLayer.strokeColor = UIColor.black.cgColor
        }
        shapeLayer.lineWidth = 2.0
        //shapeLayer.position = CGPoint(x: 0, y: 0)
        button.layer.addSublayer(shapeLayer)
    }

    @objc func didTapSignInButton(sender: UIButton!){
        self.didTapSaveButton(signed: true)
    }
    
    
    @objc func didTapSaveButton(signed: Bool = false){
        guard let nameText = nameField.text, !nameText.isEmpty, let depositText = depositField.text, !depositText.isEmpty else {
            AlertManager.sendAlert(title: "Incomplete Info", message: "Please complete all the information📝!", click: "OK", inView: self)
            return
        }
        
        if let depositNum = Int(depositText) {
            
            let startTime = self.startTimePicker.date.nearest30Min
            var endTime = self.endTimePicker.date.nearest30Min
            
            
            if DateManager.getHoursDiff(start: startTime, end: endTime) <= -20 {
                endTime = Calendar.current.date(byAdding: .day, value: 1, to: endTime) ?? endTime
            }
            
            
            if endTime <= startTime{
                AlertManager.sendAlert(title: "Time Error", message: "The endtime cannot be the same as or ealier than the start time. Please adjust the endTime. ", click: "OK", inView: self)
                startTimePicker.setDate(Date().nearest30Min, animated: true)
                updateEndTime()
                return
            }
            
            if DateManager.getMinutesDiff(start: startTime, end: endTime) > 360{
                AlertManager.sendAlert(title: "Time Error", message: "You cannot have a shift that is longer than 6 hours. Please adjust the time or split it into two separate shifts.", click: "OK", inView: self)
                startTimePicker.setDate(Date().nearest30Min, animated: true)
                updateEndTime()
                return
            }
            
            let status = Status(signed: false, signIn: self.defaultDate, signOut: self.defaultDate, breakIn: self.defaultDate, breakOut: self.defaultDate)
            if signed{
                status.signed = true
                status.signIn = Date()
            }
            
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyyMMddhh"
            var identifier = depositText + "-"
            identifier += formatter2.string(from: startTime)
            
            let newMember = Member(identifier: identifier, name: nameText, deposit: depositNum, room: "", role: self.choreShift, shiftType: self.shiftType, startTime: startTime, endTime: endTime, status: status, source: "KC")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"
            
            var infoPart = "Name: " + nameText + "\n"
            infoPart += "Deposit: " + depositText + "\n"
            infoPart += "StartTime: " + formatter.string(from: startTime) + "\n"
            infoPart += "EndTime: " + formatter.string(from: endTime) + "\n"
            infoPart += "Chore shift:" + self.choreShift + "\n"
            infoPart += "Type: " + self.shiftType + "\n"
            
            /// warning
            let refreshAlert = UIAlertController(title: "Register a shift", message: "⚠️You are registering a shift. Please note that your shift CANNOT be changed once submitted!\n" + infoPart, preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Confirmed", style: .default, handler: { _ in
                self.completion?(newMember)
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
            
            present(refreshAlert, animated: true, completion: nil)
        }else{
            AlertManager.sendAlert(title: "Incorrect Deposit⚠️", message: "Please double check the deposit number🔢. It must contain digits only", click: "OK", inView: self)
        }
        return
    }

}

extension AddViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == nameField{
            depositField.becomeFirstResponder()
        }
        else{
            textField.resignFirstResponder()
        }
        return true
    }
}


extension AddViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let crewManager = crewManager{
            return crewManager.allElements.count
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CrewCollectionViewCell.identifier, for: indexPath) as! CrewCollectionViewCell
        if let crewManager = crewManager{
            cell.config(crew: crewManager.allElements[indexPath.row] as! Crew, selectedCrew: self.choreShift)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cell = collectionView.cellForItem(at: indexPath) as! CrewCollectionViewCell
        self.choreShift = cell.textLabel.text ?? "Regular"
        self.updateEndTime()
        self.collectionView.reloadData()
    }
    
    
}
