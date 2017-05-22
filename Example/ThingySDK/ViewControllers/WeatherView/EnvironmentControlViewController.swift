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
//  ThingyWeatherControlViewController.swift
//
//  Created by Aleksander Nowakowski on 04/11/2016.
//

import UIKit

protocol EnvironmentControlDelegate: class {
    func temperatureNotificationsDidChangeTo(enabled : Bool)
    func pressureNotificationsDidChangeTo(enabled : Bool)
    func humidityNotificationsDidChangeTo(enabled : Bool)
    func airQualityNotificationsDidChangeTo(enabled : Bool)
    func lightIntensityNotificationsDidChangeTo(enabled : Bool)
}

class EnvironmentControlViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet private weak var tempSwitch: UISwitch!
    @IBOutlet private weak var pressureSwitch: UISwitch!
    @IBOutlet private weak var humiditySwitch: UISwitch!
    @IBOutlet private weak var airQualitySwitch: UISwitch!
    @IBOutlet private weak var lightIntensitySwitch: UISwitch!
    
    //MARK: - UI actions
    @IBAction func temperatureSwitchDidChange(_ sender: UISwitch) {
        delegate?.temperatureNotificationsDidChangeTo(enabled: tempSwitch.isOn)
    }
    
    @IBAction func pressureSwitchDidChange(_ sender: UISwitch) {
        delegate?.pressureNotificationsDidChangeTo(enabled: pressureSwitch.isOn)
    }
    
    @IBAction func humiditySwitchDidChange(_ sender: UISwitch) {
        delegate?.humidityNotificationsDidChangeTo(enabled: humiditySwitch.isOn)
    }
    
    @IBAction func airQualitySwitchDidChange(_ sender: UISwitch) {
        delegate?.airQualityNotificationsDidChangeTo(enabled: airQualitySwitch.isOn)
    }
    
    @IBAction func lightIntensitySwitchDidChange(_ sender: UISwitch) {
        delegate?.lightIntensityNotificationsDidChangeTo(enabled: lightIntensitySwitch.isOn)
    }
    
    //MARK: - Variables
    weak var delegate : EnvironmentControlDelegate?
    
    var tempEnabled = true
    var pressureEnabled = true
    var humidityEnabled = true
    var airQualityEnabled = true
    var lightIntensityEnabled = true
    
    //MARK: - UI View Controller methods
    override func viewDidLoad() {
        super.viewDidLoad()

        tempSwitch.isOn = tempEnabled
        pressureSwitch.isOn = pressureEnabled
        humiditySwitch.isOn = humidityEnabled
        airQualitySwitch.isOn = airQualityEnabled
        lightIntensitySwitch.isOn = lightIntensityEnabled
    }
}
