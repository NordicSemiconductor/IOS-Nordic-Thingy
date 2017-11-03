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
//  ThingyConfigurationViewController.swift
//
//  Created by Mostafa Berg on 06/10/16.
//

import UIKit
import IOSThingyLibrary
import CoreLocation

class ThingyConfigurationViewController: SwipableViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate {
        
    //MARK: - Outlets and actions
    @IBOutlet weak var configurationMenuTable: UITableView!
    @IBAction func menuButtonTapped(_ sender: Any) {
        toggleRevealView()
    }
    var progressIndicator: UIActivityIndicatorView!
    
    //MARK: - Configuration Properties
    var configName                         : String = ""
    var configFirmwareVersion              : String = ""
    var configAdvertisingInterval          : UInt16 = 0
    var configAdvertisingTimeout           : UInt8  = 0
    var configConnectionMin                : UInt16 = 0
    var configConnectionMax                : UInt16 = 0
    var configConnectionSlaveLatency       : UInt16 = 0
    var configConnectionSupervisionTimeout : UInt16 = 0
    var configEddystoneUrl                 : URL?

    //MARK: - Menu Table properties
    private let menuSectionItems = [
        "Name",
        "Advertising",
        "Connection",
        "Beacon",
        "Firmware Version"
    ]
    
