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
//  ThingyWeatherViewController.swift
//
//  Created by Mostafa Berg on 06/10/16.
//

import UIKit
import Charts
import IOSThingyLibrary

class EnvironmentViewController: SwipableTableViewController, UIPopoverPresentationControllerDelegate, EnvironmentControlDelegate {

    //MARK: - Properties and data
    private var temperatureDataGraphHandler: GraphDataHandler!
    private var humidityDataGraphHandler: GraphDataHandler!
    private var pressureDataGraphHandler: GraphDataHandler!

    //MARK: - Environment values
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var eCO2Label: UILabel!
    @IBOutlet weak var totalVolatileOrganicCompoundsLabel: UILabel!
    @IBOutlet weak var lightIntensityIcon: UIView!
    @IBOutlet weak var lightIntensityLabel: UILabel!
    
    //MARK: - Buttons
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var controlButton: UIButton!
    
    //MARK: - Graphs
    @IBOutlet weak var temperatureGraphView: LineChartView!
    @IBOutlet weak var scrollTemperatureGraphButton: UIButton!
    @IBOutlet weak var clearTemperatureGraphButton: UIButton!
    @IBOutlet weak var humidityGraphView: LineChartView!
    @IBOutlet weak var scrollHumidityGraphButton: UIButton!
    @IBOutlet weak var clearHumidityGraphButton: UIButton!
    @IBOutlet weak var pressureGraphView: LineChartView!
    @IBOutlet weak var scrollPressureGraphButton: UIButton!
    @IBOutlet weak var clearPressureGraphButton: UIButton!
    
