//
//  PacketAnalyzer.swift
//  Netrek
//
//  Created by Darrell Root on 3/2/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
import AppKit
class PacketAnalyzer {
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let universe: Universe
    var leftOverData: Data?
    
    let msg_len = 80
    let name_len = 16
    let keymap_len = 96
    let playerMax = 100 // we ignore player updates for more than this

    
    init() {
        universe = appDelegate.universe
    }
    
    func analyze(incomingData: Data) {
        var data: Data
        if let leftOverData = leftOverData {
            data = leftOverData + incomingData
            self.leftOverData = nil
        } else {
            data = incomingData
        }
        repeat {
            guard let packetType: UInt8 = data.first else {
                debugPrint("PacketAnalyzer.analyze is done")
                return
            }
            guard let packetLength = PACKET_SIZES[safe: Int(packetType)] else {
                debugPrint("Warning: PacketAnalyzer.analyze received invalid packet type \(packetType) dumping data")
                printData(data, success: false)
                return
            }
            guard packetLength > 0 else {
                debugPrint("PacketAnalyzer invalid packet length \(packetLength) type \(packetType)")
                printData(data, success: false)
                return
            }
            guard data.count >= packetLength else {
                debugPrint("PacketAnalyzer.analyze: fractional packet expected length \(packetLength) remaining size \(data.count) saving for next round")
                self.leftOverData = data
                return
            }
            let range = (data.startIndex..<data.startIndex + packetLength)
            let thisPacket = data.subdata(in: range)
            self.analyzeOnePacket(data: thisPacket)
            data.removeFirst(packetLength)
        } while data.count > 0
    }

