//
//  startViewController.swift
//  AirPasteBoard
//
//  Created by Shunzhe Ma on 12/6/19.
//  Copyright © 2019 Shunzhe Ma. All rights reserved.
//

import Foundation
import Cocoa
import LaunchAtLogin

class startViewController: NSViewController {
    
    @IBOutlet weak var startWithSysSwitch: NSSwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
}
