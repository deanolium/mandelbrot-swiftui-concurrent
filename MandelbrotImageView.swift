//
//  MandelbrotImageView.swift
//  mandelbrotXplorer
//
//  Created by Deano License on 03/09/2020.
//  Copyright © 2020 Deano License. All rights reserved.
//

import Cocoa

struct PixelData {
    var a: UInt8 = 255
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

class MandelbrotImageView: NSView {
    var mandelbrot: Mandelbrot = Mandelbrot()
    var colorCachePD: Dictionary<Int, PixelData> = [:]
    var size: Int = 8
    fileprivate var data: [MandelbrotPoint] = [MandelbrotPoint]()
    fileprivate let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    fileprivate let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    fileprivate func colorComponent(iteration: Int) -> CGFloat {
        CGFloat((sin(Double(iteration) / 20.0) + 1.0) / 2.0)
    }
    
    fileprivate func getColorForIteration(_ iteration: Int?) -> PixelData {
        guard let iteration = iteration else {
            return PixelData(r: 0, g: 0, b: 0)
        }
        
        if let cachedColor = colorCachePD[iteration] {
            return cachedColor
        }
        
        let newColor = PixelData(r: UInt8(colorComponent(iteration: iteration) * 255),
                                 g: UInt8(colorComponent(iteration: iteration + 10) * 255),
                                 b: UInt8(colorComponent(iteration: iteration + 25) * 255))
        
        colorCachePD[iteration] = newColor
        
        return newColor
    }
    
    fileprivate func drawPoints(_ data: [MandelbrotPoint], _ xscale: (Double) -> CGFloat, _ yscale: (Double) -> CGFloat) {
        var pixels = [PixelData].init(repeating: PixelData(r: 0, g: 0, b: 0), count: (size + 1) * (size + 1))
        
        // Create the image
        for item in data {
            let (location, iterations) = item
            let x = Int(xscale(location.imaginary).rounded())
            let y = Int(yscale(location.real).rounded())
            
            pixels[(y * size) + x] = getColorForIteration(iterations)
        }
        
        // Render to the display
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        let bytesPerRow = bitsPerPixel * size / 8
        let providerRef = CGDataProvider(data: NSData(bytes: &pixels, length: pixels.count * MemoryLayout<PixelData>.stride))
        
        let cgImage = CGImage.init(width: size,
                                   height: size,
                                   bitsPerComponent: bitsPerComponent,
                                   bitsPerPixel: bitsPerPixel,
                                   bytesPerRow: bytesPerRow,
                                   space: rgbColorSpace,
                                   bitmapInfo: bitmapInfo,
                                   provider: providerRef!,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: .defaultIntent
        )
        
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = .none
            let nsImage = NSImage(cgImage: cgImage!,
                                  size: NSSize(width: size, height: size))
            nsImage.draw(in: self.bounds)
            context.flushGraphics()
        }
    }
    
    fileprivate func getMapping(min: Double, max: Double, size: CGFloat) -> (_ point: Double) -> CGFloat {
    { point in
        return CGFloat(((point - min) * Double(size)) / (max - min))
        }
    }
    
    func setDesiredSize(_ desiredSize: Int) {
        recalculatePoints(size: desiredSize)
    }
    
    func recalculatePoints(size desiredSize: Int) {
        mandelbrot.size = desiredSize
        mandelbrot.create(self)
    }
    
    func render(_ points: [MandelbrotPoint], size: Int) {
        self.size = size
        self.data = points
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let xscale = getMapping(min: mandelbrot.xscale.min, max: mandelbrot.xscale.max, size: CGFloat(size))
        let yscale = getMapping(min: mandelbrot.yscale.min, max: mandelbrot.yscale.max, size: CGFloat(size))

        // Drop out if we don't have any data
        if data.count == 0 {
            return
        }
        
        drawPoints(data, xscale, yscale)
    }
}
