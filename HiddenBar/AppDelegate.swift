//
//  AppDelegate.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/24/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import AppKit
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate{
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        ContextMenuManager.setup()
        StatusBarManager.setup()
        HotKeyManager.setup()
        AppActivationManager.setup()
        NSLog("App launched.")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        PreferencesWindowController.showPrefWindow()
        NSLog("App Reopened.")
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        NSLog("App shutting down.")
        AppActivationManager.finishUp()
        HotKeyManager.finishUp()
        StatusBarManager.finishUp()
        ContextMenuManager.finishUp()
    }
   
}

 
