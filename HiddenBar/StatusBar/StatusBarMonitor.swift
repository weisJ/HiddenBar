//
//  StatusBarMonitor.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/27/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import Foundation
import AppKit
import CoreGraphics
import ApplicationServices

class StatusBarMonitor {
    public static func getOffScreenItems() {
        let windowInfosOnScreen = (CGWindowListCopyWindowInfo(CGWindowListOption.optionOnScreenOnly, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowLayer] as! Int == 25 && dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        let windowInfosAll = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowLayer] as! Int == 25 && dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        
        let windowInfoOffScreen = windowInfosAll.filter {!windowInfosOnScreen.contains($0)}
        
        for item in windowInfoOffScreen {
            if let dict = item as? [CFString: AnyObject] {
                let windowNumber = dict[kCGWindowNumber as CFString] as! Int
                let boundsDict = dict[kCGWindowBounds as CFString] as! CFDictionary
                let applicationName = dict[kCGWindowOwnerName as CFString] as! String
                let bounds = CGRect(dictionaryRepresentation: boundsDict)!
                //NSLog("ITEM: \(applicationName), \(bounds), \(CGWindowID(windowNumber))")
                //NSLog("ALL: \(dict)")
                
            }
        }
        NSLog("SERVER:\(CGSessionCopyCurrentDictionary())")
        NSLog("===============")
        
        let windowInfosAllWin = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        
        for item in windowInfosAllWin {
            if let dict = item as? [CFString: AnyObject] {
                let windowNumber = dict[kCGWindowNumber as CFString] as! Int
                let boundsDict = dict[kCGWindowBounds as CFString] as! CFDictionary
                let applicationName = dict[kCGWindowOwnerName as CFString] as! String
                let bounds = CGRect(dictionaryRepresentation: boundsDict)!
                NSLog("item: \(applicationName), \(dict), \(CGWindowID(windowNumber))")
                if applicationName == "VMware Fusion Applications Menu" {
                    //CGCaptureAllDisplays()
                    let newBounds = NSScreen.main!.convertRectFromBacking(bounds)
                    let mainDisplay = CGMainDisplayID()
                    
                    let cgImagea = CGWindowListCreateImage(
                        CGRect.null,
                        //CGRect.infinite,
                        [.optionIncludingWindow],
                        CGWindowID(windowNumber),
                        [.bestResolution, .boundsIgnoreFraming]
                        //[.boundsIgnoreFraming]
                    )
                    
                    
                    //CGReleaseAllDisplays()
                    
                    
                    guard let cgImage = cgImagea else {
                        if #available(macOS 10.15, *) {
                            NSLog("Image NOT Found! \(CGPreflightScreenCaptureAccess())")
                            
                            /* TODO:
                             1. create a window on status bar (at NSStatusWindowLevel ) => DONE
                             2. periodically moving hidden item to the front
                             3. check status by capturing image
                             4. move them back on timeout (immediate <- not changed, a preset time <- changed)
                            */
                        }
                        break
                    }
                    
                    let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    let theIamgeView = NSImageView(image: image)
                    let window = NSWindow.init()
                    window.setFrame(NSRect(x: 0, y: 1430, width: 100, height: 100), display: true)
                    window.contentView = theIamgeView
                    window.level = .statusBar
                    window.styleMask = [ .resizable ]
                    window.makeKeyAndOrderFront(NSApp)
                }
            }
        }
        /*
         let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
         
         for window in windowList {
         let boundsDict = window[kCGWindowBounds as String] as! CFDictionary
         let applicationName = window[kCGWindowOwnerName as String] as! String
         //let windowName = window[kCGWindowName as String] as! String
         
         if let bounds = CGRect(dictionaryRepresentation: boundsDict), bounds.origin.y == 0 {
         print(applicationName, bounds)
         }
         }
         */
    }
    
    public static func test() {
        return;
        let windowInfosAll = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowLayer] as! Int == 25 && dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        
        let item = windowInfosAll.filter{(($0 as? [CFString: AnyObject])?[kCGWindowOwnerName as CFString] as! String) == "ClashX"}
        if item.isEmpty {return}
        let target = item[0] as? [CFString: AnyObject]
        NSLog("TEST:\(target!)")
        let pid = target?[kCGWindowOwnerPID as CFString] as! pid_t
        
        let axElement = AXUIElementCreateApplication(pid)
        NSLog("axEle: \(axElement).")
        
        var array = CFArrayCreate(nil, nil, 0, nil)
        let result = withUnsafeMutablePointer(to: &array) {
            AXUIElementCopyActionNames(axElement, $0)
        }
        
        NSLog("array: \(array as! CFArray), \(result).")
        
    }
}