    //MARK: - Actions
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        // User tapped menu button, disable menu tooltip if it's never been seen before
        setSeenMenuTooltip()
        toggleRevealView()
    }

    private let defaults : UserDefaults!
    private let keyTemperatureEnabled = "temperature_enabled"
    private let keyPressureEnabled = "pressure_enabled"
    private let keyHumidityEnabled = "humidity_enabled"
    private let keyAirQualityEnabled = "air_quality_enabled"
    private let keyLightIntensityEnabled = "light_intensity_enabled"
    
    private weak var settingsViewController: ThingyNavigationController?
    
    required init?(coder aDecoder: NSCoder) {
        defaults = UserDefaults.standard
        defaults.register(defaults: [
            keyTemperatureEnabled : true,
            keyPressureEnabled : true,
            keyHumidityEnabled : true,
            keyAirQualityEnabled : true,
            keyLightIntensityEnabled : true
        ])
        super.init(coder: aDecoder)
    }
    
    //MARK: - UIViewController implementation
    override func viewDidLoad() {
        // Initial setup for the 'color' icon
        lightIntensityIcon.layer.cornerRadius = lightIntensityIcon.frame.width / 2;
        lightIntensityIcon.layer.masksToBounds = true
        
        temperatureDataGraphHandler = GraphDataHandler(withGraphView: temperatureGraphView,
                                                       noDataText: "No temperature data present",
                                                       minValue: -10, maxValue: 40,
                                                       numberOfDataSets: 1,
                                                       dataSetNames: ["Temperature"],
                                                       dataSetColors: [UIColor.nordicLake])
        temperatureDataGraphHandler.scrollGraphButton = scrollTemperatureGraphButton
        temperatureDataGraphHandler.clearGraphButton = clearTemperatureGraphButton
        
        pressureDataGraphHandler = GraphDataHandler(withGraphView: pressureGraphView,
                                                    noDataText: "No pressure data present",
                                                    minValue: 930, maxValue: 1050,
                                                    numberOfDataSets: 1,
                                                    dataSetNames: ["Pressure (hPa)"],
                                                    dataSetColors: [UIColor.nordicRed])
        pressureDataGraphHandler.scrollGraphButton = scrollPressureGraphButton
        pressureDataGraphHandler.clearGraphButton = clearPressureGraphButton

        humidityDataGraphHandler = GraphDataHandler(withGraphView: humidityGraphView,
                                                    noDataText: "No humidity data present",
                                                    minValue: 0, maxValue: 100,
                                                    numberOfDataSets: 1,
                                                    dataSetNames: ["Humidity (%)"],
                                                    dataSetColors: [UIColor.nordicFall])
        humidityDataGraphHandler.scrollGraphButton = scrollHumidityGraphButton
        humidityDataGraphHandler.clearGraphButton = clearHumidityGraphButton
        
        if #available(iOS 13.0, *) {
            lightIntensityIcon.backgroundColor = UIColor.label
            
            temperatureGraphView.getAxis(.left).labelTextColor = .label
            temperatureGraphView.xAxis.labelTextColor = .label
            temperatureGraphView.legend.textColor = .label
            
            pressureGraphView.getAxis(.left).labelTextColor = .label
            pressureGraphView.xAxis.labelTextColor = .label
            pressureGraphView.legend.textColor = .label
            
            humidityGraphView.getAxis(.left).labelTextColor = .label
            humidityGraphView.xAxis.labelTextColor = .label
            humidityGraphView.legend.textColor = .label
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settingsViewController = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if defaults.bool(forKey: kViewedMenuTooltip) == false {
            performSegue(withIdentifier: "showMenuTip", sender: navigationItem.leftBarButtonItem)
            setSeenMenuTooltip()
        } else if defaults.bool(forKey: kViewedSensorsTooltip) == false {
            performSegue(withIdentifier: "showServicesTip", sender: controlButton)
            setSeenSensorsTooltip()
        }
    }
    
    private func setSeenMenuTooltip() {
        guard defaults.bool(forKey: kViewedMenuTooltip) == false else {
            return
        }
        defaults.set(true, forKey: kViewedMenuTooltip)
        defaults.synchronize()
    }
    
    private func setSeenSensorsTooltip() {
        guard defaults.bool(forKey: kViewedSensorsTooltip) == false else {
            return
        }
        defaults.set(true, forKey: kViewedSensorsTooltip)
        defaults.synchronize()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue for the popover configuration window
        if segue.identifier == "showControl" {
            let controller = segue.destination as! EnvironmentControlViewController
            controller.delegate = self
            controller.tempEnabled = defaults.bool(forKey: keyTemperatureEnabled)
            controller.pressureEnabled = defaults.bool(forKey: keyPressureEnabled)
            controller.humidityEnabled = defaults.bool(forKey: keyHumidityEnabled)
            controller.airQualityEnabled = defaults.bool(forKey: keyAirQualityEnabled)
            controller.lightIntensityEnabled = defaults.bool(forKey: keyLightIntensityEnabled)
            controller.popoverPresentationController!.sourceView = sender as? UIView
            controller.popoverPresentationController!.delegate = self
        } else if segue.identifier == "showInfo" {
            segue.destination.popoverPresentationController!.sourceView = sender as? UIView
            segue.destination.popoverPresentationController!.delegate = self
        } else if segue.identifier == "showSettings" {
            settingsViewController = segue.destination as? ThingyNavigationController
            settingsViewController!.setTargetPeripheral(targetPeripheral, andManager: thingyManager)
        } else if segue.identifier == "showServicesTip" {
            // Show user tip to enable/disable services
            segue.destination.popoverPresentationController?.sourceView = sender as? UIView
            segue.destination.popoverPresentationController?.delegate = self
        } else if segue.identifier == "showMenuTip" {
            // Show user tip to enable/disable services
            segue.destination.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            segue.destination.popoverPresentationController?.delegate = self
        }
    }
    
    //MARK: - Thingy API
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        navigationItem.title = "Environment"
        
        settingsButton.isEnabled = peripheral.state == .ready
        controlButton.isEnabled = peripheral.state == .ready
        
        settingsViewController?.thingyPeripheral(peripheral, didChangeStateTo: state)
        if settingsViewController == nil && state == .ready {
            enableNotifications()
        }
    }
    
    override func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        disableNotifications()
        if new != nil {
            temperatureDataGraphHandler.clearGraphData()
            pressureDataGraphHandler.clearGraphData()
            humidityDataGraphHandler.clearGraphData()
        }
    }

    //MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // This method must return .none in order to show the ThingyWeatherControlViewController as popover
        return .none
    }
  
    //MARK: - ThingyEnvironmentControlDelegate
    func temperatureNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyTemperatureEnabled)
        if enabled {
            targetPeripheral?.beginTemperatureUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Temperature notifications enabled")
            }, andNotificationHandler: { (degreesInCelsius) -> (Void) in
                if EnvironmentSettingsViewController.isFahrenheit() {
                    let degreesInFahrenheit = degreesInCelsius * 9.0 / 5.0 + 32.0
                    self.temperatureLabel.text = "\(degreesInFahrenheit)°F"
                    _ = self.temperatureDataGraphHandler.addPoints(withValues: [Double(degreesInFahrenheit)])
                } else {
                    self.temperatureLabel.text = "\(degreesInCelsius)°C"
                    _ = self.temperatureDataGraphHandler.addPoints(withValues: [Double(degreesInCelsius)])
                }
            })
        } else {
            stopTemperatureUpdates()
        }
    }
    
    func pressureNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyPressureEnabled)
        if enabled {
            targetPeripheral?.beginPressureUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Pressure notifications enabled")
            }, andNotificationHandler: { (value) -> (Void) in
                self.pressureLabel.text = "\(value) hPa"
                _ = self.pressureDataGraphHandler.addPoints(withValues: [Double(value)])
            })
        } else {
            stopPressureUpdates()
        }
    }
    
    func humidityNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyHumidityEnabled)
        if enabled {
            targetPeripheral?.beginHumidityUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Humidity notifications enabled")
            }, andNotificationHandler: { (value) -> (Void) in
                self.humidityLabel.text = "\(value)%"
                _ = self.humidityDataGraphHandler.addPoints(withValues: [Double(value)])
            })
        } else {
            stopHumidityUpdates()
        }
    }
    
    func airQualityNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyAirQualityEnabled)
        if enabled {
            targetPeripheral?.beginAirQualityUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Air Quality notifications enabled")
            }, andNotificationHandler: { (eCO2, tvoc) -> (Void) in
                self.eCO2Label.text = "\(eCO2) ppm"
                self.totalVolatileOrganicCompoundsLabel.text = "\(tvoc) ppb"
            })
        } else {
            stopAirQualityUpdates()
        }
    }
    
    func lightIntensityNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyLightIntensityEnabled)
        if enabled {
            targetPeripheral?.beginLightIntensityUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Light Intensity notifications enabled")
            }, andNotificationHandler: { (redIntensity, greenIntensity, blueIntensity, clearIntensity, color) -> (Void) in
                self.lightIntensityIcon.backgroundColor = color
                self.lightIntensityLabel.text = color.hexString
            })
        } else {
            stopLightIntensityUpdates()
        }
    }
    
    //MARK: - Convenience
    private func enableNotifications() {
        if defaults.bool(forKey: keyTemperatureEnabled) {
            temperatureNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyPressureEnabled) {
            pressureNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyHumidityEnabled) {
            humidityNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyAirQualityEnabled) {
            airQualityNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyLightIntensityEnabled) {
            lightIntensityNotificationsDidChangeTo(enabled: true)
        }
    }

    private func disableNotifications() {        
        if settingsViewController == nil {
            stopTemperatureUpdates()
            stopPressureUpdates()
            stopHumidityUpdates()
            stopAirQualityUpdates()
            stopLightIntensityUpdates()
        }
    }
    
    private func stopTemperatureUpdates() {
        targetPeripheral?.stopTemperatureUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Temperature notifications disabled")
            self.temperatureLabel.text = "N/A"
        })
    }
    
    private func stopPressureUpdates() {
        targetPeripheral?.stopPressureUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Pressure notifications disabled")
            self.pressureLabel.text = "N/A"
        })
    }
    
    private func stopHumidityUpdates() {
        targetPeripheral?.stopHumidityUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Humidity notifications disabled")
            self.humidityLabel.text = "N/A"
        })
    }
    
    private func stopAirQualityUpdates() {
        targetPeripheral?.stopAirQualityUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Air Quality notifications disabled")
            self.eCO2Label.text = "N/A"
            self.totalVolatileOrganicCompoundsLabel.text = "N/A"
        })
    }
    
    private func stopLightIntensityUpdates() {
        targetPeripheral?.stopLightIntensityUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Light Intensity notifications disabled")
            self.lightIntensityIcon.backgroundColor = UIColor.black
            self.lightIntensityLabel.text = "N/A"
        })
    }
}
