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
//  ThingyCreatorViewController.swift
//
//  Created by Mostafa Berg on 06/10/16.
//

import UIKit
import SWRevealViewController
import IOSThingyLibrary
import CoreNFC

class ThingyCreatorViewController: ThingyViewController, ThingyManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    //MARK: - Class properties
    private var discoveredThingies = [ThingyPeripheral]()
    private var loadingView: UIAlertController?

    //MARK: - Outlets and Actions
    @IBOutlet weak var scannedPeripheralsTableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var nfcToastViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var nfcToastView: UIView!
    @IBOutlet weak var nfcToastViewButton: UIButton!
    @IBAction func nfcButtonTapped(_ sender: Any) {
        cancelScanningAndPresentNFC()
    }
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        cancelScanning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nfcToastViewButton.layer.cornerRadius  = 5
        nfcToastViewButton.layer.masksToBounds = true
        
        //Hide NFC View until the iOS device confirms having the capability
        hideNFCView(animated: false)
        discoveredThingies.removeAll()
        scannedPeripheralsTableView.isHidden = discoveredThingies.isEmpty
        emptyView.alpha = discoveredThingies.isEmpty ? 1 : 0
        
        // Show activity indicator
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        thingyManager!.delegate = self
        thingyManager!.discoverDevices()
        if deviceHasNFCCapabilities() {
            showNFCView(animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        thingyManager!.stopScan()
        super.viewWillDisappear(animated)
    }
    
    //MARK: - ThingyManagerDelegate methods
    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        print("Thingy Manager state changed to: \(state)")
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode: String?) {
        hideEmptyView()
        discoveredThingies.append(peripheral)
        scannedPeripheralsTableView.reloadData()
        scannedPeripheralsTableView.isHidden = false
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        thingyManager(manager, didDiscoverPeripheral: peripheral, withPairingCode: nil)
    }

    //MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredThingies.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "ThingyItemCell", for: indexPath)
        aCell.textLabel!.text = discoveredThingies[indexPath.row].name
        return aCell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //When connecting stop the ability to start scanning until the state of the peripheral changes
        let targetPeripheral = discoveredThingies[indexPath.row]
        didSelectPeripheral(aPeripheral: targetPeripheral)
    }
    
    //MARK: - ThingyPeripheralDelegate
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        switch (state) {
        case .connected, .ready:
            loadingView!.dismiss(animated: false, completion: {
                self.performSegue(withIdentifier: "show_initial_configure_view", sender: peripheral)
            })
        case .disconnected:
            loadingView!.dismiss(animated: true, completion: nil)
        default:
            break
        }
    }

    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_initial_configure_view" {
            let targetPeripheral = sender as! ThingyPeripheral
            let configurationView = segue.destination as! ThingyInitialConfigurationViewController
            configurationView.setTargetPeripheral(targetPeripheral, andManager: thingyManager!)
        }
    }
    
    //MARK: - Implementation
    private func cancelScanningAndPresentNFC() {
        let parentView = self.parent as! ThingyNavigationController
        parentView.dismiss(animated: true, completion: nil)
        let rootView = parentView.presentingViewController as? RootViewController
        if let childViews = rootView?.childViewControllers {
            for aChildView in childViews {
                if aChildView is MainNavigationViewController {
                    let mainNavigationView = (aChildView as? MainNavigationViewController)
                    mainNavigationView?.showInitialNFCConfigurationView()
                    break
                }
            }
        }
    }

    private func cancelScanning() {
        let parentView = self.parent as! ThingyNavigationController
        parentView.dismiss(animated: true, completion: nil)
    }

    private func deviceHasNFCCapabilities() -> Bool {
        if #available(iOS 11.0, *) {
            return NFCNDEFReaderSession.readingAvailable
        } else {
            return false
        }
    }

    private func hideNFCView(animated: Bool) {
        if nfcToastViewTopConstraint.constant == 0 {
            nfcToastViewTopConstraint.constant = -nfcToastView.frame.size.height
            if animated {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                view.layoutIfNeeded()
            }
        }
    }
    
    private func showNFCView(animated: Bool) {
        if nfcToastViewTopConstraint.constant < 0 {
            self.nfcToastViewTopConstraint.constant = 0
            if animated {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                view.layoutIfNeeded()
            }
        }
    }
    private func didSelectPeripheral(aPeripheral: ThingyPeripheral) {
        //Stop scanning and cnonect to the selected peripheral
        thingyManager!.stopScan()
        connectToPeripheral(aPeripheral)
    }
    
    private func connectToPeripheral(_ aPeripheral: ThingyPeripheral) {
        loadingView = UIAlertController(title: "Status", message: "Connecting to the device...", preferredStyle: .alert)
        loadingView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            action.isEnabled = false
            self.loadingView!.title   = "Aborting"
            self.loadingView!.message = "Cancelling connection..."
            self.thingyManager!.disconnect(fromDevice: aPeripheral)
        }))
        present(loadingView!, animated: true) {
            aPeripheral.delegate = self
            self.thingyManager!.connect(toDevice: aPeripheral)
        }
    }
    
    private func hideEmptyView() {
        if emptyView.alpha == 1 {
            UIView.animate(withDuration: 0.5) {
                self.emptyView.alpha = 0
            }
        }
    }
}
