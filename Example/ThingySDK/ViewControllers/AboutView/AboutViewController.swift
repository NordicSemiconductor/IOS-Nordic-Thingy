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
//  AboutViewController.swift
//
//  Created by Mostafa Berg on 05/05/2017.
//

import UIKit

class AboutViewController: SwipableTableViewController {

    private var aboutURLList: [[URL]] = [
        [
            URL(string:"https://www.nordicsemi.com/thingy")!
        ],
        [
            URL(string: "https://github.com/NordicSemiconductor/IOS-Nordic-Thingy/")!,
            URL(string: "https://cocoapods.org/pods/IOSThingyLibrary")!
        ],
        [
            URL(string: "https://www.nordicsemi.com/eng/About-us/Privacy-Policy")!
        ],
        [
            URL(string: "https://github.com/danielgindi/Charts")!,
            URL(string: "https://github.com/sberrevoets/SDCAlertView")!,
            URL(string: "https://github.com/John-Lluch/SWRevealViewController")!,
            URL(string: "https://github.com/pkrll/Keychain")!
        ]
    ]
    @IBAction func menuButtonTapped(_ sender: Any) {
        toggleRevealView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section < aboutURLList.count {
            if indexPath.row < aboutURLList[indexPath.section].count {
                UIApplication.shared.openURL(aboutURLList[indexPath.section][indexPath.row])
            }
        }
    }
}
