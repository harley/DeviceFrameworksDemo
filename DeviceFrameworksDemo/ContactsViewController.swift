//
//  ContactsViewController.swift
//  DeviceFrameworksDemo
//
//  Created by Harley Trung on 4/11/16.
//  Copyright © 2016 coderschool.vn. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class ContactsViewController: UIViewController {
    var store: CNContactStore!
    var objects = [CNContact]()

    @IBAction func addButtonDidTap(sender: UIBarButtonItem) {
        print("add existing contact")
        addExistingContact()
    }

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        getContacts()
    }

    func getContacts() {
        store = CNContactStore()
        let status = CNContactStore.authorizationStatusForEntityType(.Contacts)

        if status == .NotDetermined {
            showMessage("Give me your contacts?", okHandler: { 
                self.requestForAccess({ (accessGranted) in
                    if accessGranted {
                        self.retrieveContactsWithStore(self.store)
                    }
                })
                }, cancelHandler: {
                    self.showMessage("No problem. I'll ask again", okHandler: nil, cancelHandler: nil)
            })

        } else if status == .Authorized {
            self.retrieveContactsWithStore(store)
        } else {
            showMessage("Uh oh. No permission: \(status.rawValue)", okHandler: nil, cancelHandler: nil)
        }
    }

    func retrieveContactsWithStore(store: CNContactStore) {
        do {
            let groups = try store.groupsMatchingPredicate(nil)
            let predicate = CNContact.predicateForContactsInGroupWithIdentifier(groups[0].identifier)
            //let predicate = CNContact.predicateForContactsMatchingName("John")
            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName), CNContactEmailAddressesKey]

            let contacts = try store.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
            self.objects = contacts
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        } catch {
            print(error)
        }
    }

    func requestForAccess(completionHandler: (accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)

        switch authorizationStatus {
        case .Authorized:
            completionHandler(accessGranted: true)

        case .Denied, .NotDetermined:
            self.store.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(accessGranted: access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message, okHandler: nil, cancelHandler: nil)
                        })
                    }
                }
            })
            
        default:
            completionHandler(accessGranted: false)
        }
    }

    func showMessage(message: String, okHandler: (() -> Void)?, cancelHandler: (() -> Void)?) {
        let alertController = UIAlertController(title: "About your contacts", message: message, preferredStyle: .Alert)

        if let handler = cancelHandler {
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                handler()
            }
            alertController.addAction(cancelAction)
        }

        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            okHandler?()
        }
        alertController.addAction(OKAction)
        
        self.presentViewController(alertController, animated: true) {
            // ...
        }
    }
}

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCell

        let contact = self.objects[indexPath.row]
        let formatter = CNContactFormatter()

        cell.nameLabel.text = formatter.stringFromContact(contact)
//        cell.emailLabel.text = contact.emailAddresses.first?.value as? String

        return cell
    }
}

extension ContactsViewController: CNContactPickerDelegate {
    func addExistingContact() {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        presentViewController(contactPicker, animated: true, completion: nil)
    }

    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        objects.append(contact)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
        // NSNotificationCenter.defaultCenter().postNotificationName("addNewContact", object: nil, userInfo: ["contactToAdd": contact])
    }

    func contactPickerDidCancel(picker: CNContactPickerViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

//    func contactPicker(picker: CNContactPickerViewController, didSelectContacts contacts: [CNContact]) {
//        print("selected multiple contacts", contacts)
//    }
}