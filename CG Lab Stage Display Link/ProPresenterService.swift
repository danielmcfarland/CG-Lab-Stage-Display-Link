//
//  ProPresenterService.swift
//  CG Lab Stage Display Link
//
//  Created by Daniel McFarland on 16/11/2021.
//

import Foundation
import Starscream

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case disconnecting
}

class ProPresenterService: WebSocketDelegate {
    
    private var server: String?
    private var port: String?
    private var password: String?
    private var request: URLRequest!
    private let nc = NotificationCenter.default
    
    init() {
        nc.post(name: Notification.Name("ProPresenterService_Status"), object: connectionStatus)
    }
    
    var socket: WebSocket!
    var connectionStatus: ConnectionStatus = .disconnected
    
    func setServer(server: String) {
        self.server = server
    }
    
    func setPort(port: String) {
        self.port = port
    }
    
    func setPassword(password: String) {
        self.password = password
    }
    
    func connect() {
        if let server = server, let port = port {
            connectionStatus = .connecting
            request = URLRequest(url: URL(string: "ws://\(server):\(port)/stagedisplay")!)
            request.timeoutInterval = 5
            socket = WebSocket(request: request)
            socket.delegate = self
            socket.connect()
        }
    }
    
    func disconnect() {
        if let socket = socket {
            connectionStatus = .disconnecting
            socket.forceDisconnect()
        }
    }
    
    func authenticate() {
        if let socket = socket, let password = password {
            let authString = "{\"pwd\": \"\(password)\", \"ptl\": \"610\", \"acn\": \"ath\"}"
            socket.write(string: authString)
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            authenticate()
            let _ = headers;
        case .disconnected(let reason, let code):
            connectionStatus = .disconnected
            notifyStatus()
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            messageReceived(string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            connectionStatus = .disconnected
            notifyStatus()
            print("cancelled")
        case .error(let error):
            connectionStatus = .disconnected
            notifyStatus()
            handleError(error)
        }
    }
    
    func handleError(_ error: Error?) {
        print("handleError")
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func messageReceived(_ message: String) {
        if message == "{\"acn\":\"ath\",\"ath\":true,\"err\":\"\"}" {
            connectionStatus = .connected
            notifyStatus()
        }
        print("\(message)")
    }
    
    func notifyStatus() {
        print("notifyStatus: \(connectionStatus)")
        nc.post(name: Notification.Name("ProPresenterService_Status"), object: connectionStatus)
    }
}
