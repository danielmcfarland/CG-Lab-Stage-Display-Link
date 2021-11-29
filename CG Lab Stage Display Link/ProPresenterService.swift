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
    private var timer: Timer?
    private var syphonServer: SyphonService = SyphonService()
    
    private var currentLayout: ProPresenterCurrentStageLayout?
    private var allStageDisplayLayouts: ProPresenterAllStageLayout?
    
    private var systemTime: String?
    private var messageSystem: ProPresenterSystem?
    private var messageCurrentSlide: ProPresenterCurrentSlide?
    private var disconnectRequested = false
    
    private var socket: WebSocket!
    private var connectionStatus: ConnectionStatus = .disconnected
    
    init() {
        nc.post(name: Notification.Name("ProPresenterService_Status"), object: connectionStatus)
    }
    
    var currentStageDisplayLayout: ProPresenterStageLayout? {
        if let allStageDisplayLayouts = allStageDisplayLayouts, let currentLayout = currentLayout {
            return allStageDisplayLayouts.ary.filter {
                $0.uid == currentLayout.uid
            }.first
        }
        return nil
    }
    
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
        disconnectRequested = false
        if let timer = timer {
            timer.invalidate()
        }
        if let server = server, let port = port {
            if server.count > 0 && port.count > 0 {
                connectionStatus = .connecting
                notifyStatus()
                request = URLRequest(url: URL(string: "ws://\(server):\(port)/stagedisplay")!)
                request.timeoutInterval = 2
                socket = WebSocket(request: request)
                socket.delegate = self
                socket.connect()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if self.connectionStatus != .connected && self.disconnectRequested == false {
                        self.socket.forceDisconnect()
                        self.connect()
                    }
                }
            }
        }
    }
    
    func disconnect() {
        disconnectRequested = true
        if let socket = socket {
            connectionStatus = .disconnecting
            notifyStatus()
            socket.forceDisconnect()
        }
    }
    
    @objc func authenticate() {
        if let socket = socket, let password = password {
            let authString = "{\"pwd\": \"\(password)\", \"ptl\": \"610\", \"acn\": \"ath\"}"
            socket.write(string: authString)
        }
    }
    
    func allStageLayouts() {
        if let socket = socket {
            let aslString = "{\"acn\": \"asl\"}"
            socket.write(string: aslString)
        }
    }
    
    func currentStageLayout() {
        if let socket = socket {
            let slString = "{\"acn\": \"psl\"}"
            socket.write(string: slString)
        }
    }
    
    func requestFrameValues(_ uuid: String) {
        if let socket = socket {
            let request = "{\"acn\": \"fv\", \"uid\":\"\(uuid)\"}"
            socket.write(string: request)
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
            print("cancelled")
            if connectionStatus != .disconnecting {
                if let timer = timer {
                    timer.invalidate()
                    self.timer = nil
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Put your code which should be executed with a delay here
                    print("*** setup reconnect")
                    self.connect()
                }
            } else {
                connectionStatus = .disconnected
                notifyStatus()
            }
        case .error(let error):
            connectionStatus = .disconnected
            notifyStatus()
            handleError(error)
        }
    }
    
    func handleError(_ error: Error?) {
            if let e = error as? WSError {
                print("websocket encountered an error: \(e.message)")
            } else if let e = error {
                print("websocket encountered an error: \(e.localizedDescription)")
            } else {
                print("websocket encountered an error")
            }
        }
    
    func messageReceived(_ data: String) {
        let json = data.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        var dataChanged = false

        do {
            switch try decoder.decode(ProPresenterMessage.self, from: json) {
            case .ath(let rawMessage):
                if rawMessage.ath {
                    if connectionStatus != .connected {
                        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(authenticate), userInfo: nil, repeats: true)
                        connectionStatus = .connected
                        notifyStatus()
                    }
                    allStageLayouts()
                    currentStageLayout()
                    dataChanged = true
                }
            case .sys(let rawMessage):
                messageSystem = rawMessage
                systemTime = rawMessage.timeString
                syphonServer.setMessage6(rawMessage)
                dataChanged = true
                break
            case .tmr(let rawMessage):
                syphonServer.setMessage7(rawMessage)
                dataChanged = true
                break
            case .fv(let rawMessage):
                extractFrames(frames: rawMessage.ary)
                dataChanged = true
                break
            case .sl(let rawMessage):
                currentLayout = ProPresenterCurrentStageLayout(uid: rawMessage.uid)
                dataChanged = true
                break
            case .psl(let rawMessage):
                currentLayout = rawMessage
                requestFrameValues(currentLayout!.uid)
                dataChanged = true
                break
            case .asl(let rawMessage):
                allStageDisplayLayouts = rawMessage
                break
            case .msg(let rawMessage):
                syphonServer.setMessage5(rawMessage)
                dataChanged = true
                break
            case .vid(let rawMessage):
                syphonServer.setMessage8(rawMessage)
                break
            case .cc(_):
                break
            case .cs(_):
                break
            case .ns(_):
                break
            case .csn(_):
                break
            case .nsn(_):
                break
            }
            if dataChanged {
                triggerRedraw()
            }
        } catch {
            print("error occurred decoding: \(error)")
            print(data)
        }
    }
    
    func notifyStatus() {
        nc.post(name: Notification.Name("ProPresenterService_Status"), object: connectionStatus)
    }
    
    func triggerRedraw() {
        // ensure redraw is not in progress before
        syphonServer.newFrame()
        
        if let currentStageDisplayLayout = currentStageDisplayLayout {
            self.syphonServer.setBorders(currentStageDisplayLayout.brd)
            currentStageDisplayLayout.fme.forEach { frame in
                self.syphonServer.addToFrame(frame: frame)
            }
        }
        syphonServer.renderFrame()
    }
    
    func extractFrames(frames: [ProPresenterMessage]) {
        for frame in frames {
            switch frame {
            case .cs(let currentSlide):
                syphonServer.setMessage1(currentSlide)
                break
            case .ns(let nextSlide):
                syphonServer.setMessage2(nextSlide)
                break
            case .csn(let currentSlideNote):
                syphonServer.setMessage3(currentSlideNote)
                break
            case .nsn(let nextSlideNote):
                syphonServer.setMessage4(nextSlideNote)
                break
            default:
                break
            }
        }
    }
    
    func redrawFrame() {
        if connectionStatus == .connected {
            syphonServer.generateOutput()
        }
    }
}
