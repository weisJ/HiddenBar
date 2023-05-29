//
//  StatusBarMonitor.swift
//  Hidden Bar
//
//  Created by 上原葉 on 5/27/23.
//  Copyright © 2023 Dwarves Foundation. All rights reserved.
//

import Foundation
import CoreGraphics
import ApplicationServices

class StatusBarMonitor {
    public static func getOffScreenItems() {
        return;
        let windowInfosOnScreenOnly = (CGWindowListCopyWindowInfo(CGWindowListOption.optionOnScreenOnly, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowLayer] as! Int == 25 && dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        let windowInfosAll = (CGWindowListCopyWindowInfo(CGWindowListOption.optionAll, kCGNullWindowID) as! Array<CFDictionary>).filter {
            guard let dict = $0 as? [CFString: AnyObject] else {return false}
            return dict[kCGWindowLayer] as! Int == 25 && dict[kCGWindowOwnerName] as! String != "SystemUIServer"
        }
        
        let windowInfoOffScreen = windowInfosAll.filter {!windowInfosOnScreenOnly.contains($0)}
        
        for item in windowInfoOffScreen {
            if let dict = item as? [CFString: AnyObject] {
                let boundsDict = dict[kCGWindowBounds as CFString] as! CFDictionary
                let applicationName = dict[kCGWindowOwnerName as CFString] as! String
                let bounds = CGRect(dictionaryRepresentation: boundsDict)!
                NSLog("ITEM: \(applicationName), \(bounds)")
            }
        }
        NSLog("===============")
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
