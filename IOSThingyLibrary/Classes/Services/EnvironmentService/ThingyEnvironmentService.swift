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
//  ThingyEnvironmentService.swift
//
//  Created by Mostafa Berg on 25/10/16.
//

import CoreBluetooth

public typealias TemperatureNotificationCallback    = (_ degreesInCelcius: Float) -> (Void)
public typealias HumidityNotificationCallback       = (_ humidityPercentage: UInt8) -> (Void)
public typealias AirQualityNotificationCallback     = (_ equivalentCrabonDioxide: UInt16,_ volatileOrganicCompounds: UInt16) -> (Void)
public typealias LightIntensityNotificationCallback = (_ redIntensity: UInt16, _ greenIntensity: UInt16, _ blueIntensity: UInt16, _ clearIntensity: UInt16, _ color: UIColor) -> (Void)
public typealias PressureNotificationCallback       = (_ pressureInHectoPascal: Double) -> (Void)

public enum ThingyEnvironmentGasModeConfiguration: UInt8 {
    //case interval250Millisec = 0
    case interval1Sec        = 1
    case interval10Sec       = 2
    case interval60Sec       = 3
    case unknown             = 0xF
}

public enum ThingyEnvironmentError: Error {
    case charactersticNotDiscovered(characteristicName: String)
}

internal class ThingyEnvironmentService: ThingyService {
    internal var temperatureNotificationsEnabled: Bool {
        return getTemperatureCharacteristic()?.isNotifying ?? false
    }
    internal var humidityNotificationsEnabled: Bool {
        return getHumidityCharacteristic()?.isNotifying ?? false
    }
    internal var pressureNotificationsEnabled: Bool {
        return getPressureCharacteristic()?.isNotifying ?? false
    }
    internal var airQualityNotificationsEnabled: Bool {
        return getAirQualityCharacteristic()?.isNotifying ?? false
    }
    internal var lightIntensityNotificationsEnabled: Bool {
        return getLightIntensityCharacteristic()?.isNotifying ?? false
    }

    //MARK: - Initialization
    required internal init(withService aService: CBService) {
        super.init(withName: "Enviornment service", andService: aService)
    }

    //MARK: - Environment service implementation
    internal func beginTemperatureNotifications() throws {
        if let characteristic = getTemperatureCharacteristic() {
            characteristic.startNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Temperature")
        }
    }

    internal func stopTemperatureNotifications() throws {
        if let tempCharacteristic = getTemperatureCharacteristic() {
            tempCharacteristic.stopNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Temperature")
        }
    }

    internal func beginHumidityNotifications() throws {
        if let characteristic = getHumidityCharacteristic() {
            characteristic.startNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Humidity")
        }
    }

    internal func stopHumidityNotifications() throws {
        if let characteristic = getHumidityCharacteristic() {
            characteristic.stopNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Humidity")
        }
    }
    
    internal func beginPressureNotifications() throws {
        if let characteristic = getPressureCharacteristic() {
            characteristic.startNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Pressure")
        }
    }
    
    internal func stopPressureNotifications() throws {
        if let characteristic = getPressureCharacteristic() {
            characteristic.stopNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Pressure")
        }
    }

    internal func beginAirQualityNotifications() throws {
        if let characteristic = getAirQualityCharacteristic() {
            characteristic.startNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Air Quality")
        }
    }
    
    internal func stopAirQualityNotifications() throws {
        if let characteristic = getAirQualityCharacteristic() {
            characteristic.stopNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Air Quality")
        }
    }

    internal func beginLightIntensityNotifications() throws {
        if let characteristic = getLightIntensityCharacteristic() {
            characteristic.startNotifications()
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Color Intensity")
        }
    }
    
