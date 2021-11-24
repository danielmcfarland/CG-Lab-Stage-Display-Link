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
//import SceneKit

class SyphonService {
    
    var displayLink: CVDisplayLink?
    var metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()
    var context: CIContext?
    
    var textureCache: CVMetalTextureCache?
    var syphonServer: SyphonMetalServer?
    var metalLayer: CAMetalLayer!
    var currentTexture: MTLTexture!
    
    var currentFrame: CIImage!
    
    var globalFormat = GraphicsImageRendererFormat()
    var globalRenderer: GraphicsImageRenderer!
    var globalContext: GraphicsImageRendererContext!
    var mtkView: MTKView!
    
    var pixelBuffer: CVPixelBuffer?
//    var renderer: SCNRenderer!
//    var globalImage: NSImage!
    
    var frames: [(ProPresenterStageDisplayFrame)]! = []
    
    private var message1: ProPresenterCurrentSlide?
    private var message2: ProPresenterNextSlide?
    private var message3: ProPresenterCurrentSlideNote?
    private var message4: ProPresenterNextSlideNote?
    private var message5: ProPresenterMessageValue?
    private var message6: ProPresenterSystem?
    
    lazy var commandQueue: MTLCommandQueue = {
        return self.metalDevice!.makeCommandQueue()!
    }()
    
    lazy var ciContext: CIContext = {
        return CIContext(mtlDevice: self.metalDevice!)
    }()
    
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
//                if unsafeBitCast(displayLinkContext, to: ViewController.self).currentFrame != unsafeBitCast(displayLinkContext, to: ViewController.self).previousFrame {
//                    unsafeBitCast(displayLinkContext, to: ViewController.self).previousFrame = unsafeBitCast(displayLinkContext, to: ViewController.self).currentFrame
                unsafeBitCast(displayLinkContext, to: SyphonService.self).generateOutput()
//                }

            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())

        CVDisplayLinkStart(displayLink!)
        
//        _ = Timer.scheduledTimer(timeInterval: 1/24, target: self, selector: #selector(generateOutput), userInfo: nil, repeats: true)
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
        guard let rectangleImage = currentFrame
        else { return }
        
        guard let context = context else { return }
        
        context.render(rectangleImage, to: pixelBuffer!)
    }
    
    @objc func generateOutputOld() {
        let startTime = Date().timeIntervalSince1970 * 1_000_000
        
        guard let rectangleImage = currentFrame
        else { return }
        
//        guard let context = context else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let commandBuffer = commandQueue.makeCommandBuffer()

        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
              pixelFormat: MTLPixelFormat.rgba8Unorm,
              width: 1920,
              height: 1080,
              mipmapped: false)
        
        textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.renderTarget.rawValue)
        
        let targetTexture = metalDevice?.makeTexture(descriptor: textureDescriptor)

//        let syphonTexture = syphonServer?.newFrameImage()
//        print(targetTexture?.isFramebufferOnly)
        
//        let contextRenderStart = Date().timeIntervalSince1970 * 1_000_000
//        context.render(rectangleImage, to: pixelBuffer!)
        ciContext.render(rectangleImage, to: targetTexture!, commandBuffer: nil, bounds: rectangleImage.extent, colorSpace: colorSpace)

//        commandBuffer?.commit()
//        targetTexture.
//        print(targetTexture?.arrayLength)
        
//        let contextRenderEnd = Date().timeIntervalSince1970 * 1_000_000
//        print("Total Context Render Time: \(contextRenderEnd - contextRenderStart) microseconds")

//        var textureWrapper: CVMetalTexture?
//        guard let textureCache = textureCache
//        else { return }
        
//        let width = CVPixelBufferGetWidth(pixelBuffer!)
//        let height = CVPixelBufferGetHeight(pixelBuffer!)

        
//        let renderStart = Date().timeIntervalSince1970 * 1_000_000
//        _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer!, nil, .bgra8Unorm, width, height, 0, &textureWrapper)
//        let renderEnd = Date().timeIntervalSince1970 * 1_000_000
//        print("Total Metal Render Time: \(renderEnd - renderStart) microseconds")
        
//        let textureStart = Date().timeIntervalSince1970 * 1_000_000
//        let sourceTexture = CVMetalTextureGetTexture(textureWrapper!)!
//        let textureEnd = Date().timeIntervalSince1970 * 1_000_000
//        print("Total Texture Time: \(textureEnd - textureStart) microseconds")
        
//        print(sourceTexture.arrayLength)

