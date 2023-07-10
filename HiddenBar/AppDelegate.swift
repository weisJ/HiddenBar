//
//  AppDelegate.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/24/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate{
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSLog("App launched.")
        StatusBarController.setup()
        HotKeyManager.setup()
        StatusBarMonitor.setup()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("App shutting down.")
    }
   
}

 
