//
//  ViewController.swift
//  AlarmPush
//
//  Created by Martynas Klastaitis  on 02/04/2019.
//  Copyright © 2019 bajoraiciuprodukcija. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UITableViewController, UNUserNotificationCenterDelegate {
    
    //store all alarm groups
    var groups = [Group]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //costum title font
        let titleAtributes = [NSAttributedString.Key.font: UIFont(name: "Arial Rounded MT Bold", size: 20)!]
        
        navigationController?.navigationBar.titleTextAttributes = titleAtributes
        title = "AlarmPush"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroup))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Groups", style: .plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: Notification.Name("save"), object: nil)
        
        
    }
    //refresh data every time user returns to this VC
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load()
    }
    //MARK: - Table view methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return groups.count
    }
    
    //DELETES selected group & row
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        groups.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        save()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Group", for: indexPath)
        
        let group = groups[indexPath.row]
        cell.textLabel?.text = group.name
        
        if group.enabled {
            cell.textLabel?.textColor = .black
        } else {
            cell.textLabel?.textColor = .red
        }
        
        if group.alarms.count == 1 {
            cell.detailTextLabel?.text = "1 alarm"
        } else {
            cell.detailTextLabel?.text = "\(group.alarms.count) alarms"
        }
        return cell
    }
    
    //MARK: - Segues
    
    @objc func addGroup() {
        let newGroup = Group(name: "Name this group", playSound: true, enabled: false, alarms: [])
        groups.append(newGroup)
        
        performSegue(withIdentifier: "EditGroup", sender: newGroup)
        save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let groupToEdit: Group
        
        if sender is Group {
            //jei iskvieciam segue su addGroup funkcija arba su notificationu
            groupToEdit = sender as! Group
        } else {
            //jei su tableView Cell
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else {return}
            groupToEdit = groups[selectedIndexPath.row]
        }
           // unwrap our destination from the segue
           if let groupViewController = segue.destination as? GroupViewController {
            // give it whatever group we decided above
            groupViewController.group = groupToEdit
        }
    }
    
    //MARK: - Data managment
    
    @objc func save() {
        do {
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = try NSKeyedArchiver.archivedData(withRootObject: groups, requiringSecureCoding: false)
           try data.write(to: path)
        } catch {
            print("Failed to save")
        }
        updateNotifications()
    }
    func load() {
        do {
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = try Data(contentsOf: path)
            groups = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Group] ?? [Group]()
        } catch {
            print("Failed to load")
        }
        
        tableView.reloadData()
    }
    
    //MARK: - Creating Notifications
    func updateNotifications()  {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [unowned self](granted, error) in
            if granted {
                self.createNotifications()
            }
        }
    }
    /**
      Responsible for removing any notifications currently scheduled so that we have a clean slate, then going through all the groups and alarms to see which need to be scheduled
     
     1. Remove any pending notification requests, i.e. things we had scheduled previously but hadn’t been delivered.
     1. Loop through every group, ignoring those groups that aren’t enabled.
     1. Loop through every alarm in the enabled groups and call createNotificationRequest() for each one.
     1. That method will return a UNNotificationRequest object, which can then be passed to the user notification center for delivery.
 */
    func createNotifications() {
        
        let center = UNUserNotificationCenter.current()
    
        // 1.
        center.removeAllPendingNotificationRequests()
        
        for group in groups {
            //2.
            guard group.enabled == true else { continue }
            for alarm in group.alarms {
                //3.
                let notification = createNotificationRequest(group: group, alarm: alarm)
                //4.
                center.add(notification) { error in
                    if let error = error {
                        print("Error sheduling notification \(error)")
                    }
                }
            }
        }
    }

    /**
     Needs to accept a group and an alarm, and return a UNNotificationRequest object
     
     That object encapsulates everything required to deliver the notification: its title and subtitle, whether it plays a sound or not, whether it has an attachment or not, what time it should be triggered, and more.
     
    1. start by creating the content for the notification
    1. assign the user's name and caption
    1. give it an identifier we can attach to custom buttons later on
    1. attach the group ID and alarm ID for this alarm
    1. if the user requested a sound for this group, attach their default alert sound
    1. use createNotificationAttachments to attach a picture for this alert if there is one
    1. pull out the hour and minute components from this alarm's date
    1. create a trigger matching those date components, set to repeat
    1. combine the content and the trigger to create a notification request
    1. pass that object back to createNotifications() for scheduling
    
*/
    func createNotificationRequest(group: Group, alarm: Alarm) -> UNNotificationRequest {
        //1.
    
        let content = UNMutableNotificationContent()
        
        //2.
        content.title = alarm.name
        content.body = alarm.caption
        
        //3.
        content.categoryIdentifier = "alarm"
        
        //4.
        content.userInfo = ["group": group.id, "alarm": alarm.id]
        
        //5.
        if group.playSound {
            content.sound = UNNotificationSound.default
        }
        
        //6.
        content.attachments = createNotificationAttachments(alarm: alarm)
        
        //7.
        let cal = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = cal.component(.hour, from: alarm.time)
        dateComponents.minute = cal.component(.minute, from: alarm.time)
        
        //8.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        //pasileidzia po tiek sekundziu po sukurimo
      //  let testTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        //9.
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        print(request)
        //10.
        return request
    }
    /**
     Attach an image to the notification if one was set
     
     **When you attach an image to a notification, it gets moved into a separate location so that it can be guaranteed to exist when shown.** That means you cannot just use the same file we placed into the documents directory, because it will get moved away – and thus lost.
     
     
     
     1. If there is no image attach to an alert, return nothing.
     1. Get the full path to the alarm image by using getDocumentsDirectory().
     1. Create a full path to a temporary filename that we’ll use to take a copy of the alert image.
     1. Copy the alert image to the temporary file.
     1. Create a UNNotificationAttachment object with a random identifier, pointing it at the file copy we just made.
     1. Return that attachment back to createNotificationRequest().
 */
    
    func createNotificationAttachments(alarm: Alarm) -> [UNNotificationAttachment] {
        //1.
        guard alarm.image.count > 0 else {return [] }
        let fm = FileManager.default
        do {
            //2.
            let imageURL = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            //3.
            let copyURL = Helper.getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).jpg")
            //4.
            try fm.copyItem(at: imageURL, to: copyURL)
            //5.
            let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: copyURL)
            //6.
            return [attachment]
        } catch {
            print("Failed to attach alarm image: \(error)")
            return []
        }
    }
    
    //MARK: - Response to Notifications
    
    //This method called when a notification has come in while your app is running. It is part of UNUserNotificationCenter protocol.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
    
    //The second method is trigered when the user acts on the notification and it's down to us to respond.
    //In our case we have three actions that we need to deal with: displaying a group. deleting a group, and renaming a group. We're created them individually.
    // Also there is 3 more things to do:
