

//  DrawCurve.swift
//  breathing
//
//
import SwiftUI   // Import SwiftUI framework for building declarative user interfaces
import Combine   // Import Combine framework for handling reactive programming and observable objects

// A class to manage and draw a curve based on depth data, conforming to ObservableObject for SwiftUI updates
class DepthDataCurveDrawer: ObservableObject {
    // Published property to store depth history, triggering UI updates when changed
    @Published var depthHistory: [CGFloat] = []  // Array to store depth values for plotting the curve
    
    // Function to update depth data by adding a new value to the history
    func updateDepthData(_ currentDepth: CGFloat) {
        // Append the new depth value to the history array
        depthHistory.append(currentDepth)
        // Limit the array length to 100 to prevent memory overflow or performance issues
        if depthHistory.count > 100 {
            // Remove the oldest value (first element) if the limit is exceeded
            depthHistory.removeFirst()
        }
    }
    
    // Function to draw a curve based on the depth history within a given size
    func drawDepthCurve(in size: CGSize) -> Path {
        // Extract width from the provided size for horizontal scaling
        let width = size.width
        // Fix the canvas height to 200 units
        let height: CGFloat = 200.0 // Fixed canvas height of 200
        
        // Return an empty path if there is no depth data
        guard !depthHistory.isEmpty else { return Path() }
        
        // Calculate the maximum and minimum depth values in the history
        let maxDepth = depthHistory.max() ?? 1.0  // Default to 1.0 if no maximum is found
        let minDepth = depthHistory.min() ?? 0.0  // Default to 0.0 if no minimum is found
        // Compute the range of depth values
        let depthRange = maxDepth - minDepth
        
        // Define custom range parameters for the curve
        let targetRange: CGFloat = 180.0 // The desired fluctuation range of the curve
        // Calculate the offset to center the curve within the fixed height
        let centerOffset: CGFloat = (height - targetRange) / 2 // Offset to center the curve vertically
        
        // Define original scaling parameters from the initial design
        let originalScale = 500.0  // Original scaling factor for depth values
        let originalOffset = 50.0  // Original offset for the curve's baseline
        // Calculate the maximum height the curve would reach with original scaling
        let maxScaledHeight = depthRange * originalScale + originalOffset
        // Determine the scaling factor to fit the curve within the target range
        let scaleFactor = maxScaledHeight > targetRange ? targetRange / maxScaledHeight : 1.0
        
        // Apply adaptive scaling to adjust the curve
        let finalScale = originalScale * scaleFactor   // Adjusted scaling factor
        let finalOffset = originalOffset * scaleFactor // Adjusted offset
        
        // Create a Path object to define the curve's shape
        let path = Path { path in
            // Iterate over the depth history with index and value
            for (index, depth) in depthHistory.enumerated() {
                // Calculate the x-coordinate by evenly distributing points across the width
                let x = CGFloat(index) / CGFloat(depthHistory.count) * width
                // Map the depth value to the target range (180) and center it
                let scaledDepth = (depth - minDepth) * finalScale + finalOffset
                // Compute the y-coordinate, flipping and centering within the canvas
                let y = height - (scaledDepth + centerOffset)
                
                // For the first point, move the pen to the starting position
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    // For subsequent points, draw a line from the previous point to the current one
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        // Return the completed path representing the depth curve
        return path
    }
    
    // Function to reset the depth history, clearing all stored values
    func reset() {
        // Remove all elements from the depth history array
        depthHistory.removeAll()
    }
}
