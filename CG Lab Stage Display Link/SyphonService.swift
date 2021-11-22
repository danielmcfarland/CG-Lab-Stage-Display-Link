//
//  SyphonService.swift
//  CG Lab Stage Display Link
//
//  Created by Daniel McFarland on 20/11/2021.
//

import Foundation
import Cocoa
import Syphon
import CoreGraphics
import VideoToolbox

class SyphonService {
    
    var displayLink: CVDisplayLink?
    var metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    var textureCache: CVMetalTextureCache?
    var syphonServer: SyphonMetalServer?
    var metalLayer: CAMetalLayer!
    var currentTexture: MTLTexture!
    
    var currentFrame: CIImage!
    
    var globalFormat = GraphicsImageRendererFormat()
    var globalRenderer: GraphicsImageRenderer!
    var globalContext: GraphicsImageRendererContext!
    var globalImage: NSImage!
    
    var frameActions: [CGRect]! = []
    
    init() {
        globalFormat.scale = 1
        
        setupRenderer()
        renderFrame()
        
        CVMetalTextureCacheCreate(nil, nil, metalDevice!, nil, &textureCache)
        syphonServer = SyphonMetalServer(name: "Video", device: metalDevice!)
        
        _ = Timer.scheduledTimer(timeInterval: 1/24, target: self, selector: #selector(generateOutput), userInfo: nil, repeats: true)
    }
    
    @objc func generateOutput() {
        
        var pixelBuffer: CVPixelBuffer?
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
        ]
        
        var status = CVPixelBufferCreate(nil, Int(1920), Int(1080), kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        
        assert(status == noErr)
        
        guard let rectangleImage = currentFrame
        else { return }
        
        let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        context.render(rectangleImage, to: pixelBuffer!)

        var textureWrapper: CVMetalTexture?
        guard let textureCache = textureCache
        else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer!)
        let height = CVPixelBufferGetHeight(pixelBuffer!)

        status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer!, nil, .bgra8Unorm, width, height, 0, &textureWrapper)

        let sourceTexture = CVMetalTextureGetTexture(textureWrapper!)!

        syphonServer?.publishFrameTexture(sourceTexture)
        
    }
    
    func setupRenderer() {
        globalRenderer = GraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: globalFormat)
    }
    
    func newFrame() -> Void {
        frameActions = []
    }
    
    func addToFrame(x: Int, y: Int, width: Int, height: Int) {
        let element = CGRect(x: x, y: y, width: width, height: height)
        frameActions.append(element)
    }
    
    func addToFrame(frame: (x: Int, y: Int, width: Int, height: Int)) {
        addToFrame(x: frame.x, y: frame.y, width: frame.width, height: frame.height)
    }
    
    func getFrame() -> NSImage {
        
        let color = NSColor(deviceRed: 0.99, green: 0.8, blue: 0.00, alpha: 1.00).cgColor
        
        globalImage = globalRenderer.image { context in
            
            let background = CGRect(x: 0, y: 0, width: 1920, height: 1080)
            context.cgContext.setFillColor(CGColor.black)
//            context.cgContext.setFillColor(gray: 128, alpha: 0)
            context.cgContext.addRect(background)
            context.cgContext.drawPath(using: .fill)
            
            for element in self.frameActions {
                context.cgContext.setFillColor(CGColor.black)
                context.cgContext.setStrokeColor(color)
                context.cgContext.setLineWidth(1)
                // context.cgContext.clip()
                context.cgContext.addRect(element)
                context.cgContext.drawPath(using: .fillStroke)
            }
            
        }
        
        return globalImage
    }
    
    func renderFrame() -> Void {
        currentFrame = getFrame().ciImage()
    }
    
}
