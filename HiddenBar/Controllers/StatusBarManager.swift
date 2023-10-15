//
//  StatusBarManager.swift
//  vanillaClone
//
//  Created by Thanh Nguyen on 1/30/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import AppKit

enum StatusBarPolicy:Int {
    case  collapsed = 0, fullExpand = 1, partialExpand = 2
}

class StatusBarManager {

    enum StatusBarValidity {
        case invalid; case onStartUp; case valid
    }
    
    private let masterToggle = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let primarySeparator = NSStatusBar.system.statusItem(withLength: 0)
    private let secondarySeparator = NSStatusBar.system.statusItem(withLength: 0)
    private let updateLock = NSLock()
    private var autoCollapseTimer: Timer? = nil
    
    private static let hiddenSeparatorLength: CGFloat =  0
    private static let normalSeparatorLength: CGFloat =  10
    private static let expandedSeparatorLength: CGFloat = 10000

    public static func areSeperatorPositionValid () -> StatusBarValidity {
        guard
            let toggleButtonX = instance.masterToggle.button?.getOrigin?.x,
            let primarySeparatorX = instance.primarySeparator.button?.getOrigin?.x,
            let secondarySeparatorX = instance.secondarySeparator.button?.getOrigin?.x
        else {return .invalid}
        
        // all x will be all equal if applicationDidFinishLaunching have not returned, so we have to try again
        if toggleButtonX == primarySeparatorX && primarySeparatorX == secondarySeparatorX {return .onStartUp}
        
        if Global.isUsingLTRTypeSystem {
            return (toggleButtonX > primarySeparatorX && primarySeparatorX > secondarySeparatorX) ? .valid : .invalid
        } else {
            return (toggleButtonX < primarySeparatorX && primarySeparatorX < secondarySeparatorX) ? .valid : .invalid
        }
    }

    @objc private static func toggleButtonPressed(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            
            let isOptionKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.option)
            let isControlKeyPressed = event.modifierFlags.contains(NSEvent.ModifierFlags.control)
            
