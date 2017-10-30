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
//  ThingyMotionService.swift
//
//  Created by Mostafa Berg on 02/11/2016.
//

import UIKit
import CoreBluetooth

public typealias TapNotificationCallback         = (_ direction: ThingyTapDirection, _ count: UInt8) -> (Void)
public typealias OrientationNotificationCallback = (_ orientation: ThingyOrientation) -> (Void)
public typealias QuaternionNotificationCallback  = (_ w: Float, _ x: Float, _ y: Float, _ z: Float) -> (Void)
public typealias EulerNotificationCallback  = (_ roll: Float, _ pitch: Float,  _ yaw: Float) -> (Void)
public typealias PedometerNotificationCallback  = (_ steps: UInt32, _ time: UInt32) -> (Void)
public typealias RawDataNotificationCallback  = (_ accelerometerData: [Float], _ gyroscopeData: [Float], _ compassData: [Float]) -> (Void)
public typealias HeadingNotificationCallback  = (_ heading: Float) -> (Void)
public typealias GravityVectorNotificationCallback  = (_ x: Float,_  y: Float, _ z: Float) -> (Void)
public typealias RotationMatrixNotificationCallback  = (_ matrix: [[Int16]]) -> (Void)

public enum ThingyTapDirection: UInt8 {
    case XUp              = 0x01
    case XDown            = 0x02
    case YUp              = 0x03
    case YDown            = 0x04
    case ZUp              = 0x05
    case ZDown            = 0x06
    case unsupported      = 0xFF
}

public enum ThingyOrientation: UInt8 {
    case portrait         = 0x00
    case landscape        = 0x01
    case reversePortrait  = 0x02
    case reverseLandscape = 0x03
    case unsupported      = 0xFF
}

public enum ThingyMotionError: Error {
    case charactersticNotDiscovered(characteristicName: String)
}

internal class ThingyMotionService: ThingyService {
    internal var tapNotificationsEnabled: Bool {
        return getTapCharacteristic()?.isNotifying ?? false
    }
    internal var orientationNotificationsEnabled: Bool {
        return getOrientationCharacteristic()?.isNotifying ?? false
    }
    internal var quaternionNotificationsEnabled: Bool {
        return getQuaternionCharacteristic()?.isNotifying ?? false
    }
    internal var eulerNotificationsEnabled: Bool {
        return getEulerCharacteristic()?.isNotifying ?? false
    }
    internal var pedometerNotificationsEnabled: Bool {
        return getPedometerCharacteristic()?.isNotifying ?? false
    }
    internal var rawDataNotificationsEnabled: Bool {
        return getRawDataCharacteristic()?.isNotifying ?? false
    }
    internal var rotationMatrixNotificationsEnabled: Bool {
        return getRotationMatrixCharacteristic()?.isNotifying ?? false
    }
    internal var headingNotificationsEnabled: Bool {
        return getHeadingCharacteristic()?.isNotifying ?? false
    }
    internal var gravityVectorNotificationsEnabled: Bool {
        return getGravityVectorCharacteristic()?.isNotifying ?? false
    }

    //MARK: - Initialization
    required internal init(withService aService: CBService) {
        super.init(withName: "Motion service", andService: aService)
    }
    
    //MARK: - Motion service implementation -
    
    //MARK: - Tap Characteristic
    internal func beginTapNotifications() throws {
        if let tapCharcateristic = getTapCharacteristic() {
            tapCharcateristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Tap")
        }
    }
    
    internal func stopTapNotifications() throws {
        if let tapCharcateristic = getTapCharacteristic() {
            tapCharcateristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Tap")
        }
    }

    //MARK: - Orientation Charcateristic
    internal func beginOrientationNotifications() throws {
        if let orientationCharcateristic = getOrientationCharacteristic() {
            orientationCharcateristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Orientation")
        }
    }
    
    internal func stopOrientationNotifications() throws {
        if let orientationCharcateristic = getOrientationCharacteristic() {
            orientationCharcateristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Orientation")
        }
    }
    
    internal func beginQuaternionNotifications() throws {
        if let quaternionCharcteristic = getQuaternionCharacteristic() {
            quaternionCharcteristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Quaternion")
        }
    }
    
    internal func stopQuaternionNotifications() throws {
        if let quaternionCharcateristic = getQuaternionCharacteristic() {
            quaternionCharcateristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Quaternion")
        }
    }

    internal func beginEulerNotifications() throws {
        if let eulerCharcteristic = getEulerCharacteristic() {
            eulerCharcteristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Euler Angles")
        }
    }
    
    internal func stopEulerNotifications() throws {
        if let eulerCharacteristic = getEulerCharacteristic() {
            eulerCharacteristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Euler Angles")
        }
    }
    
    internal func beginPedometerNotifications() throws {
        if let pedometerCharacteristic = getPedometerCharacteristic() {
            pedometerCharacteristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Pedometer")
        }
    }
    