//        syphonServer?.publishFrameTexture(sourceTexture)
//        syphonServer?.newFrameImage()
        if let targetTexture = targetTexture {
            print(targetTexture.allocatedSize)
            print(targetTexture.device)
            syphonServer?.publishFrameTexture(targetTexture)
        }
        let endTime = Date().timeIntervalSince1970 * 1_000_000
//        print("Complete Frame Render: \(endTime)")
        print("Total Display Time: \(endTime - startTime) microseconds")
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
//        print("Start Frame Render: \(startTime)")
        let color = NSColor(deviceRed: 0.99, green: 0.8, blue: 0.00, alpha: 1.00).cgColor
        
        let frameImage = globalRenderer.image { context in
            let background = CGRect(x: 0, y: 0, width: 1920, height: 1080)
//            context.cgContext.setFillColor(CGColor.black)
            context.cgContext.setFillColor(color)
            context.cgContext.addRect(background)
            context.cgContext.drawPath(using: .fill)
            
            for frame in self.frames {
                context.cgContext.setFillColor(CGColor.black)
                context.cgContext.setStrokeColor(color)
                context.cgContext.setLineWidth(1)
                context.cgContext.addRect(frame.cgRect)
                context.cgContext.drawPath(using: .fillStroke)
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
//        print("Complete Frame Render: \(endTime)")
        print("Total Frame Render Time: \(endTime - startTime) microseconds")
        return frameImage
    }
    
    func renderFrame() -> Void {
        print("renderFrame - called")
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
        
        let textFrame = CGRect(x: frame.origin.x + 5, y: frame.origin.y + 5, width: frame.width - 10, height: frame.height - 10)
        
        var currentFont = NSFont(name: "HelveticaNeue-Bold", size: fontSize)
        let bestSize = NSFont.bestFittingFontSize(for: text, in: textFrame, fontDescriptor: currentFont!.fontDescriptor, additionalAttributes: nil)
        if bestSize < fontSize {
            currentFont = NSFont(name: currentFont!.fontName, size: bestSize)
        }

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
    
    /**
     Will return the best font conforming to the descriptor which will fit in the provided bounds.
     */
    static func bestFittingFontSize(for text: String, in bounds: CGRect, fontDescriptor: NSFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> CGFloat {
        let constrainingDimension = min(bounds.width, bounds.height)
        let properBounds = CGRect(origin: .zero, size: bounds.size)
        var attributes = additionalAttributes ?? [:]
        
        let infiniteBounds = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        var bestFontSize: CGFloat = constrainingDimension
        
        for fontSize in stride(from: bestFontSize, through: 0, by: -1) {
            let newFont = NSFont(descriptor: fontDescriptor, size: fontSize)
            attributes[.font] = newFont
            
            let currentFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
            
            if properBounds.contains(currentFrame) {
                if bounds.height == constrainingDimension {
                    let heightRatio = floor(properBounds.height / currentFrame.height)
                    if (heightRatio > 1) {
                        for ratio in stride(from: heightRatio, through: 0.1, by: -0.5) {
                            let ratioFontSize = fontSize * ratio
                            let infiniteBounds = CGSize(width: bounds.width, height: CGFloat.infinity)
                            if checkFrame(for: text, fontSize: ratioFontSize, in: bounds, frameBounds: infiniteBounds, fontDescriptor: fontDescriptor, additionalAttributes: additionalAttributes) {
                                bestFontSize = ratioFontSize
                                break
                            }
                        }
                    }
                } else if bounds.width == constrainingDimension {
                    let widthRatio = floor(properBounds.width / currentFrame.width)
                    if (widthRatio > 1) {
                        for ratio in stride(from: widthRatio, through: 0.1, by: -0.5) {
                            let ratioFontSize = fontSize * ratio
                            let infiniteBounds = CGSize(width: CGFloat.infinity, height: bounds.height)
                            if checkFrame(for: text, fontSize: ratioFontSize, in: bounds, frameBounds: infiniteBounds, fontDescriptor: fontDescriptor, additionalAttributes: additionalAttributes) {
                                bestFontSize = ratioFontSize
                                break
                            }
                        }
                    }
                } else {
                    bestFontSize = fontSize
                    break
                }
            }
        }
        
        return bestFontSize
    }
    
    static func checkFrame(for text: String, fontSize: CGFloat, in bounds: CGRect, frameBounds: CGSize, fontDescriptor: NSFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> Bool {

        let newFont = NSFont(descriptor: fontDescriptor, size: fontSize)
        var attributes = additionalAttributes ?? [:]
        attributes[.font] = newFont
        let newFrame = text.boundingRect(with: frameBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        let cBounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        
        return cBounds.contains(newFrame)
    }
}
