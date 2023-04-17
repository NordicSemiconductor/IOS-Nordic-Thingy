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
//  MainNavigationViewController.swift
//
//  Created by Jiajun Qiu on 03/11/2016.
//

import Foundation
import UIKit
import IOSThingyLibrary

class MainNavigationViewController: UINavigationController, ThingyPeripheralDelegate {
    
    private weak var targetManager: ThingyManager!
    private var currentViewIdentifier: String?
    private var tmpURL: URL?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = UIColor.dynamicColor(light: .nordicBlue, dark: .black)
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        } else {
            // Fallback on earlier versions
        }
    }

    public func thingyManager() -> ThingyManager {
        return targetManager
    }

    public func setThingyManager(_ aManager: ThingyManager) {
        targetManager = aManager
        
        if let currentViewController = topViewController as? HasThingyTarget {
            currentViewController.thingyManager = aManager
        }
    }
    
    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        // Propagate the event to top view controller
        if let currentViewController = topViewController as? HasThingyTarget {
            if peripheral.isEqual(currentViewController.targetPeripheral) {
                currentViewController.thingyPeripheral(peripheral, didChangeStateTo: state)
            }
        }
    }
    
    // Call this method when active paripheral has changed
    func setTargetPeripheral(_ peripheral: ThingyPeripheral?) {
        if topViewController?.isViewLoaded == true {
            if let hasThingy = topViewController as? HasThingyTarget {
                hasThingy.setTargetPeripheral(peripheral, andManager: targetManager)
            }
        }
    }

    // We will always default to show the environment view
    // If this changes, this is an easier way to do so
    public func showDefaultView() {
        showEnvironmentView()
    }

    public func showEmptyView() {
        showRootViewSegue(withIdentifier: "show_empty_view")
    }
    
    public func showDFUView(withURL url: URL? = nil) {
        if let url = url, currentViewIdentifier == "show_dfu_view" {
            let dfuViewController = children.first as? DFUViewController
            dfuViewController?.onFileSelected(withURL: url)
        } else {
            // Save the URL, it will be used in prepare(for segue, sender) method
            tmpURL = url
        }
        showRootViewSegue(withIdentifier: "show_dfu_view")
    }
    
    public func showAboutView() {
        showRootViewSegue(withIdentifier: "show_about_view")
    }
    
    public func showEnvironmentView() {
        showRootViewSegue(withIdentifier: "show_environment_view")
    }
    
    public func showUIView() {
        showRootViewSegue(withIdentifier: "show_ui_view")
    }
    
    public func showMotionView() {
        showRootViewSegue(withIdentifier: "show_motion_view")
    }
    
    public func showCloudView() {
        showRootViewSegue(withIdentifier: "show_cloud_view")
    }

    public func showSoundView() {
        showRootViewSegue(withIdentifier: "show_sound_view")
    }
    
    public func showConfigurationView() {
        showRootViewSegue(withIdentifier: "show_configuration_view")
    }

    public func showInitialNFCConfigurationView() {
        showRootViewSegue(withIdentifier: "show_initial_nfc_configuration_view")
    }

    public func showInitialConfigurationView() {
        showRootViewSegue(withIdentifier: "show_initial_configuration_view")
    }
    
    private func showRootViewSegue(withIdentifier anIdentifier: String) {
        if anIdentifier != currentViewIdentifier {
            performSegue(withIdentifier: anIdentifier, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_initial_configuration_view" || segue.identifier == "show_initial_nfc_configuration_view" {
            let navigationViewController = segue.destination as! ThingyCreatorNavigationController
            navigationViewController.newThingyDelegate = revealViewController() as? NewThingyDelegate
            navigationViewController.setTargetPeripheral(nil, andManager: targetManager)
        } else {
            if let tmpURL = tmpURL, segue.identifier == "show_dfu_view" {
                let viewController = segue.destination as! DFUViewController
                viewController.onFileSelected(withURL: tmpURL)
                self.tmpURL = nil
            }
            currentViewIdentifier = segue.identifier
        }
    }
}
