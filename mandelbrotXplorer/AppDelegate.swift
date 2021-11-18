//
//  AppDelegate.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 02/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Cocoa
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var mandelbrotView: MandelbrotImageView!
    var scaleWindowController: ScaleWindowController?
    var scale = Scale()
    var subscriptions: Set<AnyCancellable> = Set()
    
    fileprivate func setupSubscriptions() {
        scale.$scaleAmount
            .throttle(for: .milliseconds(50), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { (scaleValue:Double) in
                self.mandelbrotView.setDesiredSize(Int(scaleValue.rounded()))
            })
            .store(in: &subscriptions)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        setupSubscriptions()            
        
        let scaleWindow = ScaleWindowController(scale: scale)
        scaleWindow.showWindow(self)
        self.scaleWindowController = scaleWindow
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