//   1. When the notification comes in, we need to pull out the userInfo dictionary we set because that contents the group ID that triggered the alarm.
//  2.  We also need to read the actionIdentifier value to see what action the user tapped, e.g. “show” or “rename”.
//  3. It has a completionHandler block that must be called when you’ve finished work.”
//
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 1. pull out the buried userInfo dictionary
        let userInfo = response.notification.request.content.userInfo
        
        if let groupID = userInfo["group"] as? String {
            // 2. if we got a group ID, we're good to go!
            switch response.actionIdentifier {
                
            // the user swiped to unlock; do nothing
            case UNNotificationDefaultActionIdentifier:
                print("Default identifier")
                
            // the user dismissed the alert; do nothing
            case UNNotificationDismissActionIdentifier:
                print("Dismiss identifier")
                
            // the user asked to see the group, so call display()
            case "show":
                display(group: groupID)
                break
                
            // the user asked to destroy the group, so call destroy()
            case "destroy":
                destroy(group: groupID)
                break
                
            // the user asked to rename the group, so safely unwrap their text response and call rename()
            case "rename":
                if let textResponse = response as? UNTextInputNotificationResponse {
                    rename(group: groupID, newName: textResponse.userText)
                }
                
                break
                
            default:
                break
            }
        }
        
        // 3. you need to call the completion handler when you're done
        completionHandler()
    }
    
    func display(group groupID: String) {
        
        //It's required to start with popToRootVC, because we don’t want to manipulate our data while the user is several screens deep, because they might later try to rename an alarm in a group that no longer exists.
        //Going back to the root view controller before making any changes means we can be sure we’re in a sensible, safe place before running any new code.
        
        _ = navigationController?.popToRootViewController(animated: false)
        
        for group in groups {
            if group.id == groupID {
                //We're in root VC so we perform segue to get to shown group info (check prepare for segue method, for more info)
                performSegue(withIdentifier: "EditGroup", sender: group)
                return
            }
        }
    }
    
    func destroy(group groupID: String) {
        //required
        _ = navigationController?.popToRootViewController(animated: false)
        
        //groups array needs to be enumerated in this loop, because we need to know the exactly at which index is shown group.
        for (index, group) in groups.enumerated() {
            if group.id == groupID {
                groups.remove(at: index)
                break
            }
        }
        
        save()
        load()
    }
    
    func rename(group groupID: String, newName: String) {
        //required
        _ = navigationController?.popToRootViewController(animated: false)
        
        for group in groups {
            if group.id == groupID {
                group.name = newName
                break
            }
        }
        save()
        load()
    }
  
}


