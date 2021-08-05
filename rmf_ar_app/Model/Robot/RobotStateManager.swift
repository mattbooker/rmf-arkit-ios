//
//  RobotStateManager.swift
//  rmf_ar_app
//
//  Created by Matthew Booker on 21/6/21.
//

import Foundation
import os
import RealityKit
import ARKit

class RobotStateManager {
    
    private var arView: ARView
    
    private var robotDict: [String: TrackedRobot] = [:]
    private var robotDictSemaphore = DispatchSemaphore(value: 1)
    
    private var robotUIAsset: Entity
    
    private var networkManager: NetworkManager
    
    private var downloadTimer: Timer!
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "RobotStateManager")
    
    private var isLocalized = false
    private var uiLastUpdate = Date.distantPast
    
    private static let robotMesh = MeshResource.generateBox(width: 0.2, height: 0.2, depth: 0.5, cornerRadius: 0.2, splitFaces: true)
    private static let robotMaterial = SimpleMaterial(color: .purple, isMetallic: false)
    
    init(arView: ARView, networkManager: NetworkManager) {
        self.arView = arView
        
        self.networkManager = networkManager

        do {
            self.robotUIAsset = try Entity.load(named: "robotUI.usdz")
        } catch {
            logger.error("\(error.localizedDescription)")
            self.robotUIAsset = Entity()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            [weak self] in
            
            guard let self = self else { return }
            
            self.downloadTimer = Timer(timeInterval: (1 / ARConstants.RobotStates.DOWNLOAD_RATE), target: self, selector: #selector(self.updateRobotStates), userInfo: nil, repeats: true)
            
            let runLoop = RunLoop.current
            runLoop.add(self.downloadTimer, forMode: .default)
            runLoop.run()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(setIsLocalized), name: Notification.Name("setWorldOrigin"), object: nil)
    }
    
    // MARK: - Public Methods
    func getRobotsData() -> [String: TrackedRobot] {
        // Lock before copying
        robotDictSemaphore.wait()
        let copiedData = self.robotDict
        robotDictSemaphore.signal()
        
        return copiedData
    }
    
    func handleARAnchor(anchor: ARAnchor) {
        // Only process if the anchor is an image anchor
        guard let imageAnchor = anchor as? ARImageAnchor else {return}
        
        let tagName = imageAnchor.name!
        
        robotDictSemaphore.wait()
    
        guard let robot = robotDict[tagName] else {
            logger.error("Robot with name: \(tagName) not found")
            robotDictSemaphore.signal()
            return
        }
        
        // If no last seen time then we havent seen it before
        if robot.lastSeen == Date.distantPast {
            // Robot not seen before so create the necessary UI for it
            
            // Create a copy of the UI for robots
            let uiEntity = self.robotUIAsset.clone(recursive: true)
            
            let sceneAnchor = AnchorEntity.init(anchor: imageAnchor)
            sceneAnchor.name = tagName + "UI"

            sceneAnchor.addChild(uiEntity)
            self.arView.scene.addAnchor(sceneAnchor)
        }
        
        // Check if ARKit is actively tracking the associated marker
        if imageAnchor.isTracked {
            robotDict[tagName]!.lastSeen = Date()
            robotDict[tagName]!.isTracked = true
        } else {
            robotDict[tagName]!.isTracked = false
        }
        
        robotDictSemaphore.signal()
    }
    
    //MARK: - Private Methods
    @objc private func updateRobotStates() {
        self.networkManager.sendGetRequest(urlString: URLConstants.ROBOT_STATES, responseBodyType: RobotList.self) {
            responseResult in
            
            var robotData: [Robot]
            
            // Check network was succesful
            switch responseResult {
            case .success(let data):
                robotData = data.items
            case .failure(let e):
                self.logger.error("\(e.localizedDescription)")
                return
            }
        
            self.robotDictSemaphore.wait()
            for robot in robotData {
                
                // Update robot state if its in our list, otherwise create a new entry
                if self.robotDict.contains(where: {key, _ in key == robot.name}) {
                    self.robotDict[robot.name]!.robot = robot
                } else {
                    self.robotDict[robot.name] = TrackedRobot(robot: robot, isTracked: false)
                }
            }
            self.robotDictSemaphore.signal()
                
            DispatchQueue.main.async {
                [weak self] in
                
                guard let self = self else { return }
                
                let robotsData = self.getRobotsData()
                
                if self.isLocalized {
                    self.visualizeMarkers(robotsData: robotsData)
                }
                
                self.visualizeRobotUI(robotsData: robotsData)
                
            }
        }
    }
    
    @objc private func setIsLocalized(_ notification: Notification) {
        isLocalized = true
    }
    
    private func visualizeMarkers(robotsData: [String: TrackedRobot]) {
        
        var markersAnchor: AnchorEntity? = arView.scene.findEntity(named: "RobotMarkers") as? AnchorEntity
        
        // Create the marker anchor if not created. Otherwise remove all children
        if markersAnchor == nil {
            markersAnchor = AnchorEntity(world: .zero)
            markersAnchor!.name = "RobotMarkers"
            arView.scene.addAnchor(markersAnchor!)
        }
        
        for (name, trackingData) in robotsData {
            var robotMarker = arView.scene.findEntity(named: name + "Marker")
            
            if robotMarker == nil {
                robotMarker = ModelEntity(mesh: RobotStateManager.robotMesh, materials: Array(repeating: RobotStateManager.robotMaterial, count: RobotStateManager.robotMesh.expectedMaterialCount))
                robotMarker!.name = name + "Marker"
                markersAnchor?.addChild(robotMarker!)
            }

            let x = Float(trackingData.robot.state.location.x)
            let y = Float(trackingData.robot.state.location.y)
            
            // Only show the marker if it has not been seen recently
            robotMarker?.isEnabled = Date().timeIntervalSince(trackingData.lastSeen) > ARConstants.RobotStates.TRACKING_TIMEOUT

            robotMarker!.setPosition([x, y, ARConstants.RobotStates.Z_OFFSET], relativeTo: nil)
        }
    }
    
    private func visualizeRobotUI(robotsData: [String: TrackedRobot]) {
        let currentTime = Date()
        
        // Updating the UI is very expensive. Throttle to update only every second to ensure FPS remains high
        if currentTime.timeIntervalSince(uiLastUpdate) < 1 {
            return
        } else {
            uiLastUpdate = currentTime
        }
        
        // Update all UIs linked to robot states
        for (name, trackingData) in robotsData {
            
            // Skip when not seen
            if !trackingData.isTracked {
                continue
            }
            
            guard let uiEntity = self.arView.scene.findEntity(named: name + "UI") else {
                logger.error("Cant find UI for robot: \(name)")
                continue
            }
            
            // Name
            if let nameEntity = uiEntity.findEntity(named: "robotName")?.findEntity(named: "Text")?.children.first as? ModelEntity {
                nameEntity.model?.mesh = .generateText("\(trackingData.robot.name)", extrusionDepth: 0.01, font: .init(name: "Helvetica", size: CGFloat(0.1))!)
            }
            
            // Fleet
            if let fleetEntity = uiEntity.findEntity(named: "fleetName")?.findEntity(named: "Text")?.children.first as? ModelEntity {
                fleetEntity.model?.mesh = .generateText("\(trackingData.robot.fleet)", extrusionDepth: 0.01, font: .init(name: "Helvetica", size: CGFloat(0.08))!)
            }
            
            // Tasks
            if let taskEntity = uiEntity.findEntity(named: "assignments")?.findEntity(named: "Text")?.children.first as? ModelEntity {
                var taskList: [String] = []
                for task in trackingData.robot.tasks {
                    taskList.append(task.taskSummary.taskId)
                }
                
                taskEntity.model?.mesh = .generateText("\(taskList)", extrusionDepth: 0.01, font: .init(name: "Helvetica", size: CGFloat(0.08))!)
            }
            
            // Status
            if let statusEntity = uiEntity.findEntity(named: "mode")?.findEntity(named: "Text")?.children.first as? ModelEntity {
                statusEntity.model?.mesh = .generateText("\(trackingData.robot.state.mode)", extrusionDepth: 0.01, font: .init(name: "Helvetica", size: CGFloat(0.08))!)
            }
            
            // Battery
            if let batteryEntity = uiEntity.findEntity(named: "batteryPercent")?.findEntity(named: "Text")?.children.first as? ModelEntity {
                let batteryPercent: Float = round(trackingData.robot.state.batteryPercent * 100.0) / 100
                batteryEntity.model?.mesh = .generateText("\(batteryPercent)", extrusionDepth: 0.01, font: .init(name: "Helvetica", size: CGFloat(0.08))!)
            }
            
            // Level
            if let levelEntity = uiEntity.findEntity(named: "levelName")?.findEntity(named: "Text")?.children.first as? ModelEntity {
                levelEntity.model?.mesh = .generateText("\(trackingData.robot.state.location.levelName)", extrusionDepth: 0.01, font: .init(name: "Helvetica", size: CGFloat(0.08))!)
            }
            
        }
    }
    
    deinit {
        downloadTimer.invalidate()
    }
}
