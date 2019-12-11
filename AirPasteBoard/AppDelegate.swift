//
//  AppDelegate.swift
//  AirPasteBoard
//
//  Created by Shunzhe Ma on 12/6/19.
//  Copyright © 2019 Shunzhe Ma. All rights reserved.
//

import Cocoa
import SwiftyDropbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSDraggingDestination {
    
    var barItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //Add status bar icon
        addStatusBarIcon()
        //Setup DropBox
        DropboxClientsManager.setupWithAppKeyDesktop("YOUR_DROPBOXdev_TOKEN")
        //Handle Dropbox auth callback
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(self.handleGetURLEvent),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }
    
    func addStatusBarIcon(){
        let statusBar = NSStatusBar.system
        barItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        barItem.button?.image = NSImage(named: "StatusBarButtonImage")
        barItem.button?.window?.registerForDraggedTypes([.fileURL])
        barItem.button?.window?.delegate = self
        let barMenu = NSMenu(title: "AirPasteBoardMenu")
        barMenu.addItem(NSMenuItem(title: "Paste to Gist", action: #selector(self.actionGistPaste), keyEquivalent: "g"))
        barMenu.addItem(NSMenuItem(title: "Upload a File", action: #selector(self.actionFileUpload), keyEquivalent: "f"))
        barMenu.addItem(NSMenuItem.separator())
        barMenu.addItem(NSMenuItem(title: "Preferences", action: #selector(self.actionPresentSettings), keyEquivalent: ""))
        barMenu.addItem(NSMenuItem(title: "Quit", action: #selector(self.actionQuit), keyEquivalent: ""))
        barItem.menu = barMenu
        //Show starter menu once
        if (!UserDefaults.standard.bool(forKey: "starterMenu_Shown")) {
            _ = showPopover(viewIdentifier: "welcomeView")
            UserDefaults.standard.set(true, forKey: "starterMenu_Shown")
        }
    }
    
    @objc func actionGistPaste(){
        Util().uploadPasteBin()
    }
    
    @objc func actionFileUpload(){
        Util().selectFileToUpload()
    }
    
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let path = sender.draggingPasteboard.propertyList(forType: .fileURL) as? String {
            if let firstFileURL = URL(string: path) {
                Util().uploadFile(withLocalPath: firstFileURL)
                return true
            }
        }
        return false
    }
    
    /*
     View Presentations
     */
    
    @objc func actionPresentSettings(){
        _ = showPopover(viewIdentifier: "ViewController")
    }
    
    func presentSuccessView(viewIdentifier: String = "successViewController"){
        let presentedPopover = showPopover(viewIdentifier: viewIdentifier)
        //Hide after 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { (timer) in
            DispatchQueue.main.async {
                presentedPopover.close()
            }
        }
    }
    
    func presentFailedView(reason: String) {
        let alert = NSAlert()
        alert.messageText = "Sharing Failed"
        alert.informativeText = reason
        alert.alertStyle = .warning
        alert.runModal()
    }
    
    /*
     Notifications about files not stored in iCloud. Will ask user whether to share
     it on Dropbox instead
     */
    func presentNotInIcloudView(filePath: URL){
        let alert = NSAlert()
        alert.messageText = "Sharing Failed"
        alert.informativeText = "This file is not yet stored in the iCloud. You can manually copy it to your iCloud drive, or use Dropbox sharing instead."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Use Dropbox")
        alert.alertStyle = .warning
        let result = alert.runModal()
        switch result {
        case .alertSecondButtonReturn:
            Util().saveToDropbox(localPath: filePath)
        default:
            return
        }
    }
    
    func showPopover(viewIdentifier: String) -> NSPopover {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let popoverVC = storyboard.instantiateController(withIdentifier: viewIdentifier) as! NSViewController
        let popover = NSPopover()
        popover.contentViewController = popoverVC
        popover.behavior = .transient
        if let barBtn = barItem.button {
            DispatchQueue.main.async {
                popover.show(relativeTo: barBtn.frame, of: barBtn, preferredEdge: NSRectEdge.minY)
            }
        }
        if let settingsVC = popoverVC as? ViewController {
            settingsVC.popOver = popover
        }
        return popover
    }
    
    @objc func actionQuit(){
        NSApplication.shared.terminate(self)
    }
    
    /*
     Codes referenced from SwiftyDropBox Github page
     */
    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
        if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
            if let urlStr = aeEventDescriptor.stringValue {
                let url = URL(string: urlStr)!
                if let authResult = DropboxClientsManager.handleRedirectURL(url) {
                    switch authResult {
                    case .success:
                        print("Success! User is logged into Dropbox.")
                        self.presentSuccessView(viewIdentifier: "dropboxLoginSuccessful")
                    case .cancel:
                        print("Authorization flow was manually canceled by user!")
                    case .error(_, let description):
                        print("Error: \(description)")
                    }
                }
                // this brings your application back the foreground on redirect
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}
