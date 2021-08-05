//
//  RobotStatusData.swift
//  rmf_ar_app
//
//  Created by Matthew Booker on 17/6/21.
//

import Foundation

struct TrackedRobot {
    var robot: Robot
    var isTracked: Bool
    var lastSeen = Date.distantPast
}

struct RobotList: Decodable {
    let items: [Robot]
    let totalCount: Int
}

struct Robot: Decodable {
    let fleet: String
    let name: String
    let state: RobotState
    let tasks: [TaskProgress]
}

struct RobotState: Decodable {

    let name: String
    let model: String
    let taskId: String
    let seq: Int
    let mode: RobotMode
    let batteryPercent: Float
    let location: Location
    let path: [Location]
}

struct RobotMode: Decodable {
    let mode: Mode
    let modeRequestId: Int
    
    enum Mode: Int, Decodable {
        case idle = 0
        case charging = 1
        case moving = 2
        case paused = 3
        case waiting = 4
        case emergency = 5
        case goingHome = 6
        case docking = 7
        case adapterError = 8
        case cleaning = 9
        
    }
}

struct Location: Decodable {
    let t: Time
    let x: Float
    let y: Float
    let yaw: Float
    let levelName: String
    let index: Int
}