            switch (event.type, isOptionKeyPressed, isControlKeyPressed) {
            case (NSEvent.EventType.leftMouseUp, false, false):
                if (PreferenceManager.statusBarPolicy != .collapsed) {PreferenceManager.statusBarPolicy  = .collapsed}
                else {PreferenceManager.statusBarPolicy = .partialExpand}
                PreferenceManager.isEditMode = false
            case (NSEvent.EventType.leftMouseUp, true, false):
                if (PreferenceManager.statusBarPolicy != .collapsed) {PreferenceManager.statusBarPolicy  = .collapsed}
                else {PreferenceManager.statusBarPolicy = .fullExpand}
                PreferenceManager.isEditMode = false
            case (NSEvent.EventType.rightMouseUp, _, _):
                fallthrough
            case (NSEvent.EventType.leftMouseUp, _, true):
                ContextMenuManager.showContextMenu(sender)
            default:
                break
            }
        }
    }
    
    private static let instance = StatusBarManager()
    private init() {
        if let button = masterToggle.button {
            button.image = AssetManager.expandImage
        }
        
        if let button = primarySeparator.button {
            button.image = AssetManager.seperatorImage
        }
        
        if let button = secondarySeparator.button {
            button.image = AssetManager.seperatorImage
            button.appearsDisabled = true
        }
        masterToggle.autosaveName = "hiddenbar_masterToggle";
        primarySeparator.autosaveName = "hiddenbar_primarySeparator";
        secondarySeparator.autosaveName = "hiddenbar_secondarySeparator";
        NSLog("Status bar controller inited.")
    }
    
    public static func setup() {
        
        let masterToggle = instance.masterToggle,
        primarySeparator = instance.primarySeparator,
        secondarySeparator = instance.secondarySeparator
        
        if let button = masterToggle.button {
            button.target = self
            button.action = #selector(toggleButtonPressed(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        // This won't work: blocking action to be sent.
        //let menu = StatusBarMenuManager.getContextMenu()
        //masterToggle.menu = menu
        
        masterToggle.isVisible = true
        primarySeparator.isVisible = true
        secondarySeparator.isVisible = true

        NotificationCenter.default.addObserver(forName: NotificationNames.prefsChanged, object: nil, queue: Global.mainQueue) {[] (notification) in
            triggerAdjustment()
        }
        
        // Manually adjusting the bar once
        triggerAdjustment()
    }
    
    public static func finishUp() {
    }
    
    private static func triggerAdjustment() {
        switch areSeperatorPositionValid() {
        case .onStartUp:
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                // retry on more time after 1s
                NotificationCenter.default.post(Notification(name: NotificationNames.prefsChanged, object: PreferenceManager.isAutoStart))
            }
            fallthrough
        case .valid:
            resetAutoCollapseTimer()
            adjustStatusBar()
        case .invalid:
            resetSeperator()
        }
    }
    
    private static func resetSeperator () {
        let masterToggle = instance.masterToggle,
            primarySeparator = instance.primarySeparator,
            secondarySeparator = instance.secondarySeparator,
            lock = instance.updateLock
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        primarySeparator.length = StatusBarManager.normalSeparatorLength
        secondarySeparator.length = StatusBarManager.normalSeparatorLength
        masterToggle.button?.image = AssetManager.collapseImage
        masterToggle.button?.title = "Invalid".localized
        lock.unlock()
    }
    
    private static func resetAutoCollapseTimer () {
        let lock = instance.updateLock
        do {
            lock.lock(before: Date(timeIntervalSinceNow: 1))
            defer {lock.unlock()}
            //NSLog("Timer Cancelled:\(String(describing: instance.autoCollapseTimer)).")
            instance.autoCollapseTimer?.invalidate()
            switch (PreferenceManager.isAutoHide, PreferenceManager.isEditMode, PreferenceManager.statusBarPolicy) {
            case (false, _, _), (_, true, _), (_, _, .collapsed):
                return
            default:
                break
            }
            let timer = Timer(timeInterval: TimeInterval(PreferenceManager.numberOfSecondForAutoHide), repeats: false) {
                [] (timer:Timer) in
                //NSLog("Timer Triggered:\(timer).")
                PreferenceManager.statusBarPolicy = .collapsed
                return
            }
            //NSLog("Timer Dispatched:\(timer).")
            Global.runLoop.add(timer, forMode: .common)
            instance.autoCollapseTimer = timer
        }
    }
    
    private static func adjustStatusBar () {
        let masterToggle = instance.masterToggle,
            primarySeparator = instance.primarySeparator,
            secondarySeparator = instance.secondarySeparator,
            lock = instance.updateLock
        
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        if PreferenceManager.isEditMode {
            primarySeparator.length = StatusBarManager.normalSeparatorLength
            //primarySeparator.isVisible = true
            secondarySeparator.length = StatusBarManager.normalSeparatorLength
            //secondarySeparator.isVisible = true
            masterToggle.button?.image = AssetManager.collapseImage
            masterToggle.button?.title = "Edit".localized
            
        }
        else {
            switch PreferenceManager.statusBarPolicy {
            case .fullExpand:
                primarySeparator.length = StatusBarManager.hiddenSeparatorLength
                //primarySeparator.isVisible = false
                secondarySeparator.length = StatusBarManager.hiddenSeparatorLength
                //secondarySeparator.isVisible = false
                masterToggle.button?.image = AssetManager.collapseImage
                masterToggle.button?.title = ""
                
            case .partialExpand:
                primarySeparator.length = StatusBarManager.hiddenSeparatorLength
                //primarySeparator.isVisible = false
                secondarySeparator.length = StatusBarManager.expandedSeparatorLength
                //secondarySeparator.isVisible = true
                masterToggle.button?.image = AssetManager.collapseImage
                masterToggle.button?.title = ""
                
            case .collapsed:
                primarySeparator.length = StatusBarManager.expandedSeparatorLength
                //primarySeparator.isVisible = true
                secondarySeparator.length = StatusBarManager.expandedSeparatorLength
                //secondarySeparator.isVisible = true
                masterToggle.button?.image = AssetManager.expandImage
                masterToggle.button?.title = ""
                
            }
        }
        lock.unlock()
    }
}

