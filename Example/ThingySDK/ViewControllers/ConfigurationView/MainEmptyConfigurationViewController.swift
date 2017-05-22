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
//  MainEmptyConfigurationViewController.swift
//
//  Created by Mostafa Berg on 25/11/2016.
//

import UIKit
import IOSThingyLibrary

class MainEmptyConfigurationViewController: SwipableViewController {

    @IBOutlet weak var addThingyButton: UIButton!
    
    //MARK: - Outlets
    @IBAction func menuButtontapped(_ sender: AnyObject) {
        toggleRevealView()
    }
    @IBAction func addButtonPressed(_ sender: Any) {
        addThingyButton.layer.shadowRadius = 3
    }
    @IBAction func addButtonReleased(_ sender: Any) {
        // Released outside
        addThingyButton.layer.shadowRadius = 4
    }
    @IBAction func addButtonTapped(_ sender: AnyObject) {
        // Released inside
        addThingyButton.layer.shadowRadius = 4
        addButonTappedHandler()
    }
    @IBAction func linkTapped(_ sender: UIButton) {
        let url = URL(string: "https://www.nordicsemi.com/thingy")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    private var mainNavigationContorller: MainNavigationViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addThingyButton.layer.shadowOffset = CGSize.zero
        addThingyButton.layer.shadowColor = UIColor.darkGray.cgColor
        addThingyButton.layer.shadowOpacity = 1
        addThingyButton.layer.shadowRadius = 4
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mainNavigationContorller = navigationController as! MainNavigationViewController
        
        guard thingyManager!.persistentPeripheralIdentifiers() != nil else {
            return
        }
        
        if thingyManager!.persistentPeripheralIdentifiers()!.count > 0 {
            //We have stored peripherals
            mainNavigationContorller.showDefaultView()
        }
    }
    
    //MARK: - Implementation
    private func addButonTappedHandler() {
        mainNavigationContorller.showInitialConfigurationView()
    }
}