    internal func stopLightIntensityNotifications() throws {
        if let characteristic = getLightIntensityCharacteristic() {
            characteristic.stopNotifications()
       } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Color Intensity")
        }
    }
    
    internal func setConfiguration(temperatureInterval: UInt16, pressureInterval: UInt16, humidityInterval: UInt16, lightIntensityInterval: UInt16, gasMode: ThingyEnvironmentGasModeConfiguration, redCalibration: UInt8, greenCalibration: UInt8, blueCalibration: UInt8) throws {
        if let configurationCharacteristic = getConfigurationCharacteristic() {
            var dataArray = [UInt8]()
            dataArray.append(UInt8(temperatureInterval & 0x00FF))
            dataArray.append(UInt8(temperatureInterval >> 8))
            dataArray.append(UInt8(pressureInterval & 0x00FF))
            dataArray.append(UInt8(pressureInterval >> 8))
            dataArray.append(UInt8(humidityInterval & 0x00FF))
            dataArray.append(UInt8(humidityInterval >> 8))
            dataArray.append(UInt8(lightIntensityInterval & 0x00FF))
            dataArray.append(UInt8(lightIntensityInterval >> 8))
            dataArray.append(gasMode.rawValue)
            
            //TODO: This is a quick workaround to avoid version conflicts, next update will include a proper fix.
            if configurationCharacteristic.value?.count == 12 {
                //Thingy Firmware 1.1
                dataArray.append(redCalibration)
                dataArray.append(greenCalibration)
                dataArray.append(blueCalibration)
            }
            
            let data = Data(bytes: dataArray)
            configurationCharacteristic.writeValue(withData: data)
        } else {
            throw ThingyEnvironmentError.charactersticNotDiscovered(characteristicName: "Environment Configuration")
        }
    }
    
    internal func readConfiguration() -> (temperatureInterval: UInt16, pressureInterval: UInt16, humidityInterval: UInt16, lightIntensityInterval: UInt16, gasMode: ThingyEnvironmentGasModeConfiguration, redCalibration: UInt8, greenCalibration: UInt8, blueCalibration: UInt8) {
        if let environmentConfigurationCharacteristic = getConfigurationCharacteristic() {
            let environmentConfigurationData = environmentConfigurationCharacteristic.value

            if environmentConfigurationData != nil {
                let byteArray = [UInt8](environmentConfigurationData!)
                let tempInterval           : UInt16 = UInt16(byteArray[0]) | UInt16(byteArray[1]) << 8
                let pressureInterval       : UInt16 = UInt16(byteArray[2]) | UInt16(byteArray[3]) << 8
                let humidityInterval       : UInt16 = UInt16(byteArray[4]) | UInt16(byteArray[5]) << 8
                let lightIntensityInterval : UInt16 = UInt16(byteArray[6]) | UInt16(byteArray[7]) << 8
                let gasMode                : ThingyEnvironmentGasModeConfiguration = ThingyEnvironmentGasModeConfiguration(rawValue: byteArray[8]) ?? .unknown
                var redCalibration         : UInt8  = 103
                var greenCalibration       : UInt8  = 78
                var blueCalibration        : UInt8  = 29
                if environmentConfigurationData!.count == 12 {
                    if byteArray[9] > 0 {
                        redCalibration   = byteArray[9]
                    }
                    if byteArray[10] > 0 {
                        greenCalibration = byteArray[10]
                    }
                    if byteArray[11] > 0 {
                        blueCalibration  = byteArray[11]
                    }
                }
                return (tempInterval, pressureInterval, humidityInterval, lightIntensityInterval, gasMode, redCalibration, greenCalibration, blueCalibration)
            }
        }
        return (0, 0, 0, 0, .unknown, 0, 0, 0)
    }

    //MARK: - Convenince methods

    private func getTemperatureCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getTemperatureCharacteristicUUID())
    }
    
    private func getPressureCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getPressureCharacteristicUUID())
    }
    
    private func getHumidityCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getHumidityCharacteristicUUID())
    }
    
    private func getAirQualityCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getAirQualityCharacteristicUUID())
    }
    
    private func getLightIntensityCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getLightIntensityCharacteristicUUID())
    }
    
    private func getConfigurationCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getEnvironmentConfigurationCharacteristicUUID())
    }

}
