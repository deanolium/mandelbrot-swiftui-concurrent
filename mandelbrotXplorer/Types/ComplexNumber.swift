//
//  ComplexNumber.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 03/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Cocoa

struct ComplexNumber {
    var real: Double = 0
    var imaginary: Double = 0
}

// Add in the methods to interact with Complex Numbers
extension ComplexNumber {
    func normal() -> Double {
        return real * real + imaginary * imaginary
    }
    
    static func + (a: ComplexNumber, b:ComplexNumber) -> ComplexNumber {
        return ComplexNumber(real: a.real + b.real, imaginary: a.imaginary + b.imaginary)
    }
    
    static func - (a: ComplexNumber, b:ComplexNumber) -> ComplexNumber {
        return ComplexNumber(real: a.real - b.real, imaginary: a.imaginary - b.imaginary)
    }
    
    static func * (a: ComplexNumber, b:ComplexNumber) -> ComplexNumber {
        return ComplexNumber(real: a.real * b.real - a.imaginary * b.imaginary, imaginary: a.real * b.imaginary + b.real * a.imaginary)
    }
}