    func printData(_ data: Data, success: Bool) {
        let printPacketDumps = false
            if printPacketDumps {
            var dumpString = "\(success) "
            for byte in data {
                let addString = String(format:"%x ",byte)
                dumpString += addString
            }
            debugPrint(dumpString)
        }
    }
    func analyzeOnePacket(data: Data) {
        guard data.count > 0 else {
            debugPrint("PacketAnalyer.analyzeOnePacket data length 0")
            return
        }
        let packetType: UInt8 = data[0]
        guard let packetLength = PACKET_SIZES[safe: Int(packetType)] else {
            debugPrint("Warning: PacketAnalyzer.analyzeOnePacket received invalid packet type \(packetType)")
            printData(data, success: false)
            return
        }
        guard packetLength > 0 else {
            debugPrint("PacketAnalyzer.analyzeOnePacket invalid packet length \(packetLength) type \(packetType)")
            printData(data, success: false)
            return
        }
        guard packetLength == data.count else {
            debugPrint("PacketAnalyzer.analyeOnePacket unexpected data length \(data.count) expected \(packetLength) type \(packetType)")
            printData(data, success: false)
            return
        }
        switch packetType {
            
        case 1:
            let flags = Int(data[1])
            let m_recpt = Int(data[2])
            let m_from = Int(data[3])
            let range = (4..<(4 + msg_len))
            let messageData = data.subdata(in: range)
            var messageString = "message_decode_error"
            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
                messageString = "From \(m_from) " + messageStringWithNulls.filter { $0 != "\0" }
                messageString.append("\n")
                appDelegate.messageViewController?.gotMessage(messageString)
                //debugPrint(messageString)
                printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 11")
                printData(data, success: false)
            }
            debugPrint("Received SP_MESSAGE 1 from \(m_from) message \(messageString)")

        case 2:
            debugPrint("Received SP_PLAYER_INFO 2")
            //SP_PLAYER_INFO
            let playerID = Int(data[1])
            let shipType = Int(data[2])
            let team = Int(data[3])
            debugPrint("Received SP_PLAYER_INFO 2 playerID \(playerID) shipType \(shipType) team \(team)")
            universe.updatePlayer(playerID: playerID, shipType: shipType, team: team)
       
        case 3:
            // SP_KILLS
            let playerID = Int(data[1])
            let killsInt = data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped
            let kills: Double = Double(killsInt) / 100.0
            universe.updatePlayer(playerID: playerID, kills: kills)
            debugPrint("Received SP_KILLS 3 playerID \(playerID) killsInt \(killsInt) kills \(kills)")

        case 4:
            // SP_PLAYER py-struct
            let playerID = Int(data[1])
            let direction = Int(data[2])
            let speed = Int(data[3])
            let positionX = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let positionY = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            universe.updatePlayer(playerID: playerID, direction: direction, speed: speed, positionX: positionX, positionY: positionY)
            debugPrint("Received SP_PLAYER 4 playerID \(playerID) direction \(direction) speed \(speed) positionX \(positionX) positionY \(positionY)")

        case 5:
            // SP_TORP_INFO
            let war = UInt8(data[1])  //mask of teams torp is hostile to
            let status = UInt8(data[2]) // new status of torp, TFREE, TDET, etc
            // pad
            let torpedoNumber = Int(data.subdata(in: (4..<5)).to(type: UInt16.self).byteSwapped)
            universe.updateTorpedo(torpedoNumber: torpedoNumber, war: war, status: status)
            debugPrint("Received SP_TORP_INFO 5 torpedoNumber \(torpedoNumber) war \(war) status \(status) ")
        
        case 6:
            // SP_TORP
            let directionNetrek = Int(UInt8(data[1]))
            let torpedoNumber = Int(data.subdata(in: (2..<3)).to(type: UInt16.self).byteSwapped)
            let positionX = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let positionY = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            debugPrint("Received SP_TORP 6 torpedoNumber \(torpedoNumber) directionNetrek \(directionNetrek) positionX \(positionX) positionY \(positionY)")
            universe.updateTorpedo(torpedoNumber: torpedoNumber, directionNetrek: directionNetrek, positionX: positionX, positionY: positionY)
            
        case 7:
            // SP_PHASER 7
            let laserNumber = Int(data[1])
            let status = Int(data[2]) // PH_HIT etc...
            let directionNetrek = Int(UInt8(data[3]))
            let positionX = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let positionY = Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            let target = Int(data.subdata(in: (12..<16)).to(type: Int32.self).byteSwapped)
            debugPrint("Received SP_LASER 7 laserNumber \(laserNumber) status \(status) directionNetrek \(directionNetrek) positionX \(positionX) positionY \(positionY) target \(target)")
            universe.updateLaser(laserNumber: laserNumber, status: status, directionNetrek: directionNetrek, positionX: positionX, positionY: positionY, target: target)
        case 8:
            //SP_PLASMA_INFO
            let war = Int(data[1])
            let status = Int(data[2])
            let plasmaNumber = Int(data.subdata(in: (4..<5)).to(type: UInt16.self).byteSwapped)
            universe.updatePlasma(plasmaNumber: plasmaNumber, war: war, status: status)
            debugPrint("Received SP_PLASMA 8 plasmaNumber \(plasmaNumber) war \(war) status \(status)")

        case 9:
            //SP_PLASMA
            let plasmaNumber = Int(data.subdata(in: (2..<3)).to(type: UInt16.self).byteSwapped)
            let positionX = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let positionY = Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            debugPrint("Received SP_PLASMA 9 plasmaNumber \(plasmaNumber) positionX \(positionX) positionY \(positionY)")
            universe.updatePlasma(plasmaNumber: plasmaNumber, positionX: positionX, positionY: positionY)
        
        case 10:
            // SP_WARNING
            let range = (4..<84)
            let messageData = data.subdata(in: range)
            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
                var messageString = messageStringWithNulls.filter { $0 != "\0" }
                
                messageString.append("\n")
                debugPrint("Received SP_WARNING 10 sent to messages")
                appDelegate.messageViewController?.gotMessage(messageString)
                //debugPrint(messageString)
                printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 10")
                printData(data, success: false)
            }

