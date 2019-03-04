//
//  GameState.swift
//  Netrek
//
//  Created by Darrell Root on 3/2/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

enum GameState: String, CaseIterable {
    case noServerSelected
    case serverSelected
    case serverConnected
    case serverSlotFound
    case loginAccepted
    case outfitAccepted
    case gameActive
}

enum ShipType: Int, CaseIterable {
    case scout = 0
    case destroyer = 1
    case cruiser = 2
    case battleship = 3
    case assault = 4
    case starbase = 5
    case sgalaxy = 6
    case att = 7
}

enum Team: Int, CaseIterable {
    case federation = 1
    case romulan = 2
    case klingon = 4
    case orion = 8
}
