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
//  ThingyPeripheral.swift
//
//  Created by Mostafa Berg on 05/10/16.
//
//

import CoreBluetooth

public typealias CompletionCallback = (Bool) -> (Void)
public typealias ValueCallback      = (Data) -> (Void)

public class ThingyPeripheral: NSObject, CBPeripheralDelegate {

    //MARK: - Thingy public properties
    
    /// Thingy name. This can be set by the user.
    public internal(set) var name         : String
    /// A flag indicating whether the Thingy is stored in the ThingyManager.
    public internal(set) var isStored     : Bool
    /// Battery level value in percent. It is available on Thingies running firmware 2.0.0 or newer.
    public internal(set) var batteryLevel : UInt8?
    /// The CBPeripheral object.
    public let basePeripheral : CBPeripheral
    /// Thingy state delegate.
    public weak var delegate  : ThingyPeripheralDelegate?
    
    public internal(set) var state: ThingyPeripheralState = .unavailable {
        didSet {
            if state == .disconnected {
                batteryLevel = nil
            }
            delegate?.thingyPeripheral(self, didChangeStateTo: state)
            if state == .disconnected {
                //Remove all notification handlers
                valueCallbackHandlers.removeAll()
                operationCallbackHandlers.removeAll()
                configurationService = nil
                userInterfaceService = nil
                environmentService = nil
                motionService = nil
                jumpToBootloaderService = nil
                services.removeAll()
            }
        }
    }
    
    /// This value returns true if Thingy is connected and services has been discovered, false otherwise.
    public var ready: Bool {
        return services.count > 0
    }
    
    /// This flag returns true if there is an ongoing Bluetooth LE opertation.
    public var busy: Bool {
        return operationCallbackHandlers.isEmpty == false
    }
    
    //MARK: - Thingy private properties
    private var services                  : [ThingyService]
    private var operationCallbackHandlers : [CompletionCallback]
    private var valueCallbackHandlers     : Dictionary<CBUUID, ValueCallback>
    private let doNothing                 : CompletionCallback = { (Bool) -> (Void) in }

    //Service method accessors
    private var configurationService    : ThingyConfigurationService?
    private var userInterfaceService    : ThingyUserInterfaceService?
    private var batteryService          : ThingyBatteryService?
    private var environmentService      : ThingyEnvironmentService?
    private var motionService           : ThingyMotionService?
    private var soundService            : ThingySoundService?
    private var jumpToBootloaderService : ThingyJumpToBootloaderService?

    //MARK: - Initialization
    required public init(withPeripheral aPeripheral: CBPeripheral, andDelegate aDelegate: ThingyPeripheralDelegate?) {
        isStored                     = false
        delegate                     = aDelegate
        basePeripheral               = aPeripheral
        services                     = [ThingyService]()
        operationCallbackHandlers    = [CompletionCallback]()
        valueCallbackHandlers = Dictionary<CBUUID, ValueCallback>()

        if aPeripheral.name == nil {
            name = "Thingy (No name)"
        } else {
            name = aPeripheral.name!
        }
        
        //Initial state is == base peripheral CBPeripheralState value
        state = ThingyPeripheralState(rawValue: aPeripheral.state.rawValue)!
        super.init()
        basePeripheral.delegate = self
    }

    //MARK: - Jump to bootloader service implementation
    public func jumpToBootloader() -> Bool {
        do {
            if let jumpToBootloaderService = jumpToBootloaderService {
                // Add handlers for "Start notifications" and "Send jump command"
                operationCallbackHandlers.append(doNothing)
                operationCallbackHandlers.append(doNothing)
                try jumpToBootloaderService.jumpToBootloaderMode()
            } else {
                return false
            }
        } catch {
            print(error)
            _ = operationCallbackHandlers.removeLast()
            _ = operationCallbackHandlers.removeLast()
            return false
        }
        return true
    }

    //MARK: - Configuration service implementation
    public func readFirmwareVersion() -> String? {
        return configurationService?.readFirmwareVersion()
    }

    public func readName() -> String? {
        return configurationService?.readName()
    }

    public func set(name aName: String, withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if configurationService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
           try configurationService!.set(name: aName)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func readAdvertisingParameters() -> (interval: UInt16, timeout: UInt8)? {
        return configurationService?.readAdvertisingParameters()
    }

    public func setAdvertisingParameters(interval anInterval: UInt16, timeout aTimeout: UInt8, withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if configurationService == nil {
            aHandler?(false)
            return
        }
        // Save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try configurationService!.set(advertisingInterval: anInterval, andTimeout: aTimeout)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func readEddystoneUrl() -> URL? {
        return configurationService?.readEddystoneUrl()
    }

    public func disableEddystone(withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if configurationService == nil {
            aHandler?(false)
            return
        }
        // Save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try configurationService!.disableEddystone()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func set(eddystoneUrl anURL: URL, withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if configurationService == nil {
            aHandler?(false)
            return
        }
        // Save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try configurationService!.set(eddystoneUrl: anURL)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func readCloudToken() -> String? {
        return configurationService?.readCloudToken()
    }
    
