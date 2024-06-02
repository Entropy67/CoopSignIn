//
//  ViewController.swift
//  KitchenSignInSheet
//
//  Created by Sirius on 2/20/22.
//  Copyright © 2022 AMO. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GTMSessionFetcher
import JGProgressHUD




class ViewController: SecuredViewController{
    private let spinner = JGProgressHUD(style: .dark)
    
    /// button and label
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var noFoundButton: UIButton!
    @IBOutlet weak var jumpToNowButton: UIButton!
    @IBOutlet weak var bottomBlurView: UIVisualEffectView!
    
    weak var timer: Timer? // set time out to download the sign-in form every 2 hours
    
    var CREW_NAME = "Kitchen"
    let autoRefreshInterval = 1800 // 0.5 hours, automatically download sign in form from google drive
    var googleDriveFolder = ""
    
    var localWeeklySheetName: String? = nil // spreadsheet name to store weekly chore shift assignment
    var localSignInFormName: String? = nil // speadsheet name to store sign in form
    var remoteWeeklySheetFileID: String? = nil // spreadsheet id on google drive

    /// managers
    let dataManager = DataManager() // load and save data
    let crewManager = CrewManager() // add, edit, delete crews
    let policyManager = PolicyManager() // edit policies, i.e., maximal late minues
    let choreManager = ChoreManager() // add, edit, delete permanant chore shift
    
    private let refreshControl = UIRefreshControl()
    
    var today = Date()
    var lastUpdateTime = Date(timeIntervalSince1970: 0) // last time upload data to google drive
    
    /// google service
    private let googleDriveService = GTLRDriveService()
    private let googleSheetService = GTLRSheetsService()
    private var googleUser: GIDGoogleUser?
    private var googleDriveManager = GoogleDriveManager()
    
    var checking = false
    var didShowKCCOptions = false
    static let configuration = UIImage.SymbolConfiguration(pointSize: 30)
    
    
    /// Drop down menu in the top left corner
    private lazy var optionsManager: OptionsManager = {
        var manager = HomeOptionsManager(options: [//"Add a new shift",
                                                   "Look up history",
                                                   "Sign in Google Drive",
                                                   "Open advanced options"
                                                  ],
                                         mainView: self,
                                         anchorPosition: "left")
        
        manager.didSelectOption = { (option) in
            switch option{
            case "Add a new shift":
                self.addNewShift()
            case "Look up history":
                self.seeInfo()
            case "Sign in Google Drive":
                self.didTapSignInButton(){(success) in print(success)
                }
            case "Open advanced options":
                self.showKCCOptions()
            case "* Manage crews":
                self.addNewCrew()
            case "* Upload spreadsheet":
                self.seeFile()
            case "* Manage permenant shift":
                self.addPermenantShift()
                
            case "* Sign out Google Drive":
                self.didTapSignOutButton()
            case "* Close advanced options":
                self.closeKCCOptions()
            case "* Recover from drive":
                self.recoverFromDrive()
                
            case "* Settings":
                self.changeSettings()
            
            case "* Reload today's sheet":
                self.reloadSignInSheet()
            
            default:
                AlertManager.sendAlert(title: "Option not available", message: "...", click: "OK", inView: self)
                break
            }
            manager.didTapBackground()
        }
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        LogManager.writeLog(info: "\t\t\t new log")
        
        /// ***  configuration ***///
        CREW_NAME = UserDefaults.standard.string(forKey: SettingBundleKeys.CrewNameKey) ?? "Kitchen"
        googleDriveFolder = "\(CREW_NAME)DailyFDC"
        updateTitle()
        
        // security
        securityManager = SecurityManager()
        securityManager?.securedViewList.append(self)
        securityManager?.config()
        
        // crew
        crewManager.config()
        crewManager.initCrewList()
        
        //chore
        choreManager.config()
        
        
        // nevigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .done, target: self, action: #selector(didTapShowOptionsButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start Checking", style: .done, target: self, action: #selector(didTapCheckButton))
        
        navigationItem.titleView = titleButton
        titleButton.addTarget(self, action: #selector(didTapLockButton), for: .touchUpInside)
        
        if !UserDefaults().bool(forKey: "setup"){
            UserDefaults().set(true, forKey: "setup")
            UserDefaults().set(Date(), forKey: "lastUpdateTime")
        }
        
        /***** Configure DataManager*****/
        lastUpdateTime = UserDefaults().value(forKey: "lastUpdateTime") as! Date
        dataManager.lastUpdateTime = lastUpdateTime
        dataManager.config()
        dataManager.shiftManager.crewManager = crewManager
        
        /***** Configure Collection view*****/
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshAll), for: .valueChanged)
        
