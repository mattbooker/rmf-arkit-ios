//
//  URLConstants.swift
//  rmf_ar_app
//
//  Created by Matthew Booker on 27/7/21.
//

import Foundation

struct URLConstants {
    static let TASK_LIST = "http://192.168.0.152:8000/tasks"
    static let SUBMIT_TASK = "http://192.168.0.152:8000/tasks/submit_task"
    static let CANCEL_TASK = "http://192.168.0.152:8000/tasks/cancel_task"
    static let BUILDING_MAP = "http://192.168.0.152:8000/building_map"
    static let ROBOT_STATES = "http://192.168.0.152:8000/fleets/robots"
    static let TRAJ_SERVER = "ws://192.168.0.152:8006"
    static let DASHBOARD = "http://192.168.0.152:5000/dashboard_config"
}
