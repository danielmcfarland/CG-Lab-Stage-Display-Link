//
//  ViewController.swift
//  CG Lab Stage Display Link
//
//  Created by Daniel McFarland on 16/11/2021.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var connectionStatus: NSTextField!
    @IBOutlet weak var connectionServer: NSTextField!
    @IBOutlet weak var connectionPort: NSTextField!
    @IBOutlet weak var connectionPassword: NSTextField!
    
    @IBOutlet weak var buttonLabel: NSButton!
    
    var connected = false

    @IBAction func actionButton(_ sender: Any) {
        if connected == false {
            print("connecting")
            buttonLabel.title = "Connecting"
            connectionStatus.stringValue = "Connecting"
            buttonLabel.isEnabled = false
            connectionServer.isEnabled = false
            connectionPort.isEnabled = false
            connectionPassword.isEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.connected = true
                self.buttonLabel.title = "Disconnect"
                self.buttonLabel.isEnabled = true
                self.connectionStatus.stringValue = "Connected"
            }
            
        } else {
            print("disconnecting")
            buttonLabel.title = "Disconnecting"
            connectionStatus.stringValue = "Disconnecting"
            buttonLabel.isEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.connected = false
                self.buttonLabel.title = "Connect"
                self.buttonLabel.isEnabled = true
                self.connectionStatus.stringValue = "Offline"
                self.connectionServer.isEnabled = true
                self.connectionPort.isEnabled = true
                self.connectionPassword.isEnabled = true
            }
        }
        
        connected = !connected
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

