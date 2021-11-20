//
//  ProPresenterMessage.swift
//  CG Lab Stage Display Link
//
//  Created by Daniel McFarland on 17/11/2021.
//

import Foundation

enum MessageType: String, Decodable {
    case ath
    case sys
    case tmr
    case fv
    case cs
    case ns
    case csn
    case nsn
    case sl
    case asl
    case psl
    case msg
}

struct ProPresenterAuth: Codable {
    var acn: MessageType { .ath }
    var ath: Bool
    var err: String
}

struct ProPresenterSystem: Codable {
    var acn: MessageType { .sys }
    var txt: String
}

struct ProPresenterTimer: Codable {
    var acn: MessageType { .tmr }
    var uid: String
    var txt: String
}

struct ProPresenterFrame: Decodable {
    var acn: MessageType { .fv }
    var ary: [ProPresenterMessage]
}

struct ProPresenterCurrentSlide: Codable {
    var acn: MessageType { .cs }
    var uid: String
    var txt: String
}

struct ProPresenterNextSlide: Codable {
    var acn: MessageType  { .ns }
    var uid: String
    var txt: String
}

struct ProPresenterCurrentSlideNote: Codable {
    var acn: MessageType { .cs }
    var txt: String
}

struct ProPresenterNextSlideNote: Codable {
    var acn: MessageType  { .ns }
    var txt: String
}

struct ProPresenterStageLayout: Decodable {
    var acn: MessageType { .sl }
    var nme: String
    var brd: Bool
    var uid: String
    var zro: Int
    var ovr: Bool
    var oCl: String
    var fme: [ProPresenterStageDisplayFrame]
}

struct ProPresenterAllStageLayout: Decodable {
    var acn: MessageType { .asl }
    var ary: [ProPresenterStageLayout]
}

struct ProPresenterCurrentStageLayout: Codable {
    var acn: MessageType { .psl }
    var uid: String
}

struct ProPresenterStageDisplayFrame: Codable {
    var ufr: String
    var mde: Int
//    var tAl: Int
//    var tCl: String
//    var tSz: Int
    var nme: String
    var typ: Int // make this an enum and create custom frames
//    var fCl: String
//    var fCh: Bool
//    var uid: String
    
    var frameGeometry: [String] {
        return ufr.dropFirst(2).dropLast(2).description.components(separatedBy: "}, {")
    }
    
    var upperLeftX: Float {
        guard frameGeometry.count == 2 else {
            return 0
        }
        
        let coords = frameGeometry[0].components(separatedBy: ", ")
        guard coords.count == 2 else {
            return 0
        }
        
        return Float(coords[0]) ?? 0
    }
    
    var upperLeftY: Float {
        guard frameGeometry.count == 2 else {
            return 0
        }
        
        let coords = frameGeometry[0].components(separatedBy: ", ")
        guard coords.count == 2 else {
            return 0
        }
        
        return Float(coords[1]) ?? 0
    }
    
    var lowerRightX: Float {
        guard frameGeometry.count == 2 else {
            return 0
        }
        
        let coords = frameGeometry[1].components(separatedBy: ", ")
        guard coords.count == 2 else {
            return 0
        }
        
        return Float(coords[0]) ?? 0
    }
    
    var lowerRightY: Float {
        guard frameGeometry.count == 2 else {
            return 0
        }
        
        let coords = frameGeometry[1].components(separatedBy: ", ")
        guard coords.count == 2 else {
            return 0
        }
        
        return Float(coords[1]) ?? 0
    }
    
    func getWidth(width: Int) -> Int {
        return Int(getEndX(width: width) - getOriginX(width: width))
    }
    
    func getWidth() -> Int {
        return getWidth(width: 1920)
    }
    
    func getHeight(height: Int) -> Int {
        return Int(getEndY(height: height) - getOriginY(height: height))
    }
    
    func getHeight() -> Int {
        return getHeight(height: 1080)
    }
    
    func getOriginX(width: Int) -> Float {
        return Float(width) * upperLeftX
    }
    
    func getOriginX() -> Float {
        return getOriginX(width: 1920)
    }
    
    func getEndX(width: Int) -> Float {
        return Float(width) * lowerRightX
    }
    
    func getOriginY(height: Int) -> Float {
        return Float(height) * upperLeftY
    }
    
    func getOriginY() -> Float {
        return getOriginY(height: 1080)
    }
    
    func getEndY(height: Int) -> Float {
        return Float(height) * lowerRightY
    }
    
    func getOrigin(width: Int, height: Int) -> ( x: Int, y: Int ) {
        let x = getOriginX(width: width)
        let y = getOriginY(height: height)
        
        return (x: Int(x), y: Int(y))
    }
    
    func getOrigin() -> ( x: Int, y: Int ) {
        return getOrigin(width: 1920, height: 1080)
    }
}

struct ProPresenterMessageValue: Codable {
    var acn: MessageType { .msg }
    var txt: String
}

enum ProPresenterMessage {
    case ath(ProPresenterAuth)
    case sys(ProPresenterSystem)
    case tmr(ProPresenterTimer)
    case fv(ProPresenterFrame)
    case cs(ProPresenterCurrentSlide)
    case ns(ProPresenterNextSlide)
    case csn(ProPresenterCurrentSlideNote)
    case nsn(ProPresenterNextSlideNote)
    case sl(ProPresenterStageLayout)
    case asl(ProPresenterAllStageLayout)
    case psl(ProPresenterCurrentStageLayout)
    case msg(ProPresenterMessageValue)
}

extension ProPresenterMessage: Decodable {
    struct InvalidTypeError: Error {
        var acn: String
    }
    
    private enum CodingKeys: CodingKey {
        case acn
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let acn = try container.decode(String.self, forKey: .acn)
        
        switch acn {
        case "ath":
            self = .ath(try ProPresenterAuth(from: decoder))
        case "sys":
            self = .sys(try ProPresenterSystem(from: decoder))
        case "tmr":
            self = .tmr(try ProPresenterTimer(from: decoder))
        case "fv":
            self = .fv(try ProPresenterFrame(from: decoder))
        case "cs":
            self = .cs(try ProPresenterCurrentSlide(from: decoder))
        case "ns":
            self = .ns(try ProPresenterNextSlide(from: decoder))
        case "csn":
            self = .csn(try ProPresenterCurrentSlideNote(from: decoder))
        case "nsn":
            self = .nsn(try ProPresenterNextSlideNote(from: decoder))
        case "sl":
            self = .sl(try ProPresenterStageLayout(from: decoder))
        case "asl":
            self = .asl(try ProPresenterAllStageLayout(from: decoder))
        case "psl":
            self = .psl(try ProPresenterCurrentStageLayout(from: decoder))
        case "msg":
            self = .msg(try ProPresenterMessageValue(from: decoder))
        default:
            throw InvalidTypeError(acn: acn)
        }
    }
}
