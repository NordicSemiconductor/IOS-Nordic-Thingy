/*
 Copyright (c) 2010 - 2017, Nordic Semiconductor ASA
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form, except as embedded into a Nordic
 Semiconductor ASA integrated circuit in a product or a software update for
 such product, must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 4. This software, with or without modification, must only be used with a
 Nordic Semiconductor ASA integrated circuit.
 
 5. Any software provided in binary form under this license must not be reverse
 engineered, decompiled, modified and/or disassembled.
 
 THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
//
//  UIColorExtension.swift
//
//  Created by Mostafa Berg on 05/10/16.
//

import UIKit

extension UIColor {
    
    static let nordicBlue = #colorLiteral(red: 0, green: 0.7181802392, blue: 0.8448022008, alpha: 1)
    
    static let nordicSky = #colorLiteral(red: 0.4773202538, green: 0.8505803943, blue: 0.9124827981, alpha: 1)
    
    static let nordicLake = #colorLiteral(red: 0, green: 0.5483048558, blue: 0.8252354264, alpha: 1)
    
    static let nordicLakeDark = #colorLiteral(red: 0, green: 0.4745001793, blue: 0.7173394561, alpha: 1)
    
    static let nordicBlueslate = #colorLiteral(red: 0, green: 0.2858072221, blue: 0.6897063851, alpha: 1)
    
    static let nordicLightGray = #colorLiteral(red: 0.8790807724, green: 0.9051030278, blue: 0.9087315202, alpha: 1)
    
    static let nordicMediumGray = #colorLiteral(red: 0.5353743434, green: 0.5965531468, blue: 0.6396299005, alpha: 1)
    
    static let nordicDarkGray = #colorLiteral(red: 0.2590435743, green: 0.3151275516, blue: 0.353839159, alpha: 1)
    
    static let nordicGrass = #colorLiteral(red: 0.8486783504, green: 0.8850693107, blue: 0, alpha: 1)
    
    static let nordicSun = #colorLiteral(red: 1, green: 0.8319787979, blue: 0, alpha: 1)
    
    static let nordicRed = #colorLiteral(red: 0.9567440152, green: 0.2853084803, blue: 0.3770255744, alpha: 1)
    
    static let nordicFall = #colorLiteral(red: 0.9759463668, green: 0.5845184922, blue: 0.1595045924, alpha: 1)
    
    static let error = nordicRed
    
    public static var random: UIColor {
        let randomRed:   CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let randomGreen: CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let randomBlue:  CGFloat = CGFloat(arc4random()) / CGFloat(UInt32.max)
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    public convenience init(hexString: String, alpha: Double = 1.0) {
        let hex = hexString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
        var intVal = UInt32()
        Scanner(string: hex).scanHexInt32(&intVal)
        let r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((intVal >> 8) * 17, (intVal >> 4 & 0xF) * 17, (intVal & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (intVal >> 16, intVal >> 8 & 0xFF, intVal & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(255 * alpha) / 255)
    }
    
    var hexString: String {
        let components = self.cgColor.components!
        
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }
    
}
