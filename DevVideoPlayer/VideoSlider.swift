//
//  VideoSlider.swift
//  DevVideoPlayer
//
//  Created by Marek Mako on 21/03/2017.
//  Copyright © 2017 Marek Mako. All rights reserved.
//

import UIKit

@IBDesignable
class VideoSlider: UISlider {
    
    private var inOutVideoRangeCollection: InOutVideoRangeCollection?
    
    func setInOutVideoRangeCollection(collection: InOutVideoRangeCollection) {
        inOutVideoRangeCollection = collection
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        layer.borderWidth = 1
        layer.cornerRadius = 5
        layer.borderColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1).cgColor
        
        inOutVideoRangeCollection?.draw(videoSliderRect: rect)
    }

    // TODO: best place to set border but it will hide thumb, bug?
//    override func layoutSubviews() {
//        layer.borderWidth = 1
//        layer.cornerRadius = 5
//        layer.borderColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1).cgColor
//    }

    // TODO: thumb image not show, I dont know why :-\ need more resarch
//    override func thumbImage(for state: UIControlState) -> UIImage? {
//        return #imageLiteral(resourceName: "thumb-slider")
//    }
}
