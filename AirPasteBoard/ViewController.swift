//
//  ViewController.swift
//  AirPasteBoard
//
//  Created by Shunzhe Ma on 12/6/19.
//  Copyright © 2019 Shunzhe Ma. All rights reserved.
//

import Cocoa
import KeychainSwift
import SwiftyDropbox
import LaunchAtLogin

class ViewController: NSViewController {
    
    @IBOutlet weak var fileShareSourceSelector: NSPopUpButton!
    @IBOutlet weak var githubStatusLabel: NSTextField!
    @IBOutlet weak var githubActionButton: NSButton!
    @IBOutlet weak var githubTokenField: NSTextField!
    
    @IBOutlet weak var githubPrivacySelector: NSPopUpButton!
    @IBOutlet weak var gistFormatSelector: NSPopUpButton!
    
    @IBOutlet weak var dropboxLogBtn: NSButton!
    
    @IBOutlet weak var githubLogOutBtn: NSButton!
    
    @IBOutlet weak var startWithSysSwitch: NSSwitch!
    
    var popOver: NSPopover?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check the github credential value to update UI
        let githubCredential = KeychainSwift().get("AirPasteBoard_GithubKey")
        if (githubCredential == nil ||
            githubCredential == "") {
            githubStatusLabel.stringValue = "Sign in to use paste feature."
            githubTokenField.stringValue = ""
            githubTokenField.placeholderString = "No Github Tokens on file"
        } else {
            //Unfocus github token box if there's a token
            githubTokenField.refusesFirstResponder = true
            //Show github logout button
            githubLogOutBtn.isHidden = false
        }
        //Load saved values to selectors, if there is any
        if let fileType = UserDefaults.standard.string(forKey: "preferredFileType") {
            gistFormatSelector.selectItem(withTitle: fileType)
        }
        let publicPaste = UserDefaults.standard.bool(forKey: "pasteAsPublic")
        if (!publicPaste) { githubPrivacySelector.selectItem(at: 0) }
        else { githubPrivacySelector.selectItem(at: 1) }
        fileShareSourceSelector.becomeFirstResponder()
        updateDropboxBtn()
        //Update start with sys button
        if (LaunchAtLogin.isEnabled) {
            startWithSysSwitch.state = .on
        } else {
            startWithSysSwitch.state = .off
        }
    }
    
    @IBAction func onSwitchStartWithSys(_ sender: Any) {
        guard let sender = sender as? NSSwitch else { return }
        if (sender.state == .on) {
            //Start with sys
            LaunchAtLogin.isEnabled = true
        } else {
            LaunchAtLogin.isEnabled = false
        }
    }
    
    @IBAction func onClickTokenInstructions(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://mszhelp.zendesk.com/hc/en-us/articles/360039552154")!)
    }
    
    func updateDropboxBtn(){
        if (DropboxClientsManager.authorizedClient == nil) {
            //Not logged in
            dropboxLogBtn.title = "Login Dropbox"
        } else {
            dropboxLogBtn.title = "Logout Dropbox"
        }
    }
    
    @IBAction func onClickDropboxLogButton(_ sender: Any) {
        if (DropboxClientsManager.authorizedClient == nil) {
            //Not logged in
            //Present login
            DropboxClientsManager.authorizeFromController(sharedWorkspace: NSWorkspace.shared, controller: self) { (url) in
                NSWorkspace.shared.open(url)
            }
        } else {
            DropboxClientsManager.resetClients()
        }
        updateDropboxBtn()
    }
    
    @IBAction func emptyToken(_ sender: Any){
        KeychainSwift().delete("AirPasteBoard_GithubKey")
    }
    
    @IBAction func saveToken(_ sender: Any){
        //Save token
        let githubToken = githubTokenField.stringValue
        if (githubToken != "<Existing Github Token>") {
            KeychainSwift().set(githubToken, forKey: "AirPasteBoard_GithubKey")
        }
        //Close
        DispatchQueue.main.async {
            self.popOver?.close()
        }
    }
    
    @IBAction func onPrivacySelectorChanged(_ sender: Any) {
        guard let sender = sender as? NSPopUpButton else { return }
        var privatePost = false
        if (sender.titleOfSelectedItem == "Set Gist as Public") {
            privatePost = true
        }
        UserDefaults.standard.set(privatePost, forKey: "pasteAsPublic")
    }
    
    @IBAction func onGistFormatSelectorChanged(_ sender: Any) {
        guard let sender = sender as? NSPopUpButton else { return }
        UserDefaults.standard.set(sender.titleOfSelectedItem ?? ".txt", forKey: "preferredFileType")
    }
    
    @IBAction func onStorageOptionChanged(_ sender: Any) {
        guard let sender = sender as? NSPopUpButton else { return }
        UserDefaults.standard.set(sender.titleOfSelectedItem, forKey: "storageLocation")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

