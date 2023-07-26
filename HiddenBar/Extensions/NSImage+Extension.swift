//
//  NSImage+Extension.swift
//  Hidden Bar
//
//  Created by 上原葉 on 7/23/23.
//  Copyright © 2023 UeharaYou. All rights reserved.
//

import AppKit

extension NSImage {
    func withTransparency(_ alpha: CGFloat) -> NSImage {
        let newImage = NSImage(size: self.size)
            newImage.lockFocus()

            let imageRect = NSRect(origin: .zero, size: self.size)
            self.draw(in: imageRect, from: imageRect, operation: .sourceOver, fraction: alpha)

            newImage.unlockFocus()
            return newImage
    }
}
