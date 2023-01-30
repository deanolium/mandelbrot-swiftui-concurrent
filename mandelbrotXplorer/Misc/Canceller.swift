//
//  Canceller.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 11/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Foundation


class Canceller {
    private var _shouldCancel: Bool = false
    private var _isWorking: Bool = false
    private let queue = DispatchQueue(label: "Canceller Queue")
    
    var shouldCancel: Bool {
        get {
            queue.sync {
                return _shouldCancel
            }
        }
        set {
            queue.sync {
                _shouldCancel = newValue
            }
        }
    }
    
    var isWorking: Bool {
        get {
            queue.sync {
                return _isWorking
            }
        }
        set {
            queue.sync {
                _isWorking = newValue
            }
        }
    }
    
    func cancelIfWorking() -> Bool {
        queue.sync {
            if (_isWorking) {
                _shouldCancel = true
            }
            return _shouldCancel
        }
    }
    
    func set(shouldCancel: Bool, isWorking: Bool) {
        queue.sync {
            _shouldCancel = shouldCancel
            _isWorking = isWorking
        }
    }
    
    func stopWorking() -> Bool {
        queue.sync {
            _isWorking = false
            return _shouldCancel
        }
    }
}
