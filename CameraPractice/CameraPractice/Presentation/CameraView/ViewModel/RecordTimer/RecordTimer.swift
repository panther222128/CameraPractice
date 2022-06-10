//
//  RecordTimer.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/10.
//

import Foundation

protocol RecordTimerConfigurable {
    var time: Observable<String> { get }
    
    func start()
    func stop()
}

class RecordTimer: RecordTimerConfigurable {
    
    private var timeProgressStatus: Int
    var time: Observable<String>
    var timer: Timer?
    
    init() {
        self.timeProgressStatus = 0
        self.time = Observable("00:00")
    }
    
    func start() {
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
                self?.timeProgressStatus += 1
                self?.time.value = self?.convertMinSec(of: self?.timeProgressStatus ?? 0) ?? ""
            })
        }
    }
    
    func stop() {
        guard let timer = self.timer else { return }
        timer.invalidate()
        self.timer = nil
        self.time.value = "00:00"
    }
    
    private func convertMinSec(of second: Int) -> String {
        if second / 60 > 0 {
            return "\(second / 60)" + ":" + "0\(second % 60)"
        } else {
            return "00" + ":" + "0\(second % 60)"
        }
    }
    
}
