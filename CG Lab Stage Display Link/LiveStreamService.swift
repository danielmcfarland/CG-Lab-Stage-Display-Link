//
//  LiveStreamService.swift
//  CG Lab Stage Display Link
//
//  Created by Daniel McFarland on 28/11/2021.
//

import Foundation
import Starscream
import AppKit

class LiveStreamService: WebSocketDelegate {
    
    private var server: String?
    private var port: String?
    private var requestLive: URLRequest!
    private var socketLiveStream: WebSocket!
    private var liveFrame: NSImage?
    
    init() {
        
    }
    
    func connectLiveSlide(server: String, port: String) {
//        self.server = server
//        self.port = port
        
        if server.count > 0 && port.count > 0 {
            requestLive = URLRequest(url: URL(string: "ws://\(server):\(port)/livestream")!)
            requestLive.timeoutInterval = 2
            socketLiveStream = WebSocket(request: requestLive)
            socketLiveStream.delegate = self
            socketLiveStream.connect()
        }
    }
    
    func disconnect() {
        self.socketLiveStream.forceDisconnect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .text(let string):
            messageReceived(string)
            break
        default:
//            print("default")
            break
        }
    }
    
    func messageReceived(_ data: String) {
        let json = data.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            let message = try decoder.decode(LiveStreamFrame.self, from: json)
            liveFrame = message.frame
        } catch {
            print("error occurred decoding: \(error)")
            print(data)
        }
    }
    
    func getLiveFrame() -> NSImage? {
        guard let liveFrame = liveFrame else {
            return nil
        }
        return liveFrame
    }
}
