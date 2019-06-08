//
//  WindowController.swift
//  Project4
//
//  Created by Andrew Paxson on 2019-05-25.
//  Copyright © 2019 Andrew Paxson. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet var addressEntry: NSTextField!
    @IBOutlet var reloadButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override func cancelOperation(_ sender: Any?) {
        window?.makeFirstResponder(self.contentViewController)
    }

}
