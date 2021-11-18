//
//  AxisScale.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 04/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Foundation

class AxisScale {
    var min: Double
    var max: Double
    var step: Double
    
    init(min: Double, max: Double, step: Double) {
        self.min = min
        self.max = max
        self.step = step
    }
    
    init(min: Double, max: Double, numberOfSteps: Int) {
        self.min = min
        self.max = max
        self.step = abs(max - min) / Double(numberOfSteps - 1)
    }
    
    func setNumberOfSteps(_ numSteps: Int) -> () {
        step = (max - min) / Double(numSteps - 1)
    }
    
    func toStride() -> StrideTo<Double> {
        return stride(from: min, to: max, by: step)
    }
    
    func getNumberOfSteps() -> Int {
        return Int((abs(self.max - self.min) / self.step).rounded())
    }
    
}
