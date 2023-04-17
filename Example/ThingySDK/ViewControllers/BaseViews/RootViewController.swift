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
//  RootViewController.swift
//
//  Created by Mostafa Berg on 05/10/16.
//

import UIKit
import IOSThingyLibrary
import SWRevealViewController

class RootViewController: SWRevealViewController, ThingyManagerDelegate, ThingyPeripheralDelegate, NewThingyDelegate {

    private var menuViewController       : MainMenuViewController!
    private var mainNavigationController : MainNavigationViewController!
    private var alert                    : UIAlertController?
    
    private lazy var thingyManager = ThingyManager(withDelegate: self)
    
    //MARK: - NewThingyDelegate properties
    
    var targetPeripheral: ThingyPeripheral? {
        didSet {
            // When a new peripheral has been added, set it as a current one and update its state
            targetPeripheral?.delegate = self
            mainNavigationController.setTargetPeripheral(targetPeripheral)            
        }
    }
    
    //MARK: - UI View Controller methods    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the rear view width to almost whole screen width
        updateRearViewSize(targetSize: UIScreen.main.bounds.size)
        rearViewRevealDisplacement = 0
        
        menuViewController = (rearViewController as! MainMenuViewController)
        menuViewController.newThingyDelegate = self
        mainNavigationController = (frontViewController as! MainNavigationViewController)
        
        menuViewController!.setThingyManager(thingyManager)
        mainNavigationController!.setThingyManager(thingyManager)
    }

    override func viewWillTransition(to size: CGSize, with coordinator:
        UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateRearViewSize(targetSize: size)
    }

    //MARK: - Thingy Manager Delegate
    
    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        switch state {
            case .idle:
                // In idle state devices has been already read from database
                assignSelfAsPeripheralsDelegate()
            default:
                break
        }
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        // No-op.
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode: String?) {
        // No-op.
    }
    
    // MARK: - Thingy Peripheral Delegate
    
    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        if alert == nil && state != .ready && state != .disconnected && state != .dfuInProgress {
            let newAlert = UIAlertController(title: "Status", message: "Please wait...", preferredStyle: .alert)
            alert = newAlert
            if state != .disconnecting {
                newAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak thingyManager] (action) in
                    newAlert.message = "Cancelling connection..."
                    thingyManager?.disconnect(fromDevice: peripheral)
                }))
            }
            present(newAlert, animated: true)
        }
        switch state {
        case .ready:
            alert?.message = "Done"
            alert?.dismiss(animated: true)
            alert = nil
        case .disconnected:
            alert?.message = "Disconnected"
            alert?.dismiss(animated: true) { [weak self] in
                // The "Empty view" can't be shown until the alert controller is shown, so show it here.
                if self?.thingyManager.hasStoredPeripherals() == false {
                    self?.mainNavigationController.showEmptyView()
                }
            }
            alert = nil
        case .connecting:
            alert?.message = "Connecting..."
        case .connected:
            alert?.message = "Connected"
        case .discoveringServices:
            alert?.message = "Discovering services..."
        case .discoveringCharacteristics:
            alert?.message = "Reading device configuration..."
        case .disconnecting:
            alert?.message = "Disconnecting..."
        case .failedToConnect:
            alert?.message = "Failed to connect"
            alert?.dismiss(animated: true)
            alert = nil
        case .notSupported:
            alert?.message = "Device not supported"
            alert?.dismiss(animated: true)
            alert = nil
        case .unavailable:
            alert?.message = "Device unavailable"
            alert?.dismiss(animated: true)
            alert = nil
        default:
            break
        }
        
        menuViewController.thingyPeripheral(peripheral, didChangeStateTo: state)
        mainNavigationController.thingyPeripheral(peripheral, didChangeStateTo: state)
    }
    
    // MARK: - Private
    
    private func assignSelfAsPeripheralsDelegate() {
        guard let storedPeripherals = thingyManager.storedPeripherals() else { return }
        storedPeripherals.forEach { peripheral in
            peripheral.delegate = self
        }
    }
    
    private func updateRearViewSize(targetSize : CGSize) {
        rearViewRevealOverdraw = 0
        switch (UIDevice.current.userInterfaceIdiom) {
            case .pad:
                rearViewRevealWidth = targetSize.width * 0.35
            default:
                if (targetSize.width > targetSize.height) {
                    rearViewRevealWidth = targetSize.width * 0.4 // 0.35 -> 0.4 as notch takes some space as well
                } else {
                    rearViewRevealWidth = targetSize.width * 0.85
                }
        }
    }
    
}
