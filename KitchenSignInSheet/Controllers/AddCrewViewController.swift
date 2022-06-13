//
//  AddCrewViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 3/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit



@available(iOS 14.0, *)
final class AddCrewViewController: AddCrewViewControllerOld  {

    private let colorWell: UIColorWell = {
        let colorWell = UIColorWell()
        colorWell.supportsAlpha = false
        colorWell.selectedColor = .black
        colorWell.backgroundColor = .systemGray6
        colorWell.title = "Color"
        return colorWell
    }()

    
    
    override init(crewManager: CrewManager? = nil){
        super.init(crewManager: crewManager)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // colorWell
        colorWell.addTarget(self, action: #selector(colorChanged), for: .valueChanged)
        view.addSubview(colorWell)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        colorWell.frame = CGRect(x: super.listView.right + 100 + view.width / 9,
                                 y: super.tableView.bottom - 30,
                                 width: view.width / 4.5, height: 40)
        
    }
    
    @objc private func colorChanged(){
        selectedColor = colorWell.selectedColor ?? .black
        colorWell.backgroundColor = selectedColor
    }
    
    override func setSelectedColor(color: UIColor){
        super.setSelectedColor(color: color)
        colorWell.selectedColor = color
        colorWell.backgroundColor = color
    }
}



class AddCrewViewControllerOld: EditManagerViewController {
    static let identifier = "AddCrewViewControllerOld"


    var selectedColor: UIColor = .black
    
    init(crewManager: CrewManager? = nil){
        super.init(nibName: nil, bundle: nil)
        self.manager = crewManager
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = "Manage Crews"
        sectionLabels = [["Name","ID"],
                             ["Hours",
                              "Debit rate",
                              "Credit rate",
                              "Daily capacity",
                              "Color"]
        ]
        
        sectionPlaceHolder = [["Veggie (unique)",
                                   "Vg (2 letters)"],
                                  ["4",
                                   "16",
                                   "13",
                                   "2",
                                   "black"
                                  ]
        ]
        
        sectionValues = [[nil, nil], [nil, nil, nil, nil, nil]]
        
        super.viewDidLoad()
        
        self.listHead.text = "Existing crews"
        self.tableViewHead.text = "Add a new crew"
    }
    
    
    override public func getElementInfo(section: Int, row: Int) -> String {
        if let crew = manager?.getElement(at: section) as? Crew{
            switch row{
            case 0:
                return "ID\t\t\t\(crew.crewID)"
            case 1:
                return "hours\t\t\(crew.hours)"
            case 2:
                return "debit\t\t\(crew.debitRate)"
            case 3:
                return "credit\t\t\(crew.creditRate)"
            case 4:
                return "capacity\t\(crew.capacity)"
            default:
                return " "
            }
        }
        return " "
    }
    
    override public func getElementInfo(element: Element) -> [[String?]] {
        if let crew = element as? Crew{
            setSelectedColor(color: crew.color)
            return [["\(crew.name)", "\(crew.crewID)"], ["\(crew.hours)", "\(crew.debitRate)", "\(crew.creditRate)", "\(crew.capacity)", "selected color"]]
            
        }
        return sectionValues
    }
    
    override public func getElementInfoCount() -> Int {
        return 5
    }
    
    override public func getElementColor(element: Element) -> UIColor {
        if let crew = element as? Crew{
            return crew.color
        }
        return .black
    }
    
    func finishSave(){
        listView.reloadData()
        sectionValues = [[nil, nil], [nil, nil, nil, nil, nil]]
        configureModels()
    }
    

    // MARK:  Action
    override public func save(){
        guard let name = models[0][0].value,
              !name.isEmpty,
              let crewID = models[0][1].value,
              !crewID.isEmpty,
              let hoursText = models[1][0].value,
              let debitRateText = models[1][1].value,
              let creditRateText = models[1][2].value,
              let capacityText = models[1][3].value,
              //let color = models[1][3].value,
              let hours = Float(hoursText),
              let debitRate = Double(debitRateText),
              let creditRate = Double(creditRateText),
              let capacity = Int(capacityText)
        else {
            LogManager.writeLog(info: "failed to create a new crew because the input information is not valid.")
            AlertManager.sendAlert(title: "Failed", message: "You did not added a crew. The input information is incomplete or invalid.", click: "OK", inView: self)
            return
        }
        
        let crew = Crew(name: name, crewID: crewID, hours: hours, debitRate: debitRate, creditRate: creditRate, color: selectedColor, capacity: capacity)
        crew.deletable = true
        manager?.add(newElement: crew){ [weak self] error in
            if (error == nil){
                AlertManager.sendAlert(title: "Success", message: "You have added a crew", click: "OK", inView: self, completion: {self?.finishSave()})
                LogManager.writeLog(info: "successfully created a new crew: \(crew.toString())")
            }else{
                AlertManager.sendAlertWithCancel(title: "Crew exists!", message: "\(crew.name) already exists. Do you want to replace it?", click: "OK", inView: self, completion: {
                    self?.manager?.update(element: crew){ error2 in
                        if let err = error2{
                            AlertManager.sendAlert(title: "Failed", message: "Operation failed! Error: \(err)", click: "OK", inView: self)
                            LogManager.writeLog(info: "failed to updated crew: \(crew.toString()); error: \(err)")
                        }else{
                            
                            AlertManager.sendAlert(title: "Success", message: "You have updated crew \(crew.name)", click: "OK", inView: self, completion: {self?.finishSave()})
                            LogManager.writeLog(info: "successfully updated crew: \(crew.toString())")
                        }
                    }
                })
            }
        }
    }


    func setSelectedColor(color: UIColor){
        selectedColor = color
    }
    
    

}
