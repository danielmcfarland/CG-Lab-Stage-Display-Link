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
    
    private var proPresenterService: ProPresenterService!
    private let nc = NotificationCenter.default
    private var status: ConnectionStatus!

    @IBAction func actionButton(_ sender: Any) {
        if let status = status {
            switch status {
            case .connected:
                proPresenterService.disconnect()
                UserDefaults().set(connectionServer.stringValue, forKey: "connectionServer")
                UserDefaults().set(connectionPort.stringValue, forKey: "connectionPort")
                UserDefaults().set(connectionPassword.stringValue, forKey: "connectionPassword")
            case .connecting:
                print("connecting - do nothing - potentially cancel")
            case .disconnected:
                proPresenterService.setServer(server: connectionServer.stringValue)
                proPresenterService.setPort(port: connectionPort.stringValue)
                proPresenterService.setPassword(password: connectionPassword.stringValue)
                proPresenterService.connect()
            case .disconnecting:
                print("connecting - do nothing")
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Do any additional setup before loading the view.
        
        connectionServer.stringValue = UserDefaults().string(forKey: "connectionServer") ?? "127.0.0.1"
        connectionPort.stringValue = UserDefaults().string(forKey: "connectionPort") ?? "54235"
        connectionPassword.stringValue = UserDefaults().string(forKey: "connectionPassword") ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nc.addObserver(self, selector: #selector(proProPresenterStatus), name: Notification.Name("ProPresenterService_Status"), object: nil)
        proPresenterService = ProPresenterService()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc func proProPresenterStatus(_ notification: Notification) {
        if let connectionStatus = notification.object as? ConnectionStatus {
            status = connectionStatus
            updateUserInterface()
        }
    }
    
    func updateUserInterface() {
        if let status = status {
            switch status {
            case .connected:
                buttonLabel.title = "Disconnect"
                buttonLabel.isEnabled = true
                connectionStatus.stringValue = "Connected"
                
                connectionServer.isEnabled = false
                connectionPort.isEnabled = false
                connectionPassword.isEnabled = false
            case .connecting:
                buttonLabel.title = "Connecting"
                buttonLabel.isEnabled = false
                connectionStatus.stringValue = "Connecting"
                
                connectionServer.isEnabled = false
                connectionPort.isEnabled = false
                connectionPassword.isEnabled = false
            case .disconnected:
                buttonLabel.title = "Connect"
                buttonLabel.isEnabled = true
                connectionStatus.stringValue = "Offline"
                
                connectionServer.isEnabled = true
                connectionPort.isEnabled = true
                connectionPassword.isEnabled = true
            case .disconnecting:
                buttonLabel.title = "Disconnecting"
                buttonLabel.isEnabled = false
                connectionStatus.stringValue = "Disconnecting"
                
                connectionServer.isEnabled = false
                connectionPort.isEnabled = false
                connectionPassword.isEnabled = false
            }
        }
    }
}

