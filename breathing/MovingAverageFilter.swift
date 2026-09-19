import Foundation  // Import Foundation framework for basic functionality like arrays and data types

// A class to apply a weighted moving average filter to smooth depth data
class WeightedMovingAverageFilter {
    // Fixed window size for the moving average calculation
    private let windowSize: Int = 5  // Fixed window size of 5, defines how many data points are considered in the average
    
    // Array to store weights for each position in the window
    private let weights: [CGFloat]  // Stores the weight for each window position, used to prioritize newer data in the average
    
    // Array to store historical depth data
    private var data: [CGFloat] = []  // Stores historical data points, updated as new depth values are added

    // MARK: - Initialize Weighted Moving Average Filter
    // Initializer for the weighted moving average filter
    init() {
        // Initialize the weights array with fixed values for a window size of 5
        self.weights = [0.1, 0.15, 0.2, 0.25, 0.3]  // Weights can be adjusted as needed, sum to 1.0 for balanced averaging
    }
    
    // MARK: - Calculate Weighted Moving Average
    // Function to apply the weighted moving average to a depth value and return the smoothed result
    func applyWeightedMovingAverage(depthData: CGFloat) -> CGFloat? {
        // Add the current depth data to the history array
        data.append(depthData)  // Append the new depth value to the end of the data array
        
        // Remove the oldest data point if the array exceeds the window size
        if data.count > windowSize {  // Check if the data array has more elements than the defined window size
            data.removeFirst()  // Remove the oldest data point to maintain the fixed window size
        }
        
        // Calculate the weighted average for the current window
        var weightedSum: CGFloat = 0.0  // Initialize a variable to hold the sum of weighted values
        
        // Compute the weighted sum by multiplying each value with its corresponding weight
        for (index, value) in data.enumerated() {  // Iterate over the data array with index and value
            weightedSum += value * weights[index]  // Multiply each data point by its corresponding weight and add to the sum
        }
        
        // Return the weighted average value
        return weightedSum  // Return the computed weighted sum as the smoothed result
    }
    
    // MARK: - Getter Functions
    // 获取窗口大小 (Get window size)
    func getWindowSize() -> Int {
        return windowSize  // Return the fixed window size value for external access
    }
    
    // 获取权重数组 (Get weights array)
    func getWeights() -> [CGFloat] {
        return weights  // Return the array of weights for external access
    }
    
    // 获取当前数据数组 (Get current data array)
    func getData() -> [CGFloat] {
        return data  // Return the current array of historical data for external access
    }
}
