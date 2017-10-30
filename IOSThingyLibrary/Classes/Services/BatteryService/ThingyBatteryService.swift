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
//  ThingyBatteryService.swift
//
//  Created by Mostafa Berg on 18/09/17.
//

import CoreBluetooth

public typealias BatteryNotificationCallback = (_ state: UInt8) -> (Void)

public enum ThingyBatteryError: Error {
    case charactersticNotDiscovered(characteristicName: String)
}

internal class ThingyBatteryService: ThingyService {
    internal var batteryNotificationsEnabled: Bool {
        return getBatteryCharacteristic()?.isNotifying ?? false
    }
    
    //MARK: - Initialization
    required internal init(withService aService: CBService) {
        super.init(withName: "Battery service", andService: aService)
    }

    //MARK: - Battery service implementation
    internal func beginBatteryNotifications() throws {
        if let batteryCharacteristic = getBatteryCharacteristic() {
            batteryCharacteristic.startNotifications()
        } else {
            throw ThingyBatteryError.charactersticNotDiscovered(characteristicName: "Battery")
        }
    }
    
    internal func stopBatteryNotifications() throws {
        if let batteryCharacteristic = getBatteryCharacteristic() {
            batteryCharacteristic.stopNotifications()
        } else {
            throw ThingyBatteryError.charactersticNotDiscovered(characteristicName: "Battery")
        }
    }

    //MARK: - Convenince methods
    private func getBatteryCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getBatteryLevelCharacteristicUUID())
    }
}
