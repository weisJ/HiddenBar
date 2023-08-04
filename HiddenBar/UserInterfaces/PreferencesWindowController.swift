//
//  PreferencesWindowController.swift
//  Hidden Bar
//
//  Created by Phuc Le Dien on 2/22/19.
//  Copyright © 2019 Dwarves Foundation. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    
    enum MenuSegment: Int {
        case general
        case about
    }
    
    static private let instance: PreferencesWindowController = {
        let wc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "MainWindow") as! PreferencesWindowController
        wc.window?.delegate = PreferencesWindowDelegate.shared
        return wc
    }()
    
    //private static var isWindowVisible = false
    
    private var menuSegment: MenuSegment = .general {
        didSet {
            updateVC()
        }
    }
    
    private let preferencesVC = PreferencesViewController.initWithStoryboard()
    
    private let aboutVC = AboutViewController.initWithStoryboard()
    
    override func windowDidLoad() {
        super.windowDidLoad() // this is invoked when private instance is inited (not available until it returns)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            // retry on more time after 1s
            NotificationCenter.default.post(Notification(name: NotificationNames.prefsChanged, object: PreferenceManager.isAutoStart))
        }
        //NotificationCenter.default.post(Notification(name: NotificationNames.prefsChanged, object: nil)) // HERE! DEADLOCKED!!!!
        updateVC()
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        if let vc = self.contentViewController as? PreferencesViewController, vc.listening {
            vc.updateGlobalShortcut(event)
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        if let vc = self.contentViewController as? PreferencesViewController, vc.listening {
            vc.updateModiferFlags(event)
        }
    }
    
    @IBAction func switchSegment(_ sender: NSSegmentedControl) {
        guard let segment = MenuSegment(rawValue: sender.indexOfSelectedItem) else {return}
        menuSegment = segment
    }
    
    private func updateVC() {
        switch menuSegment {
        case .general:
            self.window?.contentViewController = preferencesVC
        case .about:
            self.window?.contentViewController = aboutVC
        }
    }
    
    static func showPrefWindow() {
        instance.window?.bringToFront()
        NotificationCenter.default.post(Notification(name: NotificationNames.prefsChanged, object: PreferenceManager.isAutoStart))
    }
    
    static var isPrefWindowVisible: Bool {
        let res = instance.window?.isVisible ?? false
        return res
        //return isWindowVisible
    }
}


class PreferencesWindowDelegate: NSObject, NSWindowDelegate {
    static let shared: PreferencesWindowDelegate = {
        return PreferencesWindowDelegate()
    }()
    
    
    func windowWillClose(_ notification: Notification) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            // retry on more time after 0.1s
            NotificationCenter.default.post(Notification(name: NotificationNames.prefsChanged, object: PreferenceManager.isAutoStart))
        }
    }
    
}

