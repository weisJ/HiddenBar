//
//  AssetManager.swift
//  Hidden Bar
//
//  Created by Peter Luo on 2021/5/28.
//  Copyright © 2021 Dwarves Foundation. All rights reserved.
//

import AppKit

struct AssetManager {
    static let expandImage = NSImage(named: NSImage.Name((Global.isUsingLTRTypeSystem) ? "ic_expand" : "ic_collapse"))!//.withTransparency(0.32)
    static let collapseImage = NSImage(named: NSImage.Name((Global.isUsingLTRTypeSystem) ? "ic_collapse" : "ic_expand"))!
    static let seperatorImage = NSImage(named: NSImage.Name("ic_line"))!
}
