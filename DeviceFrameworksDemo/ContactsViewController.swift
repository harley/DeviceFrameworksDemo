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
        let store = CNContactStore()

        if CNContactStore.authorizationStatusForEntityType(.Contacts) == .NotDetermined {
            store.requestAccessForEntityType(.Contacts, completionHandler: { (authorized: Bool, error: NSError?) -> Void in
                if authorized {
                    self.retrieveContactsWithStore(store)
                }
            })
        } else if CNContactStore.authorizationStatusForEntityType(.Contacts) == .Authorized {
            self.retrieveContactsWithStore(store)
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
//            for contact in contacts {
//                print("Contact: ", contact)
//            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        } catch {
            print(error)
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