    internal func stopPedometerNotifications() throws {
        if let pedometerCharacteristic = getPedometerCharacteristic() {
            pedometerCharacteristic.stopNotifications()
       } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Pedometer")
        }
    }

    internal func beginRawDataNotifications() throws {
        if let rawDataCharcateristic = getRawDataCharacteristic() {
            rawDataCharcateristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Raw Data")
        }
    }
    
    internal func stopRawDataNotifications() throws {
        if let rawDataCharacteristic = getRawDataCharacteristic() {
            rawDataCharacteristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Raw Data")
        }
    }

    internal func beginRotationMatrixNotifications() throws {
        if let rotationMatrixCharcateristic = getRotationMatrixCharacteristic() {
            rotationMatrixCharcateristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Rotation Matrix")
        }
    }
    
    internal func stopRotationMatrixNotifications() throws {
        if let rotationMatrixcharacteristic = getRotationMatrixCharacteristic() {
            rotationMatrixcharacteristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Rotation Matrix")
        }
    }

    internal func beginHeadingNotifications() throws {
        if let headingCharcateristic = getHeadingCharacteristic() {
            headingCharcateristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Heading")
        }
    }
    
    internal func stopHeadingNotifications() throws {
        if let headingCharacteristic = getHeadingCharacteristic() {
            headingCharacteristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Heading")
        }
    }

    internal func beginGravityVectorNotifications() throws {
        if let gravityVectorCharcateristic = getGravityVectorCharacteristic() {
            gravityVectorCharcateristic.startNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Gravity Vector")
        }
    }
    
    internal func stopGravityVectorNotifications() throws {
        if let gravicyVectorCharcateristic = getGravityVectorCharacteristic() {
            gravicyVectorCharcateristic.stopNotifications()
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Gravicy Vector")
        }
    }

    internal func setConfiguration(pedometerInterval: UInt16, temperatureCompensationInterval: UInt16, compassInterval: UInt16, motionProcessingFrequency: UInt16, wakeOnMotion: Bool) throws {
        if let configurationCharacteristic = getConfigurationCharacteristic() {
            var dataArray = [UInt8]()
            dataArray.append(UInt8(pedometerInterval & 0x00FF))
            dataArray.append(UInt8(pedometerInterval >> 8))
            dataArray.append(UInt8(temperatureCompensationInterval & 0x00FF))
            dataArray.append(UInt8(temperatureCompensationInterval >> 8))
            dataArray.append(UInt8(compassInterval & 0x00FF))
            dataArray.append(UInt8(compassInterval >> 8))
            dataArray.append(UInt8(motionProcessingFrequency & 0x00FF))
            dataArray.append(UInt8(motionProcessingFrequency >> 8))
            dataArray.append(UInt8(wakeOnMotion ? 0x01 : 0x00))
            
            let data = Data(bytes: dataArray)            
            configurationCharacteristic.writeValue(withData: data)
        } else {
            throw ThingyMotionError.charactersticNotDiscovered(characteristicName: "Configuration")
        }
    }
    
    internal func readConfiguration() -> (pedometerInterval: UInt16, temperatureCompensationInterval: UInt16, compassInterval: UInt16, motionProcessingFrequency: UInt16, andWakeOnMotion: Bool) {
        if let motionConfigurationCharacteristic = getConfigurationCharacteristic() {
            let motionConfigurationData = motionConfigurationCharacteristic.value
            
            if motionConfigurationData != nil {
                let byteArray = [UInt8](motionConfigurationData!)
                let pedometerInterval               : UInt16 = UInt16(byteArray[0]) | UInt16(byteArray[1]) << 8
                let temperatureCompensationInterval : UInt16 = UInt16(byteArray[2]) | UInt16(byteArray[3]) << 8
                let compassInterval                 : UInt16 = UInt16(byteArray[4]) | UInt16(byteArray[5]) << 8
                let motionProcessingFrequency       : UInt16 = UInt16(byteArray[6]) | UInt16(byteArray[7]) << 8
                let wakeOnMotion                    : Bool   = byteArray[8] == 0x01
                
                return(pedometerInterval, temperatureCompensationInterval,compassInterval, motionProcessingFrequency, wakeOnMotion)
            }
        }
        return (0, 0, 0, 0, false)
    }
    
    //MARK: - Convenince methods
    
    private func getGravityVectorCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getGravityVectorCharacteristicUUID())
    }
    
    private func getHeadingCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getHeadingCharacteristicUUID())
    }
    
    private func getRotationMatrixCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getRotationMatrixCharacteristicUUID())
    }
    
    private func getEulerCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getEulerCharacteristicUUID())
    }
    
    private func getRawDataCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getRawDataCharacteristicUUID())
    }

    private func getTapCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getTapCharacteristicUUID())
    }

    private func getOrientationCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getOrientationCharacteristicUUID())
    }

    private func getQuaternionCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getQuaternionCharacteristicUUID())
    }
    
    private func getPedometerCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getPedometerCharacteristicUUID())
    }

    private func getConfigurationCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getMotionConfigurationCharacteristicUUID())
    }

}
