//
//  GroupViewController.swift
//  AlarmPush
//
//  Created by Martynas Klastaitis  on 02/04/2019.
//  Copyright © 2019 bajoraiciuprodukcija. All rights reserved.
//

import UIKit

class GroupViewController: UITableViewController {
    
    var group: Group!
    let playSoundTag = 1001
    let enabledTag = 1002

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAlarm))
        title = group.name
        

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    //MARK: - TableView methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    //uzdedam title antram section, bet tik tada, jei si grupe turi alarms.
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return nothing if we're in first section
        if section == 0 { return nil }
        if group.alarms.count > 0 { return "Alarms" }
        return nil
    }
    //pirmoje section visada bus trys eilutes, antroje - tiek, kiek bus sukurtu alarms
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
            
        } else {
            return group.alarms.count
        }
    }
    //nurodom, kad tik antraja section galima editint
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    //pridedam istrynimo funkcija
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        group.alarms.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        save()
    }
    //MARK: - Segues
    @objc func addAlarm() {
        let newAlarm = Alarm(name: "Create new alarm", caption: "Add an optional description", time: Date(), image: "")
        group.alarms.append(newAlarm)
        
        performSegue(withIdentifier: "EditAlarm", sender: newAlarm)
        save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let alarmToEdit: Alarm
        
        if sender is Alarm {
            alarmToEdit = sender as! Alarm
        } else {
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else {return}
            alarmToEdit = group.alarms[selectedIndexPath.row]
        }
        if let alarmVC  = segue.destination as? AlarmViewController {
            alarmVC.alarm = alarmToEdit
        }
    }
    //MARK: - TableView methtods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return createGroupCell(for: indexPath, in: tableView)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetail", for: indexPath)
            let alarm = group.alarms[indexPath.row]
            cell.textLabel?.text = alarm.name
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: alarm.time, dateStyle: .none, timeStyle: .short)
            return cell
        }
    }
    func createGroupCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            //pirma cele
            //editinam grupes pavadinima
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditableText", for: indexPath)
            //surandam textfield celej
            if let cellTextField = cell.viewWithTag(1) as? UITextField {
                cellTextField.text = group.name
            }
            return cell
            
        case 1:
            //antra cele, arba play sound cele
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath)
            //surandam lebel ir switch knapki
            if let cellLabel = cell.viewWithTag(1) as? UILabel, let cellSwitch = cell.viewWithTag(2) as? UISwitch {
                cellLabel.text = "Play Sound"
                cellSwitch.isOn = group.playSound
                
                // set the switch up with the playSoundTag tag so we know which one was changed later on
                cellSwitch.tag = playSoundTag
            }
            return cell
        default:
            //jei mes cia, vadinasi esame paskutinej eilutej Enabled
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath)
            if let cellLabel = cell.viewWithTag(1) as? UILabel, let cellSwitch = cell.viewWithTag(2) as? UISwitch {
                cellLabel.text = "Enabled"
                cellSwitch.isOn = group.enabled
                cellSwitch.tag = enabledTag
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = true
        cell.contentView.preservesSuperviewLayoutMargins = true
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        // panaudojam musu specialius tagus, nustatyti kuris switch knapkis pajudintas
        if sender.tag == playSoundTag {
            group.playSound = sender.isOn
        } else {
            group.enabled = sender.isOn
        }
        save()
    }
    
    @objc func save() {
        NotificationCenter.default.post(name: Notification.Name("save"), object: nil)
    }
}

extension GroupViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        group.name = textField.text!
        title = group.name
        save()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
