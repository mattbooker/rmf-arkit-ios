//
//  Task.swift
//  rmf_ar_app
//
//  Created by Matthew Booker on 6/7/21.
//

import Foundation

// MARK: - Task Data
struct Task: Decodable {
    let taskId: String
    let summary: TaskSummary
    let progress: TaskProgress
}

struct TaskSummary: Decodable {
    let fleetName: String
    let taskId: String
    let taskProfile: TaskProfile
    let state: State
    let status: String
    let submissionTime: Time
    let startTime: Time
    let endTime: Time
    let robotName: String
    
    enum State: Int, Decodable {
        case queued = 0
        case active = 1
        case completed = 2
        case failed = 3
        case canceled = 4
        case pending = 5
    }
}

struct TaskProgress: Decodable {
    let status: String
}

struct TaskProfile: Decodable {
    let taskId: String
    let submissionTime: Time
    let description: TaskDescription
}

struct TaskDescription: Decodable {
    let startTime: Time
    let priority: Priority
    let taskType: TaskType
    let station: Station
    let loop: Loop
    let delivery: Delivery
    let clean: Clean
    
    struct Priority: Decodable {
        let value: Int
    }
    
    struct TaskType: Decodable {
        let type: Int
        
        func getTaskName() -> String {
            switch type {
            case 0:
                return "Station"
            case 1:
                return "Loop"
            case 2:
                return "Delivery"
            case 3:
                return "Charge Battery"
            case 4:
                return "Clean"
            case 5:
                return "Patrol"
            default:
                return "Waiting"
            }
        }
    }
    
    struct Station: Decodable {
        let taskId: String
        let robotType: String
        let placeName: String
    }
    
    struct Loop: Decodable {
        let taskId: String
        let robotType: String
        let numLoops: Int
        let startName: String
        let finishName: String
    }
    
    struct Delivery: Decodable {
        let taskId: String
        let pickupPlaceName: String
        let pickupDispenser: String
        let dropoffPlaceName: String
        let dropoffIngestor: String
    }
    
    struct Clean: Decodable {
        let startWaypoint: String
    }
}

// MARK: Task Creation
protocol CreateTaskRequest: Encodable {
    var taskType: Int { get }
    var startTime: Int { get }
    var priority: Int { get }
}

struct CreateLoopTaskRequest: CreateTaskRequest {
    let taskType = 1
    let startTime: Int
    let priority: Int
    let description: LoopDescription
    
    struct LoopDescription: Encodable {
        let numLoops: Int
        let startName: String
        let finishName: String
    }
    
    init(startTime: Int, priority: Int, numLoops: Int, startName: String, finishName: String) {
        self.startTime = Int(Date().timeIntervalSince1970) + startTime
        self.priority = priority
        
        self.description = LoopDescription(numLoops: numLoops, startName: startName, finishName: finishName)
    }
}

struct CreateDeliveryTaskRequest: CreateTaskRequest {
    let taskType = 2
    let startTime: Int
    let priority: Int
    let description: DeliveryDescription
    
    struct DeliveryDescription: Encodable {
        let pickupPlaceName: String
        let pickupDispenser: String
        let dropoffPlaceName: String
        let dropoffIngestor: String
    }
    
    init(startTime: Int, priority: Int, pickupPlaceName: String, pickupDispenser: String, dropoffPlaceName: String, dropoffIngestor: String) {
        self.startTime = Int(Date().timeIntervalSince1970) + startTime
        self.priority = priority
        
        self.description = DeliveryDescription(pickupPlaceName: pickupPlaceName, pickupDispenser: pickupDispenser, dropoffPlaceName: dropoffPlaceName, dropoffIngestor: dropoffIngestor)
    }
}

struct CreateCleanTaskRequest: CreateTaskRequest {
    let taskType = 4
    let startTime: Int
    let priority: Int
    let description: CleanDescription
    
    struct CleanDescription: Encodable {
        let startWaypoint: String
    }
    
    init(startTime: Int, priority: Int, startWaypoint: String) {
        self.startTime = Int(Date().timeIntervalSince1970) + startTime
        self.priority = priority
        
        self.description = CleanDescription(startWaypoint: startWaypoint)
    }
}

struct CreateTaskResponse: Codable {
    let taskId: String
}

// MARK: Task Cancellation
struct CancelTaskRequest: Encodable {
    let taskId: String
}

struct CancelTaskResponse: Decodable {
    let success: Bool
}


