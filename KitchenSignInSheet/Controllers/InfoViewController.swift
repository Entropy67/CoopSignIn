//
//  InfoViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/21/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit


class InfoViewController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate{
    

    var viewShiftList = [Member]()
    var allShiftList = [ [Member](), [Member](), [Member](), [Member](), [Member]()]
    
    var searchController : UISearchController!
    
    @IBOutlet weak var dateView: UIDatePicker!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headView: UITableView!
    
    let noResultsLabel: UILabel = {
        let label = UILabel(frame:.zero)
        label.text = "No Result!"
        label.textAlignment = .center
        label.textColor = MyColor.first_color
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
//    let chartButton: UIButton = {
//        let button = UIButton()
//        button.backgroundColor = .systemGray6
//        button.layer.cornerRadius = 10
//        button.setImage(UIImage(systemName: "chart.bar.xaxis",  withConfiguration: ViewController.configuration), for: .normal)
//        button.tintColor = MyColor.first_color
//        return button
//    }()

    var searchText = ""

    
    private lazy var optionsManager: OptionsManager = {
        let manager = HomeOptionsManager(options: [ "No-shows", "Credits", "Fine", "Reset"], mainView: self, anchorPosition: "right")
        
        manager.didSelectOption = { (option) in
            if option == "No-shows"{
                self.showNoShowOnly()
            }else if option == "Credits"{
                self.showCreditOnly()
            }else if option == "Reset"{
                self.resetData()
            }else if option == "Fine"{
                self.showFineOnly()
            }else if option == "Export"{
                self.exportData()
            }
            
            manager.didTapBackground()
        }
        return manager
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: InfoTableViewCell.identifier, bundle: nil)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tag = 233
        
        headView.delegate = self
        headView.dataSource = self
        headView.tag = 133
        navigationItem.title = "History"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .done, target: self, action: #selector(didTapShowOptionsButton))

        tableView.register(nib, forCellReuseIdentifier: InfoTableViewCell.identifier)
        headView.register(nib, forCellReuseIdentifier: InfoTableViewCell.identifier)
        
        dateView.addTarget(self, action: #selector(updateDate), for: .valueChanged)
        
        loadData(date: Date()){ [weak self] in
            self?.updateTableView()
        }
        
        //chartButton.addTarget(self, action: #selector(showCharts), for: .touchUpInside)

        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        //self.searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "search by shift name or deposit"
        tableView.tableHeaderView = self.searchController.searchBar
        searchController.showsSearchResultsController = true
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        self.optionsManager.closeOptions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //chartButton.frame = CGRect(x: view.frame.width - 200, y: view.frame.height - 100, width: 100, height: 40)
        //view.addSubview(chartButton)
        noResultsLabel.frame = CGRect(x: (view.frame.width - 200)/2,
                                      y: (view.frame.height - 52) / 2,
                                      width: 200,
                                      height: 52)
        view.addSubview(noResultsLabel)
    }
    
    func exportData(){
        // export records
        
        
        // save data
        
    }
    
    
    @objc func didTapShowOptionsButton(_ sender: Any) {
        if optionsManager.didShowOptions{
            optionsManager.closeOptions()
        }else{
            optionsManager.showOptions()
        }
    }
    
//    @objc private func showCharts(){
//        
//        getData(){ [weak self] sectionIndex, alldata in
//            guard let strongSelf = self else{
//                return
//            }
//            let vc = ChartViewController(frame: strongSelf.view.bounds, dataX: [sectionIndex, sectionIndex], dataY: alldata, labels: ["All shifts", "No shows"])
//            strongSelf.present(vc, animated: true)
//        }
//    }
    
    private func getData(completion: @escaping ([Double], [[Double]]) -> Void){
        let sectionIndex = [0.0, 2.0, 4.0, 6.0, 8.0]
        var totalCounts = [Double]()
        var noShows = [Double]()
        
        for section in 0..<allShiftList.count{
            var noshow = 0
            var num = 0
            for mem in allShiftList[section]{
                num += 1
                if !mem.status.signed{
                    noshow += 1
                }
            }
            totalCounts.append(Double(num))
            noShows.append(Double(noshow))
        }
        completion(sectionIndex, [totalCounts, noShows])
        return
    }
    
    private func updateTableView(){
        tableView.reloadData()
        if viewShiftList.count > 0{
            noResultsLabel.isHidden = true
            tableView.isHidden = false
        }else{
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        }
    }
    
    func resetData(){
        viewShiftList = allShiftList.reduce([], +)
        updateTableView()
    }
    
    func showNoShowOnly(){
        resetData()
        viewShiftList =  viewShiftList.filter({(shift: Member) -> Bool in
            return shift.status.noShow
        })
        updateTableView()
    }
    
    func showCreditOnly(){
        resetData()
        viewShiftList =  viewShiftList.filter({(shift: Member) -> Bool in
            return shift.shiftType == "Credit"
        })
        updateTableView()
    }
    
    func showFineOnly(){
        resetData()
        viewShiftList =  viewShiftList.filter({(shift: Member) -> Bool in
            return abs(shift.status.fine) > 0.5
        })
        //print("show fin only: viewmemxount: \(viewShiftList.count)")
        updateTableView()
    }
    
    func getShiftInfo(shift: Member) -> String{
        
        return shift.name
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func loadData(date: Date, completion: @escaping (() -> Void)){
        let userDefaults = UserDefaults.standard
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let key = "memberList-\( formatter.string(from: date))"
        if !isKeyPresentInUserDefaults(key: key){
            
            LogManager.writeLog(info: "no such key in memory \(key)")
            completion()
            return
        }
        guard let decoded  = userDefaults.data(forKey: key) else{
            completion()
            return
        }
        do{
            //self.shiftList = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [[Shift]]
            allShiftList  = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(decoded) as! [[Member]]
        }catch{
            LogManager.writeLog(info: "load data error: \(error)")
        }
        viewShiftList = allShiftList.reduce([], +)
        completion()
    }
    
    func clearShiftList(){
        for i in 0..<allShiftList.count{
            allShiftList[i].removeAll()
        }
        viewShiftList = []
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text{
            if searchText == ""{
                tableView.reloadData()
            }else{
                searchShift(searchText: searchText)
                self.searchText = searchText
            }
        }
    }
    
    private func searchShift(searchText: String){
        var allname = [String]()
        var alldeposite = [String]()
        let allShift = allShiftList.reduce([], +)
        
        for mem in viewShiftList{
            allname.append(mem.name)
            alldeposite.append("\(mem.deposit)")
        }

        self.viewShiftList = searchText.isEmpty ? allShift : allShift.filter({(shift: Member) -> Bool in
            let memDeposite = "\(shift.deposit)"
            return (shift.name.range(of: searchText, options: .caseInsensitive) != nil) || (memDeposite.range(of: searchText) != nil)
        })
        
        updateTableView()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        self.searchShift(searchText: self.searchText)
        //print("will dismiss search controller, searchtext =", self.searchText)
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        self.searchShift(searchText: self.searchText)
        //print("did dismiss search controller, searchtext =", self.searchText)
    }
    
    @objc func updateDate(){
        clearShiftList()
        loadData(date: dateView.date){[weak self] in
            self?.updateTableView()
        }
    }
}


extension InfoViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView.tag == 233{
            let mem = viewShiftList[indexPath.row]
            mem.config()
            mem.presentInfo(inView: self, mode: .full)
        }
        
    }
}

extension InfoViewController: UITableViewDataSource{
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40

    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 233{
            return self.viewShiftList.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "InfoTableViewCell", for: indexPath) as! InfoTableViewCell
        
        
        if tableView.tag == 233{
            let mem = self.viewShiftList[indexPath.row]
            mem.config()
            cell.config(mem: mem, head: false)
        }else{
            cell.config(mem: nil, head: true)
        }
        return cell
    }
    
    
}
