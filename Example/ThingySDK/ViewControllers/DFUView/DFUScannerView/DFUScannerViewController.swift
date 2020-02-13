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
//  DFUScannerViewController.swift
//
//  Created by Mostafa Berg on 28/11/2016.
//
//

import UIKit
import IOSThingyLibrary

class DFUScannerViewController: ThingyViewController, UITableViewDelegate, UITableViewDataSource, ThingyManagerDelegate {

    //MARK: - Outlets and actions
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var scannedPeripheralsTableView: UITableView!
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        let parentView = self.parent as! ThingyNavigationController
        parentView.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - View properties
    private var discoveredThingies = [ThingyPeripheral]()
    private var originalManagerDelegate: ThingyManagerDelegate!
    
    //MARK: - UIViewController methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originalManagerDelegate = thingyManager?.delegate
        thingyManager?.delegate = self
        
        if let connectedThingies = thingyManager?.activePeripherals() {
            discoveredThingies.append(contentsOf: connectedThingies)
        }
        
        scannedPeripheralsTableView.isHidden = discoveredThingies.isEmpty
        
        // Show activity indicator
        var style = UIActivityIndicatorView.Style.gray
        if #available(iOS 13.0, *) {
            style = UIActivityIndicatorView.Style.medium
        }
        let activityIndicatorView = UIActivityIndicatorView(style: style)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        thingyManager?.discoverDevices(includingInDfuState: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        thingyManager?.stopScan()
        thingyManager?.delegate = originalManagerDelegate
        super.viewWillAppear(animated)
    }

    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectPeripheral(atIndexPath: indexPath)
    }
    
    //MARK: - UITAbleViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "ThingyDFUItemCell", for: indexPath)
        aCell.textLabel!.text = discoveredThingies[indexPath.row].name
        return aCell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredThingies.count
    }
    
    //MARK: - ThingyManagerDelegate
    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        if state == .unavailable {
            print("Thingy Manager is unavaiable")
        }
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        self.thingyManager(manager, didDiscoverPeripheral: peripheral, withPairingCode: nil)
    }

    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode: String?) {
        // This should not be needed, scanning is done without duplicates
        guard discoveredThingies.contains(peripheral) == false else {
            //Ignore duplicates
            return
        }
        hideEmptyView()
        discoveredThingies.append(peripheral)
        scannedPeripheralsTableView.reloadData()
        scannedPeripheralsTableView.isHidden = false
    }
    
    //MARK: - Private methods
    private func didSelectPeripheral(atIndexPath anIndexPath: IndexPath) {
        let targetPeripheral = discoveredThingies[anIndexPath.row]
        let parentController = parent as! ThingyCreatorNavigationController
        parentController.newThingyDelegate?.targetPeripheral = targetPeripheral
        parentController.dismiss(animated: true, completion: nil)
    }
    
    private func hideEmptyView() {
        if emptyView.alpha == 1 {
            UIView.animate(withDuration: 0.5) {
                self.emptyView.alpha = 0
            }
        }
    }
}