    public func set(cloudToken aToken: String, withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if configurationService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try configurationService!.set(cloudToken: aToken)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func readConnectionParameters() -> (minimumInterval: UInt16, maximumInterval: UInt16, slaveLatency: UInt16, supervisionTimeout: UInt16)? {
        return configurationService?.readConnectionParameters()
    }

    public func setConnectionParameters(minimumInterval aMinInterval: UInt16, maximumInterval aMaxInterval: UInt16, slaveLatency aSlaveLatency: UInt16, supervisionTimeout aSupervisionTimeout: UInt16, withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if configurationService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try configurationService!.set(minConnectionInterval: aMinInterval, maxConnectionInterval: aMaxInterval, slaveLatency: aSlaveLatency, andSupervisionTimeout: aSupervisionTimeout)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    //MARK: - User Interface Service implementations
    public func readLEDState() -> (mode: ThingyLEDMode, presetColor: ThingyLEDColorPreset?, rgbColor: UIColor?, intensity: UInt8?, breatheDelay: UInt16?)? {
        do {
            return try userInterfaceService?.readLEDState()
        } catch {
            print("Error reading LED data: \(error)")
            return nil
        }
    }
    
    public func turnOffLED(withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if userInterfaceService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try userInterfaceService!.turnOffLED()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func turnOnConstantLED(withCompletionHandler aHandler: CompletionCallback?, andColor aColor: UIColor) {
        // Has the service been found?
        if userInterfaceService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try userInterfaceService!.setConstantLED(withColor: aColor)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func turnOnOneShotLED(withCompletionHandler aHandler: CompletionCallback?, intensity anIntensityPercentage: UInt8, andPresetColor aPresetColor: ThingyLEDColorPreset) {
        // Has the service been found?
        if userInterfaceService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try userInterfaceService!.setOneShotLED(withPresetColor: aPresetColor, andIntensity: anIntensityPercentage)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func turnOnBreathingLED(withCompletionHandler aHandler: CompletionCallback?, presetColor aPresetColor: ThingyLEDColorPreset, intensity anIntensityPercentage: UInt8, andBreatheDelay aBreatheDelay: UInt16) {
        // Has the service been found?
        if userInterfaceService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try userInterfaceService!.setBreatheLED(withPresetColor: aPresetColor, intensity: anIntensityPercentage, andBreatheDelay: aBreatheDelay)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginButtonStateNotifications(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: ButtonNotificationCallback?) {
        // Has the service been found?
        if userInterfaceService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getButtonCharacteristicUUID()] = { (buttonData) -> (Void) in
            let buttonValue     = UInt8(buttonData[0])
            let buttonState     = ThingyButtonState(rawValue: buttonValue) ?? .unknown
            aNotificationHandler?(buttonState)
        }
        // Were notifications already enabled?
        if userInterfaceService!.buttonNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try userInterfaceService!.beginButtonNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getButtonCharacteristicUUID())
        }
    }
    
    public func stopButtonStateUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getButtonCharacteristicUUID())
        // Has the service been found?
        if userInterfaceService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try userInterfaceService!.stopButtonNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    //MARK: - Environment Service implementateion
    public func setEnvironmentConfiguration(temperatureInterval temperatureIntervalInterval: UInt16,
                                            pressureInterval: UInt16,
                                            humidityInterval: UInt16,
                                            lightIntensityInterval: UInt16,
                                            gasMode: ThingyEnvironmentGasModeConfiguration,
                                            redCalibration: UInt8,
                                            greenCalibration: UInt8,
                                            blueCalbiration: UInt8,
                                            withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if environmentService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try environmentService!.setConfiguration(temperatureInterval: temperatureIntervalInterval,
                                                     pressureInterval: pressureInterval,
                                                     humidityInterval: humidityInterval,
                                                     lightIntensityInterval: lightIntensityInterval,
                                                     gasMode: gasMode, redCalibration: redCalibration, greenCalibration: greenCalibration, blueCalibration: blueCalbiration)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func readEnvironmentConfiguration() -> (temperatureInterval: UInt16, pressureInterval: UInt16, humidityInterval: UInt16, lightIntensityInterval: UInt16, gasMode: ThingyEnvironmentGasModeConfiguration, redCalibration: UInt8, greenCalibration: UInt8, blueCalibration: UInt8)? {
        return environmentService?.readConfiguration()
    }
    
    public func beginTemperatureUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler : TemperatureNotificationCallback?) {
        // Has the service been found?
        if environmentService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getTemperatureCharacteristicUUID()] = { (temperatureData) -> (Void) in
            let digit        = Int8(truncatingIfNeeded: Int(temperatureData[0]))
            let remainder    = UInt8(temperatureData[1])
            var temp = Float(digit)
            temp += Float(remainder) / 100
            aNotificationHandler?(temp)
        }
        // Were notifications already enabled?
        if environmentService!.temperatureNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try environmentService!.beginTemperatureNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getTemperatureCharacteristicUUID())
        }
    }
    
    public func stopTemperatureUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getTemperatureCharacteristicUUID())
        // Has the service been found?
        if environmentService == nil || environmentService!.temperatureNotificationsEnabled == false {
            aHandler?(environmentService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try environmentService!.stopTemperatureNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginHumidityUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: HumidityNotificationCallback?) {
        // Has the service been found?
        if environmentService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getHumidityCharacteristicUUID()] = { (humidityData) -> (Void) in
            let humidity = UInt8(humidityData[0])
            aNotificationHandler?(humidity)
        }
        // Were notifications already enabled?
        if environmentService!.humidityNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try environmentService!.beginHumidityNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getHumidityCharacteristicUUID())
        }
    }
    
    public func stopHumidityUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getHumidityCharacteristicUUID())
        // Has the service been found?
        if environmentService == nil || environmentService!.humidityNotificationsEnabled == false {
            aHandler?(environmentService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try environmentService!.stopHumidityNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func beginAirQualityUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: AirQualityNotificationCallback?) {
        // Has the service been found?
        if environmentService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getAirQualityCharacteristicUUID()] = { (data) -> (Void) in
            var eCO2 : UInt16 = 0
            var tvoc : UInt16  = 0
            (data as NSData).getBytes(&eCO2, range: NSRange(location: 0, length: 2))
            (data as NSData).getBytes(&tvoc, range: NSRange(location: 2, length: 2))
            aNotificationHandler?(eCO2, tvoc)
        }
        // Were notifications already enabled?
        if environmentService!.airQualityNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try environmentService!.beginAirQualityNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getAirQualityCharacteristicUUID())
        }
    }
    
    public func stopAirQualityUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getAirQualityCharacteristicUUID())
        // Has the service been found?
        if environmentService == nil || environmentService!.airQualityNotificationsEnabled == false {
            aHandler?(environmentService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try environmentService!.stopAirQualityNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func beginLightIntensityUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: LightIntensityNotificationCallback?) {
        // Has the service been found?
        if environmentService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getLightIntensityCharacteristicUUID()] = { (data) -> (Void) in
            // This algorithm converts light intensities to RGB color. It "works" assuming the Thingy board is placed in the plastic box which is blueish.
            let clear_at_black: Float = 300.0
            let clear_at_white: Float = 400.0
            let clear_diff = clear_at_white - clear_at_black

            let redIntensity   = (UInt16(data[1]) << 8) + UInt16(data[0])
            let greenIntensity = (UInt16(data[3]) << 8) + UInt16(data[2])
            let blueIntensity  = (UInt16(data[5]) << 8) + UInt16(data[4])
            let clearIntensity = (UInt16(data[7]) << 8) + UInt16(data[6])
            let totalIntensity = Float(max(Int(redIntensity) + Int(greenIntensity) + Int(blueIntensity), 1)) // max to avoid division by 0

            let redRatio       = Float(redIntensity)   / totalIntensity
            let greenRatio     = Float(greenIntensity) / totalIntensity
            let blueRatio      = Float(blueIntensity)  / totalIntensity

            let clear_normalized = max((Float(clearIntensity) - clear_at_black) / clear_diff, 0) // Cannot go below 0

            let r = min(redRatio   * 255.0 * 3.0 * Float(clear_normalized), 255.0)
            let g = min(greenRatio * 255.0 * 3.0 * Float(clear_normalized), 255.0)
            let b = min(blueRatio  * 255.0 * 3.0 * Float(clear_normalized), 255.0)
            let color = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1.0))
            aNotificationHandler?(redIntensity, greenIntensity, blueIntensity, clearIntensity, color)
        }
        // Were notifications already enabled?
        if environmentService!.lightIntensityNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try environmentService!.beginLightIntensityNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getLightIntensityCharacteristicUUID())
        }
    }
    
    public func stopLightIntensityUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getLightIntensityCharacteristicUUID())
        // Has the service been found?
        if environmentService == nil || environmentService!.lightIntensityNotificationsEnabled == false {
            aHandler?(environmentService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try environmentService?.stopLightIntensityNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func beginPressureUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: PressureNotificationCallback?) {
        // Has the service been found?
        if environmentService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getPressureCharacteristicUUID()] = { (pressureData) -> (Void) in
            var pressure : UInt32 = 0
            var decimal  : UInt8  = 0
            (pressureData as NSData).getBytes(&pressure, range: NSRange(location: 0, length: 4))
            (pressureData as NSData).getBytes(&decimal, range: NSRange(location: 4, length: 1))
            
            var doubleVal = Double(pressure)
            let decimalVal = Double(decimal)
            if decimal < 10 {
                doubleVal += decimalVal / 10
            } else if decimal < 100 {
                doubleVal += decimalVal / 100
            } else {
                doubleVal += decimalVal / 1000
            }
            aNotificationHandler?(doubleVal)
        }
        // Were notifications already enabled?
        if environmentService!.pressureNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try environmentService!.beginPressureNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getPressureCharacteristicUUID())
        }
    }

    public func stopPressureUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getPressureCharacteristicUUID())
        // Has the service been found?
        if environmentService == nil || environmentService!.pressureNotificationsEnabled == false {
            aHandler?(environmentService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try environmentService!.stopPressureNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    //MARK: - Motion Service Implementation
    public func setMotionConfiguration(pedometerInterval aPedometerInterval: UInt16, temperatureCompensationInterval aTemperatureComensationInterval: UInt16, compassInterval aCompassInterval: UInt16, motionProcessingInterval aProcessingInterval: UInt16, wakeOnMotion aWakeOnMotionFlag: Bool, withCompletionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try motionService!.setConfiguration(pedometerInterval: aPedometerInterval, temperatureCompensationInterval: aTemperatureComensationInterval, compassInterval: aCompassInterval, motionProcessingFrequency: aProcessingInterval, wakeOnMotion: aWakeOnMotionFlag)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func readMotionConfiguration() -> (pedometerInterval: UInt16, temperatureCompensationInterval: UInt16, compassInterval: UInt16, motionProcessingFrequency: UInt16, andWakeOnMotion: Bool)? {
        return motionService?.readConfiguration()
    }
    
    public func beginTapUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: TapNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getTapCharacteristicUUID()] = { (tapData) -> (Void) in
            let tapDirection = ThingyTapDirection(rawValue: tapData[0]) ?? .unsupported
            let tapCount     = tapData[1]
            aNotificationHandler?(tapDirection, tapCount)
        }
        // Were notifications already enabled?
        if motionService!.tapNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginTapNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getTapCharacteristicUUID())
        }
    }

    public func stopTapUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getTapCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.tapNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopTapNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func beginOrientationUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: OrientationNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getOrientationCharacteristicUUID()] = { (orientationData) -> (Void) in
            let orientation = ThingyOrientation(rawValue: orientationData[0]) ?? .unsupported
            aNotificationHandler?(orientation)
        }
        // Were notifications already enabled?
        if motionService!.orientationNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginOrientationNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getOrientationCharacteristicUUID())
        }
    }
    
    public func stopOrientationUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getOrientationCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.orientationNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopOrientationNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginQuaternionUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: QuaternionNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getQuaternionCharacteristicUUID()] = { (quaternionData) -> (Void) in
            let quaternionArray = quaternionData.toArray(type: Int32.self)
            let w = Float(quaternionArray[0]) / Float(1 << 30)
            let x = Float(quaternionArray[1]) / Float(1 << 30)
            let y = Float(quaternionArray[2]) / Float(1 << 30)
            let z = Float(quaternionArray[3]) / Float(1 << 30)
            aNotificationHandler?(w,x,y,z)
        }
        // Were notifications already enabled?
        if motionService!.quaternionNotificationsEnabled {
            aHandler?(true)
            return
        }

        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginQuaternionNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getQuaternionCharacteristicUUID())
        }
    }

    public func stopQuaternionUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getQuaternionCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.quaternionNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopQuaternionNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func beginEulerUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: EulerNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getEulerCharacteristicUUID()] = { (eulerData) -> (Void) in
            let eulerArray = eulerData.toArray(type: Int32.self)
            let roll  = Float(eulerArray[0]) / Float((1 << 16))
            let pitch = Float(eulerArray[1]) / Float((1 << 16))
            let yaw   = Float(eulerArray[2]) / Float((1 << 16))
            aNotificationHandler?(roll, pitch, yaw)
        }
        // Were notifications already enabled?
        if motionService!.eulerNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginEulerNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getEulerCharacteristicUUID())
        }
    }

    public func stopEulerUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getEulerCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.eulerNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopEulerNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginPedometerUpdates(withCompletoinHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: PedometerNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getPedometerCharacteristicUUID()] = { (pedometerData) -> (Void) in
            let pedometerArray = pedometerData.toArray(type: UInt32.self)
            let steps     = pedometerArray[0]
            let timestamp = pedometerArray[1]
            aNotificationHandler?(steps, timestamp)
        }
        // Were notifications already enabled?
        if motionService!.pedometerNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginPedometerNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getPedometerCharacteristicUUID())
        }
    }
    
    public func stopPedometerUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getPedometerCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.pedometerNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopPedometerNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginRawDataUpdates(withCompletoinHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: RawDataNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getRawDataCharacteristicUUID()] = { (rawData) -> (Void) in
            let rawDataArray = rawData.toArray(type: Int16.self)
            
            var accelerometerData = [Float]()
            var gyroscopeData     = [Float]()
            var compassData       = [Float]()
            //Accelerometer
            accelerometerData.append(Float(rawDataArray[0]) / Float(2 << 14))
            accelerometerData.append(Float(rawDataArray[1]) / Float(2 << 14))
            accelerometerData.append(Float(rawDataArray[2]) / Float(2 << 14))
            //Gyroscope
            gyroscopeData.append(Float(rawDataArray[3]) / Float(2 << 14))
            gyroscopeData.append(Float(rawDataArray[4]) / Float(2 << 14))
            gyroscopeData.append(Float(rawDataArray[5]) / Float(2 << 14))
            //Compass
            compassData.append(Float(rawDataArray[6]) / Float(2 << 14))
            compassData.append(Float(rawDataArray[7]) / Float(2 << 14))
            compassData.append(Float(rawDataArray[8]) / Float(2 << 14))
            
            aNotificationHandler?(accelerometerData, gyroscopeData, compassData)
        }
        // Were notifications already enabled?
        if motionService!.rawDataNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginRawDataNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getRawDataCharacteristicUUID())
        }
    }
    
    public func stopRawDataUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getRawDataCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.rawDataNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopRawDataNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginHeadingUpdates(withCompletoinHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: HeadingNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getHeadingCharacteristicUUID()] = { (headingData) -> (Void) in
            let headingValue = Float(headingData.toArray(type: Int32.self)[0]) / Float(1 << 16)
            aNotificationHandler?(headingValue)
        }
        // Were notifications already enabled?
        if motionService!.headingNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginHeadingNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getHeadingCharacteristicUUID())
        }
    }

    public func stopHeadingataUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getHeadingCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.headingNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService?.stopHeadingNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginGravityVectorUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: GravityVectorNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getGravityVectorCharacteristicUUID()] = { (gravityVectorData) -> (Void) in
            let gravityVectorArray = gravityVectorData.toArray(type: UInt32.self)
            let x = Float(bitPattern: gravityVectorArray[0])
            let y = Float(bitPattern: gravityVectorArray[1])
            let z = Float(bitPattern: gravityVectorArray[2])
            aNotificationHandler?(x, y, z)
        }
        // Were notifications already enabled?
        if motionService!.gravityVectorNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try motionService!.beginGravityVectorNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getGravityVectorCharacteristicUUID())
        }
    }
    
    public func stopGravityVectorUpdates(withCompletionHandler aHandler : CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getGravityVectorCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.gravityVectorNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopGravityVectorNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }

    public func beginRotationMatrixUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler : RotationMatrixNotificationCallback?) {
        // Has the service been found?
        if motionService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getRotationMatrixCharacteristicUUID()] = { (rotationMatrixData) -> (Void) in
            let rotationMatrixArray = rotationMatrixData.toArray(type: Int16.self)
            var rotationMatrix = [[Int16]]()
            
            let row0 : [Int16] = [rotationMatrixArray[0], rotationMatrixArray[1], rotationMatrixArray[2]]
            let row1 : [Int16] = [rotationMatrixArray[3], rotationMatrixArray[4], rotationMatrixArray[5]]
            let row2 : [Int16] = [rotationMatrixArray[6], rotationMatrixArray[7], rotationMatrixArray[8]]
            
            rotationMatrix.append(row0)
            rotationMatrix.append(row1)
            rotationMatrix.append(row2)
            
            aNotificationHandler?(rotationMatrix)
        }
        // Were notifications already enabled?
        if motionService!.rotationMatrixNotificationsEnabled {
            aHandler?(true)
            return
        }
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        
        do {
            try motionService!.beginRotationMatrixNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getRotationMatrixCharacteristicUUID())
        }        
    }
    
    public func stopRotationMatrixUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getRotationMatrixCharacteristicUUID())
        // Has the service been found?
        if motionService == nil || motionService!.rotationMatrixNotificationsEnabled == false {
            aHandler?(motionService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try motionService!.stopRotationMatrixNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    //MARK: - Sound service implementation
    public func setSoundConfiguration(speakerMode: ThingySpeakerMode, andMicrophoneMode micMode: ThingyMicrophoneMode, withCompletitionHandler aHandler: CompletionCallback?) {
        // Has the service been found?
        guard let soundService = soundService else {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to write data
        do {
            try soundService.set(speakerMode: speakerMode, microphoneMode: micMode)
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func readSoundConfiguration() -> (speakerMode: ThingySpeakerMode, microphoneMode: ThingyMicrophoneMode)? {
        return soundService?.readConfiguration()
    }
    
    public func play(toneWithFrequency frequency: UInt16, forMilliseconds duration: UInt16, andVolume volume: UInt8) {
        // Has the service been found?
        guard let soundService = soundService else {
            return
        }
        let play: CompletionCallback = { (success) -> (Void) in
            if success {
                do {
                    try soundService.play(toneWithFrequency: frequency, forMilliseconds: duration, andVolume: volume)
                } catch {
                    print(error)
                }
            }
        }
        if readSoundConfiguration()!.speakerMode != .frequencyAndDuration {
            setSoundConfiguration(speakerMode: .frequencyAndDuration, andMicrophoneMode: .adpcm, withCompletitionHandler: play)
        } else {
            play(true)
        }
    }
    
    public func play(soundEffect: ThingySoundEffect) {
        // Has the service been found?
        guard let soundService = soundService else {
            return
        }
        let play: CompletionCallback = { (success) -> (Void) in
            if success {
                do {
                    try soundService.play(soundEffect: soundEffect)
                } catch {
                    print(error)
                }
            }
        }
        if readSoundConfiguration()!.speakerMode != .soundEffect {
            setSoundConfiguration(speakerMode: .soundEffect, andMicrophoneMode: .adpcm, withCompletitionHandler: play)
        } else {
            play(true)
        }
    }
    
    /// This method accepts a 16-bit PCM data without the header.
    /// The first 44 bytes of a wav file should be skipped prior to calling it.
    public func play(pcm16bit data: Data) {
        var pcm8bit = Data(count: data.count / 2)
        for i in stride(from: 0, to: data.count, by: 2) {
            let value16bit = Int16(data[i]) | (Int16(data[i + 1]) << 8)
            pcm8bit[i / 2] = UInt8(value16bit / 256 + 128)
        }
        play(pcm8bit: pcm8bit)
    }
    
    /// This method accepts a 8-bit PCM data without the header.
    /// The first 44 bytes of a wav file should be skipped prior to calling it.
    public func play(pcm8bit data: Data) {
        // Has the service been found?
        guard let soundService = soundService else {
            return
        }
        let play: CompletionCallback = { (success) -> (Void) in
            if success {
                do {
                    self.valueCallbackHandlers[getSpeakerStatusCharacteristicUUID()] = { (data) -> (Void) in
                        // Status Values:
                        // 1  = buffer full,
                        // 2  = buffer ready,
                        // 16 = packet disregarded (0x10),
                        // 0  = buffer empty
                        let bufferFull = data[0] == 0x01 || data[0] == 0x10
                        soundService.bufferFull = bufferFull
                    }
                    if soundService.statusNotificationsEnabled == false {
                        // Dummy callback handler for enabling notifications
                        self.operationCallbackHandlers.append(self.doNothing)
                        try soundService.beginSpeakerStatusNotifications()
                    }
                    // Play data
                    try soundService.play(pcm: data)
                } catch {
                    print(error)
                }
            }
        }
        if readSoundConfiguration()!.speakerMode != .eightBitPCM {
            setSoundConfiguration(speakerMode: .eightBitPCM, andMicrophoneMode: .adpcm, withCompletitionHandler: play)
        } else {
            play(true)
        }
    }
    
    public func stopSpeakerStatusNotifications(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getSpeakerStatusCharacteristicUUID())
        // Has the service been found?
        guard let soundService = soundService, soundService.statusNotificationsEnabled else {
            aHandler?(self.soundService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try soundService.stopSpeakerStatusNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    public func beginMicrophoneUpdates(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: MicrophoneNotificationCallback?) {
        // Has the service been found?
        guard let soundService = soundService else {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getMicrophoneCharacteristicUUID()] = { (microphoneData) -> (Void) in
            if let pcm16Bit = soundService.decodeAdpcm(data: microphoneData) {
                aNotificationHandler?(pcm16Bit)
            }
        }
        // Were notifications already enabled?
        if soundService.microphoneNotificationsEnabled {
            aHandler?(true)
            return
        }
        // Prepare a task that will enable microphone notifications
        let startMicrophone: CompletionCallback = { (success) -> (Void) in
            if success {
                // Save the completion callback
                self.operationCallbackHandlers.append(aHandler ?? self.doNothing)
                // and try to enable notifications
                do {
                    try soundService.beginMicrophoneNotifications()
                } catch {
                    print(error)
                    aHandler?(false)
                    _ = self.operationCallbackHandlers.removeLast()
                    self.valueCallbackHandlers.removeValue(forKey: getMicrophoneCharacteristicUUID())
                }
            } else {
                print("Setting ADPCM failed")
                aHandler?(false)
                self.valueCallbackHandlers.removeValue(forKey: getMicrophoneCharacteristicUUID())
            }
        }
        // Check the mic mode. Only ADPCM is supported here. If SPL is set, switch to ADPCM before starting microphone updates.
        let modes = soundService.readConfiguration()
        guard modes?.microphoneMode == .adpcm else {
            setSoundConfiguration(speakerMode: .eightBitPCM, andMicrophoneMode: .adpcm, withCompletitionHandler: startMicrophone)
            return
        }
        // Microphone mode is correct, let's hear it!
        startMicrophone(true)
    }
    
    public func stopMicrophoneUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getMicrophoneCharacteristicUUID())
        // Has the service been found?
        guard let soundService = soundService, soundService.microphoneNotificationsEnabled else {
            aHandler?(self.soundService != nil)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try soundService.stopMicrophoneNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
    }
    
    //MARK: - Battery service implementation
    public func beginBatteryLevelNotifications(withCompletionHandler aHandler: CompletionCallback?, andNotificationHandler aNotificationHandler: BatteryNotificationCallback?) {
        // Has the service been found?
        if batteryService == nil {
            aHandler?(false)
            return
        }
        // Save the notification callback. This may overwrite the old one if such existed
        valueCallbackHandlers[getBatteryLevelCharacteristicUUID()] = { (batteryData) -> (Void) in
            self.batteryLevel = UInt8(batteryData[0])
            aNotificationHandler?(self.batteryLevel!)
        }
        
        // Were notifications already enabled?
        if batteryService!.batteryNotificationsEnabled {
            aHandler?(true)
            return
        }
        
        // If not, save the completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to enable notifications
        do {
            try batteryService!.beginBatteryNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
            valueCallbackHandlers.removeValue(forKey: getBatteryServiceUUID())
        }
    }
    
    public func stopBatteryLevelUpdates(withCompletionHandler aHandler: CompletionCallback?) {
        // Forget the notification callback
        valueCallbackHandlers.removeValue(forKey: getBatteryServiceUUID())
        // Has the service been found?
        if batteryService == nil {
            aHandler?(false)
            return
        }
        // Save he completion callback
        operationCallbackHandlers.append(aHandler ?? doNothing)
        // and try to disable notifications
        do {
            try batteryService!.stopBatteryNotifications()
        } catch {
            print(error)
            aHandler?(false)
            _ = operationCallbackHandlers.removeLast()
        }
        batteryLevel = nil // invalidate Battery Level
    }

    //MARK: - Discovery
    public func discoverServices() {
        if basePeripheral.services?.isEmpty ?? true {
            state = .discoveringServices
            basePeripheral.discoverServices(getAllThingyServices())
        } else {
            // All Thingy services were already discovered
            state = .ready
        }
    }

    internal func discoverCharacteristics(forService aService: ThingyService) {
        if state != .discoveringCharacteristics {
            state = .discoveringCharacteristics
        }
        basePeripheral.discoverCharacteristics(nil, for: aService.baseService)
    }

    //MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral.services != nil else {
            return
        }

        services.removeAll()
        for aService in basePeripheral.services! {
            var thingyService: ThingyService
            
            if aService.uuid == getConfigurationServiceUUID() {
                thingyService = ThingyConfigurationService(withService: aService)
                configurationService = thingyService as? ThingyConfigurationService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            } else if aService.uuid == getUIServiceUUID() {
                thingyService = ThingyUserInterfaceService(withService: aService)
                userInterfaceService = thingyService as? ThingyUserInterfaceService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            } else if aService.uuid == getEnvironmentServiceUUID() {
                thingyService = ThingyEnvironmentService(withService: aService)
                environmentService = thingyService as? ThingyEnvironmentService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            } else if aService.uuid == getMotionServiceUUID() {
                thingyService = ThingyMotionService(withService: aService)
                motionService = thingyService as? ThingyMotionService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            } else if aService.uuid == getSoundServiceUUID() {
                thingyService = ThingySoundService(withService: aService)
                soundService = thingyService as? ThingySoundService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            } else if aService.uuid == getSecureDFUServiceUUID() {
                thingyService = ThingyJumpToBootloaderService(withService: aService)
                jumpToBootloaderService = thingyService as? ThingyJumpToBootloaderService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            } else if aService.uuid == getBatteryServiceUUID() {
                thingyService = ThingyBatteryService(withService: aService)
                batteryService = thingyService as? ThingyBatteryService
                discoverCharacteristics(forService: thingyService)
                services.append(thingyService)
            }
        }
        
        if services.isEmpty {
            state = .notSupported
        }
    }

    private var tmpCharacteristic: CBCharacteristic?
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard service.characteristics != nil else {
            return
        }

        var newCharacteristics = [ThingyCharacteristic]()
        let targetService = servicesGetWrapper(baseService: service)

        if targetService == nil {
            print("Warning: got characteristics of a non-saved service")
        } else {
            // Get all Characteristics
            for aCharacteristic in service.characteristics! {
                let thingyCharacteristic = ThingyCharacteristic(withCharacteristic: aCharacteristic, andName: "\(targetService!.name) Service Characteristic")
                newCharacteristics.append(thingyCharacteristic)
                if aCharacteristic.properties.contains(.read) {
                    tmpCharacteristic = aCharacteristic
                    peripheral.readValue(for: aCharacteristic)
                }
            }
            targetService!.add(characteristics: newCharacteristics)
        }

        // After all characteristics were discovered they will be automatically read and peripheral:didUpdateValueFor:error method will be called
        // several times. When last characteristic is read the state will change to .ready
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            // Update device name if the UUID matches
            if characteristic.uuid == getDeviceNameCharacteristicUUID() {
                if let nameData = characteristic.value {
                    name = String(data: nameData, encoding: .utf8)!
                }
            } else if characteristic.uuid == getBatteryLevelCharacteristicUUID() {
                if let batteryData = characteristic.value {
                    batteryLevel = UInt8(batteryData[0])
                }
            }
            // When characteristic discovery and reading is complete, set the state to .ready
            if state == .discoveringCharacteristics && characteristic == tmpCharacteristic {
                tmpCharacteristic = nil
                state = .ready
                return
            }
            valueCallbackHandlers[characteristic.uuid]?(characteristic.value!)
        } else {
            print("Characteristic value update error: \(error!.localizedDescription)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.properties.contains(.write) == false {
            // On iOS 10.1.x there was a bug which caused this callback to be invoked also after writing
            // to a characteristic without a response. As doc says: this should only be called after writing with response.
            // We should return here as the callback handler has not been added to such write.
            return
        }
        if error == nil {
            // A value has been written to the characteristic. In order to make it available in cache we have to read it as well.
            if characteristic.properties.contains(.read) && characteristic.uuid != getSoundConfigurationCharacteristicUUID() {
                // First, put the operation callback to the end of the queue. It will be notified when the value was read successfully.
                let readOperationCallback = operationCallbackHandlers.removeFirst()
                let originalValueCallback = valueCallbackHandlers[characteristic.uuid]
                // Define a new value callback that will be called when the characteristic value is read.
                valueCallbackHandlers[characteristic.uuid] = { _ in
                    // --------
                    // Warning: we assume here that the readValue operation will succeed and this callback will be called!
                    // --------
                    // Restore the original value callback or remove if there wasn't such
                    if originalValueCallback != nil {
                        self.valueCallbackHandlers[characteristic.uuid] = originalValueCallback
                    } else {
                        self.valueCallbackHandlers.removeValue(forKey: characteristic.uuid)
                    }
                    // Confirm the write operation here. Actually we confirm write and read operations.
                    // You may use `busy` property in this callback
                    readOperationCallback(true)
                }
                
                peripheral.readValue(for: characteristic)
            } else {
                operationCallbackHandlers.removeFirst()(true)
            }
        } else {
            operationCallbackHandlers.removeFirst()(false)
            print("Characteristic write error: \(error!.localizedDescription)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil {
            operationCallbackHandlers.removeFirst()(true)
            if characteristic.isNotifying == false {
                // Callback was removed in stop...Updates method
                // valueCallbackHandlers.removeValue(forKey: characteristic.uuid)
            }
        } else {
            operationCallbackHandlers.removeFirst()(false)
            print("Notification state update error: \(error!.localizedDescription)")
        }
    }

    //MARK: - Convenience Methods
    public override func isEqual(_ object: Any?) -> Bool {
        if object != nil {
            if object is CBPeripheral {
                return basePeripheral.identifier == (object as! CBPeripheral).identifier
            } else if object is ThingyPeripheral {
                return basePeripheral.identifier == (object as! ThingyPeripheral).basePeripheral.identifier
            }
        }
        return false
    }

    private func servicesGetWrapper(baseService: CBService) -> ThingyService? {
        for service in services where service.baseService.uuid == baseService.uuid {
            return service
        }
        return nil
    }
}
 