        case 11:
            debugPrint("Received SP_PLAYER_INFO SP_MOTD 11")
            // message
            let range = (4..<84)
            let messageData = data.subdata(in: range)
            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
                var messageString = messageStringWithNulls.filter { $0 != "\0" }
                messageString.append("\n")
                appDelegate.messageViewController?.gotMessage(messageString)
                //debugPrint(messageString)
                printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 11")
                printData(data, success: false)
            }
        case 12:
            // My information
            // SP_YOU length 32
            let myPlayerID = Int(data[1])
            let hostile = Int(data[2])
            let war = Int(data[3])
            let armies = Int(data[4])
            let tractor = Int(data[5])
            let flags = data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped
            let damage = Int(data.subdata(in: (12..<16)).to(type: UInt32.self).byteSwapped)
            let shieldStrength = Int(data.subdata(in: (16..<20)).to(type: UInt32.self).byteSwapped)
            let fuel = Int(data.subdata(in: (20..<24)).to(type: UInt32.self).byteSwapped)
            let engineTemp = Int(data.subdata(in: (24..<25)).to(type: UInt16.self)).byteSwapped
            let weaponsTemp = Int(data.subdata(in: (26..<27)).to(type: UInt16.self)).byteSwapped
            let whyDead = Int(data.subdata(in: (28..<29)).to(type: UInt16.self)).byteSwapped
            let whoDead = Int(data.subdata(in: (30..<31)).to(type: UInt16.self)).byteSwapped
            debugPrint("Received SP_YOU 12 \(myPlayerID) hostile \(hostile) war \(war) armies \(armies) tractor \(tractor) flags \(flags) damage \(damage) shieldStrength \(shieldStrength) fuel \(fuel) engineTemp \(engineTemp) weaponsTemp \(weaponsTemp) whyDead \(whyDead) whodead \(whoDead)")
            universe.updateMe(myPlayerID: myPlayerID, hostile: hostile, war: war, armies: armies, tractor: tractor, flags: flags, damage: damage, shieldStrength: shieldStrength, fuel: fuel, engineTemp: engineTemp, weaponsTemp: weaponsTemp, whyDead: whyDead, whoDead: whoDead)
            if appDelegate.gameState == .serverSelected || appDelegate.gameState == .serverConnected {
                appDelegate.newGameState(.serverSlotFound)
            }
            //debugPrint(me.description)
            //printData(data, success: true)

        case 13:
            debugPrint("Received SP_QUEUE 13")
            // SP_QUEUE
            let queue = data.subdata(in: (2..<3)).to(type: UInt16.self).byteSwapped
            appDelegate.messageViewController?.gotMessage("Connected to server. Wait queue position \(queue)")
            printData(data, success: true)
            
        case 14:
            let tourn = Int(data[1])
            //pad1
            //pad2
            let armsBomb = (data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let planets = (data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            let kills = (data.subdata(in: (12..<16)).to(type: UInt32.self).byteSwapped)
            let losses = (data.subdata(in: (16..<20)).to(type: UInt32.self).byteSwapped)
            let time = (data.subdata(in: (20..<24)).to(type: UInt32.self).byteSwapped)
            let timeProd = (data.subdata(in: (24..<28)).to(type: Int32.self).byteSwapped)
            debugPrint("Received SP_STATUS 14 tourn \(tourn) armsBomb \(armsBomb) planets \(planets) kills \(kills) losses \(losses) time \(time) timeProd \(timeProd)")
            let messageString = "Your stats: bombed \(armsBomb) armies, captured \(planets) planets, killed \(kills) enemies, died \(losses) times in \(time/3600) hours"
            appDelegate.messageViewController?.gotMessage(messageString)
        case 15:
            //SP_PLANET
            let planetID = Int(data[1])
            let owner = Int(data[2])
            let info = Int(data[3])
            let flags = data.subdata(in: (4..<5)).to(type: UInt16.self).byteSwapped
            // pad
            // pad
            let armies = data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped
            debugPrint("Received SP_PLANET planetID \(planetID) owner \(owner) info \(info) flags \(flags) armies \(armies)")
            guard let planet = universe.planets[planetID] else {
                debugPrint("ERROR: invalid planetID \(planetID)")
                return
            }
            planet.setOwner(newOwnerInt: owner)
            planet.setInfo(newInfoInt: info)
            planet.setFlags(newFlagsInt: Int(flags))
            planet.armies = Int(armies)
            
        case 16:
            // SP_PICKOK
            let state = Int(data[1]) // 0 = no, 1 = yes
            //pad2
            //pad3
            debugPrint("Received SP_PICKOK 16 state: \(state)")
            if state == 1 {
                appDelegate.newGameState(.outfitAccepted)
            }

        case 17:
            debugPrint("Received SP_LOGIN 17")
            // SP_LOGIN
            let accept = Int(data[1])
            let paradise1 = Int(data[2])
            let paradise2 = Int(data[3])
            let flags = data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped
            let keymap = data.subdata(in: (8..<96))
            
            if paradise1 == 69 && paradise2 == 42 {
                appDelegate.messageViewController?.gotMessage("paradise server not supported")
                appDelegate.newGameState(.noServerSelected)
            }
            if accept == 0 {   // login failed
                appDelegate.messageViewController?.gotMessage("login failed")
                appDelegate.newGameState(.noServerSelected)
            } else {
                appDelegate.newGameState(.loginAccepted)
            }
            printData(data, success: true)

        case 18:
            debugPrint("Received SP_FLAGS 18")
            //SP_FLAGS
            let playerID = Int(data[1])
            let tractor = Int(data[2])
            let flags = data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped

            guard let player = universe.players[playerID] else {
                debugPrint("PacketAnalyzer type 18 invalid player id \(playerID)")
                printData(data, success: false)

                return
            }
            player.update(tractor: tractor, flags: flags)
            //debugPrint(player)
            printData(data, success: true)

        case 19:
            //TODO process mask
            //SP_MASK
            let mask = UInt8(data[1])
            // pad2
            // pad3
            debugPrint("Received SP_MASK 19 mask \(mask)")
        case 20:
            debugPrint("Received SP_PSTATUS 20")
            // SP_PSTATUS
            let playerID = Int(data[1])
            let status = Int(data[2])
            guard let player = universe.players[playerID] else {
                debugPrint("PacketAnalyzer type 20 invalid player id \(playerID)")
                printData(data, success: false)
                return
            }
            player.status = Int(status)
            //debugPrint(player)
            printData(data, success: true)


        case 22:
            debugPrint("Received SP_HOSTILE 22")
            let playerID = Int(data[1])
            let war = Int(data[2])
            let hostile = Int(data[3])
            debugPrint("Received SP_HOSTILE 22 playerID \(playerID) war \(war) hostile \(hostile)")
            universe.updatePlayer(playerID: playerID, war: war, hostile: hostile)
            
        case 24:
            debugPrint("Received SP_PL_LOGIN 24")
            //plyr_long_spacket SP_PL_LOGIN
            // new player logged in
            let playerID = Int(data[1])
            let rank = Int(data[2])
            let nameData = data.subdata(in: (4..<20))
            var name = "unknown"
            if let nameStringWithNulls = String(data: nameData, encoding: .utf8) {
                name = nameStringWithNulls.filter { $0 != "\0" }
            }
            let monitorData = data.subdata(in: (20..<36))
            var monitor = "unknown"
            if let monitorStringWithNulls = String(data: monitorData, encoding: .utf8) {
                monitor = monitorStringWithNulls.filter { $0 != "\0" }
            }
            let loginData = data.subdata(in: (36..<52))
            var login = "unknown"
            if let loginStringWithNulls = String(data: loginData, encoding: .utf8) {
                login = loginStringWithNulls.filter { $0 != "\0" }
            }
            debugPrint("Received SP_PL_LOGIN 24 playerID: \(playerID) rank: \(rank) name: \(name) login: \(login)")
            universe.updatePlayer(playerID: playerID, rank: rank, name: name, login: login)

        case 26:
            debugPrint("Received SP_PLANET_LOC 26")
            // SP_PLANET_LOC
            let planetID = Int(data[1])
            let positionX = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let positionY = Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            let nameData = data.subdata(in: (12..<28))
            var name = "unknown"
            if let nameStringWithNulls = String(data: nameData, encoding: .utf8) {
                name = nameStringWithNulls.filter { $0 != "\0" }
            }
            universe.createPlanet(planetID: planetID, positionX: positionX, positionY: positionY, name: name)
            if let planet = universe.planets[planetID] {
                //debugPrint(planet)
            }
            printData(data, success: true)

        case 32:
            let version = Int(data[1])
            guard version == 98 else {
                debugPrint("Received SPGeneric 32 version \(version) discarding)")
                return
            }
            let repairTime = (data.subdata(in: (2..<3)).to(type: UInt16.self).byteSwapped)
            let pl_orbit = Int8(data[3])
            let gameup = (data.subdata(in: (4..<5)).to(type: UInt16.self).byteSwapped)
            let tournamentTeams = UInt8(data[6])
            let tournamentAge = UInt8(data[7])
            let tournamentUnits = UInt8(data[8])
            let tournamentRemain = UInt8(data[9])
            let tournamentRemainUnits = UInt8(data[10])
            let starbaseRemain = UInt8(data[11]) //starbase reconstruction in minutes
            let teamRemain = UInt8(data[12]) // team surrender time
            // 18 bytes padding
            debugPrint("Received SP_GENERIC 32 version \(version) repairTime \(repairTime) orbit \(pl_orbit) and other stuff all discarded")
            // 26 bytes of unused padding
        case 39:
            // SP_SHIP_CAP
            let operation = UInt8(data[1])  // /* 0 = add/change a ship, 1 = remove a ship */
            let shipType = (data.subdata(in: (2..<3)).to(type: UInt16.self).byteSwapped)
            let torpSpeed = (data.subdata(in: (4..<5)).to(type: UInt16.self).byteSwapped)
            let phaserRange = (data.subdata(in: (6..<7)).to(type: UInt16.self).byteSwapped)
            let maxSpeed = (data.subdata(in: (8..<11)).to(type: UInt32.self).byteSwapped)
            let maxFuel = (data.subdata(in: (12..<15)).to(type: UInt32.self).byteSwapped)
            let maxShield = (data.subdata(in: (16..<19)).to(type: UInt32.self).byteSwapped)
            let maxDamage = (data.subdata(in: (20..<23)).to(type: UInt32.self).byteSwapped)
            let maxWpnTmp = (data.subdata(in: (24..<27)).to(type: Int32.self).byteSwapped)
            let maxEngTmp = (data.subdata(in: (28..<31)).to(type: Int32.self).byteSwapped)
            let width = (data.subdata(in: (32..<33)).to(type: UInt16.self).byteSwapped)
            let height = (data.subdata(in: (34..<35)).to(type: UInt16.self).byteSwapped)
            let maxArmies = (data.subdata(in: (36..<37)).to(type: UInt16.self).byteSwapped)
            let letter = Character(UnicodeScalar(Int(data[38])) ?? "U")
            // pad 39
            let nameData = data.subdata(in: (40..<55))
            var shipName = "unknown"
            if let nameStringWithNulls = String(data: nameData, encoding: .utf8) {
                shipName = nameStringWithNulls.filter { $0 != "\0" }
            }
            let s_desig1 = UInt8(data[56])
            let s_desig2 = UInt8(data[57])
            let bitmap = (data.subdata(in: (58..<59)).to(type: UInt16.self).byteSwapped)
            debugPrint("Received SP_SHIP_CAP 39 operation \(operation) shipType \(shipType) torpSpeed \(torpSpeed) phaserRange \(phaserRange) maxSpeed \(maxSpeed) maxFuel \(maxFuel) maxShield \(maxShield) maxDamage \(maxDamage) maxWpnTmp \(maxWpnTmp) maxEngTmp \(maxEngTmp) width \(width) height \(height) maxArmies \(maxArmies) letter \(letter) shipName \(shipName) s_desig1 \(s_desig1) s_desig2 \(s_desig2) bitmap \(bitmap)")

        case 60:
            var datacopy = data
            let feature_type = Character(UnicodeScalar(Int(data[1])) ?? "U") // expect C
            let arg1 = Int(data[2])
            let arg2 = Int(data[3])
            let value = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            var features: [String] = []
            var newString: String = ""
            var newStringValid = false
            for index in 8 ..< 88 {  // feature packet size better be 88
                if data[index] != 0 {
                    if let unicodeScalar = UnicodeScalar(Int(data[index])) {
                        let char = Character(unicodeScalar)
                        newStringValid = true
                        newString.append(char)
                    }
                } else {
                    if newStringValid == true {
                        features.append(newString)
                        newString = ""
                        newStringValid = false
                    }
                }
            }
            if features.count > 0 {
                for feature in features {
                    debugPrint("Received SP_FEATURE 60 \(feature)")
                }
            } else {
                debugPrint("Received SP_FEATURE 60 empty")
            }
            appDelegate.serverFeatures = appDelegate.serverFeatures + features

        default:
            debugPrint("Default case: Received packet type \(packetType) length \(packetLength)\n")
            printData(data, success: true)

        }
    }
}
