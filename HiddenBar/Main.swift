//
//  main.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/16/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import AppKit

@main struct MyApp {
    
    static func main () -> Void {
        // Check for duplicated instances (in case of "open -n" command or other circumstances).
        let otherRunningInstances = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == Global.mainAppId && $0 != NSRunningApplication.current
        }
        let isAppAlreadyRunning = !otherRunningInstances.isEmpty
        
        if (isAppAlreadyRunning) {
            NSLog("Program already running: \(otherRunningInstances.map{$0.processIdentifier}).")
        }
        else {
            // Register user default
            PreferenceManager.setDefault()
            
            // Load main entry for NSApp
            NSLog("App started.")
            let ret_val = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
            NSLog("App exited with exit code: \(ret_val).")
        }
        return
    }
}
