//
//  DepthDataProcessor.swift
//  breathing
//
//

import AVFoundation  // Import AVFoundation framework for handling audiovisual media
import UIKit         // Import UIKit framework for UI-related functionality

// A class to process depth data and detect breathing states, conforming to ObservableObject for SwiftUI updates
class DepthDataProcessor: ObservableObject {
    // Singleton instance for shared access across the app
    static let shared = DepthDataProcessor()
    
    // MARK: - Properties
    // Current average depth value for the latest frame
    private var currentAverageDepth: CGFloat = 0.0
    // Accumulated average depth over time
    private var accumulatedAverageDepth: CGFloat = 0.0
    // Previous accumulated average depth for reference
    private var previousAccumulatedAverageDepth: CGFloat = 0.0
    // Timer for periodic breathing state detection
    private var timer: Timer?
    // Instance of Gaussian filter for smoothing depth data
    private var gaussianFilter = GaussianFilter()
    // Instance of weighted moving average filter for smoothing depth values
    private var movingAverageFilter = WeightedMovingAverageFilter()
    // Instance for cropping pixel buffers
    private var pixelBufferCropper = PixelBufferCropper()
    // Lock to ensure thread-safe access to depth data
    private let dataLock = NSLock()
    // Rectangle defining the chest area for depth processing
    private var chestRect: CGRect!
    
    // Published property to store depth history for curve plotting, observable by SwiftUI
    @Published var depthHistory: [CGFloat] = []  // Array to store depth data for drawing curves
    
    // MARK: - Methods
    
    // Start the depth tracking timer
    func startTracking() {
        // Ensure the timer isn't already running
        guard timer == nil else { return }
        print("Starting depth tracking")
        // Schedule a timer to call detectBreathingState every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.detectBreathingState()
        }
    }
    
    // Stop the depth tracking timer
    func stopTracking() {
        // Invalidate and clear the timer
        timer?.invalidate()
        timer = nil
    }
    
    // Process the depth map by cropping and filtering
    func processDepthMap(depthMap: CVPixelBuffer) {
        // First, crop the depth map to the chest region
        if let croppedDepthMap = pixelBufferCropper.cropPixelBuffer(depthMap, rect: chestRect) {
            // Apply Gaussian filter to the cropped depth map
            if let filteredDepthMap = gaussianFilter.applyGaussianFilter(depthImage: croppedDepthMap) {
                // Update depth data with the filtered result
                updateDepthData(depthMap: filteredDepthMap)
            } else {
                print("Gaussian filtering failed")
            }
        } else {
            print("Cropping failed")
        }
    }
    
    // Update depth data with a processed depth map
    func updateDepthData(depthMap: CVPixelBuffer) {
        // Lock the base address of the depth map for reading
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        // Ensure the base address is unlocked when the function exits
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        // Calculate the total depth and valid pixel count
        let depthData = getTotalDepth(depthMap: depthMap)
        // Return if no valid pixels are found
        guard depthData.validPixelCount > 0 else { return }
        
        // Compute the average depth for the current frame
        let frameAverage = depthData.totalDepth / CGFloat(depthData.validPixelCount)
        
        // Apply weighted moving average to smooth the depth value
        if let smoothedDepth = movingAverageFilter.applyWeightedMovingAverage(depthData: frameAverage) {
            // Update depth values in a thread-safe manner
            dataLock.lock()
            self.currentAverageDepth = smoothedDepth
            self.accumulatedAverageDepth += smoothedDepth
            dataLock.unlock()
        } else {
            print("Weighted moving average failed")
        }
    }
    
    // Detect breathing state and update depth history
    func detectBreathingState() {
        // Lock data access for thread safety
        dataLock.lock()
        
        // Append the accumulated average depth to the history array
        depthHistory.append(accumulatedAverageDepth)
        print("accumulatedAverageDepth\(accumulatedAverageDepth)")
        // Store the current accumulated depth as the previous value
        self.previousAccumulatedAverageDepth = accumulatedAverageDepth
        // Reset the accumulated depth for the next cycle
        self.accumulatedAverageDepth = 0.0
        // Unlock data access
        dataLock.unlock()
    }
    
    // Calculate the total depth and valid pixel count from a depth map
    public func getTotalDepth(depthMap: CVPixelBuffer) -> (totalDepth: CGFloat, validPixelCount: Int) {
        var totalDepth: CGFloat = 0.0
        var validPixelCount: Int = 0
        // Get the width and height of the depth map
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Iterate over all pixels in the depth map
        for y in 0..<height {
            for x in 0..<width {
                // Get the depth value at the current pixel
                let depthValue = getDepthValueFromPixel(depthMap: depthMap, x: x, y: y)
                // Only include valid depth values between 0 and 1
                if depthValue > 0 && depthValue < 1 {
                    totalDepth += depthValue
                    validPixelCount += 1
                }
            }
        }
        
        // Return the total depth and number of valid pixels
        return (totalDepth, validPixelCount)
    }
    
    // Retrieve the depth value at a specific pixel in the depth map
    private func getDepthValueFromPixel(depthMap: CVPixelBuffer, x: Int, y: Int) -> CGFloat {
        // Get the base address of the pixel buffer
        let pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(depthMap)
        // Get the number of bytes per row
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        // Bind the base address to Float32 type for depth data
        let depthData = pixelBufferBaseAddress?.assumingMemoryBound(to: Float32.self)
        // Calculate the offset for the current pixel
        let pixelOffset = y * bytesPerRow / MemoryLayout<Float32>.size + x
        // Retrieve the depth value, defaulting to 0.0 if unavailable
        let depthValue = depthData?[pixelOffset] ?? 0.0
        // Convert the depth value to CGFloat and return
        return CGFloat(depthValue)
    }
    
    // MARK: - Public Method to Set chestRect
    // Set the chest rectangle for depth processing
    func setChestRect(_ rect: CGRect) {
        self.chestRect = rect
    }
    
    // Public method to get the current average depth
    public func getCurrentAverageDepth() -> CGFloat {
        return currentAverageDepth
    }
    
    // Public method to get the accumulated average depth
    public func getAccumulatedAverageDepth() -> CGFloat {
        return accumulatedAverageDepth
    }
    
    // Public method to get the previous accumulated average depth
    public func getPreviousAccumulatedAverageDepth() -> CGFloat {
        return previousAccumulatedAverageDepth
    }
}
