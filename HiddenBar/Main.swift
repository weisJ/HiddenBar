//
//  main.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/16/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import AppKit
import ApplicationServices

@main struct MyApp {
    
    static func main () -> Void {
        // Check for duplicated instances.
        let otherRunningInstances = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == Global.mainAppId && $0 != NSRunningApplication.current
        }
        let isAppAlreadyRunning = !otherRunningInstances.isEmpty
        
        if (isAppAlreadyRunning) {
            
            NSLog("Program already running: \(otherRunningInstances.map{$0.processIdentifier}).")
            return;
        }
        
        // Register user default
        Preferences.setDefault()
        
        // Check Accessibility Permission
        let options : NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as CFString: true as CFBoolean]
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        NSLog("PERMIT: \(accessibilityEnabled)")
        
        // Load GUI
        NSLog("GUI started.")
        let ret_val = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        NSLog("GUI exited with exit code: \(ret_val).")
        return
    }
}
