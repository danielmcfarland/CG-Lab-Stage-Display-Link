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
    
    init() {
        
        currentFrame = drawMultiviewer().ciImage()
        
        CVMetalTextureCacheCreate(nil, nil, metalDevice!, nil, &textureCache)
        syphonServer = SyphonMetalServer(name: "Video", device: metalDevice!)
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext) -> CVReturn in
            autoreleasepool {
                unsafeBitCast(displayLinkContext, to: SyphonService.self).generateOutput()
            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())

        CVDisplayLinkStart(displayLink!)
        
    }
    
    func generateOutput() {

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
    
    func drawMultiviewer() -> NSImage {
        
        let format = GraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = GraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: format)
        
        let img = renderer.image { ctx in
            let background = CGRect(x: 0, y: 0, width: 1920, height: 1080)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.addRect(background)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_1 = CGRect(x: 2, y: 2, width: 956, height: 536)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.clip()
            ctx.cgContext.addRect(rectangle_1)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_2 = CGRect(x: 962, y: 2, width: 956, height: 536)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.clip()
            ctx.cgContext.addRect(rectangle_2)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_3 = CGRect(x: 2, y: 542, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.init(red: 0, green: 1, blue: 0, alpha: 1))
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.clip()
            ctx.cgContext.addRect(rectangle_3)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_4 = CGRect(x: 482, y: 542, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.addRect(rectangle_4)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_5 = CGRect(x: 962, y: 542, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.addRect(rectangle_5)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_6 = CGRect(x: 1442, y: 542, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.addRect(rectangle_6)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_7 = CGRect(x: 2, y: 812, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.addRect(rectangle_7)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_8 = CGRect(x: 482, y: 812, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.addRect(rectangle_8)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_9 = CGRect(x: 962, y: 812, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.init(red: 1, green: 0, blue: 0, alpha: 1))
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.addRect(rectangle_9)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let rectangle_10 = CGRect(x: 1442, y: 812, width: 476, height: 266)
            ctx.cgContext.setFillColor(CGColor.black)
            ctx.cgContext.setStrokeColor(CGColor.white)
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.addRect(rectangle_10)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attrs = [
                NSAttributedString.Key.font: NSFont(name: "HelveticaNeue-Thin", size: 36)!,
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: NSColor.white,
            ]
            
            let textTransform = CGAffineTransform(scaleX: -1.0, y: -1.0)
            ctx.cgContext.textMatrix = textTransform
            
            ctx.cgContext.saveGState()
            defer { ctx.cgContext.restoreGState() }
            
            ctx.cgContext.translateBy(x: 0, y: 1080)
            ctx.cgContext.scaleBy(x: 1, y: -1)

            let string = "Hello, World!"
            string.draw(with: CGRect(x: 0, y: 0, width: 1920, height: 1080), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            
            string.draw(with: CGRect(x: 0, y: -30, width: 1920, height: 1050), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

        }
        
        return img
    }

}