    private let menuConfigurationIcons = [
        [#imageLiteral(resourceName: "ic_developer_board_24pt")],
        [#imageLiteral(resourceName: "ic_timer_24pt"), #imageLiteral(resourceName: "ic_timer_24pt")],
        [#imageLiteral(resourceName: "ic_timer_24pt"),#imageLiteral(resourceName: "ic_timer_24pt"),#imageLiteral(resourceName: "ic_timer_24pt"),#imageLiteral(resourceName: "ic_timer_24pt")],
        [#imageLiteral(resourceName: "ic_http_24pt")],
        [#imageLiteral(resourceName: "ic_dfu_24pt")]
    ]

    private let menuConfigurationItems = [
        ["Name"],
        ["Interval", "Timeout"],
        ["Min. interval", "Max. interval", "Slave latency", "Supervision timeout"],
        ["Eddystone URL"],
        ["Update firmware"]
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        // Show activity indicator
        progressIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        progressIndicator.hidesWhenStopped = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: progressIndicator)
    }
    
    //MARK: - ThingyPeripheralDelegate
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        navigationItem.title = peripheral.name + " Configuration"
        configName = peripheral.name
        configurationMenuTable.reloadData()
        if state == .ready {
            readCurrentConfigurations(fromThingy: peripheral)
        }
    }
    
    //MARK: - Navigation and performSegue
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //MARK: - Implementation
    private func showDFUAlert() {
        guard targetPeripheral != nil && targetPeripheral!.state == .ready else {
            let dfuAlert = UIAlertController(title: "Firmware Update", message: "You are no longer connected to the Thingy.", preferredStyle: .alert)
            dfuAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(dfuAlert, animated: true)
            return
        }
        
        var newerVersionAvailable = false
        if configFirmwareVersion.versionToInt().lexicographicallyPrecedes(kCurrentDfuVersion.versionToInt()) {
           newerVersionAvailable = true
        }
        let message = newerVersionAvailable ? "Newer firmware version (\(kCurrentDfuVersion)) is available. Do you want to update your Thingy?" : "Your device is up to date."
        let dfuAlert = UIAlertController(title: "Firmware Update", message: message, preferredStyle: .alert)
        if newerVersionAvailable {
            dfuAlert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action) in
                let mainNavigationController = self.navigationController as! MainNavigationViewController
                mainNavigationController.showDFUView()
            }))
            dfuAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        } else {
            dfuAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
        }
        present(dfuAlert, animated: true)
    }

    private func readCurrentConfigurations(fromThingy aThingy: ThingyPeripheral) {
        configFirmwareVersion = aThingy.readFirmwareVersion() ?? "0.0.0"
        configName = aThingy.readName() ?? "Thingy"
        
        let advertisingParams = aThingy.readAdvertisingParameters()
        if let advertisingParams = advertisingParams {
            configAdvertisingInterval = advertisingParams.interval
            configAdvertisingTimeout = advertisingParams.timeout
        }
        
        let connectionParams = aThingy.readConnectionParameters()
        if let connectionParams = connectionParams {
            configConnectionMin = connectionParams.minimumInterval
            configConnectionMax = connectionParams.maximumInterval
            configConnectionSlaveLatency = connectionParams.slaveLatency
            configConnectionSupervisionTimeout = connectionParams.supervisionTimeout
        }

        configEddystoneUrl = aThingy.readEddystoneUrl()
    }
    
    private func defaultConfigurationFor(indexPath: IndexPath) -> String? {
        switch indexPath.section {
            case 0:
                switch indexPath.row {
                    case 0:
                        return configName
                    default:
                        return "Nil"
                }
            case 1:
                switch indexPath.row {
                    case 0:
                        if configAdvertisingInterval == UInt16.max {
                            return "Saving..."  // Using max as a saving flag
                        } else {
                            return "\(Float(configAdvertisingInterval) * 0.625) ms"
                        }
                    case 1:
                        if configAdvertisingTimeout == UInt8.max {
                           return "Saving..." // Using max as a saving flag
                        } else {
                            return "\(configAdvertisingTimeout) s"
                        }
                    default:
                        return "Nil"
                }
            case 2:
                switch indexPath.row {
                    case 0:
                        if configConnectionMin == UInt16.max {
                            return "Saving..." // Using Max as a saving flag
                        } else {
                            return "\(Float(configConnectionMin) * 1.25) ms"
                        }
                    
                    case 1:
                        if configConnectionMax == UInt16.max {
                            return "Saving..."
                        } else {
                            return "\(Float(configConnectionMax) * 1.25) ms"
                        }
                    
                    case 2:
                        if configConnectionSlaveLatency == UInt16.max {
                            return "Saving..."
                        } else {
                            return "\(configConnectionSlaveLatency)"
                        }
                    case 3:
                        if configConnectionSupervisionTimeout == UInt16.max {
                            return "Saving..."
                        } else {
                            return "\(Int(configConnectionSupervisionTimeout) * 10) ms"
                        }
                    
                    default:
                        return "Nil"
                }
            case 3:
                switch indexPath.row {
                case 0:
                    if configEddystoneUrl == nil { // Nil used as disabled
                        return "Disabled"
                    } else if configEddystoneUrl?.absoluteString == "http://saving.config" { // Predefined domain used as a saving flag
                        return "Saving..."
                    } else {
                        return configEddystoneUrl?.absoluteString
                    }
                default:
                    return "Nil"
                }
            case 4:
                switch indexPath.row {
                case 0:
                    return configFirmwareVersion
                default:
                    return "Nil"
            }
            default:
                return "Unknown Configuration"
        }
    }
    
    func indicateProgress() {
        progressIndicator.startAnimating()
    }
    
    func indicateCompletion() {
        //Add a delay to make indicator visible
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.progressIndicator.stopAnimating()
        }
    }

    //MARK: - UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            PopupHelper.showTextInput(withTitle: "New name", subtitle: "Max 10 bytes", value: configName, andPlaceholderValue: "My Thingy",
                                      validator: { (value: String?) -> (Bool) in return value != nil && value!.utf8.count <= 10 },
                                      completion: {
                                        value in
                                        let originalValue = self.configName
                                        self.indicateProgress()
                                        self.configName = "Saving..."
                                        self.configurationMenuTable.reloadData()
                                        self.targetPeripheral!.set(name: value, withCompletionHandler: { (success) -> (Void) in
                                            if success {
                                                self.configName = value
                                                self.navigationItem.title = value + " Configuration"
                                            } else {
                                                self.configName = originalValue
                                            }
                                            self.indicateCompletion()
                                            self.configurationMenuTable.reloadData()
                                        })
                                      })
        case 1:
            switch indexPath.row {
            case 0: // Advertising interval
                PopupHelper.showIntervalInput(withTitle: "Advertising interval",
                                              subtitle: "Range: 20 ms - 5000 ms\nin units of 0.625 ms\n(acceptable values: 32 - 8000,\ni.e. 160 -> 100 ms)",
                                              value: Int(configAdvertisingInterval), availableRange: NSMakeRange(20, 8000 - 20 + 1), unitInMs: 0.625,
                                              andPlaceholderValue: "Interval",
                                              completion: {
                                                (value:Int) -> (Void) in
                                                self.indicateProgress()
                                                let originalInterval = self.configAdvertisingInterval
                                                self.configAdvertisingInterval = UInt16.max //use max value as a flag to show "Saving..."
                                                self.configurationMenuTable.reloadData()
                                                self.targetPeripheral!.setAdvertisingParameters(interval: UInt16(value), timeout: self.configAdvertisingTimeout, withCompletionHandler: { (success) -> (Void) in
                                                    if success {
                                                        self.configAdvertisingInterval = UInt16(value)
                                                    } else {
                                                        self.configAdvertisingInterval = originalInterval
                                                    }
                                                    self.indicateCompletion()
                                                    self.configurationMenuTable.reloadData()
                                                })
                                              })
            case 1: // Advertising timeout
                PopupHelper.showIntervalInput(withTitle: "Advertising timeout", subtitle: "Range: 0 s - 180 s\n(0 disables timeout)",
                                              value: Int(configAdvertisingTimeout), availableRange: NSMakeRange(0, 180 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Timeout",
                                              completion: {
                                                (value:Int) -> (Void) in
                                                self.indicateProgress()
                                                let originalTimeout = self.configAdvertisingTimeout
                                                self.configAdvertisingTimeout = UInt8.max //use max value as a flag to show "Saving..."
                                                self.configurationMenuTable.reloadData()
                                                self.targetPeripheral!.setAdvertisingParameters(interval: self.configAdvertisingInterval, timeout: UInt8(value), withCompletionHandler: { (success) -> (Void) in
                                                    if success {
                                                        self.configAdvertisingTimeout = UInt8(value)
                                                    } else {
                                                        self.configAdvertisingTimeout = originalTimeout
                                                    }
                                                    self.indicateCompletion()
                                                    self.configurationMenuTable.reloadData()
                                                })
                                              })
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0: // Min connection interval
                PopupHelper.showIntervalInput(withTitle: "Min interval",
                                              subtitle: "Range: 7.5 ms -> 4000 ms\nin units of 1.25 ms\n(input range: 6 -> 3200 units)\nConstraints: min_interval <= max_interval\ncurrent max interval: \(Float(self.configConnectionMax) * 1.25) ms",
                                              value: Int(configConnectionMin), availableRange: NSMakeRange(6, Int(self.configConnectionMax) - 6 + 1), unitInMs: 1.25,
                                              andPlaceholderValue: "Min Connection Interval",
                                              completion: {
                                                (value:Int) -> (Void) in
                                                self.indicateProgress()
                                                let originalValue = self.configConnectionMin
                                                self.configConnectionMin = UInt16.max
                                                self.configurationMenuTable.reloadData()
                                                self.targetPeripheral!.setConnectionParameters(minimumInterval: UInt16(value), maximumInterval: self.configConnectionMax, slaveLatency: self.configConnectionSlaveLatency, supervisionTimeout: self.configConnectionSupervisionTimeout, withCompletionHandler: { (success) -> (Void) in
                                                    if success {
                                                        self.configConnectionMin = UInt16(value)
                                                    } else {
                                                        self.configConnectionMin = originalValue
                                                    }
                                                    self.indicateCompletion()
                                                    self.configurationMenuTable.reloadData()
                                                })
                                              })
            case 1: // Max connection interval
                //24 units is the smallest possible value on iOS (30 ms).
                let minVal = Int(max(self.configConnectionMin, 24))
                //3200 units is the max value possible on the Thingy (4000 ms).
                let maxVal = min(Int(self.configConnectionSupervisionTimeout * 4 / (self.configConnectionSlaveLatency + 1)) , 3200)
                PopupHelper.showIntervalInput(withTitle: "Max interval",
                                              subtitle: "Range: 7.5 ms -> 4000 ms\nin units of 1.25 ms\n(input range: 6 -> 3200 units)\nCurrent value constraints:\n\(minVal) to \(maxVal)",
                                              value: Int(configConnectionMax), availableRange: NSMakeRange(minVal, maxVal - minVal + 1), unitInMs: 1.25,
                                              andPlaceholderValue: "Max Connection Interval",
                                              completion: {
                                                (value:Int) -> (Void) in
                                                self.indicateProgress()
                                                let originalValue = self.configConnectionMax
                                                self.configConnectionMax = UInt16.max
                                                self.configurationMenuTable.reloadData()
                                                self.targetPeripheral!.setConnectionParameters(minimumInterval: self.configConnectionMin, maximumInterval: UInt16(value), slaveLatency: self.configConnectionSlaveLatency, supervisionTimeout: self.configConnectionSupervisionTimeout, withCompletionHandler: { (success) -> (Void) in
                                                    if success {
                                                        self.configConnectionMax = UInt16(value)
                                                    } else {
                                                        self.configConnectionMax = originalValue
                                                    }
                                                    self.indicateCompletion()
                                                    self.configurationMenuTable.reloadData()
                                                })
                                              })
            case 2: // Slave latency
                let maxLatency = min(499, (self.configConnectionSupervisionTimeout * 4 / self.configConnectionMax) - 1) //499 is the Thingy max vaule
                PopupHelper.showIntervalInput(withTitle: "Slave latency", subtitle: "(input range: 0 - 499)\nCurrent value constraints:\n0 to \(maxLatency)",
                                              value: Int(configConnectionSlaveLatency), availableRange: NSMakeRange(0, Int(maxLatency) + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Slave Latency",
                                              completion: {
                                                (value:Int) -> (Void) in
                                                self.indicateProgress()
                                                let originalValue = self.configConnectionSlaveLatency
                                                self.configConnectionSlaveLatency = UInt16.max
                                                self.configurationMenuTable.reloadData()
                                                self.targetPeripheral!.setConnectionParameters(minimumInterval: self.configConnectionMin, maximumInterval: self.configConnectionMax, slaveLatency: UInt16(value), supervisionTimeout: self.configConnectionSupervisionTimeout, withCompletionHandler: { (success) -> (Void) in
                                                    if success {
                                                        self.configConnectionSlaveLatency = UInt16(value)
                                                    } else {
                                                        self.configConnectionSlaveLatency = originalValue
                                                    }
                                                    self.indicateCompletion()
                                                    self.configurationMenuTable.reloadData()
                                                })
                                              })
            case 3: // Supervision timeout
                let minValue = max(10, (1 + self.configConnectionSlaveLatency) * self.configConnectionMax / 4) + 1
                PopupHelper.showIntervalInput(withTitle: "Supervision timeout",
                                              subtitle: "Range: 100 ms - 32000 ms\nin units of 10 ms\n(input range: 10 - 3200)\nCurrent value constraints:\n\(minValue) to 3200",
                                              value: Int(configConnectionSupervisionTimeout), availableRange: NSMakeRange(Int(minValue), 3200 - Int(minValue) + 1), unitInMs: 10,
                                              andPlaceholderValue: "Supervision timeout",
                                              completion: {
                                                (value:Int) -> (Void) in
                                                self.indicateProgress()
                                                let originalValue = self.configConnectionSupervisionTimeout
                                                self.configConnectionSupervisionTimeout = UInt16.max
                                                self.configurationMenuTable.reloadData()
                                                self.targetPeripheral!.setConnectionParameters(minimumInterval: self.configConnectionMin, maximumInterval: self.configConnectionMax, slaveLatency: self.configConnectionSlaveLatency, supervisionTimeout: UInt16(value), withCompletionHandler: { (success) -> (Void) in
                                                    if success {
                                                        self.configConnectionSupervisionTimeout = UInt16(value)
                                                    } else {
                                                        self.configConnectionSupervisionTimeout = originalValue
                                                    }
                                                    self.indicateCompletion()
                                                    self.configurationMenuTable.reloadData()
                                                })
                                              })
            default:
                break
            }
        case 3:
            PopupHelper.showEddystoneUrlInput(currentUrl: configEddystoneUrl, completion: { (url) -> (Void) in
                self.indicateProgress()
                let originalValue =  self.configEddystoneUrl
                self.configEddystoneUrl = URL(string: "http://saving.config")
                self.configurationMenuTable.reloadData()
                
                if url.absoluteString == "url.disabled" {
                    self.targetPeripheral!.disableEddystone(withCompletionHandler: { (success) -> (Void) in
                        if success {
                            self.configEddystoneUrl = nil
                        } else {
                            self.configEddystoneUrl = originalValue
                        }
                        self.indicateCompletion()
                        self.configurationMenuTable.reloadData()
                    })
                } else {
                    self.targetPeripheral!.set(eddystoneUrl: url, withCompletionHandler: { (success) -> (Void) in
                        if success {
                            self.configEddystoneUrl = url
                        } else {
                            self.configEddystoneUrl = originalValue
                        }
                        self.indicateCompletion()
                        self.configurationMenuTable.reloadData()
                    })
                }
            })
        case 4:
            showDFUAlert()
        default:
            break
        }
    }

    //MARK: - UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuConfigurationItems[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "ThingyConfigurationCell", for: indexPath) as! ThingyConfigurationItemTableViewCell
        
        let configurationTitle = menuConfigurationItems[indexPath.section][indexPath.row]
        let configurationValue = defaultConfigurationFor(indexPath: indexPath) ?? "Not set"
        let configurationIcon  = menuConfigurationIcons[indexPath.section][indexPath.row]

        aCell.populateWithConfigurationInfo(title: configurationTitle, value: configurationValue, andIcon: configurationIcon)
        return aCell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return menuSectionItems.count
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return menuSectionItems[section]
    }
}
