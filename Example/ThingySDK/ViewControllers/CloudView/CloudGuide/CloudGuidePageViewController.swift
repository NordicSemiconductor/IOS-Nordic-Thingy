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
//  CloudGuidePageViewController.swift
//  Created by Mostafa Berg on 10/04/2017.
//

import UIKit

protocol CloudGuidePageViewControllerDelegate: AnyObject {
    
    /**
     Called when the current index is updated.
     
     - parameter pageViewController: the CloudGuidePageViewController instance
     - parameter index: the index of the currently visible page.
     */
    func pageViewController(_ pageViewController: UIPageViewController, didUpdatePageIndex index: Int)
}

class CloudGuidePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    weak var pageControlDelegate: CloudGuidePageViewControllerDelegate?

    private var titles      = [String]()
    private var bodies      = [String]()
    private var imageNames  = [[String]]()
    private var nextIndex   = 0
    
    var pages : Int {
        return titles.count
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        titles.append(contentsOf: ["IFTTT",
                                   "Account preparation",
                                   "Maker Webhooks service",
                                   "Maker Webhooks service",
                                   "Maker Webhooks service",
                                   "Obtaining Webhooks Key",
                                   "Obtaining Webhooks Key",
                                   "Obtaining Webhooks Key",
                                   "Adding Access Key to Thingy",
                                   "Adding Access Key to Thingy",
                                   "Adding Access Key to Thingy",
                                   "Button State Cloud Feature",
                                   "Button State Cloud Feature",
                                   "Button State Cloud Overview"])
        
        bodies.append(contentsOf: ["Cloud services rely on IFTTT (IF This Then That). The service allows to execute a task (like sending a text message, publishing on Facebook or many, many others) on an event received from a Thingy.",
                                   "To be able to use IFTTT a free account is required. Go to https://ifttt.com website and log in into your account or create a new one.",
                                   "After logging in, a \"Maker Webhooks\" service must be added. Tap the services button.",
                                   "Find the service by tapping the search button.",
                                   "Type \"Maker Webhooks\" into the search bar. When the service appears, tap the \"Maker Webhooks\" service icon to enable it.",
                                   "In order for the Webhooks service to work, an access key needs to be obtained. To do that, tap the settings icon.",
                                   "Copy the URL under the \"account info\" section and open it in a new browser window.",
                                   "The account access key will be displayed in the new page. Copy it or note it down for later. This page may be now closed.",
                                   "Open Thingy app and connect to your Thingy. Then, select Cloud on the main menu.",
                                   "In the configuration group, tap the \"Cloud Token\" entry.",
                                   "An input alert appears, paste in the token obtained earlier. This will save the token in the app and assign it to your currently connected Thingy",
                                   "Let's try out the button service, toggle the \"Button State\" switch to the ON position.",
                                   "Try pressing the physical button on the Thingy. This will now trigger the maker webhook service. The button press event together with its duration will be sent to the maker webhook.",
                                   "Additionally, cloud view will display the total amount of data sent and received."])
        
        imageNames.append(contentsOf: [["cloud_tutorial_1"],
                                       ["cloud_tutorial_2", "cloud_tutorial_2_1", "cloud_tutorial_2_2"],
                                       ["cloud_tutorial_3", "cloud_tutorial_3_1"],
                                       ["cloud_tutorial_4", "cloud_tutorial_4_1"],
                                       ["cloud_tutorial_5", "cloud_tutorial_5_1", "cloud_tutorial_5_2", "cloud_tutorial_5_3"],
                                       ["cloud_tutorial_6", "cloud_tutorial_6_1"],
                                       ["cloud_tutorial_7", "cloud_tutorial_7_1"],
                                       ["cloud_tutorial_8", "cloud_tutorial_8_1"],
                                       ["cloud_tutorial_9"],
                                       ["cloud_tutorial_10", "cloud_tutorial_10_1"],
                                       ["cloud_tutorial_11", "cloud_tutorial_11_1"],
                                       ["cloud_tutorial_12", "cloud_tutorial_12_1"],
                                       ["cloud_tutorial_13", "cloud_tutorial_13_1"],
                                       ["cloud_tutorial_14"]])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate   = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set up the first page. The following will be added through the data source's methods below.
        if let firstViewController = contentViewForIndex(anIndex: 0) {
            setViewControllers([firstViewController], direction: .forward, animated: false)
        }
    }
    
    private func contentViewForIndex(anIndex: Int) -> CloudGuidePageContentViewController? {
        guard anIndex != pages else {
            return nil
        }
        
        let contentView = storyboard?.instantiateViewController(withIdentifier: "CloudGuidePageContent") as? CloudGuidePageContentViewController
        contentView?.set(pageIndex: anIndex, title: titles[anIndex], body: bodies[anIndex], andImageNames: imageNames[anIndex])

        return contentView
    }

    //MARK: - UIPageViewcontrollerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentVC = viewController as! CloudGuidePageContentViewController
        let index = currentVC.pageIndex!
        if index == 0 {
            return nil
        }
        return contentViewForIndex(anIndex: index - 1)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentVC = viewController as! CloudGuidePageContentViewController
        let index = currentVC.pageIndex!
        if index == titles.count {
            return nil
        }
        return contentViewForIndex(anIndex: index + 1)
    }
    
    //MARK: - UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            pageControlDelegate?.pageViewController(pageViewController, didUpdatePageIndex: nextIndex)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let pendingView = pendingViewControllers.first as! CloudGuidePageContentViewController
        nextIndex = pendingView.pageIndex
    }
}
