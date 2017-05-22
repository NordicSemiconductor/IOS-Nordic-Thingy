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
//  CloudGuidePageViewController.swift
//  Created by Mostafa Berg on 10/04/2017.
//

import UIKit

class CloudGuidePageContentViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet weak var titleLabel   : UILabel!
    @IBOutlet weak var image        : UIImageView!
    @IBOutlet weak var contentLabel : UITextView!
    
    //MARK: - Properties
    var titleText                       : String!
    var imageNames                      : [String]!
    var bodyText                        : String!
    public private(set) var pageIndex   : Int!

    //MARK: - Implementation
    public func set(pageIndex: Int, title: String, body: String, andImageNames imageNames: [String]) {
        self.titleText = title
        self.bodyText = body
        self.imageNames = imageNames
        self.pageIndex = pageIndex
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = titleText
        contentLabel.text = bodyText
        
        if imageNames.count > 1 {
            image.animationImages = [UIImage]()
            for anImageName in imageNames {
                if let loadedImage = UIImage(named: anImageName) {
                    image.animationImages!.append(loadedImage)
                }
            }
            image.animationDuration = Double(image.animationImages!.count)
            image.startAnimating()
        } else if imageNames.count == 1 {
            image.animationImages = nil
            if let loadedImage = UIImage(named: imageNames[0]) {
                image.image = loadedImage
            }
        }
    }
}
