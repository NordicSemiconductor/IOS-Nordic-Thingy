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
//  GraphDataHandler.swift
//
//  Created by Mostafa Berg on 07/12/2016.
//

import UIKit
import Charts

class GraphDataHandler: NSObject, IAxisValueFormatter, ChartViewDelegate, UIGestureRecognizerDelegate {

    let maximumVisiblePoints    : Int
    let targetChartView         : LineChartView
    var lineChartData           : LineChartData
    var xPosition               : Double = 0
    var timestamps              : [Date]
    var dateFormatter           : DateFormatter
    private var originalMinValue: Double
    private var originalMaxValue: Double
    private var graphIsTouched  : Bool = false
    
    weak var scrollGraphButton  : UIButton? {
        willSet {
            scrollGraphButton?.removeTarget(self, action: #selector(scrollToEnd), for: .touchUpInside)
        }
        didSet {
            scrollGraphButton?.addTarget(self, action: #selector(scrollToEnd), for: .touchUpInside)
            scrollGraphButton?.isEnabled = false
        }
    }
    
    weak var clearGraphButton   : UIButton? {
        willSet {
            clearGraphButton?.removeTarget(self, action: #selector(clearGraphData), for: .touchUpInside)
        }
        didSet {
            clearGraphButton?.addTarget(self, action: #selector(clearGraphData), for: .touchUpInside)
            clearGraphButton?.isEnabled = false
        }
    }


    init(withGraphView aGraphView: LineChartView, noDataText aNoDataTextString: String, minValue aMinValue: Double, maxValue aMaxValue: Double, numberOfDataSets aDataSetCount: Int, dataSetNames aDataSetNameList: [String], dataSetColors aColorSet: [UIColor], andMaxVisibleEntries maxEntries: Int = 10) {

        originalMaxValue     = aMaxValue
        originalMinValue     = aMinValue
        dateFormatter        = DateFormatter()
        targetChartView      = aGraphView
        lineChartData        = LineChartData()
        maximumVisiblePoints = maxEntries
        timestamps           = [Date]()
        
        for i in 0..<aDataSetCount {
            let firstEntry = ChartDataEntry(x: 0, y: 0)
            var entries    = [ChartDataEntry]()
            entries.append(firstEntry)
            let aDataSet = LineChartDataSet(values: entries, label: aDataSetNameList[i])
            aDataSet.setColor(aColorSet[i])
            aDataSet.lineWidth = 3
            aDataSet.lineCapType = .round
            aDataSet.drawCircleHoleEnabled = false
            aDataSet.circleRadius = 2
            aDataSet.axisDependency = .left
            aDataSet.highlightEnabled = true
            lineChartData.addDataSet(aDataSet)
        }
        
        targetChartView.data = lineChartData
        targetChartView.noDataText = aNoDataTextString
        targetChartView.chartDescription?.text = ""
        targetChartView.rightAxis.drawLabelsEnabled = false
        targetChartView.xAxis.drawGridLinesEnabled = false
        targetChartView.xAxis.labelPosition = .bottom
        targetChartView.leftAxis.drawGridLinesEnabled = false
        targetChartView.dragEnabled = true
        targetChartView.xAxis.granularityEnabled = true
        targetChartView.xAxis.granularity = 1
        targetChartView.xAxis.decimals = 0
        targetChartView.leftAxis.granularityEnabled = true
        targetChartView.leftAxis.granularity = 1
        targetChartView.leftAxis.decimals = 1
        targetChartView.xAxis.axisMinimum = Double(0)
        targetChartView.xAxis.axisMaximum = Double(maximumVisiblePoints)
        targetChartView.leftAxis.axisMinimum = aMinValue
        targetChartView.leftAxis.axisMaximum = aMaxValue
        targetChartView.setScaleEnabled(false)
        super.init()
        targetChartView.xAxis.valueFormatter = self
        targetChartView.delegate = self
        
        // This gesture recognizer will track begin and end of touch/swipe.
        // When user presses the graph we don't want it to be moving when new data is received even when the most recent value is visible.
        let clickRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        clickRecognizer.minimumPressDuration = 0
        clickRecognizer.delegate = self
        targetChartView.addGestureRecognizer(clickRecognizer)
    }

    func clearGraphData() {
        for aDataset in lineChartData.dataSets {
            aDataset.clear()
            _ = aDataset.addEntry(ChartDataEntry(x: 0, y: 0))
        }
        targetChartView.leftAxis.axisMinimum = originalMinValue
        targetChartView.leftAxis.axisMaximum = originalMaxValue
        targetChartView.xAxis.axisMinimum = Double(0)
        targetChartView.xAxis.axisMaximum = Double(maximumVisiblePoints)
        targetChartView.fitScreen()
        xPosition = 0
        targetChartView.notifyDataSetChanged()
        targetChartView.setVisibleXRange(minXRange: 1, maxXRange: Double(maximumVisiblePoints))
        targetChartView.moveViewTo(xValue: xPosition, yValue: 0, axis: .left)
        
        clearGraphButton?.isEnabled = false
    }

    func addPoints(withValues values: [Double]) {
        var i = 0
        for aDataset in lineChartData.dataSets {
            
            //If value is outside the range, update the view
            if values[i] < targetChartView.leftAxis.axisMinimum {
                targetChartView.leftAxis.axisMinimum = values[i]
            }
            if values[i] > targetChartView.leftAxis.axisMaximum {
                targetChartView.leftAxis.axisMaximum = values[i]
            }

            //Create new entry for that value
            let newEntry = ChartDataEntry(x: xPosition, y: values[i])
            timestamps.append(Date())
            _ = aDataset.addEntry(newEntry)
            //Jump to next
            i += 1
        }

        if xPosition >= targetChartView.xAxis.axisMaximum {
            //We have more points to display, start incrementing the max value
            targetChartView.xAxis.axisMaximum += 1
        }

        targetChartView.setVisibleXRange(minXRange: 1, maxXRange: Double(maximumVisiblePoints))
        targetChartView.notifyDataSetChanged()

        //Only auto scroll when the chart is at the edge
        if graphIsTouched == false && xPosition <= targetChartView.highestVisibleX.rounded(.up) {
            targetChartView.moveViewTo(xValue: xPosition + 1, yValue: 0, axis: .left)
            // Hide the Scroll to end button
            scrollGraphButton?.isEnabled = false
        }
        xPosition += 1
        
        clearGraphButton?.isEnabled = true
    }
    
    func scrollToEnd() {
        targetChartView.moveViewToAnimated(xValue: xPosition + 1, yValue: 0, axis: .left, duration: 0.3)
        // Hide the Scroll to end button
        scrollGraphButton?.isEnabled = false
    }
    
    //MARK: - Gesture handlers
    /// Method called when user touches the graph. Handles touchDown and touchUp events to set the graphIsTouched flag. 
    func didLongPress(gesture: UITapGestureRecognizer) {
        if gesture.state == .began {
            graphIsTouched = true
        } else if gesture.state == .ended {
            graphIsTouched = false
            
            if xPosition > targetChartView.highestVisibleX.rounded(.up) {
                // Show the Scroll to end button
                scrollGraphButton?.isEnabled = true
            }
        }
    }
    
    //MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    //MARK: - IAxisValueFormatter
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value > xPosition {
            return ""
        } else {
            if timestamps.count > Int(value) {
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .medium
                return dateFormatter.string(from: timestamps[Int(value)])
            } else {
                return ""
            }
        }
    }

    //MARK: - ChartViewDelegate
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        if timestamps.count > Int(entry.x) {
            let timestamp = timestamps[Int(entry.x)]
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            let descriptionString = String(format: "Value: %.2f, Time: %@", entry.y, dateFormatter.string(from: timestamp))
            targetChartView.chartDescription?.text = descriptionString
        }
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        targetChartView.chartDescription?.text = nil
    }

}
