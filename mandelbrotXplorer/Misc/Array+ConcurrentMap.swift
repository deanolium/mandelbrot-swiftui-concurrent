//
//  ConcurrentMap.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 11/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Foundation
import Swift
import os

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

