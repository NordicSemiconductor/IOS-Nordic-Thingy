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
//  TutorialViewController.swift
//
//  Created by Jiajun Qiu on 27/10/2016.
//
//

import Foundation
import UIKit

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBAction func continueButtonClicked(_ sender: UIButton) {
        // For now, as we don't support nRF Cloud, skip the second page and go immediately to the main screen.
        jumpToMainScreen()
        /*
        // TODO: create second tutorial screen when nRF Cloud support is added 
        if let vc = childViewControllers.first as? TutorialPageViewController {
            if pageControl.currentPage < (vc.orderedViewControllers.count - 1) {
                vc.scrollToNextViewController()
            } else if pageControl.currentPage == (vc.orderedViewControllers.count - 1) {
                jumpToMainScreen()
            }
        }
        */
    }
    
    var tutorialPageViewController: TutorialPageViewController! {
        didSet {
            tutorialPageViewController.tutorialDelegate = self
            pageControl.numberOfPages = tutorialPageViewController.orderedViewControllers.count
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        continueButton.setTitle("CONTINUE", for: .normal)
        pageControl.isEnabled = false
        
        //Jump to main view as early as possible
        let key = "AppOpenedCounter"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
        if count > 0 {
            jumpToMainScreen()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedTutorialView" {
            if let destination = segue.destination as? TutorialPageViewController {
                tutorialPageViewController = destination
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func jumpToMainScreen() {
        // Change the status bar color back to light one
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        performSegue(withIdentifier: "SkipTutorial", sender: nil)
    }
}

extension TutorialViewController: TutorialPageViewControllerDelegate {
    
    func tutorialPageViewController(_ tutorialPageViewController: TutorialPageViewController, didUpdatePageIndex index: Int) {
        pageControl.currentPage = index

        /*
        if index == 1 {
            continueButton.setTitle("SKIP", for: .normal)
        }
        */
    }
}
