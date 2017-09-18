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
//  ThingyDFUDelegate.swift
//
//  Created by Mostafa Berg on 01/11/2016.
//
//

public protocol ThingyDFUDelegate {
    func dfuDidStart()
    /// This method is called after the Thingy has switched to bootloader mode. It advertises
    /// with a different address so iOS sees it as a new peripheral.
    /// Note: do not use this peripheral to connect to it. It is a device in DFU mode, so 
    /// does not have Thingy services. It's delegate is also used by the DFU library and can't be changed.
    /// The device given here may be used to reinitialize DFU when the process was aborted, or to get it's name only.
    func dfuDidJumpToBootloaderMode(newPeripheral: ThingyPeripheral)
    func dfuDidStartUploading()
    func dfuDidFinishUploading()
    /// This method is called when the DFU process finished with success. If the device was connected 
    /// when DFU started its instance will be returned here. The DFU controller did not start to reconnect to it.
    /// If the device was not connected before the parameter will be nil and app should scan for Thingy on its own.
    func dfuDidComplete(thingy: ThingyPeripheral?)
    func dfuDidAbort()
    func dfuDidFail(withError anError: Error, andMessage aMessage: String)
    func dfuDidProgress(withCompletion aCompletion: Int, forPart aPart: Int, outOf totalParts: Int, andAverageSpeed aSpeed: Double)
}
