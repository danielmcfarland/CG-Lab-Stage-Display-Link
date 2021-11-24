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
import MetalKit

class SyphonService {
    
    var displayLink: CVDisplayLink?
    var metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    var context: CIContext?
    
    private var textureCache: CVMetalTextureCache?
    var syphonServer: SyphonMetalServer?
    private var currentTexture: MTLTexture!
    
    var currentFrame: CIImage!
    
    var globalFormat = GraphicsImageRendererFormat()
    var globalRenderer: GraphicsImageRenderer!
    var globalContext: GraphicsImageRendererContext!
    var mtkView: MTKView!
    
    private var pixelBuffer: CVPixelBuffer?
    private var targetTexture: MTLTexture!
    private var textureWrapper: CVMetalTexture?
    
    var frames: [(ProPresenterStageDisplayFrame)]! = []
    
    private var message1: ProPresenterCurrentSlide?
    private var message2: ProPresenterNextSlide?
    private var message3: ProPresenterCurrentSlideNote?
    private var message4: ProPresenterNextSlideNote?
    private var message5: ProPresenterMessageValue?
    private var message6: ProPresenterSystem?
    
    init() {
        globalFormat.scale = 1
        
        initOutput()
        setupRenderer()
        renderFrame()
        
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
    
    func initOutput() {
        if let metalDevice = metalDevice {
            context = CIContext(mtlDevice: metalDevice)
        }
        
        mtkView = MTKView()
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
        ]
        
        let status = CVPixelBufferCreate(nil, Int(1920), Int(1080), kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        
        assert(status == noErr)
    }
    
    func generateOutput() {
        let startTime = Date().timeIntervalSince1970 * 1_000_000
        guard let rectangleImage = currentFrame
        else { return }
        
        guard let context = context else { return }
        
        context.render(rectangleImage, to: pixelBuffer!)

        guard let textureCache = textureCache else { return }
        
        let width = CVPixelBufferGetWidth(pixelBuffer!)
        let height = CVPixelBufferGetHeight(pixelBuffer!)
        
        _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer!, nil, .bgra8Unorm, width, height, 0, &textureWrapper)
        
        let sourceTexture = CVMetalTextureGetTexture(textureWrapper!)!
        
        syphonServer?.publishFrameTexture(sourceTexture)
        let endTime = Date().timeIntervalSince1970 * 1_000_000
        print("Total Output Time: \(endTime - startTime) microseconds")
    }
    
    func setupRenderer() {
        globalRenderer = GraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: globalFormat)
    }
    
    func newFrame() -> Void {
        frames = []
    }
    
    func addToFrame(frame: ProPresenterStageDisplayFrame) {
        frames.append(frame)
    }
    
    func getFrame() -> NSImage {
        let startTime = Date().timeIntervalSince1970 * 1_000_000
        let color = NSColor(deviceRed: 0.99, green: 0.8, blue: 0.00, alpha: 1.00).cgColor
        
        let frameImage = globalRenderer.image { context in
            
            for frame in self.frames {
                context.cgContext.setStrokeColor(color)
                context.cgContext.setLineWidth(1)
                context.cgContext.addRect(frame.cgRect)
                context.cgContext.drawPath(using: .stroke)
                switch frame.typ {
                case 1:
                    if let message1 = self.message1, let fontSize = frame.tSz {
                        self.drawText(frame: frame.cgRect, text: message1.txt, context: context.cgContext, fontSize: fontSize)
                    }
                    break
                case 2:
                    if let message2 = self.message2, let fontSize = frame.tSz {
                        self.drawText(frame: frame.cgRect, text: message2.txt, context: context.cgContext, fontSize: fontSize)
                    }
                    break
                case 3:
                    if let message3 = self.message3, let fontSize = frame.tSz {
                        self.drawText(frame: frame.cgRect, text: message3.txt, context: context.cgContext, fontSize: fontSize)
                    }
                    break
                case 4:
                    if let message4 = self.message4, let fontSize = frame.tSz {
                        self.drawText(frame: frame.cgRect, text: message4.txt, context: context.cgContext, fontSize: fontSize)
                    }
                    break
                case 5:
                    if let message5 = self.message5, let fontSize = frame.tSz {
                        self.drawText(frame: frame.cgRect, text: message5.txt, context: context.cgContext, fontSize: fontSize)
                    }
                    break
                case 6:
                    if let message6 = self.message6, let fontSize = frame.tSz {
                        self.drawText(frame: frame.cgRect, text: message6.timeString, context: context.cgContext, fontSize: fontSize)
                    }
                    break
                default:

                    break
                }
            }
        }
        let endTime = Date().timeIntervalSince1970 * 1_000_000
        print("Total Frame Render Time: \(endTime - startTime) microseconds")
        return frameImage
    }
    
    func renderFrame() -> Void {
        currentFrame = getFrame().ciImage()
    }
    
    func drawText(frame: CGRect, text: String, context: CGContext) {
        drawText(frame: frame, text: text, context: context, fontSize: 396)
    }
    
    func drawText(frame: CGRect, text: String, context: CGContext, fontSize: Int) {
        drawText(frame: frame, text: text, context: context, fontSize: CGFloat(fontSize))
    }
    
    func drawText(frame: CGRect, text: String, context: CGContext, fontSize: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        var currentFont = NSFont(name: "HelveticaNeue-Bold", size: fontSize)
        let bestSize = NSFont.getBestSize(for: text, in: textFrame, font: currentFont, fontSize: fontSize)
        currentFont = NSFont(name: currentFont!.fontName, size: bestSize)

        let attrs = [
            NSAttributedString.Key.font: currentFont!,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.foregroundColor: NSColor.white,
        ]
        
        let textTransform = CGAffineTransform(scaleX: -1.0, y: -1.0)
        context.textMatrix = textTransform

        context.saveGState()
        defer { context.restoreGState() }

        context.translateBy(x: 0, y: (frame.origin.y * 2) + frame.height)
        context.scaleBy(x: 1, y: -1)
        
        text.draw(with: frame, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
    }
    
    func setMessage1(_ message: ProPresenterCurrentSlide) {
        message1 = message
    }
    
    func setMessage2(_ message: ProPresenterNextSlide) {
        message2 = message
    }
    
    func setMessage3(_ message: ProPresenterCurrentSlideNote) {
        message3 = message
    }
    
    func setMessage4(_ message: ProPresenterNextSlideNote) {
        message4 = message
    }
    
    func setMessage5(_ message: ProPresenterMessageValue) {
        message5 = message
    }
    
    func setMessage6(_ message: ProPresenterSystem) {
        message6 = message
    }
}

extension NSFont {
    static func getBestSize(for text: String, in bounds: CGRect, font: NSFont?, fontSize: CGFloat) -> CGFloat {
        let properBounds = CGRect(origin: .zero, size: bounds.size)
        var attributes: [NSAttributedString.Key: Any] = [:]
        
        guard let font = font else {
            return 0
        }
        
        let fontDescriptor = font.fontDescriptor
        let startingSize = fontSize * 2
        var bestFontSize = fontSize
        
        for fontSize in stride(from: startingSize, through: 1, by: -1) {
            let newFont = NSFont(descriptor: fontDescriptor, size: fontSize)
            attributes[.font] = newFont
            
            let infiniteBounds = CGSize(width: bounds.width, height: CGFloat.infinity)
            
            let testFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
            if properBounds.contains(testFrame) {
                bestFontSize = fontSize
                break
            }
        }
        
        return bestFontSize > font.pointSize ? font.pointSize : bestFontSize
    }
}
