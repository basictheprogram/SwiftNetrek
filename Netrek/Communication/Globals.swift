//
//  Globals.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

// packet type globals

let MAXPLAYERS = 32

let SOCKVERSION: UInt8 = 4
let UDPVERSION: UInt8 = 10

let NUMOFBITS: [Int] = [
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
]

// sizes of variable torpbuffers
let VTSIZE: [Int] = [
    4, 8, 8, 12, 12, 16, 20, 20, 24
]

// 4 byte Header + torpdata
let VTISIZE: [Int] = [
    4, 7, 9, 11, 13, 16, 18, 20, 22
]

let PACKET_SIZES: [Int] = [
    0,        // NULL
    84,        // SP_MESSAGE
    4,        // SP_PLAYER_INFO
    8,        // SP_KILLS
    12,        // SP_PLAYER
    8,        // SP_TORP_INFO
    12,        // SP_TORP
    16,        // SP_PHASER
    8,        // SP_PLASMA_INFO
    12,        // SP_PLASMA
    84,        // SP_WARNING
    84,        // SP_MOTD
    32,        // SP_YOU
    4,        // SP_QUEUE
    28,        // SP_STATUS
    12,        // SP_PLANET
    4,        // SP_PICKOK
    104,        // SP_LOGIN
    8,        // SP_FLAGS
    4,        // SP_MASK
    4,        // SP_PSTATUS
    4,        // SP_BADVERSION
    4,        // SP_HOSTILE
    56,        // SP_STATS
    52,        // SP_PL_LOGIN
    20,        // SP_RESERVED
    28,        // SP_PLANET_LOC
    0,        // SP_SCAN
    8,        // SP_UDP_REPLY
    4,        // SP_SEQUENCE
    4,        // SP_SC_SEQUENCE
    36,        // SP_RSA_KEY
    12,        // SP_MOTD_PIC
    0,        // 33
    0,        // 34
    0,        // 35
    0,        // 36
    0,        // 37
    0,        // 38
    60,        // SP_SHIP_CAP
    8,        // SP_S_REPLY
    -1,        // SP_S_MESSAGE
    -1,        // SP_S_WARNING
    12,        // SP_S_YOU
    12,        // SP_S_YOU_SS
    -1,        // SP_S_PLAYER
    8,        // SP_PING
    -1,        // SP_S_TORP
    -1,        // SP_S_TORP_INFO
    20,        // SP_S_8_TORP
    -1,        // SP_S_PLANET
    0,        // 51
    0,        // 52
    0,        // 53
    0,        // 54
    0,        // 55
    0,        // SP_S_SEQUENCE
    -1,        // SP_S_PHASER
    -1,        // SP_S_KILLS
    36,        // SP_S_STATS
    88,        // SP_FEATURE
    524        // SP_BITMAP
]




