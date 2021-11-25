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
    case vid
    case cc
}

struct ProPresenterAuth: Codable {
    var acn: MessageType { .ath }
    var ath: Bool
    var err: String
}

struct ProPresenterSystem: Codable {
    var acn: MessageType { .sys }
    var txt: String
    
    var dateString: String {
        return txt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var time: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // fixes nil if device time in 24 hour format
        return dateFormatter.date(from: dateString) ?? Date()

//        dateFormatter.dateFormat = "HH:mm"
//        let date24 = dateFormatter.string(from: date!)
    }
    
    var timeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: time)
    }
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
    var tSz: Int?
    var nme: String
    var typ: Int // make this an enum and create custom frames
//    var fCl: String
//    var fCh: Bool
    var uid: String?
    
    var textSize: Int {
        if let tSz = tSz {
            return tSz
        }
        return 0
    }
    
    var frameGeometry: [String] {
        return ufr.dropFirst(2).dropLast(2).description.components(separatedBy: "}, {")
    }
    
    var frameRect: FrameRect {
        return FrameRect(displayHeight: 1080, displayWidth: 1920, left: lowerLeftX, top: lowerLeftY, right: upperRightX, bottom: upperRightY)
    }
    
    var frame: (x: Int, y: Int, width: Int, height: Int) {
        return frameRect.getFrame
    }
    
    var cgRect: CGRect {
        return frameRect.frameRect
    }
    
    var lowerLeftX: Float {
        guard frameGeometry.count == 2 else {
            print("error")
            return 0
        }
        
        let coords = frameGeometry[0].components(separatedBy: ", ")
        guard coords.count == 2 else {
            print("error")
            return 0
        }
        
        return Float(coords[0]) ?? 0
    }
    
    var lowerLeftY: Float {
        guard frameGeometry.count == 2 else {
            print("error")
            return 0
        }
        
        let coords = frameGeometry[0].components(separatedBy: ", ")
        guard coords.count == 2 else {
            print("error")
            return 0
        }
        
        return Float(coords[1]) ?? 0
    }
    
    var upperRightX: Float {
        guard frameGeometry.count == 2 else {
            return 0
        }
        
        let coords = frameGeometry[1].components(separatedBy: ", ")
        guard coords.count == 2 else {
            return 0
        }
        
        return Float(coords[0]) ?? 0
    }
    
    var upperRightY: Float {
        guard frameGeometry.count == 2 else {
            print("error")
            return 0
        }
        
        let coords = frameGeometry[1].components(separatedBy: ", ")
        guard coords.count == 2 else {
            print("error")
            return 0
        }
        
        return Float(coords[1]) ?? 0
    }
}

struct ProPresenterMessageValue: Codable {
    var acn: MessageType { .msg }
    var txt: String
}

struct ProPresenterVideoTimer: Codable {
    var acn: MessageType { .vid }
    var txt: String
}

struct ProPresenterChordChart: Codable {
    var acn: MessageType { .cc }
    var uid: String
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
    case vid(ProPresenterVideoTimer)
    case cc(ProPresenterChordChart)
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
        case "vid":
            self = .vid(try ProPresenterVideoTimer(from: decoder))
        case "cc":
            self = .cc(try ProPresenterChordChart(from: decoder))
        default:
            throw InvalidTypeError(acn: acn)
        }
    }
}

class FrameRect {
    var left: Float
    var top: Float
    var right: Float
    var bottom: Float
    var h2: Float
    var displayHeight: Float
    var displayWidth: Float
    
    init(displayHeight: Float, displayWidth: Float, left: Float, top: Float, right: Float, bottom: Float) {
        self.displayHeight = displayHeight
        self.displayWidth = displayWidth
        
        self.left = self.displayWidth * left
        self.right = self.displayWidth * right + self.left
        self.bottom = self.displayHeight * bottom
        self.top = -((self.displayHeight * top) - self.bottom)
        self.h2 = self.bottom + self.top
    }

    private var width: Float {
        return right - left
    }
    
    private var height: Float {
        return h2 - top
    }
    
    var getFrame: (x: Int, y: Int, width: Int, height: Int) {
        let y = self.displayHeight - (self.bottom - self.top + self.height)
        return (x: Int(self.left), y: Int(y), width: Int(self.width), height: Int(self.height))
    }
    
    var frameRect: CGRect {
        return CGRect(x: getFrame.x, y: getFrame.y, width: getFrame.width, height: getFrame.height)
    }
}
