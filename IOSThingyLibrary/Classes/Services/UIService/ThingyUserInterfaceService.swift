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
//  ThingyUserInterfaceService.swift
//
//  Created by Mostafa Berg on 10/10/16.
//

import CoreBluetooth

public typealias ButtonNotificationCallback = (_ state: ThingyButtonState) -> (Void)

public enum ThingyLEDColorPreset: UInt8 {
    case undefined  = 0
    case red        = 1
    case green      = 2
    case yellow     = 3
    case blue       = 4
    case purple     = 5
    case cyan       = 6
    case white      = 7
}

public enum ThingyLEDMode: UInt8 {
    case off      = 0
    case constant = 1
    case breathe  = 2
    case oneShot  = 3
}

public enum ThingyButtonState: UInt8 {
    case released = 0
    case pressed  = 1
    case unknown  = 2
}

public enum ThingyUserInterfaceError: Error {
    case charactersticNotDiscovered(characteristicName: String)
}

internal class ThingyUserInterfaceService: ThingyService {
    internal var buttonNotificationsEnabled: Bool {
        return getButtonCharacteristic()?.isNotifying ?? false
    }
    
    //MARK: - Initialization
    
    required internal init(withService aService: CBService) {
        super.init(withName: "User Interface service", andService: aService)
    }
    
    //MARK: - User Interface service implementation
    
    internal func turnOffLED() throws {
        let ledBytes = [UInt8](arrayLiteral: ThingyLEDMode.off.rawValue)
        if let ledCharacteristic = getLEDCharacteristic() {
            ledCharacteristic.writeValue(withData: Data(bytes: ledBytes))
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "LED")
        }
    }
    
    internal func setConstantLED(withColor aColor: UIColor) throws {
        let colorIntensities = self.getColorIntensities(forColor: aColor)
        let ledBytes = [UInt8](arrayLiteral: ThingyLEDMode.constant.rawValue, colorIntensities[0], colorIntensities[1], colorIntensities[2])
        if let ledCharacteristic = getLEDCharacteristic() {
            ledCharacteristic.writeValue(withData: Data(bytes: ledBytes))
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "LED")
        }
    }
    
    internal func setOneShotLED(withPresetColor aPresetColor: ThingyLEDColorPreset, andIntensity anIntensityPercentage: UInt8) throws {
        let ledBytes = [UInt8](arrayLiteral: ThingyLEDMode.oneShot.rawValue, aPresetColor.rawValue, anIntensityPercentage)
        if let ledCharacteristic = getLEDCharacteristic() {
            ledCharacteristic.writeValue(withData: Data(bytes: ledBytes))
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "LED")
        }
    }
    
    internal func setBreatheLED(withPresetColor aPresetColor: ThingyLEDColorPreset, intensity anIntensity: UInt8, andBreatheDelay aDelay: UInt16) throws {
        let delayBytes = [UInt8](arrayLiteral: UInt8(aDelay & 0xFF), UInt8(aDelay >> 8))
        let ledBytes = [UInt8](arrayLiteral: ThingyLEDMode.breathe.rawValue, aPresetColor.rawValue, anIntensity, delayBytes[0], delayBytes[1])

        if let ledCharacteristic = getLEDCharacteristic() {
            ledCharacteristic.writeValue(withData: Data(bytes: ledBytes))
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "LED")
        }
    }
    
    internal func readLEDState() throws -> (mode: ThingyLEDMode, presetColor: ThingyLEDColorPreset?, rgbColor: UIColor?, intensity: UInt8?, breatheDelay: UInt16?)? {
        if let ledCharacteristic = getLEDCharacteristic() {
            let data = ledCharacteristic.value
            if data == nil || (data!.count != 4 && data!.count != 5) {
                //Return default values since data is either empty or in a wrond format
                return (ThingyLEDMode.breathe, ThingyLEDColorPreset.blue, UIColor.blue, UInt8(100), UInt16(3500))
            } else {
                let ledBytes = data?.toArray(type: UInt8.self)
                let ledMode = ThingyLEDMode(rawValue: ledBytes![0])!
                var presetColor: ThingyLEDColorPreset?
                var rgbColor: UIColor?
                var intensity: UInt8?
                var breatheDelay: UInt16?
                
                switch ledMode {
                case .breathe:
                    presetColor = ThingyLEDColorPreset(rawValue: ledBytes![1])!
                    intensity   = ledBytes![2]
                    breatheDelay = UInt16(ledBytes![4]) * 256 + UInt16(ledBytes![3])
                case .constant:
                    rgbColor = UIColor(red: CGFloat(ledBytes![1]) / 255, green: CGFloat(ledBytes![2]) / 255, blue: CGFloat(ledBytes![3]) / 255, alpha: 1)
                case .oneShot:
                    presetColor = ThingyLEDColorPreset(rawValue: ledBytes![1])!
                    intensity   = ledBytes![2]
                case .off:
                    break
                }
                
                return (ledMode, presetColor, rgbColor, intensity, breatheDelay)
            }
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "LED")
        }
    }
    
    internal func beginButtonNotifications() throws {
        if let buttonCharacteristic = getButtonCharacteristic() {
            buttonCharacteristic.startNotifications()
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "Button")
        }
    }
    
    internal func stopButtonNotifications() throws {
        if let buttonCharacteristic = getButtonCharacteristic() {
            buttonCharacteristic.stopNotifications()
        } else {
            throw ThingyUserInterfaceError.charactersticNotDiscovered(characteristicName: "Button")
        }
    }

    //MARK: - Convenince methods
    
    private func getLEDCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getLEDCharacteristicUUID())
    }
    
    private func getButtonCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getButtonCharacteristicUUID())
    }
    
    private func getColorIntensities(forColor aColor: UIColor) -> [UInt8] {
        var components = aColor.cgColor.components!
        var intensities: [UInt8] = []
        
        if components.count == 2 {
            // All intensities are equal, set same to RGB components
            intensities.append(UInt8(components[0] * 255.0))
            intensities.append(UInt8(components[0] * 255.0))
            intensities.append(UInt8(components[0] * 255.0))
        } else {
            // Intensities are different
            intensities.append(UInt8(components[0] * 255.0))
            intensities.append(UInt8(components[1] * 255.0))
            intensities.append(UInt8(components[2] * 255.0))
        }

        return intensities
    }
}
