//
//  ViewController.swift
//  Project4
//
//  Created by Andrew Paxson on 2019-05-25.
//  Copyright © 2019 Andrew Paxson. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate, NSGestureRecognizerDelegate, NSTouchBarDelegate, NSSharingServicePickerTouchBarItemDelegate {

    var rows: NSStackView!
    var selectedWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rows = NSStackView()
        rows.translatesAutoresizingMaskIntoConstraints = false
        rows.orientation = .vertical
        rows.distribution = .fillEqually
        view.addSubview(rows)
        
        rows.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        rows.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rows.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        rows.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let column = NSStackView(views: [makeWebView()])
        column.distribution = .fillEqually
        
        rows.addArrangedSubview(column)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: Toolbar Connections
    @IBAction func urlEntered(_ sender: NSTextField) {
        
        guard let selected = selectedWebView else { return }
        
        if let url = URL(string: sender.stringValue) {
            selected.load(URLRequest(url: url))
        }
        
    }
    
    @IBAction func navigationClicked(_ sender: NSSegmentedControl) {
        guard let selected = selectedWebView else { return }
        
        if sender.selectedSegment == 0 {
            selected.goBack()
        } else {
            selected.goForward()
        }
        
    }
    
    @IBAction func adjustRows(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            let columnCount = (rows.arrangedSubviews.first as! NSStackView).arrangedSubviews.count
            let newWebViews = (1...columnCount).map { _ in makeWebView() }
            let row = NSStackView(views: newWebViews)
            row.distribution = .fillEqually
            rows.addArrangedSubview(row)
        } else {
            guard rows.arrangedSubviews.count > 1 else { return }
            
            guard let rowToRemove = rows.arrangedSubviews.last as? NSStackView else { return }
            for cell in rowToRemove.arrangedSubviews {
                cell.removeFromSuperview()
            }
            
            rows.removeArrangedSubview(rowToRemove)
        }
    }
    
    @IBAction func adjustColumns(_ sender: NSSegmentedControl) {
        
        if sender.selectedSegment == 0 {
            for case let row as NSStackView in rows.arrangedSubviews {
                row.addArrangedSubview(makeWebView())
            }
        } else {
            
            guard let firstRow = rows.arrangedSubviews.first as? NSStackView else { return }
            
            guard firstRow.arrangedSubviews.count > 1 else { return }
            
            for case let row as NSStackView in rows.arrangedSubviews {
                if let last = row.arrangedSubviews.last {
                    // Removing a view from a StackView is a two-step process
                    // First: Remove is from the StackView
                    // Second Remove it from the superview.
                    row.removeArrangedSubview(last)
                    last.removeFromSuperview()
                }
            }
        }
        
    }
    
    @IBAction func refreshPage(_ sender: NSButton) {
        guard let selectedView = selectedWebView else {
            return
        }
        if selectedView.isLoading {
            selectedView.stopLoading()
        } else {
            selectedView.reload()
        }
    }
    // MARK: -
    
    func makeWebView() -> NSView {
        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.wantsLayer = true
        webView.load(URLRequest(url: URL(string: "https://apple.com")!))
        
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(webViewClicked))
        recognizer.delegate = self
        webView.addGestureRecognizer(recognizer)
        
        if selectedWebView == nil {
            select(webView: webView)
        }
        
        return webView
    }
    
    func select(webView: WKWebView) {
        selectedWebView = webView
        selectedWebView.layer?.borderWidth = 4
        selectedWebView.layer?.borderColor = NSColor.systemBlue.cgColor
        
        if let windowController = view.window?.windowController as?
            WindowController {
            windowController.addressEntry.stringValue =
                selectedWebView.url?.absoluteString ?? ""
        }
        selectedWebView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [.new, .old], context: nil)
        updateReloadButtonRepresentation()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            updateReloadButtonRepresentation()
        }
    }
    func updateReloadButtonRepresentation() {
        guard let selected = selectedWebView else { return }
        
        guard let windowController = view.window?.windowController as? WindowController else {
            return
        }
        if selected.isLoading {
            windowController.reloadButton.image = NSImage(named: NSImage.stopProgressTemplateName)
        } else {
            windowController.reloadButton.image = NSImage(named: NSImage.refreshTemplateName)
        }
    }
    
    @objc func webViewClicked(recognizer: NSClickGestureRecognizer) {
        guard let newSelectedWebView = recognizer.view as? WKWebView else { return }
        
        if let selected = selectedWebView {
            selected.layer?.borderWidth = 0
        }
        
        select(webView: newSelectedWebView)
    }
    
    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        if gestureRecognizer.view == selectedWebView {
            return false
        } else {
            return true
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation:
        WKNavigation!) {
        guard webView == selectedWebView else { return }
        if let windowController = view.window?.windowController as?
            WindowController {
            windowController.addressEntry?.stringValue =
                webView.url?.absoluteString ?? ""
        }
    }
    
    // MARK: Touch Bar Methods
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        NSApp.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
        // create touch bar with UID
        let touchBar = NSTouchBar()
        touchBar.customizationIdentifier = NSTouchBar.CustomizationIdentifier("com.apaxson.gridbrowser")
        touchBar.delegate = self
        
        touchBar.defaultItemIdentifiers = [.navigation, .adjustGrid, .enterAddress, .sharingPicker]
        
        // Enter Address Principle
        touchBar.principalItemIdentifier = .enterAddress
        
        // All User to Customize all four controls
        touchBar.customizationAllowedItemIdentifiers = [.adjustColumns, .adjustGrid, .adjustRows, .sharingPicker]
        
        // Set the required items
        touchBar.customizationRequiredItemIdentifiers = [.enterAddress]
        
        return touchBar
    }
    
    
    @available(OSX 10.12.2, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        
        // MARK: Enter Address Touch Bar Button
        case NSTouchBarItem.Identifier.enterAddress:
            let button = NSButton(title: "Enter Address", target: self, action: #selector(selectAddressEntry))
            button.setContentHuggingPriority(NSLayoutConstraint.Priority(10), for: .horizontal)
            let customTouchBarItem = NSCustomTouchBarItem(identifier: identifier)
            customTouchBarItem.view = button
            return customTouchBarItem
        
        // MARK: Navigation Touch Bar Button
        case NSTouchBarItem.Identifier.navigation:
            let forward = NSImage(named: NSImage.touchBarGoForwardTemplateName)!
            let back = NSImage(named: NSImage.touchBarGoBackTemplateName)!
            
            let segmentedControl = NSSegmentedControl(images: [back, forward], trackingMode: .momentary, target: self, action: #selector(navigationClicked))
            let customTouchBarItem = NSCustomTouchBarItem(identifier: identifier)
            customTouchBarItem.view = segmentedControl
            return customTouchBarItem
            
        case NSTouchBarItem.Identifier.sharingPicker:
            let picker = NSSharingServicePickerTouchBarItem(identifier: identifier)
            picker.delegate = self
            return picker
            
        case NSTouchBarItem.Identifier.adjustRows:
            let control = NSSegmentedControl(labels: ["Add Row", "Remove Row"], trackingMode: .momentaryAccelerator, target: self, action: #selector(adjustRows))
            let customTouchBarItem = NSCustomTouchBarItem(identifier: identifier)
            customTouchBarItem.customizationLabel = "Rows"
            customTouchBarItem.view = control
            return customTouchBarItem
            
        case NSTouchBarItem.Identifier.adjustColumns:
            let control = NSSegmentedControl(labels: ["Add Column", "Remove Column"], trackingMode: .momentaryAccelerator, target: self, action: #selector(adjustColumns))
            let customTouchBarItem = NSCustomTouchBarItem(identifier: identifier)
            customTouchBarItem.customizationLabel = "Columns"
            customTouchBarItem.view = control
            return customTouchBarItem
            
        case NSTouchBarItem.Identifier.adjustGrid:
            let popover = NSPopoverTouchBarItem(identifier: identifier)
            popover.collapsedRepresentationLabel = "Grid"
            popover.customizationLabel = "Adjust Grid"
            popover.popoverTouchBar = NSTouchBar()
            popover.popoverTouchBar.delegate = self
            popover.popoverTouchBar.defaultItemIdentifiers = [
                .adjustRows,
                .adjustColumns
            ]
            return popover
            
        default:
            return nil
        }
    }
    
    @objc func selectAddressEntry() {
        if let windowController = view.window?.windowController as? WindowController {
            print(windowController.addressEntry.acceptsFirstResponder)
            windowController.window?.makeFirstResponder(windowController.addressEntry)
        }
    }
    
    @available(OSX 10.12.2, *)
    func items(for pickerTouchBarItem: NSSharingServicePickerTouchBarItem) -> [Any] {
        guard let webView = selectedWebView else { return [] }
        guard let url = webView.url?.absoluteString else { return [] }
        return [url]
    }

}

extension NSTouchBarItem.Identifier {
    static let navigation = NSTouchBarItem.Identifier("com.apaxson.gridbrowser.navigation")
    static let enterAddress = NSTouchBarItem.Identifier("com.apaxson.gridbrowser.enterAddress")
    static let sharingPicker = NSTouchBarItem.Identifier("com.apaxson.gridbrowser.sharingPicker")
    static let adjustGrid = NSTouchBarItem.Identifier("com.apaxson.gridbrowser.adjustGrid")
    static let adjustRows = NSTouchBarItem.Identifier("com.apaxson.gridbrowser.adjustRows")
    static let adjustColumns = NSTouchBarItem.Identifier("com.apaxson.gridbrowser.adjustColumns")
}

