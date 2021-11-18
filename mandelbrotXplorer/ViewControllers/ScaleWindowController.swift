//
//  ScaleWindowController.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 02/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Cocoa
import Combine

class ScaleWindowController: NSWindowController {
    @IBOutlet weak var scaleSlider: NSSlider!
    @IBOutlet weak var scaleLabel: NSTextField!
    var scale: Scale
    var subscriptions: Set<AnyCancellable> = Set()
    
    init(scale: Scale) {
        self.scale = scale
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Init(coder:) has not been implemenetd")
    }
    
    // Ensure this always loads the correct nib
    override var windowNibName: NSNib.Name! {
        return "ScaleWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        setupScale()
    }
    
    @IBAction func sliderChanged(_ sender: NSSlider) {
        // Send the value to the scale which will then trigger all the subscriptions
        scale.scaleAmount = sender.doubleValue
    }
    
    func setupScale() {
        scale.$scaleAmount
            .map({ (amount: Double) -> Double in
                return amount.rounded()
            })
            .map({ (amount: Double) -> String in
                return "Scale: \(amount)"
            })
            .assign(to: \NSTextField.stringValue, on: scaleLabel)
            .store(in: &subscriptions)
    }
    
}
