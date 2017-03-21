//
//  InOutVideoRange.swift
//  DevVideoPlayer
//
//  Created by Marek Mako on 21/03/2017.
//  Copyright © 2017 Marek Mako. All rights reserved.
//

import UIKit


class InOutVideoRangeCollection {
    
    private let collection: [InOutVideoRange]
    
    init(collection inOutRanges: [InOutVideoRange]) {
        collection = inOutRanges
    }
    
    func draw(videoSliderRect rect: CGRect) {
        for inOutRange in collection {
            inOutRange.draw(videoSliderRect: rect)
        }
    }
    
    func setActive(range: InOutVideoRange) {
        for inOutRange in collection {
            if inOutRange === range {
                inOutRange.isActive = true
                
            } else {
                inOutRange.isActive = false
            }
        }
    }
    
    func lookupForNearestRange(xCoord x: CGFloat) -> InOutVideoRange? {
        var distanceMap: [CGFloat : InOutVideoRange] = [:]
        
        for inOutRange in collection {
            guard let distance = inOutRange.distance(fromTapCoord: x) else {
                continue
            }
            distanceMap[distance] = inOutRange
        }
        
        let closest = distanceMap
            .enumerated()
            .min( by: { abs($0.element.key - 0) < abs($1.element.key - 0) })
        
        return closest?.element.value
    }
    
    func first() -> InOutVideoRange? {
        return collection.first
    }
}


class InOutVideoRange {
    
    private enum ColorState {
        case active, inactive
        
        func color() -> UIColor {
            switch self {
            case .active:
                return UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1)
            case .inactive:
                return UIColor(red: 89/255, green: 89/255, blue: 89/255, alpha: 1)
            }
        }
    }
    
    // MARK: - coords
    // in/out server
    private let from: CGFloat
    private let to: CGFloat
    // xAxis view
    private var minX: CGFloat?
    private var maxX: CGFloat?
    
    private let fillLineHeightKoeficient: CGFloat = 0.7
    
    private var fillColor = ColorState.inactive
    
    var isActive = false {
        didSet {
            fillColor = isActive ? ColorState.active : ColorState.inactive
        }
    }
    
    init(in from: CGFloat, out to: CGFloat) {
        // TODO: exception, dont trust server
        self.from = from
        self.to = to
    }
    
    func draw(videoSliderRect rect: CGRect) {
        // compute rect
        let x: CGFloat = from * rect.width
        let height: CGFloat = rect.height * fillLineHeightKoeficient
        let y: CGFloat = rect.midY - height / 2
        let width: CGFloat = to * rect.width - x
        
        // set coords
        minX = x
        maxX = x + width
        
        // draw
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let path = UIBezierPath(rect: rect)
        fillColor.color().setFill()
        path.fill()
    }
    
    func distance(fromTapCoord x: CGFloat) -> CGFloat? {
        guard minX != nil || maxX != nil else {
            return nil
        }
        
        if minX! <= x && x <= maxX! { // taped on me
            return 0
            
        } else { // count for distance
            if x < minX! {
                return minX! - x
                
            } else {
                return x - maxX!
            }
        }
    }
    
    func getPlaySquence(duration: Float) -> (start: Float, end: Float) {
        return (Float(from) * duration, Float(to) * duration)
    }
}
