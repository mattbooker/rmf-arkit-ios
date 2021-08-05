//
//  TaskCell.swift
//  rmf_ar_app
//
//  Created by Matthew Booker on 6/7/21.
//

import UIKit

class TaskCell: UICollectionViewCell {
 
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var progressText: UILabel!
    @IBOutlet weak var taskIDText: UILabel!
    @IBOutlet weak var detailsText: UILabel!
    @IBOutlet weak var robotText: UILabel!
    @IBOutlet weak var taskTypeText: UILabel!
    @IBOutlet weak var priorityText: UILabel!
    @IBOutlet weak var taskStateText: UILabel!
    @IBOutlet weak var startTimeText: UILabel!
    @IBOutlet weak var endTimeText: UILabel!
    
    func populateFromTask(task: TaskProgress) {
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        
        let progressValue = Float(task.progress.replacingOccurrences(of: "%", with: ""))
        progressBar.setProgress(0, animated: false)
        progressBar.trackTintColor = UIColor.systemGray4
        
        var taskState = ""
        
        switch task.taskSummary.state {
        case .queued:
            progressBar.trackTintColor = UIColor.black
            progressText.text = "Queued"
            taskState = "Queued"
        
        case .active:
            progressBar.setProgress((progressValue ?? 0) / 100, animated: false)
            progressText.text = task.progress
            taskState = "Active"
            
        case .completed:
            progressBar.trackTintColor = UIColor.systemGreen
            progressText.text = "Completed"
            taskState = "Completed"
        
        case .failed:
            progressBar.trackTintColor = UIColor.red
            progressText.text = "Failed"
            taskState = "Failed"
            
        case .canceled:
            progressBar.trackTintColor = UIColor.white
            progressText.text = "Cancelled"
            taskState = "Cancelled"
            
        case .pending:
            progressBar.trackTintColor = UIColor.systemYellow
            progressText.text = "Pending"
            taskState = "Pending"
        }
        
        
        progressText.sizeToFit()
        taskIDText.text = task.taskSummary.taskId
        detailsText.text = task.taskSummary.status
//        detailsText.sizeToFit()
        robotText.text = task.taskSummary.robotName
        taskTypeText.text = task.taskSummary.taskProfile.description.taskType.getTaskName()
        priorityText.text = String(task.taskSummary.taskProfile.description.priority.value)
        taskStateText.text = taskState
        startTimeText.text = String(task.taskSummary.startTime.sec)
        endTimeText.text = String(task.taskSummary.endTime.sec)
        
    }
    
}
