//
//  Util.swift
//  AirPasteBoard
//
//  Created by Shunzhe Ma on 12/6/19.
//  Copyright © 2019 Shunzhe Ma. All rights reserved.
//

import Foundation
import Cocoa
import KeychainSwift
import SwiftyDropbox

/*
 Here's the place that the paste & upload action actually happens
 */

class Util {
    
    func uploadPasteBin(){
        //Check if there's a Gist credential
        guard let gistToken = KeychainSwift().get("AirPasteBoard_GithubKey") else {
            showNoGithubToken(); return
        }
        guard let pasteBoardStr = NSPasteboard.general.pasteboardItems?.first?.string(forType: .string) else {
            return
        }
        //Generate paste file name
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyyyyHHmm"
        let dateStr = formatter.string(from: Date())
        //Read user preferences
        let fileType = UserDefaults.standard.string(forKey: "preferredFileType") ?? ""
        let publicPaste = UserDefaults.standard.bool(forKey: "pasteAsPublic")
        //Make a request to Gist
        GithubRequestHelper().createGist(utilObj: self, githubToken: gistToken, fileName: "paste" + dateStr + fileType, content: pasteBoardStr, setPublic: publicPaste)
    }
    
    func selectFileToUpload(){
        let dialog = NSOpenPanel()
        dialog.title = "Choose a file to upload"
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.allowsMultipleSelection = false
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            if (result != nil) {
                self.uploadFile(withLocalPath: result!)
            }
        }
    }
    
    func uploadFile(withLocalPath: URL) {
        //Check storage locations
        let storageLocation = UserDefaults.standard.string(forKey: "storageLocation") ?? "iCloud Drive"
        if (storageLocation == "iCloud Drive") {
            //iCloud
            saveToiCloud(localPath: withLocalPath)
        } else if (storageLocation == "DropBox") {
            //Dropbox
            saveToDropbox(localPath: withLocalPath)
        }
    }
    
    func saveToiCloud(localPath: URL) {
        ///First check if the file is on iCloud
        if (FileManager.default.isUbiquitousItem(at: localPath)) {
            do {
                let path = try FileManager.default.url(forPublishingUbiquitousItemAt: localPath, expiration: nil)
                onSuccessShare(url: path.absoluteString)
            } catch {
                onFailedGistShare(reason: error.localizedDescription)
            }
        } else {
            //Tell the user that this file is not in iCloud thus cannot be shared
            DispatchQueue.main.async {
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                appDelegate.presentNotInIcloudView(filePath: localPath)
            }
        }
    }
    
    func saveToDropbox(localPath: URL) {
        //Check if DropBox is already logged in
        do {
            let file = try Data(contentsOf: localPath)
            if let client = DropboxClientsManager.authorizedClient {
                let ramdomStr = UUID().uuidString
                let endIndex = ramdomStr.index(ramdomStr.startIndex, offsetBy: 9)
                let remotePath = "/" + ramdomStr[..<endIndex] + localPath.lastPathComponent
                client.files.upload(path: remotePath, input: file).response { (response, error) in
                    if (error == nil) {
                        self.shareUploadedFile(path: remotePath)
                    } else {
                        self.onFailedGistShare(reason: error?.description ?? "Dropbox upload failed.")
                    }
                }
            } else {
                //Not authorized
                onFailedGistShare(reason: "Please sign in Dropbox in the Preferences")
            }
        } catch {
            return
        }
    }
    
    func shareUploadedFile(path: String) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        client.sharing.createSharedLinkWithSettings(path: path).response { (shareResponse, error) in
            if (error == nil) {
                guard let url = shareResponse?.url else { return }
                self.onSuccessShare(url: url)
            } else {
                self.onFailedGistShare(reason: error?.description ?? "The file has been uploaded the DropBox but AirPasteBoard failed to generate an URL for it.")
            }
        }
    }
    
    /*
     User interactions
     */
    
    func onSuccessShare(url: String) {
        //Copy the URL to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(url, forType: NSPasteboard.PasteboardType.string)
        //Show success popover
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.presentSuccessView()
        }
    }
    
    func onFailedGistShare(reason: String){
        //Show error alert
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.presentFailedView(reason: reason)
        }
    }
    
    private func showNoGithubToken(){
        onFailedGistShare(reason: "Please go to preferences to log into your Github account first.")
    }
    
    private func showNotification(title: String, content: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = content
        notification.contentImage = NSImage(named: "AppIcon")
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
    
}
