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
//  ThingyInitialConfigurationViewController.swift
//
//  Created by Mostafa Berg on 13/10/16.
//

import UIKit
import IOSThingyLibrary

class ThingyInitialConfigurationViewController: ThingyViewController, UITableViewDataSource, UITableViewDelegate, ThingyManagerDelegate {

    //MARK: - Outlets and actions
    @IBOutlet weak var configurationMenuTable: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        saveUserConfiguration()
    }

    //MARK: - Properties
    private var settingsHasBeenSaved : Bool = false
    private var newThingyName        : String?
    private var loadingView          : UIAlertController?
    
    //MARK: - Menu Table properties
    private let menuSectionItems = [
        "Basic configuration"
    ]

    private let menuConfigurationIcons = [
        [#imageLiteral(resourceName: "ic_developer_board_24pt")]
    ]
    private let menuConfigurationItems = [
        ["Device name"]
    ]
    
    //MARK: - UIViewDelegate
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        thingyManager!.delegate = self
        // Wait until Thingy is ready
        saveButton.isEnabled = false
        showLoadingAlert() //Show a blocking alert until Thingy services are discovered
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingsHasBeenSaved == false {
            // If the user hasen't saved the peripheral, it'll
            // disconnect at this stage since it's not configured
            // and should resume advertising
            if targetPeripheral != nil {
                thingyManager!.disconnect(fromDevice: targetPeripheral!)
            }
        }
    }
    
    //MARK: - Implementation
    override func setTargetPeripheral(_ aTargetPeripheral: ThingyPeripheral?, andManager aManager: ThingyManager?) {
        super.setTargetPeripheral(aTargetPeripheral, andManager: aManager)
        targetPeripheral?.delegate = self
    }
    
    private func showLoadingAlert() {
        loadingView = UIAlertController(title: "Status", message: "Reading device configuration...", preferredStyle: .alert)
        loadingView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            action.isEnabled = false
            self.loadingView!.title   = "Aborting"
            self.loadingView!.message = "Cancelling connection..."
            self.thingyManager!.disconnect(fromDevice: self.targetPeripheral!)
        }))
        self.navigationController!.present(loadingView!, animated: false) {
            self.targetPeripheral!.discoverServices()
        }
    }

    private func saveUserConfiguration() {
        // Write Name characteristics and save Thingy in local DB
        saveButton.isEnabled = false
        
        if newThingyName == targetPeripheral!.name {
            //Set this Thingy as the active one if we have no others
            thingyManager!.addPeripheral(targetPeripheral!)
            userConfigurationSaveCompleted()
        } else {
            loadingView = UIAlertController(title: "Configuring Thingy", message: "Sending name...", preferredStyle: .alert)
            loadingView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                action.isEnabled = false
                self.loadingView!.title   = "Aborting"
                self.loadingView!.message = "Cancelling connection..."
                self.thingyManager!.disconnect(fromDevice: self.targetPeripheral!)
            }))
            present(loadingView!, animated: true) {
                self.targetPeripheral!.set(name: self.newThingyName!, withCompletionHandler: { (success) -> (Void) in
                    if success {
                        self.loadingView!.message = "Done!"
                        self.loadingView!.dismiss(animated: true) {
                            //Set this Thingy as the active one if we have no others
                            self.thingyManager!.addPeripheral(self.targetPeripheral!)
                            self.userConfigurationSaveCompleted()
                        }
                    } else {
                        self.loadingView!.message = "Failed!"
                        self.loadingView!.dismiss(animated: true)
                        print("Couldn't write name!")
                    }
                })
            }
        }
    }

    private func userConfigurationSaveCompleted() {
        settingsHasBeenSaved = true
        let parentController = parent as! ThingyCreatorNavigationController
        parentController.newThingyDelegate?.targetPeripheral = targetPeripheral
        parentController.dismiss(animated: true)
    }
    
    private func userEnteredNewDeviceName(name: String) {
        newThingyName = name
        configurationMenuTable.reloadData()
    }
    
    private func defaultConfigurationForIndexPath(indexPath: IndexPath) -> String {
        if indexPath.section == 0 && indexPath.row == 0 {
            return newThingyName ?? "Loading..."
        }
        return "Nil"
    }

    //MARK: - UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            //Modifying name
            PopupHelper.showTextInput(withTitle: "New name", subtitle: "Max 10 bytes", value: newThingyName, andPlaceholderValue: "My Thingy",
                                      validator: { (value: String?) -> (Bool) in return value != nil ? value!.utf8.count <= 10 : false },
                                      completion: { (value) -> (Void) in self.userEnteredNewDeviceName(name: value) })
        }
    }

    //MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuConfigurationItems[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "ThingyConfigurationCell", for: indexPath)
        
        let configurationTitle = menuConfigurationItems[indexPath.section][indexPath.row]
        let configurationValue = defaultConfigurationForIndexPath(indexPath: indexPath)
        let configurationIcon  = menuConfigurationIcons[indexPath.section][indexPath.row]
        
        aCell.textLabel?.text = configurationTitle
        aCell.imageView?.image = configurationIcon
        aCell.detailTextLabel?.text = configurationValue
        return aCell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 1 {
            return UIScreen.main.bounds.width
        } else {
            return tableView.rowHeight
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return menuSectionItems.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menuSectionItems[section]
    }
    
    //MARK: - ThingyManagerDelegate
    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        if state == .unavailable {
            saveButton.isEnabled = false
        }
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        thingyManager(manager, didDiscoverPeripheral: peripheral, withPairingCode: nil)
    }

    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode: String?) {
    }

    //MARK: - ThingyPeripheralDelegate
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        switch (state) {
        case .ready:
            loadingView!.message = "Done!"
            loadingView!.dismiss(animated: true) {
                self.saveButton.isEnabled = true
            }
            newThingyName = peripheral.name
            configurationMenuTable.reloadData()
        case .disconnecting:
            loadingView!.message = "Disconnecting..."
        case .disconnected:
            loadingView!.message = "Disconnected"
            loadingView!.dismiss(animated: true)
        case .notSupported:
            configurationMenuTable.allowsSelection = false
            loadingView!.message = "Device not supported"
            loadingView!.dismiss(animated: true)
        default:
            break
        }
    }
}
