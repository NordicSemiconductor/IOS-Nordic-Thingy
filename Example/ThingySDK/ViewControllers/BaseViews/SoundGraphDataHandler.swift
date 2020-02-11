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
//  SoundGraphDataHandler.swift
//
//  Created by Aleksander Nowakowski on 08/03/2017.
//

import UIKit
import Charts

class SoundGraphDataHandler: NSObject {    
    let maximumVisiblePoints    : Int
    let targetChartView : LineChartView
    let lineChartData   : LineChartData
    let dataSet         : LineChartDataSet
    var xPosition       : Double = 0
    
    init(withGraphView aGraphView: LineChartView, andMaxVisibleEntries maxEntries: Int) {
        targetChartView      = aGraphView
        maximumVisiblePoints = maxEntries
        lineChartData        = LineChartData()
        
        dataSet = LineChartDataSet()
        if #available(iOS 13.0, *) {
            dataSet.setColor(UIColor.label)
        } else {
            dataSet.setColor(UIColor.black)
        }
        dataSet.lineWidth             = 2
        dataSet.mode                  = .cubicBezier
        dataSet.lineCapType           = .round
        dataSet.axisDependency        = .left
        dataSet.drawCirclesEnabled    = false
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawValuesEnabled     = false
        dataSet.highlightEnabled      = false
        lineChartData.addDataSet(dataSet)
        
        targetChartView.data = lineChartData
        targetChartView.noDataText                   = ""
        targetChartView.chartDescription?.text       = ""
        targetChartView.legend.enabled               = false
        targetChartView.rightAxis.enabled            = false // no horizontal grid lines
        targetChartView.rightAxis.drawLabelsEnabled  = false
        targetChartView.leftAxis.enabled             = false // no horizontal grid lines
        targetChartView.leftAxis.drawLabelsEnabled   = false
        targetChartView.xAxis.enabled                = false // no vertical grid lines
        targetChartView.xAxis.drawLabelsEnabled      = false
        targetChartView.drawBordersEnabled           = false
        targetChartView.drawGridBackgroundEnabled    = false
        targetChartView.drawMarkers                  = false
        targetChartView.dragEnabled                  = false
        targetChartView.xAxis.axisMinimum    = Double(0)
        targetChartView.xAxis.axisMaximum    = Double(maxEntries)
        targetChartView.leftAxis.axisMinimum = -1.0
        targetChartView.leftAxis.axisMaximum = 1.0
        targetChartView.setScaleEnabled(false)
        super.init()
    }
    
    func clearGraphData() {
        dataSet.removeAll(keepingCapacity: false)
        xPosition = 0
        targetChartView.xAxis.axisMinimum = 0
        targetChartView.xAxis.axisMaximum = Double(maximumVisiblePoints)
        targetChartView.moveViewToX(0)
        targetChartView.notifyDataSetChanged()
    }
    
    func addPoints(withValues values: [Double]) {
        for v in values {
            let entry = ChartDataEntry(x: xPosition, y: v)
            _ = dataSet.append(entry)
            
            if xPosition > Double(maximumVisiblePoints) {
                let _:ChartDataEntry = dataSet.removeFirst()
            }
            
            xPosition += 1.0
        }
        
        if xPosition >= targetChartView.xAxis.axisMaximum {
            // We have more points to display, start incrementing the max value
            targetChartView.xAxis.axisMaximum = xPosition
            targetChartView.xAxis.axisMinimum = xPosition - Double(maximumVisiblePoints)
            targetChartView.moveViewToX(xPosition)
        }
        
        targetChartView.notifyDataSetChanged()
    }
    
}
