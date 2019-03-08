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
//  ExandableTableHeaderView.swift
//
//  Created by Mostafa Berg on 05/10/16.
//

import UIKit
import CoreFoundation

let animationDuration = 0.2 //0.2 seconds

class ExpandableTableHeaderView: UITableViewHeaderFooterView {

    //Mark: Private variables
    private var tapGestureRecognizer : UITapGestureRecognizer?
    private var isExpandable         : Bool = false
    var isOpen               : Bool = true
    var delegate             : ExpandableTableHeaderViewDelegate?
    var section              : Int

    //Mark: Outlets
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!

    //Mark: UIView methods
    required init?(coder aDecoder: NSCoder) {
        section = -1
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(_:)))
        addGestureRecognizer(tapGestureRecognizer!)
    }
    
    func updateContents(withTitle aTitle: String?, andIsExpandable anIsExpandableValue: Bool) {
        title.text = aTitle
        isExpandable = anIsExpandableValue
        icon.isHidden = !anIsExpandableValue
    }

    //MARK: Implementation
    @objc func handleSingleTap(_ sender: UITapGestureRecognizer) {
        if isExpandable {
            toggle()
        }
    }
    
    func toggle(force: Bool = false) {
        if force || delegate == nil || delegate!.canCollapse(forSection: section) {
            isOpen = !isOpen
            flipExpandArrow(withDuration: animationDuration)
            if isOpen {
                delegate?.didExpandHeaderView(forSection: section)
            } else {
                delegate?.didCollapseHeaderView(forSection: section)
            }
        }
    }
    
    func flipExpandArrow(withDuration aDuration: Double) {
        //Get current rotation value
        let currentAngle = icon.layer.value(forKeyPath: "transform.rotation.z")
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fillMode = CAMediaTimingFillMode.forwards
        rotateAnimation.fromValue = currentAngle

        if isOpen {
            let rotation = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
            icon.layer.transform = rotation
        } else {
            let rotation = CATransform3DMakeRotation(0.0, 0, 0, 1)
            icon.layer.transform = rotation
        }
        
        rotateAnimation.duration = aDuration
        icon.layer.add(rotateAnimation, forKey: nil)
    }
}
