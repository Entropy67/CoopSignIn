//
//  AddChoreViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 5/7/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit

class AddChoreViewController: EditManagerViewController {
    
    static let identifier = "EditManagerViewController"
    
    var crewManager: CrewManager? = nil
    
    init(choreManager: ChoreManager? = nil){
        super.init(nibName: nil, bundle: nil)
        self.manager = choreManager
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        title = "Manage Chore"
        
        sectionLabels = [["Name","deposit"],
                             ["Date",
                              "Start Time",
                              "End Time",
                              "Crew"]
        ]
        
        sectionPlaceHolder = [["member name", "12345"],
                                  ["Mon",
                                   "9:00",
                                   "15:00",
                                   "Office"
                                  ]
        ]
        
        sectionValues = [[nil, nil], [nil, nil, nil, nil]]

        super.viewDidLoad()
        
        self.listHead.text = "Existing weekly shift"
        self.tableViewHead.text = "Add a weekly shift"
    }
    
    
    override public func getElementInfo(section: Int, row: Int) -> String {
        if let chore = manager?.getElement(at: section) as? Chore{
            switch row{
            case 0:
                return "deposit\t\t\t\(chore.member.id)"
            case 1:
                return "date\t\t\t\t\(chore.date)"
            case 2:
                return "start\t\t\t\t\(chore.startTime)"
            case 3:
                return "end\t\t\t\t\(chore.endTime)"
            case 4:
                return "crew\t\t\t\t\(chore.role.name)"
            default:
                return " "
            }
        }
        return " "
    }
    
    override public func getElementInfo(element: Element) -> [[String?]] {
        if let chore = element as? Chore{
            return [["\(chore.member.name)", "\(chore.member.id)"], ["\(chore.date)", "\(chore.startTime)", "\(chore.endTime)", "\(chore.role.name)"]]
        }
        return sectionValues
    }
    
    
    override public func getElementInfoCount() -> Int {
        return 5
    }
    
    override func getElementColor(element: Element) -> UIColor {
        if let chore = element as? Chore{
            return chore.role.color
        }
        return .black
    }
    
    func finishSave(){
        listView.reloadData()
        sectionValues = [[nil, nil], [nil, nil, nil, nil]]
        configureModels()
    }
    
    override func save() {
        guard let name = models[0][0].value,
              !name.replacingOccurrences(of: " ", with: "").isEmpty,
              let depositString = models[0][1].value,
              let deposit = Int(depositString),
              let dateRaw = models[1][0].value,
              let date = DateManager.getWeekdayName(day: dateRaw),
              let startTime = models[1][1].value,
              let endTime = models[1][2].value,
              let role = models[1][3].value else{
            LogManager.writeLog(info: "failed to create a new chore because the input information is not valid")
            AlertManager.sendAlert(title: "Failed", message: "Failed to add a chore shift. The input information is incomplete or invalid.", click: "OK", inView: self)
            return
        }
        let id = depositString + "-" + startTime
        let member = Person(name: name, deposit: deposit)
        if let crew = crewManager?.find(id: role) as? Crew{
            let chore = Chore(id: id, date: date, startTime: startTime, endTime: endTime, member: member, role: crew)
            
            manager?.add(newElement: chore){[weak self] error in
                if(error == nil){
                    AlertManager.sendAlert(title: "Success", message: "You have added a chore", click: "OK", inView: self, completion: {self?.finishSave()})
                    LogManager.writeLog(info: "successfully added a new chore shift: \(chore.toString())")
                }else{
                    AlertManager.sendAlertWithCancel(title: "Chore exists!", message: "\(name) has a shift from \(startTime) to \(endTime). Do you want to replace it?", click: "OK", inView: self){
                        self?.manager?.update(element: chore){error2 in
                            if let err = error2{
                                AlertManager.sendAlert(title: "Failed", message: "Cannot edit the shift. Error: \(err)", click: "OK", inView: self)
                            }else{
                                AlertManager.sendAlert(title: "Success", message: "You have updated chore shift of \(name)", click: "OK", inView: self, completion: {self?.finishSave()})
                                LogManager.writeLog(info: "successfully update chore shift: \(chore.toString())")
                            }
                        }
                    }
                }
            }
        }else{
            AlertManager.sendAlert(title: "Failed", message: "Failed to add a chore shift. The crew doesn't exist.", click: "OK", inView: self)
        }
        
    }
    
}
