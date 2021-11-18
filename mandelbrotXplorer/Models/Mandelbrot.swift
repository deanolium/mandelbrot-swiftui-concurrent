//
//  Mandelbrot.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 03/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Foundation
import Swift
import os

let log = OSLog(subsystem: "mandelbrot", category: .pointsOfInterest)


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


extension Array {
    func concurrentMap<U>(chunks: Int,
                          canceller: Canceller,
                          transform: @escaping (Element) -> U,
                          callback: @escaping ([U]) -> (),
                          onCancel: @escaping () -> ()) {
        os_signpost(.begin, log: log, name: "array mapping")

        let queue = DispatchQueue(label: "Concurrent Map Queue", qos: .userInitiated)
        let resultQueue = DispatchQueue(label: "Result Queue")
        
        let r = transform(self[0])
        var results = [U]()
        results.reserveCapacity(self.count)
        
        os_signpost(.event, log: log, name: "Starting concurrent map")
        queue.async {
            let numChunks = Int((Double(self.count - 1) / Double(chunks)).rounded(.up))
        
            DispatchQueue.concurrentPerform(iterations: numChunks) { (chunkIndex: Int) in
                let startIndex = chunks * chunkIndex
                let endIndex = Swift.min(startIndex + chunks, self.count)
                let chunkedRange = self[startIndex..<endIndex]
                var chunkedResults = [U](repeating: r, count: endIndex - startIndex)
                
                for (index, item) in chunkedRange.enumerated() {
                    if (canceller.shouldCancel) {
                        return
                    }
                    
                    chunkedResults[index] = transform(item)
                }
                
                if (canceller.shouldCancel) {
                    return
                }
                
                resultQueue.sync {
                    os_signpost(.event, log: log, name: "Appending Result")
                    results.append(contentsOf: chunkedResults)
                }
            }

            os_signpost(.end, log: log, name: "array mapping")

            if (canceller.shouldCancel) {
                onCancel()
                return
            }
            

            callback(results)
        }
    }
}


// The main Mandelbrot class!
class Mandelbrot: NSObject {
    var xscale = AxisScale(min: -0.67, max: -0.45, numberOfSteps: 33)
    var yscale = AxisScale(min: -0.67, max: -0.45, numberOfSteps: 33)
    var escape = 2.0
    var maxIterations = 256
    var size: Int = 32 {
        didSet {
            self.xscale.setNumberOfSteps(size + 1)
            self.yscale.setNumberOfSteps(size + 1)
        }
    }
    
    let entranceQueue = DispatchQueue(label: "Mandelbrot Entrance Queue", qos: .userInitiated)
    
    let canceller = Canceller()
    let cancelSemaphore = DispatchSemaphore(value: 0) // If we're cancelling, then wait on it
    
    func create(_ sender: MandelbrotImageView) -> () {
        
        os_signpost(.event, log: log, name: "Entering MB Create")
        
        entranceQueue.sync {
            if (self.canceller.cancelIfWorking()) {
                // wait for the semaphore
                os_signpost(.event, log: log, name: "Waiting on cancel semaphore")
                self.cancelSemaphore.wait()
                self.canceller.set(shouldCancel: false, isWorking: true)
                os_signpost(.event, log: log, name: "Finished Cancelling - about to start")
            } else {
                self.canceller.isWorking = true
            }
        }
        
        os_signpost(.event, log: log, name: "Creating Points")
        
        self.generateDatapoints()
            .concurrentMap(chunks: 10000,
                           canceller: self.canceller,
                           transform: { (location) -> MandelbrotPoint in
                            return (location, self.iterationsForLocation(location))
            },
                           callback: { (points) in
                            if (self.canceller.stopWorking()) {
                                self.cancelSemaphore.signal()
                                return
                            }
                            
                            DispatchQueue.main.async {
                                // call the sender
                                sender.render(points, size: self.size)
                            }
            },
                           onCancel: {
                            if (self.canceller.stopWorking()) {
                                self.cancelSemaphore.signal()
                            }
            }
        )
    }
    
    func generateDatapoints() -> [ComplexNumber] {
        var datapoints = [ComplexNumber]()
        
        DispatchQueue.global(qos: .userInitiated).sync {
            for dx in xscale.toStride() {
                for dy in yscale.toStride() {
                    datapoints.append(ComplexNumber(real: dy, imaginary: dx))
                }
            }
        }

        return datapoints
    }
    
    func iterationsForLocation(_ c: ComplexNumber) -> Int? {
        var iteration = 0
        var z = ComplexNumber()
        
        repeat {
            z = z*z + c
            iteration += 1
        } while(z.normal() < escape && iteration < maxIterations)
        
        return iteration < maxIterations ? iteration : nil
    }
}
