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
//  ThingyCloudViewController.swift
//
//  Created by Mostafa Berg on 03/04/2017.
//

import UIKit
import IOSThingyLibrary
import Keychain

class ThingyCloudViewController: SwipableTableViewController {

    //MARK: - Defaults
    private let defaults : UserDefaults!
    private let keyPressureEnabled      = "pressure_cloud_enabled"
    private let keyTemperatureEnabled   = "temperature_cloud_enabled"
    private let keyButtonEnabled        = "button_cloud_enabled"

    private var isNotifyingPressure: Bool = false {
        didSet {
            pressureToggle.isOn = isNotifyingPressure
        }
    }
    private var isNotifyingTemperature: Bool = false {
        didSet {
            temperatureToggle.isOn = isNotifyingTemperature
        }
    }
    private var isNotifyingButton: Bool = false {
        didSet {
            buttonStateToggle.isOn = isNotifyingButton
        }
    }
    
    private var totalUploadedBytes      : UInt32 = 0
    private var totalDownloadedBytes    : UInt32 = 0
    private var cloudToken              : String!
    private var buttonPressTime         : Date?
    private var endPoint                : String = "https://maker.ifttt.com/trigger/{0}/with/key/{1}"

    //MARK: - Outlets and actions
    @IBOutlet weak var temperatureToggle: UISwitch!
    @IBOutlet weak var pressureToggle: UISwitch!
    @IBOutlet weak var buttonStateToggle: UISwitch!
    @IBOutlet weak var temperatureValueLabel: UILabel!
    @IBOutlet weak var pressureValueLabel: UILabel!
    @IBOutlet weak var buttonStateValueLabel: UILabel!
    @IBOutlet weak var temperatureIntervalValueLabel: UILabel!
    @IBOutlet weak var pressureIntervalValueLabel: UILabel!
    @IBOutlet weak var totalUploadSizeLabel: UILabel!
    @IBOutlet weak var totalDownloadSizeLabel: UILabel!
    @IBOutlet weak var cloudTokenLabel: UILabel!

    @IBAction func menuButtonTapped(_ sender: Any) {
        toggleRevealView()
    }
    @IBAction func pressureToggleTapped(_ sender: Any) {
        handlePressuerToggleChange()
    }
    @IBAction func ButtonStateToggleTapped(_ sender: Any) {
        handleButtonStateTogglechange()
    }
    @IBAction func temperatureToggleTapped(_ sender: Any) {
        handleTemperatueToggleChange()
    }