        collectionView.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: MyCollectionViewCell.identifier)
        collectionView.register(AddNewShiftCollectionViewCell.self, forCellWithReuseIdentifier: AddNewShiftCollectionViewCell.identifier)
        // register header
        collectionView.register(HeaderCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.identifier)
        // register footer
        collectionView.register(FooterCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: FooterCollectionReusableView.identifier)

        collectionView.delegate = self
        collectionView.dataSource = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCollectionView))

        self.collectionView.addGestureRecognizer(longTapGesture)

        
        /***** Configure Google Sign In *****/
        
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance().presentingViewController = self
        googleDriveManager.config()
        if googleDriveManager.useGoogleDrive{
            GIDSignIn.sharedInstance()?.scopes = [kGTLRAuthScopeDrive,kGTLRAuthScopeSheetsDrive]
            GIDSignIn.sharedInstance()?.restorePreviousSignIn()
            
            googleDriveManager.googleDriveService = googleDriveService
            googleDriveManager.googleUser = GIDSignIn.sharedInstance()?.currentUser
            googleDriveManager.googleSheetService = googleSheetService
        }else{
            refreshAll()
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let securityManager = securityManager else{
            return
        }
        
        
        // determine how the lock icon look like according to the lock status
        if securityManager.lock{
            titleButton.setImage(UIImage(systemName: "lock.fill", withConfiguration: ViewController.configuration), for:.normal)
        }else{
            titleButton.setImage(UIImage(systemName: "lock.open", withConfiguration: ViewController.configuration), for:.normal)
        }
        
        while securityManager.securedViewList.count > 1{
            _ = securityManager.securedViewList.popLast()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        layout.itemSize = CGSize(width: (view.frame.size.width/4-10),
                                 height: (view.frame.size.width/4-10))
        
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.scrollDirection = .vertical
        collectionView.collectionViewLayout = layout
        collectionView.collectionViewLayout.invalidateLayout()
        
    }
    
    
    @objc func didTapLockButton(){
        securityManager?.update(inView: self)
    }
    
    
    
    @objc func didLongPressCollectionView(gesture: UITapGestureRecognizer){
        
        if isModalInPresentation{
            return
        }
        
        isModalInPresentation = true
        
        guard let securityManager = securityManager else {
            return
        }
        
        let pointInCollectionView = gesture.location(in: self.collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: pointInCollectionView) else{
            return
        }

        if let shift = dataManager.shiftManager.getShift(section: indexPath.section, row: indexPath.row){

            if securityManager.lock{
                shift.presentInfo(inView: self, mode: .basic)
            }else{
                shift.presentInfo(inView: self, mode: .full)
            }
        }
        return
    }

    
    @IBAction func didTapHelpButton(){
        guard let vc = storyboard?.instantiateViewController(identifier: "WebView") as? WebViewController else {
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    @IBAction func didTapNotFindMyNameButton(){
        
        let refreshAlert = UIAlertController(title: AlertMessages.addNewShiftAlert.title,
                                             message: AlertMessages.addNewShiftAlert.message,
                                             preferredStyle: .alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            
            guard let strongSelf = self else{
                return
            }
            if PolicyManager.allowMemberToCreateShift(){
                guard let vc = strongSelf.storyboard?.instantiateViewController(identifier: "NewSignIn2") as? AddViewController else {
                    return
                }
                vc.signIn = true
                vc.crewManager = strongSelf.crewManager
                
                vc.completion = { newShift in DispatchQueue.main.async {
                    strongSelf.navigationController?.popToRootViewController(animated: true)
                    strongSelf.dataManager.shiftManager.addShift(newShift: newShift){ success in
                        if !success{
                            LogManager.writeLog(info: "manually sign-in failed because of duplication for shift \(newShift.name) or maximal capacity exceeded")
                            AlertManager.sendRedAlert(title: AlertMessages.addNewShiftFailed.title, message: AlertMessages.addNewShiftFailed.message, click: "OK", inView: self)
                        }else{
                            LogManager.writeLog(info: "SignIn: sign-in successful for shift \(newShift.name). shift information: \(newShift.toString())")
                            AlertManager.sendAlert(title: AlertMessages.addNewShiftSuccess.title , message:  AlertMessages.addNewShiftSuccess.message + "\(newShift.name).", click: "OK", inView: self)
                        }
                    }
                    strongSelf.collectionView.reloadData()
                    strongSelf.dataManager.saveData(completion: nil)
                }
                }
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else{
                AlertManager.sendAlert(title: AlertMessages.addNewShiftForbidden.title, message: AlertMessages.addNewShiftForbidden.message, click: "OK", inView: strongSelf)
            }
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func jumpToNow(){
        let numberOfSectionYouWant = DateManager.getSection(date: Date())
        let indexPath = NSIndexPath(item: 0, section: numberOfSectionYouWant )
        
        if let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath as IndexPath) {
            collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.contentInset.top), animated: true)
        }
    }
    
    
    
    
    @objc func refreshAll(){
        today = Date()
        updateTitle()
        googleDriveManager.config()
        securityManager?.config()
        
        spinner.show(in: view)
        startAutoRefresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.spinner.dismiss(animated: true)
        }
        
        updateSignInSheet(){
            [weak self] () in
            DispatchQueue.main.async {
                self?.dataManager.shiftManager.refresh()
                self?.collectionView.reloadData()
                self?.spinner.dismiss(animated: true)
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    
    
    // if appropriate, make sure to stop your timer in `deinit`
    deinit {
        timer?.invalidate() // stop timer
    }
    
    
    private func startAutoRefresh(){

        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
        
        let now = Date()
        let eight_today = now.dateAt(hours: 8, minutes: 0)
        let nine_thirty_today = now.dateAt(hours: 21, minutes: 30)
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(autoRefreshInterval), repeats: true) { [weak self] _ in
            let now = Date()
            if now >= eight_today && now <= nine_thirty_today{
                self?.refreshSignInFormSilently(){[weak self] in
                    self?.collectionView.reloadData()
                }
            }else{
                LogManager.writeLog(info: "Auto refreshing terminiated!")
                self?.timer?.invalidate() // stop timer
            }
        }
    }
    
    

    func updateTitle(){
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "yyyy-MM-dd, EEEE"
        titleLabel.text  = "UCHA \(CREW_NAME) Sign In Sheet --- " + formatter.string(from: today)
        titleLabel.textColor = MyColor.first_text_color
        titleLabel.backgroundColor = MyColor.first_color
        
        let compactMode = UserDefaults.standard.bool(forKey: SettingBundleKeys.CompactModeKey)
        
        if compactMode{
            helpButton.isHidden = true
            noFoundButton.isHidden = true
            jumpToNowButton.isHidden = true
            bottomBlurView.effect = nil
            //bottomBackground.alpha = 0
            //bottomBlurView.removeFromSuperview()
        }else{
            helpButton.isHidden = false
            noFoundButton.isHidden = false
            jumpToNowButton.isHidden = false
            bottomBlurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            helpButton.backgroundColor = MyColor.first_color
            helpButton.setTitleColor(MyColor.first_text_color, for: .normal)
            noFoundButton.backgroundColor = MyColor.first_color
            noFoundButton.setTitleColor(MyColor.first_text_color, for: .normal)
            jumpToNowButton.backgroundColor = MyColor.first_color
            jumpToNowButton.setTitleColor(MyColor.first_text_color, for: .normal)
        }
    }
    
    func seeFile(){
        guard let vc = storyboard?.instantiateViewController(identifier: "File") as? FileViewController else {
            return
        }
        vc.googleDriveManager = googleDriveManager
        vc.googleDriveTarget = googleDriveFolder
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func seeInfo(){
        guard let vc = storyboard?.instantiateViewController(identifier: "Info") as? InfoViewController else {
            return
        }
        navigationController?.pushViewController(vc, animated: true)
    }


    
    
    
    func addNewShift(){
        guard let vc = storyboard?.instantiateViewController(identifier: "NewSignIn2") as? AddViewController else {
            return
        }
        vc.signIn = false 
        vc.crewManager = crewManager
        vc.completion = {[weak self] newShift in DispatchQueue.main.async {
            
            guard let strongSelf = self else{
                return
            }
            strongSelf.navigationController?.popToRootViewController(animated: true)
            strongSelf.dataManager.shiftManager.addShift(newShift: newShift){ success in
                    if success{
                        LogManager.writeLog(info: "Add a new shft for \(newShift.name). Info: \(newShift.toString())")
                        AlertManager.sendAlert(
                            title:AlertMessages.addNewShiftSuccess.title,
                            message:AlertMessages.addNewShiftSuccess.message,
                            click: "OK", inView: self)
                    }else{
                        LogManager.writeLog(info: "failed to add a new shift, because a shift already exists for \(newShift.name) or maximal capacity is exceeded.")
                        AlertManager.sendRedAlert(title: AlertMessages.addNewShiftFailed.title, message:  AlertMessages.addNewShiftFailed.message, click: "OK", inView: self)
                    }
                }
            strongSelf.collectionView.reloadData()
            strongSelf.dataManager.saveData(completion: nil)
            }
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func showKCCOptions(){
        didTapKCCOptions(){ [weak self] in
            self?.optionsManager.resetOptions(options: [//"Add a new shift",
                                                        "Check History",
                                                        "Sign in Google Drive",
                                                        "* Settings",
                                                        "* Manage crews",
                                                        "* Upload spreadsheet",
                                                        //"* Recover from drive",
                                                        "* Manage permenant shift",
                                                        "* Sign out Google Drive",
                                                        "* Close advanced options"
                                                       ])
            self?.optionsManager.showOptions()
        }
    }
    
    func closeKCCOptions(){
        optionsManager.resetOptions(options: [
                                              "Look up history",
                                              "Sign in Google Drive",
                                              "Open advanced options"
                                             ])
    }
    
    
    
    func didTapKCCOptions(completion: @escaping () -> Void){
        securityManager?.kccPasswordCheck(inView: self){ success in
            if success{
                completion()
            }
        }
    }

    func searchMembersDeposit(){
        
    }
    
    func addNewCrew(){
        if #available(iOS 14.0, *) {
            let vc = AddCrewViewController(crewManager: crewManager)
            vc.completion = {[weak self] () in
                self?.navigationController?.popToRootViewController(animated: true)
            }
            navigationController?.pushViewController(vc, animated: true)
        }else{
            let vc = AddCrewViewControllerOld(crewManager: crewManager)
            vc.completion = {[weak self] () in
                self?.navigationController?.popToRootViewController(animated: true)
            }
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    
    func addPermenantShift(){
        let vc = AddChoreViewController(choreManager: choreManager)
        vc.crewManager = crewManager
        vc.completion = {[weak self] () in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func changeSettings(){
        let vc = SettingViewController()
        vc.policyManager = policyManager
        vc.securityManager = securityManager
        vc.crewManager = crewManager
        vc.googleDriveManager = googleDriveManager
        vc.shiftManager = dataManager.shiftManager
        vc.completion = {[weak self] () in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func reloadSignInSheet(){
        // Dangerous option. may delete all historical records
        AlertManager.sendAlertWithCancel(title: AlertMessages.reloadSignInSheetAlert.title, message: AlertMessages.reloadSignInSheetAlert.message, click: "Okay", inView: self){[weak self] in
            // remove info in shiftlist
            self?.dataManager.shiftManager.clearShiftList()
            
            // remove info in userDefaults
            self?.dataManager.clearUserDefaults()
            
            // delete locak csv file
            self?.dataManager.deleteCSV()
            
            // remove local sign-in form and weekly spreadsheet
            self?.dataManager.deleteSignInForm(fileNames: [self?.localWeeklySheetName, self?.localSignInFormName])
            
            // refresh all
            self?.refreshAll()
            
        }
        
    }
    
    func recoverFromDrive(){
        // Download all records from record.csv in google drive
        // This is not shown in the APP because it will delete all the local information on iPad.
        // Only use for de-bug
        if !googleDriveManager.useGoogleDrive{
            return
        }
        // download csv from google drive
        guard googleUser != nil else {
            LogManager.writeLog(info: "recoverFrom Drive failed because no google user")
            AlertManager.sendAlert(title: "Failed", message: "recoverFrom Drive failed because no google user", click: "OK", inView: self)
            return
        }
        
        AlertManager.sendAlertWithCancel(title: AlertMessages.recoverFromDriveAlert.title, message: AlertMessages.recoverFromDriveAlert.message, click: "Okay", inView: self){[weak self] in
            
            guard let strongSelf = self else{
                return
            }
            
            let formatter = DateManager.dateFormatter
            //configure names
            formatter.dateFormat = "MMddyyyy"
            let dateString = formatter.string(from: Date())
            let recordBackUpSheet =  "\(dateString)_Records_downloaded"
            let fileNameStrings = ["\(dateString)_Records.csv"]
            
            strongSelf.dataManager.shiftManager.clearShiftList()
            strongSelf.spinner.show(in: strongSelf.view)
            strongSelf.googleDriveManager.searchSignInForm(fileNameStrings: fileNameStrings){ (fileID, error) in
                if error == nil, fileID != nil{
                    strongSelf.googleDriveManager.downloadFile(fileID: fileID ?? ""){
                        (data, error) in
                        if error == nil{
                            DataManager.saveCSVFile(data: data, filename: recordBackUpSheet + ".csv"){(file) in
                                LogManager.writeLog(info: "Successfully download records from google drive")
                                // load data from the downloaded csv
                                strongSelf.dataManager.loadFromCSV(filename: recordBackUpSheet){success in
                                    strongSelf.spinner.dismiss(animated: true)
                                    if success{
                                        AlertManager.sendAlert(title: "Success", message: "Successfully recovered the sign-in sheet", click: "OK", inView: strongSelf, completion: {strongSelf.collectionView.reloadData()})
                                    }
                                    
                                }
                                //strongSelf.dataManager.loadFromSignInSheet(filename: signInForm, completion: nil)
                            }
                        }else{
                            strongSelf.spinner.dismiss(animated: true)
                            LogManager.writeLog(info: "Failed to download backup records sheet. error : \(String(describing: error)).")
                            AlertManager.sendAlert(title: "Failed", message: "recoverFrom Drive failed because failed to download the sheet. \(String(describing: error))", click: "OK", inView: strongSelf)
                            
                        }
                        return
                    }
                }
            }
            
        }
    }


    
    @objc func didTapShowOptionsButton(_ sender: Any) {
        if let securityManager = securityManager, !securityManager.lock{
            if self.optionsManager.didShowOptions{
                self.optionsManager.closeOptions()
            }else{
                self.optionsManager.showOptions()
            }
        }else{
            AlertManager.sendAlert(title: "Disabled", message: "Please tap the 🔒 button to use the KC mode.", click: "OK", inView: self)
        }
    }
    

    @objc func didTapCheckButton(){
        //LogManager.writeLog(info: "did tap check button")
        if checking{
            //LogManager.writeLog(info: "checking closed")
            navigationItem.rightBarButtonItem?.title = "Start Checking"
            navigationItem.rightBarButtonItem?.tintColor = .link
            checking = false
            dataManager.saveData(completion: nil)
            collectionView.reloadData()
            
            if !googleDriveManager.useGoogleDrive{
                AlertManager.sendAlert(title: "Done", message: "Check complete ✅", click: "OK", inView: self)
                return
            }
            
            spinner.show(in: view)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.spinner.dismiss(animated: true)
            }
            
            
            googleDriveManager.uploadData(target: googleDriveFolder, timeStamp: lastUpdateTime ){[weak self] (success, uploadError) in
                self?.spinner.dismiss(animated: true)
                if uploadError != ""{
                    AlertManager.sendAlert(title: AlertMessages.uploadFailed.title , message:  AlertMessages.uploadFailed.message + " \(uploadError)", click: "OK", inView: self)
                }else{
                    AlertManager.sendAlert(title: AlertMessages.uploadSuccess.title,
                                           message: AlertMessages.uploadSuccess.message,
                                           click: "OK", inView: self)
                }
                
            }
            
            // update the status in the google spreadsheet, column H
            if let fileIDString = self.remoteWeeklySheetFileID, googleDriveManager.useSpreadsheet{
                googleDriveManager.getDataFromSpreadsheet(spreadsheetId: fileIDString){[weak self] data in
                    guard let strongSelf = self else{
                        return
                    }
                    if let localWeeklySheetName = strongSelf.localWeeklySheetName{
                        DataManager.saveCSVFile(data: DataManager.anyArrayToData(any2DArray: data), filename: localWeeklySheetName){(file) in
                            strongSelf.dataManager.exportShiftFromCC(filename: localWeeklySheetName){ rowToBeUpdated, contentArray in
                                
                                strongSelf.googleDriveManager.updateRowFromSpreadsheet(spreadsheetId: fileIDString,
                                                                                       rowToBeUpdated: rowToBeUpdated,
                                                                                       columnToBeUpdated: rowToBeUpdated.map {_ in return "H"},
                                                                                       content: contentArray
                                )
                            }
                        }
                    }
                    
                }
            }
        }else{
            if let securityManager =  securityManager, !securityManager.lock{
                LogManager.writeLog(info: "start checking")
                navigationItem.rightBarButtonItem?.tintColor = .red
                checking = true
                navigationItem.rightBarButtonItem?.title = "Finish Checking and upload"
                collectionView.reloadData()
            }else {
                AlertManager.sendAlert(title: "Disabled", message: "Please tap the 🔒 button to use the KC mode.", click: "OK", inView: self)
            }
        }
        
    }
   
    
    /// upload data from previous day.
    /// this function will be called when this APP is used for the first time in a day
    private func uploadDataFromPreviousDay(completion: @escaping () -> Void ){
        //LogManager.writeLog(info: "try to updateSignIn  sheet. ")
        if DateManager.isSameDay(date1: self.lastUpdateTime, date2: Date()){
            completion()
            return
        }
        
        dataManager.saveData(completion: nil)
        
        if !googleDriveManager.useGoogleDrive{
            dataManager.shiftManager.clearShiftList() // clear all shifts from list
            completion()
            return
        }
        
        // upload data of the privous day
        LogManager.writeLog(info: "Cloud data not updated. Upload spreadsheet to google drive. last update time=\(self.lastUpdateTime). Now is \(Date())")
        
        googleDriveManager.uploadData(target: googleDriveFolder, timeStamp: lastUpdateTime){[weak self]
            (success, error) in
            if !success{
                LogManager.writeLog(info: "Upload faild. Unable to upload to Google Drive. Error: \(error). Please upload it to Google Drive manually later!")
                AlertManager.sendAlert(title: AlertMessages.uploadPreviousDayFailed.title, message: AlertMessages.uploadPreviousDayFailed.message + " Error: \(error).", click: "OK", inView: self)
            }
            
            self?.dataManager.shiftManager.clearShiftList() // clear all shifts from list
            completion()
        }
        return
        
    }
    
    /// refresh signin form without any notification
    /// this is used for auto-refreshing
    func refreshSignInFormSilently(completion: @escaping () -> Void){
        if !googleDriveManager.useGoogleDrive{
            completion()
            return
        }
        
        // then try to download from the google drive
        guard googleUser != nil else {
            LogManager.writeLog(info: "Silent refresh failed because no google user")
            completion()
            return
        }
        
        let formatter = DateManager.dateFormatter
        //configure names
        formatter.dateFormat = "MMddyyyy"
        let dateString = formatter.string(from: Date())
        let signInForm =  "\(dateString)_\(CREW_NAME)_Sign_In.csv"
        let fileNameStrings = [
            "\(dateString)_\(CREW_NAME)",
            "\(dateString) \(CREW_NAME)",
            "\(dateString)\(CREW_NAME)"
        ]

        //strongSelf.googleDriveManager.search(signInForm){ (fileID, error) in // search by exact name
        googleDriveManager.searchSignInForm(fileNameStrings: fileNameStrings){ [weak self] (fileID, error) in
            guard let strongSelf = self else{
                completion()
                return
            }
            if error == nil, fileID != nil{
                strongSelf.googleDriveManager.downloadFile(fileID: fileID ?? ""){
                    (data, error) in
                    if error == nil{
                        DataManager.saveCSVFile(data: data, filename: signInForm){(file) in
                            //LogManager.writeLog(info: "Silent refresh complete: successfully download the sign in form. Now load data from it.")
                            strongSelf.dataManager.loadFromSignInSheet(filename: signInForm, completion: nil)
                        }
                    }else{
                        LogManager.writeLog(info: "Silent refresh: Failed to download signin sheet. error : \(String(describing: error)).")
                    }
                    completion()
                    return
                }
            }else{
                completion()
                return
            }
        }
        return
    }
    
    
    
    
    /// update sign in sheet, contains multiple steps:
    /// 1. upload data from previous day (if this function is called for the first time in a day)
    /// 2. load records from Records.csv file
    /// 3. load from chore shift manager (permenant weekly shift)
    /// 4. load from sign in form on google drive
    /// 5. load from spreadsheet on google drive
    func updateSignInSheet(completion: @escaping ()->Void){
        dataManager.saveData(completion: nil)
        uploadDataFromPreviousDay(){ [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.lastUpdateTime = Date()
            strongSelf.dataManager.lastUpdateTime = Date()
            LogManager.writeLog(info: "update the last update time to \(strongSelf.dataManager.lastUpdateTime)")
            UserDefaults().set(strongSelf.lastUpdateTime, forKey: "lastUpdateTime")
            // first search the cvs file
            let formatter = DateManager.dateFormatter
            formatter.dateFormat = "MMddyyyy"
            let filename = "\( formatter.string(from: Date()))_Records"
            
            if DataManager.checkFileExist(filename: filename + ".csv"){
                strongSelf.dataManager.loadFromCSV(filename: filename, completion: nil)
            }else{
                //LogManager.writeLog(info: "Did not find history records in memory.")
            }
            
            // then load from chore shift
            strongSelf.dataManager.loadFromChoreManager(choreManager: strongSelf.choreManager)
            
            if !strongSelf.googleDriveManager.useGoogleDrive{
                completion()
                return
            }
            
            // then try to download from the google drive
            guard strongSelf.googleUser != nil else {
                LogManager.writeLog(info: "Failed to download the signin sheet because googleUser is nil.")
                AlertManager.sendAlert(title: AlertMessages.downloadFailed.title,
                                       message: AlertMessages.downloadFailed.message,
                                       click: "OK", inView: self)
                completion()
                return
            }
            
            strongSelf.loadFromSignInFormOnGoogleDrive(){success, error in
                if !success{
                    strongSelf.loadFromSignInFormInMemory(){ success2 in
                        strongSelf.loadFromSpreadSheet(){success3 in
                            if !success, !success2, !success3{
                                var errorCode = 0
                                if let error = error {
                                    errorCode = (error as NSError).code
                                }
                                if (errorCode == -1009){
                                    LogManager.writeLog(info: "Google Drive error: -1009, the Internet connection appears to be offline")
                                    AlertManager.sendAlert(
                                        title: AlertMessages.noInternetAlert.title,
                                        message: AlertMessages.noInternetAlert.message,
                                        click: "OK", inView: self)
                                }else{
                                    LogManager.writeLog(info: "No sign in form error.")
                                    AlertManager.sendAlert(title: AlertMessages.noSignInFormAlert.title, message: AlertMessages.noSignInFormAlert.message, click: "OK", inView: strongSelf)
                                }
                            }
                            completion()
                        }
                    }
                }else{
                    strongSelf.loadFromSpreadSheet(){success in
                        completion()
                    }
                }
            }
            
            
        }
        return
    }
    
    
    /// load chore shifts from the spreadsheet on google drive
    func loadFromSpreadSheet(completion: @escaping (Bool)->Void){
        if !googleDriveManager.useGoogleDrive || !googleDriveManager.useSpreadsheet{
            completion(true)
            return
        }
        
        let spreadsheetName = CREW_NAME + "WeeklyShift"
        let year = DateManager.getYear(date: Date())
        let week = DateManager.getWeekOfYear(date: Date())
        localWeeklySheetName = "\(year)-week\(week)-" + spreadsheetName + ".csv"
        googleDriveManager.searchSignInForm(fileNameStrings: [spreadsheetName]){[weak self] fileID, error in
            guard let strongSelf = self else{
                return
            }
            strongSelf.remoteWeeklySheetFileID = fileID
            if error == nil, let fileIDString = fileID{
                strongSelf.googleDriveManager.getDataFromSpreadsheet(spreadsheetId: fileIDString){data in
                    if let localWeeklySheetName = strongSelf.localWeeklySheetName{
                        DataManager.saveCSVFile(data: DataManager.anyArrayToData(any2DArray: data), filename: localWeeklySheetName){(file) in
                            strongSelf.dataManager.loadFromSpreadSheet(filename: localWeeklySheetName){ success, rowToBeUpdated in
                                completion(success)
                                strongSelf.googleDriveManager.updateRowFromSpreadsheet(spreadsheetId: fileIDString,
                                                                                       rowToBeUpdated: rowToBeUpdated,
                                                                                       columnToBeUpdated: rowToBeUpdated.map {_ in return "H"},
                                                                                       content: rowToBeUpdated.map {_ in return "Downloaded"}
                                )
                            }
                        }
                    }
                }
            }else{
                LogManager.writeLog(info: "failed to fetch the spreadsheet \(spreadsheetName). fileID:\(fileID), Error: \(error)")
                if error != nil{
                    // load from memory
                    if let localWeeklySheetName = strongSelf.localWeeklySheetName, DataManager.checkFileExist(filename: localWeeklySheetName) {
                        strongSelf.dataManager.loadFromSpreadSheet(filename: localWeeklySheetName){success, rowToBeRemoved in
                            completion(success)
                        }
                    }else{
                        LogManager.writeLog(info: "Did not find local spreadsheet in memory.")
                        completion(false)
                    }
                }else{
                    AlertManager.sendAlertWithCancel(title: "No spreadsheet", message: "It seems you haven't created any spreadsheet for weekly chore shift schedule on Google Drive. Do you want to creat one now? ", click: "Yes", inView: strongSelf){
                        strongSelf.googleDriveManager.createSpreadsheet(filename: spreadsheetName){success, error in
                            if success{
                                AlertManager.sendAlert(title: "Success", message: "A spreadsheet named \(spreadsheetName) has been created on your Google Drive. Please put weekly chore shift information there. ", click: "OK", inView: strongSelf){
                                    completion(true)
                                    
                                }
                            }else{
                                AlertManager.sendAlert(title: "Failed", message: "Unable to create \(spreadsheetName) on your Google Drive. Please try again later. Error: \(error). Please make sure to allow ALL Goole Drive serive (including editing).", click: "OK", inView: strongSelf){
                                    completion(false)
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    
    /// load chore shift from local memory
    func loadFromSignInFormInMemory(completion: @escaping (Bool)->Void){
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "MMddyyyy"
        let dateString = formatter.string(from: Date())
        let signInForm =  "\(dateString)_\(CREW_NAME)_Sign_In.csv"
        if DataManager.checkFileExist(filename:  signInForm){
            dataManager.loadFromSignInSheet(filename: signInForm, completion: nil)
            completion(true)
            return
        }else{
            LogManager.writeLog(info: "Did not find sign in form in the memory TT.")
            completion(false)
            return
        }
    }
    
    
    /// load chore shift from google drive
    func loadFromSignInFormOnGoogleDrive(completion: @escaping (Bool, Error?)->Void){
        if !googleDriveManager.useGoogleDrive{
            completion(true, nil)
            return
        }
        
        let formatter = DateManager.dateFormatter
        formatter.dateFormat = "MMddyyyy"
        let dateString = formatter.string(from: Date())
        localSignInFormName =  "\(dateString)_\(CREW_NAME)_Sign_In.csv"
        let fileNameStrings = [
            "\(dateString)",
            "\(CREW_NAME)"
        ]
        
        googleDriveManager.searchSignInForm(fileNameStrings: fileNameStrings){[weak self] (fileID, error) in
            
            guard let strongSelf = self else{
                return
            }
            if error == nil, fileID != nil{
                strongSelf.googleDriveManager.downloadFile(fileID: fileID ?? ""){
                    (data, error) in
                    if error == nil{
                        if let localSignInFormName = strongSelf.localSignInFormName {
                            DataManager.saveCSVFile(data: data, filename: localSignInFormName){(file) in
                                strongSelf.dataManager.loadFromSignInSheet(filename: localSignInFormName){ success in
                                    completion(true, nil)
                                }
                            }
                            
                        }
                    }else{
                        LogManager.writeLog(info: "Failed to download signin sheet \(String(describing: strongSelf.localSignInFormName)). error : \(String(describing: error)).")
                        completion(false, error)
                    }
                    return
                }
            }else{
                LogManager.writeLog(info: "Dit not find sign-in form on Google Drive. error: \(String(describing: error))")
                completion(false, error)
            }
        }
    }
    
    
    
    @objc func didTapSignInButton(silent: Bool = false, completion: @escaping (Bool) -> Void){
        if !googleDriveManager.useGoogleDrive{
            if !silent{
                AlertManager.sendAlert(title: AlertMessages.offlineModeAlert.title, message: AlertMessages.offlineModeAlert.message, click: "OK", inView: self)
            }
            completion(false)
            return
        }

        GIDSignIn.sharedInstance()?.signIn()
        completion(false)
        if !silent{
            AlertManager.sendAlert(title: "You have signed In.", message: "", click: "OK", inView: self)
            LogManager.writeLog(info: "successfully signed in google drive. ")
        }
    }
    
    func didTapSignOutButton(){
        LogManager.writeLog(info: "did tap google drive sign out button")
        if GIDSignIn.sharedInstance()?.currentUser == nil{
            AlertManager.sendAlert(title: "You haven't signed in", message: "", click: "OK", inView: self)
        }else{
            GIDSignIn.sharedInstance()?.signOut()
            AlertManager.sendAlert(title: "You have signed out google account", message: "", click: "OK", inView: self)
        }
    }
}


// MARK: - UICollectionView Delegate and datasource

extension ViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath.row == self.dataManager.shiftManager.shiftList[indexPath.section].count{
            // if it is the add button
            if let securityManager = self.securityManager, !securityManager.lock{
                //if self.dataManager.shiftManager.getOpenings(crewName: "Regular", section: indexPath.section) > 0,
                //if DateManager.getSection(date: Date()) <= indexPath.section{
                self.addNewShift()
                //}
            }else{
                AlertManager.sendAlert(title: "Option disabled", message: "Please tap the 🔒 button to use the KC mode!", click: "OK", inView: self)
            }
            return
        }
        
        guard let shift = dataManager.shiftManager.getShift(section: indexPath.section, row: indexPath.row) else{
            return
        }
        //LogManager.writeLog(info: "did tap shift cell. selected memebr = \(shift.name)")
        if checking{
            if shift.status.signed, shift.status.signedOut{
                shift.status.setChecked(checked: !shift.status.checked)
                LogManager.writeLog(info: "the check state of \(shift.name) has been changed: checked = \(shift.status.checked)")
                self.dataManager.saveData(completion: nil)
                collectionView.reloadData()
            }else if shift.status.signed{
                AlertManager.sendAlert(title: "Failed", message: "\(shift.name) hasn't signed out yet. Please wait until shift sign out.", click: "OK", inView: self)
            }
            return
        }else{
            let vc = storyboard?.instantiateViewController(identifier: "signIn") as! SignInViewController
            
            vc.shift = shift
            vc.crewManager = crewManager
            vc.update = {
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
            securityManager?.securedViewList.append(vc)
            vc.securityManager = self.securityManager
            vc.dataManager = self.dataManager
            vc.completion = { [weak self] status in
                guard let strongSelf = self, let securityManager = strongSelf.securityManager else {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.navigationController?.popToRootViewController(animated: true)
                    _ = securityManager.securedViewList.popLast()
                    if let shift = strongSelf.dataManager.shiftManager.getShift(section: indexPath.section, row: indexPath.row){
                        shift.updateStatus(newStatus: status)
                        LogManager.writeLog(info: "shift \(shift.name) status might be updated: new shift status =\(status.toString())")
                        if shift.status.deleted{
                            LogManager.writeLog(info: "shift will be delted: shift info = \(shift.toString())")
                            strongSelf.dataManager.shiftManager.deleteShift(section: indexPath.section, row: indexPath.row)
                        }
                        strongSelf.collectionView.reloadData()
                        strongSelf.dataManager.saveData(completion: nil)
                    }
                }}
            navigationController?.pushViewController(vc, animated: true)
            
        }
    }
    
    
}


extension ViewController: UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return  self.dataManager.shiftManager.shiftList.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataManager.shiftManager.shiftList[section].count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < self.dataManager.shiftManager.shiftList[indexPath.section].count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionViewCell.identifier, for: indexPath) as! MyCollectionViewCell
            
            if let shift = self.dataManager.shiftManager.getShift(section: indexPath.section, row: indexPath.row){
                shift.config()
                cell.configure( mem: shift, checking: self.checking, inView: self)
            }
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddNewShiftCollectionViewCell.identifier, for: indexPath) as! AddNewShiftCollectionViewCell
            
            var openings = self.dataManager.shiftManager.getOpenings(crewName: "Regular", section: indexPath.section)
            if DateManager.getSection(date: Date()) > indexPath.section{
                openings = 0
            }
            cell.configure(openings: openings)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader{
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderCollectionReusableView.identifier, for: indexPath) as! HeaderCollectionReusableView
            
            header.config(section: indexPath.section)
            return header
        }
        
            
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: FooterCollectionReusableView.identifier, for: indexPath) as! FooterCollectionReusableView
        
        footer.config()
        return footer
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout{

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 20)
    }
}



//// google sign in
extension ViewController: GIDSignInDelegate{

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

        // A nil error indicates a successful login
        if error == nil {
            // Include authorization headers/values with each Drive API request.
            self.googleDriveService.authorizer = user.authentication.fetcherAuthorizer()
            self.googleUser = user
            self.googleDriveManager.googleUser = user
            self.refreshAll()
        } else {
            AlertManager.sendAlert(title: "Not Sign-in", message: "You haven't signed in Google Drive yet. The sign-in sheet may be outdated. Please sign-in to fetch the sign-in sheet. Tap Options -> Sign In Google Drive", click: "OK", inView: self)

            self.googleDriveService.authorizer = nil
            self.googleUser = nil
        }
    }

}


enum FileError: Error {
    case savingFileFailed
    case readingFileFailed
    case fetchingPthURLFailed
    case getDataFailed
}


