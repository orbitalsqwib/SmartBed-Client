//
//  StatusViewController.swift
//  SmartBedClient
//
//  Created by Eugene L. on 2/2/20.
//  Copyright © 2020 ARandomDeveloper. All rights reserved.
//

import UIKit
import MQTTClient
import Firebase

// Globals

// Variables
var beds = [Bed]()
var searchedBeds = [Bed]()
var searchMode = Bool()
var keyboardHeight:CGFloat = 0

// Constants
let rowHeight = CGFloat(35)
let documentDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
let saveFileURL = documentDirectory.appendingPathComponent("beds.json")
let unc = UNUserNotificationCenter.current()
let d = UserDefaults.standard

class StatusViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var MQTTButtonContainer: UIView!
    @IBOutlet weak var MQTTButton: UIButton!
    @IBOutlet weak var Header: UIView!
    @IBOutlet weak var BedCollectionView: UICollectionView!
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var SearchButtonContainer: UIView!
    @IBOutlet weak var SearchButton: UIButton!
    @IBOutlet weak var ProfileButtonContainer: UIView!
    @IBOutlet weak var ProfileButton: UIButton!

    @IBAction func clickedProfile(_ sender: Any) {
        //Show alert to sign out/rebind/bind card?
        
        //Get status of user
        if Auth.auth().currentUser != nil {
            
            // User currently logged in
            let menuAlert = UIAlertController(title: "Settings", message: nil, preferredStyle: .alert)
            menuAlert.addAction(.init(title: "MQTT Settings", style: .default, handler: { (result) in
                
                let settingsAlert = UIAlertController(title: "Edit MQTT Settings", message: nil, preferredStyle: .alert)
                settingsAlert.addTextField { (textfield) in
                    textfield.placeholder = "Enter ipaddress..."
                    textfield.text = d.string(forKey: "mqttHost")
                }
                settingsAlert.addTextField { (textfield) in
                    textfield.placeholder = "Enter topic..."
                    textfield.text = d.string(forKey: "mqttTopic")
                }
                settingsAlert.addAction(.init(title: "Confirm & Attempt Connection", style: .destructive, handler: { (result) in
                    if let ipaddressField = settingsAlert.textFields?[0] {
                        d.set(ipaddressField.text ?? "192.168.0.1", forKey: "mqttHost")
                        self.transport.host = ipaddressField.text ?? "192.168.0.1"
                    }
                    if let topicField = settingsAlert.textFields?[1] {
                        d.set(topicField.text ?? "smartbed", forKey: "mqttTopic")
                    }
                    
                    self.session?.connect() { error in
                        if error != nil {
                            self.presentSimpleAlert(title: "Connection Error", message: "connection aborted with status \(String(describing: error))", btnMsg: "OK")
                        } else {
                            let topic = d.string(forKey: "mqttTopic")
                            self.session?.subscribe(toTopic: topic, at: .exactlyOnce, subscribeHandler: { (error, result) in
                                print("subscribe result error \(String(describing: error)) result \(result!)")
                            })
                            self.MQTTButtonContainer.backgroundColor = .systemGreen
                            self.MQTTButton.isEnabled = false
                            self.MQTTButton.setTitle("MQTT Connected!", for: .disabled)
                        }
                    }
                }))
                
                settingsAlert.addAction(.init(title: "Cancel", style: .default, handler: nil))
                
                self.present(settingsAlert, animated: true, completion: nil)
            }))
            
            menuAlert.addAction(.init(title: "Clear Local Cache", style: .destructive, handler: { (result) in
                beds.removeAll()
                searchedBeds.removeAll()
                self.saveBedData()
                self.BedCollectionView.reloadData()
            }))
            
            menuAlert.addAction(.init(title: "Sign Out", style: .destructive, handler: { (result) in
                self.askUserToLogOut()
            }))
            
            menuAlert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(menuAlert, animated: true, completion: nil)
            
        } else {
            
            // No user logged in
            askUserToSignIn()
            
        }
    }
    
    @IBAction func clickedConnect(_ sender: Any) {
        
        self.session?.connect() { error in
            if error != nil {
                self.presentSimpleAlert(title: "Connection Error", message: "connection aborted with status \(String(describing: error))", btnMsg: "OK")
            } else {
                let topic = d.string(forKey: "mqttTopic")
                self.session?.subscribe(toTopic: topic, at: .exactlyOnce, subscribeHandler: { (error, result) in
                    print("subscribe result error \(String(describing: error)) result \(result!)")
                    if error != nil {
                        self.presentSimpleAlert(title: "Connection Error", message: "connection aborted with status \(String(describing: error))", btnMsg: "OK")
                    }
                })
                self.MQTTButtonContainer.backgroundColor = .systemGreen
                self.MQTTButton.isEnabled = false
                self.MQTTButton.setTitle("MQTT Connected!", for: .disabled)
            }
        }
        
    }
    
    @IBAction func clickedSearchToggle(_ sender: Any) {
        toggleSearchBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil {
            self.performSegue(withIdentifier: "presentAuth", sender: self)
        }
    }
    
    private var transport = MQTTCFSocketTransport()
    fileprivate var session = MQTTSession()
    fileprivate var completion: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notification Setup
        unc.delegate = self
        
        unc.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                unc.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    
                }
            }
        }
                
        // MQTT Setup
        self.session?.delegate = self
        self.transport.host = d.string(forKey: "mqttHost")
        self.transport.port = UInt32(d.integer(forKey: "mqttPort"))
        session?.transport = transport
        
        // Do any additional setup after loading the view.
        
        Header.dropShadow(radius: 5, widthOffset: 0, heightOffset: 1)
        SearchBar.dropShadow(radius: 5, widthOffset: 0, heightOffset: 1)
        SearchButtonContainer.dropShadow(radius: 2, widthOffset: 1, heightOffset: 1)
        ProfileButtonContainer.dropShadow(radius: 2, widthOffset: 1, heightOffset: 1)
        MQTTButtonContainer.dropShadow(radius: 5, widthOffset: 0, heightOffset: 1)
        
        MQTTButtonContainer.layer.cornerRadius = 10
        SearchButtonContainer.layer.cornerRadius = 24
        ProfileButtonContainer.layer.cornerRadius = 24
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        SearchBar.layer.borderWidth = 1
        SearchBar.layer.borderColor = UIColor.white.cgColor
        SearchBar.delegate = self
        
        toggleSearchBar()
        
        BedCollectionView.dataSource = self
        BedCollectionView.delegate = self
        
        beds = loadBedData()
        self.BedCollectionView.reloadData()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
        }
    }
    
    func askUserToLogOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (result) in
            
            // Sign out
            self.signOut()
            self.performSegue(withIdentifier: "presentAuth", sender: self)
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func askUserToSignIn() {
        
        let alert = UIAlertController(title: "Not Signed In", message: "Sign into the app so we can start tracking your receipts!", preferredStyle: .alert)
        alert.addAction(.init(title: "Continue", style: .cancel, handler: { (alert) in
            self.BedCollectionView.refreshControl?.endRefreshing()
            self.performSegue(withIdentifier: "presentAuth", sender: self)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func toggleSearchBar() {
        if let searchBarHeight = SearchBar.constraint(withIdentifier: "SearchBarHeight")?.constant {
            if searchBarHeight == 44 {
                
                self.SearchBar.constraint(withIdentifier: "SearchBarHeight")?.constant = 0
                self.Header.layer.shadowOpacity = 0.25
                self.SearchBar.layer.shadowOpacity = 0
                self.SearchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
                self.SearchBar.endEditing(true)
                keyboardHeight = 0
                searchedBeds.removeAll()
                searchMode = false
                self.BedCollectionView.reloadData()
                
            } else {
                
                self.SearchBar.constraint(withIdentifier: "SearchBarHeight")?.constant = 44
                self.Header.layer.shadowOpacity = 0
                self.SearchBar.layer.shadowOpacity = 0.25
                self.SearchButton.setImage(UIImage(systemName: "xmark"), for: .normal)
                searchMode = true
                self.BedCollectionView.reloadData()
                
            }
        }
    }
    
    func updateBeds(message: String, completion: ((Bool) -> ())) {
        //TODO: MQTT loading
        
        let processed = message.split(separator: "\n")[0].split(separator: ",")
        if processed.count == 3 {
            guard let bedno = Int(processed[0]) else {
                return completion(false)
            }
            guard let bedweight = Double(processed[1]) else {
                return completion(false)
            }
            guard let bedrpm = Double(processed[2]) else {
                return completion(false)
            }
            
            if beds.count > 0 {
                for i in 0...beds.count-1 {
                    if beds[i].BedNo == bedno {
                        
                        if beds[i].BedWeight > 2 && bedweight < 2 {
                            
                            unc.getNotificationSettings { settings in
                                if settings.authorizationStatus == .authorized {
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = "Person Out Of Bed!"
                                    content.body = "The person at Bed \(bedno) has gotten out of bed. It is advisable to check on them."
                                    
                                    if settings.alertSetting != .enabled {
                                        content.badge = 0
                                        content.sound = .default
                                    }
                                    
                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                    repeats: false)
                                    
                                    let request = UNNotificationRequest(identifier: "POOB", content: content, trigger: trigger)
                                    
                                    unc.add(request, withCompletionHandler: nil)
                                    
                                }
                            }
                        }
                        
                        beds[i].BedWeight = bedweight
                        beds[i].BedRPM = bedrpm
                        
                        return completion(true)
                    }
                }
            }
            
            beds.append(Bed(code: bedno, weight: bedweight, rpm: bedrpm))
        }
        
        completion(true)
    }
    
    func saveBedData() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(beds) {
            do {
                if FileManager.default.fileExists(atPath: saveFileURL.path) {
                    try FileManager.default.removeItem(at: saveFileURL)
                }
                FileManager.default.createFile(atPath: saveFileURL.path, contents: data, attributes: nil)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func loadBedData() -> [Bed] {
        let decoder = JSONDecoder()
        if let retrieved = try? Data(contentsOf: saveFileURL) {
            do {
                return try decoder.decode([Bed].self, from: retrieved)
            } catch {
                return [Bed]()
            }
        }
        return [Bed]()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

class BedCollectionViewCell: UICollectionViewCell {
    
    var Weight: Double = 0
    var RPM: Double = 0
    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var BedDetailTableView: UITableView!
    @IBOutlet weak var BedNoLabel: UILabel!
    
}

class BedDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var BedDetailNameLabel: UILabel!
    @IBOutlet weak var BedDetailValueLabel: UILabel!
    
}

extension StatusViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchMode == true {
            return searchedBeds.count
        } else {
            return beds.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = BedCollectionView.dequeueReusableCell(withReuseIdentifier: "bedCell", for: indexPath) as! BedCollectionViewCell
        
        var dataSource = [Bed]()
        if searchMode == true {
            dataSource = searchedBeds
        } else {
            dataSource = beds
        }
        
        cell.ContainerView.layer.cornerRadius = 10
        cell.ContainerView.clipsToBounds = true
        cell.contentView.dropShadow(radius: 5, widthOffset: 1, heightOffset: 1)
        
        cell.BedNoLabel.text = String(dataSource[indexPath.item].BedNo)
        cell.BedDetailTableView.delegate = cell
        cell.BedDetailTableView.dataSource = cell
        
        cell.Weight = dataSource[indexPath.item].BedWeight
        cell.RPM = dataSource[indexPath.item].BedRPM
        cell.BedDetailTableView.reloadData()
        
        return cell
    }
    
    
}

extension StatusViewController: UICollectionViewDelegate {
    
}

extension StatusViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (self.view.window?.frame.width ?? UIScreen.main.bounds.width) - 10
        
        let numberOfItems = 2
        let height = CGFloat(numberOfItems) * (rowHeight) + (86 + 30)
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if searchMode == true {
            return UIEdgeInsets(top: 5, left: 5, bottom: keyboardHeight - 5, right: 5)
        }
        return UIEdgeInsets(top: 5, left: 5, bottom: 80, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
}

extension BedCollectionViewCell: UITableViewDelegate {
    
}

extension BedCollectionViewCell: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = BedDetailTableView.dequeueReusableCell(withIdentifier: "bedDetailCell", for: indexPath) as! BedDetailTableViewCell
        
        if indexPath.item == 0 {
            cell.BedDetailNameLabel.text = "Weight"
            cell.BedDetailValueLabel.text = String(Weight)
        } else if indexPath.item == 1 {
            cell.BedDetailNameLabel.text = "RPM"
            cell.BedDetailValueLabel.text = String(RPM)
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return rowHeight
        
    }
    
}

extension StatusViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchedBeds.removeAll()
        for b in beds {
            if b.IsNo(text: searchText) {
                searchedBeds.append(b)
            }
        }
        self.BedCollectionView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
    }
    
}

extension StatusViewController: MQTTSessionManagerDelegate, MQTTSessionDelegate {

    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        if let msg = String(data: data, encoding: .utf8) {
            self.updateBeds(message: msg) { (result) in
                if result == true {
                    saveBedData()
                    BedCollectionView.reloadData()
                }
            }
        }
    }
    
    func showInterrupt(session: MQTTSession) {
        self.MQTTButtonContainer.backgroundColor = .systemRed
        self.MQTTButton.isEnabled = true
        self.MQTTButton.setTitle("Connection Interrupted. Retry?", for: .normal)
    }
    
    func connectionClosed(_ session: MQTTSession!) {
        showInterrupt(session: session)
    }
    
    func connectionError(_ session: MQTTSession!) {
        showInterrupt(session: session)
    }
    
}
