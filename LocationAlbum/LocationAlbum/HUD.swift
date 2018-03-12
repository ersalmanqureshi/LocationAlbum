//
//  HUD.swift
//  LocationAlbum
//
//  Created by Salman Qureshi on 3/13/18.
//  Copyright © 2018 Salman Qureshi. All rights reserved.
//

import UIKit

class HUD: UIView {
    var text = ""
    
    //Convenience contructor
    class func hud(view: UIView, animated: Bool) -> HUD {
        let hudView = HUD(frame: view.bounds)
        hudView.isOpaque = false
        
        view.addSubview(hudView)
        view.isUserInteractionEnabled = false
        
        //hudView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        return hudView
    }
    
    override func draw(_ rect: CGRect) {
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        
        let boxRect = CGRect(x: round((bounds.size.width - boxWidth) / 2), y: round((bounds.size.height - boxHeight) / 2), width: boxWidth, height: boxHeight)
        
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        
        if let image = UIImage(named: "checkmark") {
            let imagePoint = CGPoint(
                x: center.x - round(image.size.width / 2),
                y: center.y - round(image.size.height / 2) - boxHeight / 8)
            image.draw(at: imagePoint)
        }
    }
}
