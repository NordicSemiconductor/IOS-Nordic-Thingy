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
//  EnvironmentSettingsViewController.swift
//
//  Created by Aleksander Nowakowski on 09/12/2016.
//

import UIKit
import IOSThingyLibrary

class EnvironmentSettingsViewController: ThingyTableViewController, ConfigurationPresetDelegate {
    private static let keyTemperatureUnit = "temperatureUnit"
    
    static func isFahrenheit() -> Bool {
        return UserDefaults.standard.bool(forKey: EnvironmentSettingsViewController.keyTemperatureUnit)
    }
    
    private static func saveUnit(fahrenheit: Bool) {
        UserDefaults.standard.set(fahrenheit, forKey: EnvironmentSettingsViewController.keyTemperatureUnit)
    }

    //MARK: - Actions
    @IBOutlet weak var temperatureIntervalLabel    : UILabel!
    @IBOutlet weak var pressureIntervalLabel       : UILabel!
    @IBOutlet weak var humidityIntervalLabel       : UILabel!
    @IBOutlet weak var lightIntensityIntervalLabel : UILabel!
    @IBOutlet weak var airQualityIntervalLabel     : UILabel!
    @IBOutlet weak var temperatureUnitLabel        : UILabel!
    
    //MARK: - Outlets
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        handleCancel()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        handleSave()
    }

    private let tempUnitRequestId   = 0
    private let airQualityRequestId = 1
    
    private var tempInterval           : UInt16 = 0
    private var pressureInterval       : UInt16 = 0
    private var humidityInterval       : UInt16 = 0
    private var lightIntensityInterval : UInt16 = 0
    private var airQualityInterval     : ThingyEnvironmentGasModeConfiguration = .interval1Sec
    private var redCalibration         : UInt8 = 0
    private var greenCalibration       : UInt8 = 0
    private var blueCalibration        : UInt8 = 0
    private var temperatureUnitIsFahrenheit: Bool = EnvironmentSettingsViewController.isFahrenheit()
    
    //MARK: - UIViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Environment service must exist if Settings screen is opened
        (tempInterval, pressureInterval, humidityInterval, lightIntensityInterval, airQualityInterval, redCalibration, greenCalibration, blueCalibration) = targetPeripheral!.readEnvironmentConfiguration()!
        temperatureIntervalLabel.text = "\(tempInterval) ms"
        pressureIntervalLabel.text = "\(pressureInterval) ms"
        humidityIntervalLabel.text = "\(humidityInterval) ms"
        lightIntensityIntervalLabel.text = "\(lightIntensityInterval) ms"
        airQualitySampleRateSelected(value: airQualityInterval)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        temperatureUnitLabel.text = temperatureUnitIsFahrenheit ? "Fahrenheit" : "Celsius"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "airQualitySampleRate" {
            let view = segue.destination as! ConfigurationPresetTableViewController
            view.delegate = self
            view.title = "Air Quality Sample Rate"
            view.requestId = airQualityRequestId
            view.keys = [
                ThingyEnvironmentGasModeConfiguration.interval1Sec,
                ThingyEnvironmentGasModeConfiguration.interval10Sec,
                ThingyEnvironmentGasModeConfiguration.interval60Sec
            ]
            view.values = ["1 second", "10 seconds", "1 minute"]
            view.selectedKey = airQualityInterval
        } else if segue.identifier == "temperatureUnit" {
            let view = segue.destination as! ConfigurationPresetTableViewController
            view.delegate = self
            view.title = "Temperature Unit"
            view.requestId = tempUnitRequestId
            view.keys = [ false, true ]
            view.values = [ "Celsius", "Fahrenheit" ]
            view.selectedKey = temperatureUnitIsFahrenheit
        }
    }
    
    //MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: // Temperature
                PopupHelper.showIntervalInput(withTitle: "Temperature interval", subtitle: "Range: 100 ms - 60000 ms",
                                              value: Int(tempInterval), availableRange: NSMakeRange(100, 60000 - 100 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value: Int) -> (Void) in
                                                self.tempInterval = UInt16(value)
                                                self.temperatureIntervalLabel.text = "\(value) ms"
                                              })
            case 1: // Pressure
                PopupHelper.showIntervalInput(withTitle: "Pressure interval", subtitle: "Range: 50 ms - 60000 ms",
                                              value: Int(pressureInterval), availableRange: NSMakeRange(50, 60000 - 50 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value: Int) -> (Void) in
                                                self.pressureInterval = UInt16(value)
                                                self.pressureIntervalLabel.text = "\(value) ms"
                                              })
            case 2: // Humidity
                PopupHelper.showIntervalInput(withTitle: "Humidity interval", subtitle: "Range: 100 ms - 5000 ms",
                                              value: Int(humidityInterval), availableRange: NSMakeRange(100, 5000 - 100 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value: Int) -> (Void) in
                                                self.humidityInterval = UInt16(value)
                                                self.humidityIntervalLabel.text = "\(value) ms"
                                              })
            case 3: // Light intensity
                PopupHelper.showIntervalInput(withTitle: "Light intensity interval", subtitle: "Range: 200 ms - 5000 ms",
                                              value: Int(lightIntensityInterval), availableRange: NSMakeRange(200, 5000 - 200 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value: Int) -> (Void) in
                                                self.lightIntensityInterval = UInt16(value)
                                                self.lightIntensityIntervalLabel.text = "\(value) ms"
                                              })
            default:
                break
            }
        default:
            break
        }
    }
    
    //MARK: - ConfigurationPresetDelegate
    func value(_ key: AnyHashable, selectedWithText text: String, inRequest requestId: Int) {
        switch requestId {
        case tempUnitRequestId:
            temperatureUnitIsFahrenheit = key.base as! Bool
            temperatureUnitLabel.text = text
        case airQualityRequestId:
            airQualityInterval = key.base as! ThingyEnvironmentGasModeConfiguration
            airQualityIntervalLabel.text = text
        default:
            break
        }
    }
    
    //MARK: - Implementation
    private func handleSave() {
        let (tempInterval, pressureInterval, humidityInterval, lightIntensityInterval, airQualityInterval, redCalibration, greenCalibration, blueCalibration) = targetPeripheral!.readEnvironmentConfiguration()!
        
        let dataChanged = tempInterval != self.tempInterval ||
            pressureInterval != self.pressureInterval ||
            humidityInterval != self.humidityInterval ||
            lightIntensityInterval != self.lightIntensityInterval ||
            airQualityInterval != self.airQualityInterval ||
            redCalibration != self.redCalibration ||
            greenCalibration != self.greenCalibration ||
            blueCalibration != self.blueCalibration
        
        
        // Save the unit
        EnvironmentSettingsViewController.saveUnit(fahrenheit: temperatureUnitIsFahrenheit)
        
        // Save data only when at least one value has been changed
        if dataChanged {
            let loadingView = UIAlertController(title: "Configuring Thingy", message: "Sending configuration...", preferredStyle: .alert)
            present(loadingView, animated: true) {
                self.targetPeripheral!.setEnvironmentConfiguration(temperatureInterval: self.tempInterval, pressureInterval: self.pressureInterval, humidityInterval: self.humidityInterval, lightIntensityInterval: self.lightIntensityInterval, gasMode: self.airQualityInterval, redCalibration: self.redCalibration, greenCalibration: self.greenCalibration, blueCalbiration: self.blueCalibration, withCompletionHandler: { (success) -> (Void) in
                    if success {
                        loadingView.message = "Done!"
                        loadingView.dismiss(animated: true, completion: {
                            self.handleCancel()
                        })
                    } else {
                        loadingView.message = "Failed!"
                        loadingView.dismiss(animated: true)
                        print("Couldn't save environment configuration!")
                    }
                })
            }
        } else {
            // Otherwise just dismiss the settings view controller
            handleCancel()
        }
    }
    
    private func handleCancel() {
        let parentView = self.parent as! ThingyNavigationController
        parentView.dismiss(animated: true, completion: nil)
    }
    
    private func airQualitySampleRateSelected(value: ThingyEnvironmentGasModeConfiguration) {
        airQualityInterval = value
        switch value {
        case .interval1Sec:
            airQualityIntervalLabel.text = "1 second"
        case .interval10Sec:
            airQualityIntervalLabel.text = "10 seconds"
        case .interval60Sec:
            airQualityIntervalLabel.text = "1 minute"
        default:
            airQualityInterval = .interval1Sec
            airQualityIntervalLabel.text = "1 second"
        }
    }
}
