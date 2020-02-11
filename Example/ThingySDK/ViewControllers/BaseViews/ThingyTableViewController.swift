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
//  ThingyTableViewController.swift
//
//  Created by Aleksander Nowakowski on 30/11/2016.
//

import UIKit
import IOSThingyLibrary

class ThingyTableViewController: UITableViewController, HasThingyTarget {
    
    var thingyManager    : ThingyManager?
    var targetPeripheral : ThingyPeripheral? {
        willSet {
            if targetPeripheral != nil && targetPeripheral != newValue {
                targetPeripheralWillChange(old: targetPeripheral!, new: newValue)
            }
        }
        didSet {
            if isViewLoaded {
                targetPeripheralDidChange(new: targetPeripheral)
            }
        }
    }
    
    //MARK: UIViewController lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Notify the UI about the initial state when view is loaded
        if let peripheral = targetPeripheral {
            targetPeripheralDidChange(new: peripheral)
            thingyPeripheral(peripheral, didChangeStateTo: peripheral.state)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let targetPeripheral = targetPeripheral {
            targetPeripheralWillChange(old: targetPeripheral, new: nil)
        }
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Implementation
    final func setTargetPeripheral(_ aTargetPeripheral: ThingyPeripheral?, andManager aManager: ThingyManager?) {
        thingyManager = aManager
        targetPeripheral = aTargetPeripheral
        if isViewLoaded {
            if let peripheral = targetPeripheral {
                thingyPeripheral(peripheral, didChangeStateTo: peripheral.state)
            }
        }
    }
    
    /// This method is called every time the active Thingy device changes its state and, additionally,
    /// every time the view is loaded (in viewDidLoad()). This should enable notifications if required if state = .ready.
    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        // empty default implementation
    }
    
    func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        // empty default implementation
    }
    
    func targetPeripheralDidChange(new: ThingyPeripheral?) {
        // empty default implementation
    }
}
