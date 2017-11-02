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
//  ThingyCreatorViewController.swift
//
//  Created by Mostafa Berg on 03/08/17.
//

import UIKit
import SWRevealViewController
import IOSThingyLibrary
import CoreNFC

@available(iOS 11.0, *)
class ThingyNFCCreatorViewController: ThingyViewController, ThingyManagerDelegate, NFCNDEFReaderSessionDelegate {

    //MARK: - Class properties
    private var scanner: NFCReaderSession?
    private var discoveredThingies = Dictionary<String, ThingyPeripheral>()
    private var loadingView: UIAlertController?
    private var nfcPairingCode: String!

    //MARK: - Outlets and Actions
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nfcIconView: UIImageView!
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        let parentView = parent as! ThingyNavigationController
        parentView.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusLabel.text = nil
        discoveredThingies.removeAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        thingyManager!.delegate = self
        startNFCScan()
        thingyManager!.discoverDevices()
    }

    override func viewWillDisappear(_ animated: Bool) {
        thingyManager!.stopScan()
        super.viewWillDisappear(animated)
    }

    //MARK: - Implementation
    func startNFCScan() {
        statusLabel.text = nil
        beginAnimation()
        scanner = NFCNDEFReaderSession(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
        scanner!.alertMessage = "Touch your Thingy:52"
        scanner!.begin()
    }

    func beginAnimation() {
        nfcIconView.alpha = 1
        UIView.animateKeyframes(withDuration: 1, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.nfcIconView.alpha = 0
        })
    }
    
    func stopAnimation() {
        nfcIconView.stopAnimating()
        UIView.animate(withDuration: 0.5) {
            self.nfcIconView.alpha = 1
        }
    }
    
    //MARK: - ThingyManagerDelegate methods
    func thingyManager(_ manager: ThingyManager, didChangeStateTo state: ThingyManagerState) {
        print("Thingy Manager state changed to: \(state)")
        //TODO: handle turning OFF Bluetooth
    }
    
    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral, withPairingCode pairingCode: String?) {
        guard let pairingCode = pairingCode else {
            return
        }

        if nfcPairingCode != nil && pairingCode == nfcPairingCode {
            didSelectPeripheral(aPeripheral: peripheral)
        }

        if discoveredThingies[pairingCode] == nil {
            discoveredThingies[pairingCode] = peripheral
            print("New Thingy discovered, pairing code = \(pairingCode)")
        }
    }

    func thingyManager(_ manager: ThingyManager, didDiscoverPeripheral peripheral: ThingyPeripheral) {
        thingyManager(manager, didDiscoverPeripheral: peripheral, withPairingCode: nil)
    }

    //MARK: - ThingyPeripheralDelegate
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        switch (state) {
        case .connected, .ready:
            loadingView!.dismiss(animated: false, completion: {
                self.performSegue(withIdentifier: "show_initial_configure_view", sender: peripheral)
            })
        case .disconnected:
            loadingView!.dismiss(animated: true, completion: nil)
        default:
            break
        }
    }

    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_initial_configure_view" {
            let targetPeripheral = sender as! ThingyPeripheral
            let configurationView = segue.destination as! ThingyInitialConfigurationViewController
            configurationView.setTargetPeripheral(targetPeripheral, andManager: thingyManager!)
        }
    }

    //MARK: - Implementation
    private func didSelectPeripheral(aPeripheral: ThingyPeripheral) {
        //Stop scanning and connect to the selected peripheral
        nfcPairingCode = nil
        targetPeripheral = aPeripheral
        thingyManager!.stopScan()
        connectToPeripheral(aPeripheral)
    }
    
    private func connectToPeripheral(_ aPeripheral: ThingyPeripheral) {
        loadingView = UIAlertController(title: "Status", message: "Connecting to the device...", preferredStyle: .alert)
        loadingView!.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            action.isEnabled = false
            self.loadingView!.title   = "Aborting"
            self.loadingView!.message = "Cancelling connection..."
            self.thingyManager!.disconnect(fromDevice: aPeripheral)
        }))
        present(loadingView!, animated: true) {
            aPeripheral.delegate = self
            self.thingyManager!.connect(toDevice: aPeripheral)
        }
    }

    private func reorderPairingCode(_ aCode: String) -> String {
        var codeChars: [Character] = aCode.reversed()
        codeChars.swapAt(0, 1)
        codeChars.swapAt(2, 3)
        codeChars.swapAt(4, 5)
        codeChars.swapAt(6, 7)

        return String(codeChars)
    }

    //MARK:- NFCNDEFReaderSessionDelegate
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        guard let readerError = error as? NFCReaderError else {
            return
        }
        switch readerError.code {
        case .readerSessionInvalidationErrorFirstNDEFTagRead:
            //Do nothing, when the Thingy is scanned the segue will be performed
            break
        default:
            let parentView = parent as! ThingyNavigationController
            parentView.dismiss(animated: true, completion: nil)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        stopAnimation()
        for aMessage in messages {
            for aRecord in aMessage.records {
                if aRecord.typeNameFormat == .nfcWellKnown {
                    if let stringPayload = String(data:aRecord.payload, encoding:.utf8) {
                        let parts  = stringPayload.split(separator: " ")
                        if parts.count > 0 {
                            nfcPairingCode = reorderPairingCode(parts.last!.lowercased())
                        }
                        break
                    }
                }
            }
        }

        if let nfcPairingCode = nfcPairingCode {
            statusLabel.text = "Scanned code: \(nfcPairingCode)"
            if discoveredThingies[nfcPairingCode] != nil {
                didSelectPeripheral(aPeripheral: discoveredThingies[nfcPairingCode]!)
            } else {
                statusLabel.text = "Scanned code: \(nfcPairingCode)\nWaiting for a Thingy to advertise the same code."
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5) , execute: {
                    self.statusLabel.text = "No Thingy peripherals advertising with that code\nEnsure Thingy is powered on and NFC capable."
                })
            }
        } else {
            thingyManager!.stopScan()
            statusLabel.text = "Error:\nThe scanned NFC tag did not contain a Thingy pairing code."
        }
    }
}
