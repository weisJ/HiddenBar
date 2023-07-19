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
    private static let instance = StatusBarMonitor()
    private init() {
    }
    
    public static func setup() {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: Global.mainQueue) {[] (notification) in
            StatusBarMonitor.test()
        }
        StatusBarMonitor.getOffScreenItems()
        StatusBarMonitor.moveIcons()
    }
    
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
                let desc = CGWindowListCreateDescriptionFromArray([CGWindowID(windowNumber)] as CFArray)!
                NSLog("DESC:\(desc)")
                if applicationName == "SystemUIServer" {
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
    
    public static func moveIcons() {
        let windowInfosAll = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        for item in windowInfosAll {
            if let dict = item as? [CFString: AnyObject] {
                let applicationName = dict[kCGWindowOwnerName as CFString] as! String
                let boundsDict = dict[kCGWindowBounds as CFString] as! CFDictionary
                let pid = dict[kCGWindowOwnerPID as CFString] as! pid_t
                let bounds = CGRect(dictionaryRepresentation: boundsDict)!
                if applicationName == "SystemUIServer" {
                    let eventMask =
                        (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue)
                    let machPort = CGEvent.tapCreateForPid(pid: pid, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(eventMask), callback: (
                        { [] (_,_,event,_)  in
                            NSLog("TRIGGERED! \(event.location)");
                            return Unmanaged.passUnretained(event)}
                    ), userInfo: nil)
                    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0)
                    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                    CGEvent.tapEnable(tap: machPort!, enable: true)
                    CFRunLoopRun()
                    NSLog("MOVE:\(machPort)")
                }
            }
        }
    }
    
    public static func test() {
        let windowInfosAll = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        let windowInfosServer = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>)
        
        var pid = 0 as pid_t
        for item in windowInfosServer {
            if let dict = item as? [CFString: AnyObject] {
                let applicationName = dict[kCGWindowOwnerName as CFString] as! String
                if applicationName == "Dock" {
                    pid = dict[kCGWindowOwnerPID as CFString] as! pid_t
                }
            }
        }
        if pid == 0 {NSLog("OOPS");return}
        for item in windowInfosAll {
            if let dict = item as? [CFString: AnyObject] {
                let applicationName = dict[kCGWindowOwnerName as CFString] as! String
                let boundsDict = dict[kCGWindowBounds as CFString] as! CFDictionary
                let bounds = CGRect(dictionaryRepresentation: boundsDict)!
                if applicationName == "SystemUIServer" {
                    let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: CGPoint(x: bounds.minX + 1, y: bounds.minY + 1), mouseButton: .left)
                    //event!.post(tap: .cghidEventTap)
                    event!.postToPid(pid)
                    //usleep(useconds_t(Int.random(in: 400_010..<600_200)))
                    let event2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: CGPoint(x: bounds.minX + 1, y: bounds.minY + 1), mouseButton: .left)
                    //event2!.post(tap: .cghidEventTap)
                    event2!.postToPid(pid)
                    NSLog("POST")
                }
            }
        }
        return
    }
    public static func test2() {
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
        
        // result will be UNABLE_TO_COMPLETE when sandboxing is ON. 
        
        NSLog("array: \(array!), \(result).")
        
    }
}
