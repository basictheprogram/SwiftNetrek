//
//  KeymapController.swift
//  Netrek
//
//  Created by Darrell Root on 3/8/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
import AppKit

enum Control: String {
    case zeroKey = "0 key"
    case oneKey = "1 key"
    case twoKey = "2 key"
    case threeKey = "3 key"
    case fourKey = "4 key"
    case fiveKey = "5 key"
    case sixKey = "6 key"
    case sevenKey = "7 key"
    case eightKey = "8 key"
    case nineKey = "9 key"
    case leftMouse = "left mouse button"
    case rightMouse = "right mouse button and control-click"
    case sKey = "s key"
    case uKey = "u key"
}

enum Command: String {
    case speedZero = "Set speed 0"
    case speedOne = "Set speed 1"
    case speedTwo = "Set speed 2"
    case speedThree = "Set speed 3"
    case speedFour = "Set speed 4"
    case speedFive = "Set speed 5"
    case speedSix = "Set speed 6"
    case speedSeven = "Set speed 7"
    case speedEight = "Set speed 8"
    case speedNine = "Set speed 9"
    case setCourse = "Set course"
    case fireTorpedo = "Fire torpedo"
    case toggleShields = "Toggle shields"
    case raiseShields = "Raise shields"
}

class KeymapController {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    var keymap: [Control:Command] = [:]

    init() {
        self.setDefaults()
    }
    
    func setDefaults() {
        keymap = [
            .zeroKey:.speedZero,
            .oneKey:.speedOne,
            .twoKey:.speedTwo,
            .threeKey:.speedThree,
            .fourKey:.speedFour,
            .fiveKey:.speedFive,
            .sixKey:.speedSix,
            .sevenKey:.speedSeven,
            .eightKey:.speedEight,
            .nineKey:.speedNine,
            .sKey:.toggleShields,
            .uKey:.raiseShields,
            .leftMouse:.fireTorpedo,
            .rightMouse:.setCourse,
        ]
    }
    func execute(_ control: Control, location: CGPoint?) {
        if let command = keymap[control] {
            switch command {
                
            case .speedZero:
                self.setSpeed(0)
            case .speedOne:
                self.setSpeed(1)
            case .speedTwo:
                self.setSpeed(2)
            case .speedThree:
                self.setSpeed(3)
            case .speedFour:
                self.setSpeed(4)
            case .speedFive:
                self.setSpeed(5)
            case .speedSix:
                self.setSpeed(6)
            case .speedSeven:
                self.setSpeed(7)
            case .speedEight:
                self.setSpeed(8)
            case .speedNine:
                self.setSpeed(9)
            case .setCourse:
                guard let location = location else {
                    debugPrint("KeymapController.execute.setCourse location is nil...holding steady")
                    return
                }
                if let me = appDelegate.universe.me {
                    let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(me.positionX), mePositionY: Double(me.positionY), destinationX: Double(location.x), destinationY: Double(location.y))
                    if let cpDirection = MakePacket.cpDirection(netrekDirection: netrekDirection) {
                        appDelegate.reader?.send(content: cpDirection)
                    }
                }

            case .toggleShields:
                if let shieldsUp = appDelegate.universe.me?.shieldsUp {
                    if shieldsUp {
                        let cpShield = MakePacket.cpShield(up: false)
                        appDelegate.reader?.send(content: cpShield)
                    } else {
                        let cpShield = MakePacket.cpShield(up: true)
                        appDelegate.reader?.send(content: cpShield)
                    }
                }

            case .raiseShields:
                let cpShield = MakePacket.cpShield(up: true)
                appDelegate.reader?.send(content: cpShield)
                
            case .fireTorpedo:
                debugPrint("RightMouseDown location \(String(describing: location))")
                guard let targetLocation = location else {
                    debugPrint("KeymapController.execute.fireTorpedo location is nil...holding fire")
                    return
                }
                if let me = appDelegate.universe.me {
                    let netrekDirection = NetrekMath.calculateNetrekDirection(mePositionX: Double(me.positionX), mePositionY: Double(me.positionY), destinationX: Double(targetLocation.x), destinationY: Double(targetLocation.y))
                    let cpTorp = MakePacket.cpTorp(netrekDirection: netrekDirection)
                    appDelegate.reader?.send(content: cpTorp)
                }

            }
        }
    }
    func setSpeed(_ speed: Int) {
        if let cpSpeed = MakePacket.cpSpeed(speed: speed) {
            appDelegate.reader?.send(content: cpSpeed)
        }
    }

}
