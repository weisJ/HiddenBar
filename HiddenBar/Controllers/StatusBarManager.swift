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
    private let primarySeprator = NSStatusBar.system.statusItem(withLength: 0)
    private let secondarySeprator = NSStatusBar.system.statusItem(withLength: 0)
    private let updateLock = NSLock()
    private var autoCollapseTimer: Timer? = nil
    
    private static let hiddenSepratorLength: CGFloat =  0
    private static let normalSepratorLength: CGFloat =  10
    private static let expandedSeperatorLength: CGFloat = 10000

    public static func areSeperatorPositionValid () -> StatusBarValidity {
        guard
            let toggleButtonX = instance.masterToggle.button?.getOrigin?.x,
            let primarySepratorX = instance.primarySeprator.button?.getOrigin?.x,
            let secondarySepratorX = instance.secondarySeprator.button?.getOrigin?.x
        else {return .invalid}
        
        // all x will be all equal if applicationDidFinishLaunching have not returned, so we have to try again
        if toggleButtonX == primarySepratorX && primarySepratorX == secondarySepratorX {return .onStartUp}
        
        if Global.isUsingLTRTypeSystem {
            return (toggleButtonX > primarySepratorX && primarySepratorX > secondarySepratorX) ? .valid : .invalid
        } else {
            return (toggleButtonX < primarySepratorX && primarySepratorX < secondarySepratorX) ? .valid : .invalid
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
        
        if let button = primarySeprator.button {
            button.image = AssetManager.seperatorImage
        }
        
        if let button = secondarySeprator.button {
            button.image = AssetManager.seperatorImage
            button.appearsDisabled = true
        }
        masterToggle.autosaveName = "hiddenbar_masterToggle";
        primarySeprator.autosaveName = "hiddenbar_primarySeprator";
        secondarySeprator.autosaveName = "hiddenbar_secondarySeprator";
        NSLog("Status bar controller inited.")
    }
    
    public static func setup() {
        
        let masterToggle = instance.masterToggle,
        primarySeprator = instance.primarySeprator,
        secondarySeprator = instance.secondarySeprator
        
        if let button = masterToggle.button {
            button.target = self
            button.action = #selector(toggleButtonPressed(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        // This won't work: blocking action to be sent.
        //let menu = StatusBarMenuManager.getContextMenu()
        //masterToggle.menu = menu
        
        masterToggle.isVisible = true
        primarySeprator.isVisible = true
        secondarySeprator.isVisible = true

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
            primarySeprator = instance.primarySeprator,
            secondarySeprator = instance.secondarySeprator,
            lock = instance.updateLock
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        primarySeprator.length = StatusBarManager.normalSepratorLength
        secondarySeprator.length = StatusBarManager.normalSepratorLength
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
            primarySeprator = instance.primarySeprator,
            secondarySeprator = instance.secondarySeprator,
            lock = instance.updateLock
        
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        if PreferenceManager.isEditMode {
            primarySeprator.length = StatusBarManager.normalSepratorLength
            //primarySeprator.isVisible = true
            secondarySeprator.length = StatusBarManager.normalSepratorLength
            //secondarySeprator.isVisible = true
            masterToggle.button?.image = AssetManager.collapseImage
            masterToggle.button?.title = "Edit".localized
            
        }
        else {
            switch PreferenceManager.statusBarPolicy {
            case .fullExpand:
                primarySeprator.length = StatusBarManager.hiddenSepratorLength
                //primarySeprator.isVisible = false
                secondarySeprator.length = StatusBarManager.hiddenSepratorLength
                //secondarySeprator.isVisible = false
                masterToggle.button?.image = AssetManager.collapseImage
                masterToggle.button?.title = ""
                
            case .partialExpand:
                primarySeprator.length = StatusBarManager.hiddenSepratorLength
                //primarySeprator.isVisible = false
                secondarySeprator.length = StatusBarManager.expandedSeperatorLength
                //secondarySeprator.isVisible = true
                masterToggle.button?.image = AssetManager.collapseImage
                masterToggle.button?.title = ""
                
            case .collapsed:
                primarySeprator.length = StatusBarManager.expandedSeperatorLength
                //primarySeprator.isVisible = true
                secondarySeprator.length = StatusBarManager.expandedSeperatorLength
                //secondarySeprator.isVisible = true
                masterToggle.button?.image = AssetManager.expandImage
                masterToggle.button?.title = ""
                
            }
        }
        lock.unlock()
    }
}