    //MARK: - Implementation
    //MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if cloudToken == nil {
                tableView.deselectRow(at: indexPath, animated: true)
            UIAlertView(title: "Cloud Token not set", message: "To enable services, please set the cloud token first", delegate: nil, cancelButtonTitle: "Ok").show()
                return
            }
            if targetPeripheral?.basePeripheral.state != .connected {
                tableView.deselectRow(at: indexPath, animated: true)
                UIAlertView(title: "No Thingy connected", message: "Please connect to a Thingy to enable cloud services", delegate: nil, cancelButtonTitle: "Ok").show()
                return
            }

            switch indexPath.row {
            case 0:
                temperatureToggle.setOn(!temperatureToggle.isOn, animated: true)
                handleTemperatueToggleChange()
            case 1:
                pressureToggle.setOn(!pressureToggle.isOn, animated: true)
                handlePressuerToggleChange()
            case 2:
                buttonStateToggle.setOn(!buttonStateToggle.isOn, animated: true)
                handleButtonStateTogglechange()
            default:
                break
            }
            
        case 1:
            switch indexPath.row {
            case 0:
                guard self.targetPeripheral != nil else {
                    UIAlertView(title: "No Thingy connected", message: "Please connect to a Thingy to configure its token", delegate: nil, cancelButtonTitle: "Ok").show()
                    return
                }
                showTokenInputPopup()
            default:
                break
            }
            
        case 2:
            let tappedCell = tableView.cellForRow(at: indexPath)
            if let cellValue = tappedCell?.detailTextLabel?.text {
                if cellValue == "-" {
                    break
                } else {
                    UIPasteboard.general.string = cellValue
                }
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - UIVIewController Implementation
    required init?(coder aDecoder: NSCoder) {
        defaults = UserDefaults.standard
        defaults.register(defaults:
            [
                keyButtonEnabled        : false,
                keyPressureEnabled      : false,
                keyTemperatureEnabled   : false
            ]
        )
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearValues()
        guard targetPeripheral != nil else {
            print("No peripheral , disabling all views")
            return
        }
        cloudToken = loadToken(forPeripheral: targetPeripheral!)
        cloudTokenLabel.text = cloudToken
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        defaults.synchronize()
        disableNotifications()
        super.viewWillDisappear(animated)
    }

    func loadToken(forPeripheral aPeripheral: ThingyPeripheral) -> String? {
        let uuid = aPeripheral.basePeripheral.identifier.uuidString
        if let token = Keychain.load(uuid) {
            print("Token loaded for \(uuid)")
            return token
        } else {
            print("Token doesn't exist")
        }
        return nil
    }

    func removeToken(forPeripheral aPeriphreal: ThingyPeripheral) -> Bool {
        let uuid = aPeriphreal.basePeripheral.identifier.uuidString
        return Keychain.delete(uuid)
    }

    func setToken(aToken: String, forPeripheral aPeripheral: ThingyPeripheral) -> Bool {
        let uuid = aPeripheral.basePeripheral.identifier.uuidString
        return Keychain.save(aToken, forKey: uuid)
    }
    
    func showTokenInputPopup() {
        PopupHelper.showTextInput(withTitle: "New Token", subtitle: "Max 250 Bytes", value: cloudToken ?? "", andPlaceholderValue: "Enter cloud token here",
                                  validator: { (value: String?) -> (Bool) in return value != nil && value!.utf8.count <= 250 },
                                  completion: {
                                    value in
                                    //Save token locally, override if it exists for thingy
                                    DispatchQueue.main.async {
                                        guard self.targetPeripheral != nil else {
                                            self.cloudToken = nil
                                            self.cloudTokenLabel.text = "None, tap to add"
                                            self.setUIState(enabled: false)
                                            return
                                        }
                                        
                                        if value.characters.count == 0 {
                                            if self.removeToken(forPeripheral: self.targetPeripheral!) {
                                                print("Token removed")
                                            }
                                            self.cloudToken = nil
                                            self.cloudTokenLabel.text = "None, tap to add"
                                            self.setUIState(enabled: false)
                                        } else {
                                            if self.setToken(aToken: value, forPeripheral: self.targetPeripheral!) {
                                                self.cloudToken = value
                                                self.cloudTokenLabel.text = value
                                                self.setUIState(enabled: true)
                                            } else {
                                                self.cloudToken = nil
                                                self.cloudTokenLabel.text = "None, tap to add"
                                                self.setUIState(enabled: false)
                                            }
                                        }
                                    }
                                    
        })
    }
    
    //MARK: - UI Helpers
    private func handleButtonStateTogglechange() {
        defaults.set(buttonStateToggle.isOn, forKey: keyButtonEnabled)
        if buttonStateToggle.isOn {
            if isNotifyingButton == false {
                self.beginButtonNotifications()
            }
        } else {
            if isNotifyingButton == true {
                self.stopButtonNotifications()
            }
        }
    }

    private func handlePressuerToggleChange() {
        defaults.set(pressureToggle.isOn, forKey: keyPressureEnabled)
        if pressureToggle.isOn {
            if isNotifyingPressure == false {
                self.beginPressureNotifications()
            }
        } else {
            if isNotifyingPressure == true {
                self.stopPressureNotifications()
            }
        }
    }

    private func handleTemperatueToggleChange() {
        defaults.set(temperatureToggle.isOn, forKey: keyTemperatureEnabled)
        if temperatureToggle.isOn {
            if isNotifyingTemperature == false {
                self.beginTemperatureNotifications()
            }
        } else {
            if isNotifyingTemperature == true {
                self.stopTemperatureNotifications()
            }
        }
    }

    private func setUIState(enabled: Bool) {
        pressureToggle.isEnabled            	= enabled
        temperatureToggle.isEnabled             = enabled
        buttonStateToggle.isEnabled             = enabled
        pressureValueLabel.isEnabled            = enabled
        temperatureValueLabel.isEnabled         = enabled
        buttonStateValueLabel.isEnabled         = enabled
        temperatureIntervalValueLabel.isEnabled = enabled
        pressureIntervalValueLabel.isEnabled    = enabled
        cloudTokenLabel.isEnabled               = enabled
    }
    
    private func clearValues() {
        pressureValueLabel.text             = "-"
        temperatureValueLabel.text          = "-"
        buttonStateValueLabel.text          = "-"
        temperatureIntervalValueLabel.text  = "-"
        pressureIntervalValueLabel.text     = "-"
        cloudTokenLabel.text                = "-"
    }

    //MARK: - Event Cloud handlers
    private func temperatureUpdated(newValue: Float) {
        let eventData = [String(newValue), "°C"]
        temperatureValueLabel.text = String.init(format: "%.2f °C", newValue)
        submitToAPI(type: "temperature_update", andData: eventData)
    }

    private func pressureUpdated(newValue: Double) {
        let eventData = [String(newValue)]
        pressureValueLabel.text = String.init(format: "%.2f hPa", newValue)
        submitToAPI(type: "pressure_update", andData: eventData)
    }

    private func buttonDown() {
        buttonStateValueLabel.text = "Pressed"
        buttonPressTime = Date()
    }

    private func buttonUp() {
        guard buttonPressTime != nil else {
            return
        }

        let buttonPressDuration = Date().timeIntervalSince(buttonPressTime!)
        buttonPressTime = nil
        buttonStateValueLabel.text = String.init(format: "Released (%.2f Sec)", buttonPressDuration)
        let eventData = ["pressDuration", String.init(format: "%0.2f", buttonPressDuration), "Seconds"]
        submitToAPI(type: "button_press", andData: eventData)
    }

    private func submitToAPI(type: String, andData someData: [String]) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        guard cloudToken != nil else {
            UIAlertView(title: "Error", message: "Clout token not present", delegate: nil, cancelButtonTitle: "Ok").show()
            print("Token not set, will skip")
            disableNotifications()
            return
        }
        let url = endPoint.replacingOccurrences(of: "{0}", with: type).replacingOccurrences(of: "{1}", with: cloudToken!)

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8",forHTTPHeaderField: "Content-Type")
        request.addValue("application/json",forHTTPHeaderField: "Accept")
        var postString = "{"
        var i = 1
        for anArgument in someData {
            postString = postString.appendingFormat("\"value%d\":\"%@\"", i, anArgument)
            if someData.index(of: anArgument)! < someData.endIndex - 1 {
                postString.append(",")
            }
            i = i + 1
        }

        postString.append("}")

        print(postString)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error!)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                self.disableNotifications()
                self.setUIState(enabled: false)
            }
            
            var errorMessages: String = ""
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let root = json?["errors"] {
                    if let errorArray = root as? NSArray {
                        for anError in errorArray {
                            if let errorObject = anError as? NSDictionary {
                                if let errorMessage = errorObject["message"] {
                                    errorMessages.append("\r\n\(errorMessage)")
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    UIAlertView(title: "Error", message: errorMessages, delegate: nil, cancelButtonTitle: "Ok").show()
                }
            } else {
                DispatchQueue.main.async {
                    UIAlertView(title: "Error", message: "Something went wrong, please try again", delegate: nil, cancelButtonTitle: "Ok").show()
                }
            }
            

            DispatchQueue.main.async {
                if let uploadedBytes = request.httpBody?.count {
                    self.updateUploadCount(byteCount: uploadedBytes)
                }
                
                if data.count > 0 {
                    self.updateDownloadCount(byteCount: data.count)
                }
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        task.resume()
    }

    private func updateUploadCount(byteCount: Int) {
        self.totalUploadedBytes = self.totalUploadedBytes + UInt32(byteCount)
        if self.totalUploadedBytes < 1024 {
            self.totalUploadSizeLabel.text = String.init(format: "%d Bytes", self.totalUploadedBytes)
        } else if self.totalUploadedBytes < 1024 * 1024 {
            self.totalUploadSizeLabel.text = String.init(format: "%.2f Kb", Float(self.totalUploadedBytes) / 1024.0)
        } else {
            self.totalUploadSizeLabel.text = String.init(format: "%.2f Mb", Float(self.totalUploadedBytes) / 1024.0 * 1024.0)
        }
    }
    
    private func updateDownloadCount(byteCount: Int) {
        self.totalDownloadedBytes = self.totalDownloadedBytes + UInt32(byteCount)
        if self.totalDownloadedBytes < 1024 {
            self.totalDownloadSizeLabel.text = String.init(format: "%d Bytes", self.totalDownloadedBytes)
        } else if self.totalUploadedBytes < 1024 * 1024 {
            self.totalDownloadSizeLabel.text = String.init(format: "%.2f Kb", Float(self.totalDownloadedBytes) / 1024.0)
        } else {
            self.totalDownloadSizeLabel.text = String.init(format: "%.2f Mb", Float(self.totalDownloadedBytes) / 1024.0 * 1024.0)
        }
    }

    //MARK: - Service control helpers
    private func beginButtonNotifications() {
        targetPeripheral?.beginButtonStateNotifications(withCompletionHandler: { (success) -> (Void) in
            print("Enabled button state notifications: \(success)")
            self.isNotifyingButton = success
        }, andNotificationHandler: { (buttonState) -> (Void) in
            switch buttonState {
            case .pressed:
                self.buttonDown()
            case .released:
                self.buttonUp()
            default:
                print("Unknown State")
            }
        })
    }

    private func stopButtonNotifications() {
        targetPeripheral?.stopButtonStateUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Stopped button state notifications: \(success)")
            self.buttonStateValueLabel.text = "-"
            self.isNotifyingButton = !success //Success to turn off means it's off, failure to turn off means it's on, thus, inverted.
        })
    }

    private func beginPressureNotifications() {
        targetPeripheral?.beginPressureUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Started pressure notifications: \(success)")
            self.isNotifyingPressure = success
        }, andNotificationHandler: { (pressure) -> (Void) in
            self.pressureUpdated(newValue: pressure)
        })
    }

    private func stopPressureNotifications() {
        targetPeripheral?.stopPressureUpdates(withCompletionHandler: { (success) -> (Void) in
            self.pressureValueLabel.text = "-"
            print("Stopped pressure notifications: \(success)")
            self.isNotifyingPressure = !success
        })
    }

    private func beginTemperatureNotifications() {
        targetPeripheral?.beginTemperatureUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Started temperature notifications: \(success)")
            self.isNotifyingTemperature = success
        }, andNotificationHandler: { (temperature) -> (Void) in
            self.temperatureUpdated(newValue: temperature)
        })
    }

    private func stopTemperatureNotifications() {
        targetPeripheral?.stopTemperatureUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Stopped temperature notifications: \(success)")
             self.temperatureValueLabel.text = "-"
            self.isNotifyingTemperature = !success
        })
    }

    private func enableNotifications() {        
        if defaults.bool(forKey: keyTemperatureEnabled) {
            beginTemperatureNotifications()
        } else {
            temperatureToggle.isOn = false
        }
        if defaults.bool(forKey: keyPressureEnabled) {
            beginPressureNotifications()
        } else {
            pressureToggle.isOn = false
        }
        if defaults.bool(forKey: keyButtonEnabled) {
            beginButtonNotifications()
        } else {
            buttonStateToggle.isOn = false
        }
    }

    private func disableNotifications() {
        if isNotifyingTemperature {
            stopTemperatureNotifications()
        }
        if isNotifyingButton {
            stopButtonNotifications()
        }
        if isNotifyingPressure {
            stopPressureNotifications()
        }
    }

    //MARK: - Thingy delegate
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        navigationItem.title = peripheral.name + " Cloud"

        if state == .disconnecting || state == .disconnected {
            print("Disconnected thingy")
            setUIState(enabled: false)
        } else if state == .ready {
            cloudToken = loadToken(forPeripheral: targetPeripheral!)
            cloudTokenLabel.text = cloudToken ?? "None, tap to add"
            let (temperatureInterval, pressureInterval, _, _, _) = (targetPeripheral?.readEnvironmentConfiguration())!
            self.temperatureIntervalValueLabel.text = String.init(format:"%d", temperatureInterval)
            self.pressureIntervalValueLabel.text = String.init(format: "%d", pressureInterval)
            if cloudToken != nil {
                enableNotifications()
                setUIState(enabled: true)
            }
        }
    }
    
    override func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        guard new != nil else {
            return
        }
        disableNotifications()
    }
}
