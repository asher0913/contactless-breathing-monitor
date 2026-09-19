//
//  CameraViewController.swift
//  breathing
//
//

import UIKit         // Import UIKit framework for building the user interface
import AVFoundation  // Import AVFoundation framework for camera and media handling
import CoreImage     // Import CoreImage framework for image processing
import CoreGraphics  // Import CoreGraphics framework for 2D graphics operations

// A view controller managing camera input, pose estimation, and depth data processing
class CameraViewController: UIViewController, CameraSetupDelegate {
    
    // MARK: - Properties
    // Instance for estimating human pose from video frames
    var poseEstimator: HumanPoseEstimator!
    // Instance for setting up and managing camera capture
    var cameraSetup: CameraSetup!
    // Instance for processing depth data
    var depthDataProcessor: DepthDataProcessor! // Depth data processing instance
    
    // Previous positions of left and right shoulders for tracking movement
    private var previousLeftShoulder: CGPoint?
    private var previousRightShoulder: CGPoint?
    // Last time shoulder positions were updated
    private var lastUpdateTime: Date?
    // Flag indicating whether shoulder positions are locked
    private var isShoulderLocked = false // Indicates if shoulder positions are fixed
    
    // Dimensions of the depth camera's resolution
    private var depthCameraWidth: Int = 640
    private var depthCameraHeight: Int = 480
    
    // Threshold for detecting significant shoulder movement
    private let positionThreshold: CGFloat = 0.15 // Displacement threshold
    // Time threshold (in seconds) to lock shoulders if no significant movement occurs
    private let timeThreshold: TimeInterval = 5.0 // Lock shoulders after 5 seconds of minimal movement
    
    // MARK: - View Lifecycle
    // Called when the view controller's view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize camera and pose estimation setup
        setupCameraAndPoseEstimator()
    }

    // MARK: - Setup Methods
    // Private function to initialize camera and pose estimation components
    private func setupCameraAndPoseEstimator() {
        // Reset the shared view model's shoulder lock state
        CameraViewModel.shared.isShoulderLocked = false
        // Create a new camera setup instance
        cameraSetup = CameraSetup()
        // Create a new pose estimator instance
        poseEstimator = HumanPoseEstimator()
        // Use the shared instance of depth data processor
        depthDataProcessor = DepthDataProcessor.shared // Initialize depth data processing
        
        // Set this view controller as the delegate for camera setup
        cameraSetup.delegate = self
        // Configure and start the camera for this view controller
        cameraSetup.setupCamera(for: self)
    }
    
    // MARK: - CameraSetupDelegate
    // Delegate method called when a video frame is captured
    func didCaptureVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        // If shoulders are locked, skip pose estimation
        if isShoulderLocked {
            return
        } else {
            // Extract the pixel buffer from the sample buffer, or return if unavailable
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            // Process the video frame to estimate human pose and update the view
            poseEstimator.processFrame(pixelBuffer: pixelBuffer, view: self.view)
        }
    }

    // Delegate method called when depth data is captured
    func didCaptureDepthData(_ depthData: AVDepthData) {
        // Process depth data differently based on whether shoulders are locked
        if isShoulderLocked {
            processDepthDataWhenShoulderLocked(depthData)
        } else {
            processDepthDataWhenShoulderUnlocked()
        }
    }

    // MARK: - Process Depth Data (Shoulder Locked/Unlocked)
    // Private function to process depth data when shoulders are locked
    private func processDepthDataWhenShoulderLocked(_ depthData: AVDepthData) {
        // Extract the depth map from the depth data
        let depthMap = depthData.depthDataMap

        // Pass the depth map directly to the processor for Gaussian filtering and data updates
        depthDataProcessor.processDepthMap(depthMap: depthMap)
    }
    
    // Private function to process depth data when shoulders are not locked
    private func processDepthDataWhenShoulderUnlocked() {
        // Get the current positions of left and right shoulders from the pose estimator
        guard let leftShoulder = poseEstimator.getLeftShoulderPosition(),
              let rightShoulder = poseEstimator.getRightShoulderPosition() else {
            print("Failed to retrieve left or right shoulder position")
            return
        }
        
        // If previous shoulder positions exist, calculate movement and check for locking condition
        if let previousLeft = previousLeftShoulder, let previousRight = previousRightShoulder,
           let lastUpdate = lastUpdateTime {
            // Calculate time elapsed since the last update
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            
            // Calculate the distance moved by each shoulder
            let leftShoulderMove = distanceBetweenPoints(previousLeft, leftShoulder)
            let rightShoulderMove = distanceBetweenPoints(previousRight, rightShoulder)
            
            // Check if movement is below threshold and time exceeds threshold to lock shoulders
            if leftShoulderMove < positionThreshold && rightShoulderMove < positionThreshold && timeSinceLastUpdate > timeThreshold {
                lockShoulderPositions(leftShoulder: leftShoulder, rightShoulder: rightShoulder)
            }
        } else {
            // Initialize previous positions and time on the first run
            previousLeftShoulder = leftShoulder
            previousRightShoulder = rightShoulder
            lastUpdateTime = Date()
        }
    }

    // MARK: - Lock Shoulder Position
    // Private function to lock shoulder positions and start depth tracking
    private func lockShoulderPositions(leftShoulder: CGPoint, rightShoulder: CGPoint) {
        // Update the shared view model to indicate shoulders are locked
        CameraViewModel.shared.isShoulderLocked = true
        // Set the local flag to indicate shoulders are locked
        isShoulderLocked = true
        // Calculate the chest rectangle based on shoulder positions, or return if unavailable
        guard let chestRect = getChestRectFromShoulders(leftShoulder: leftShoulder, rightShoulder: rightShoulder) else { return }
        // Set the chest rectangle in the depth data processor
        depthDataProcessor.setChestRect(chestRect)
        // Update the last update time
        lastUpdateTime = Date()
        // Store the current shoulder positions as previous positions
        previousLeftShoulder = leftShoulder
        previousRightShoulder = rightShoulder
        print("Shoulder positions locked, starting depth data processing")
        // Start tracking depth data
        depthDataProcessor.startTracking()
    }

    // MARK: - Utility Methods
    // Private function to calculate the chest rectangle based on shoulder positions
    private func getChestRectFromShoulders(leftShoulder: CGPoint, rightShoulder: CGPoint) -> CGRect? {
        // Ensure shoulder positions are valid (not zero)
        guard leftShoulder != .zero, rightShoulder != .zero else { return nil }
        
        // Convert shoulder positions to depth camera coordinates
        let leftShoulderDepth = convertToDepthCameraCoordinates(point: leftShoulder)
        let rightShoulderDepth = convertToDepthCameraCoordinates(point: rightShoulder)
        print(leftShoulder.x, leftShoulder.y)
        print(rightShoulder.x, rightShoulder.y)
        // Calculate the center of the chest with an offset
        let chestX = (leftShoulderDepth.x + rightShoulderDepth.x) / 2 + 200
        let chestY = (leftShoulderDepth.y + rightShoulderDepth.y) / 2 - 70
        // Define the width and height of the chest rectangle
        let chestWidth: CGFloat = 100
        let chestHeight: CGFloat = 140
        print(chestX, chestY)
        // Return the calculated chest rectangle
        return CGRect(x: chestX, y: chestY, width: chestWidth, height: chestHeight)
    }
    
    // Private function to calculate the Euclidean distance between two points
    private func distanceBetweenPoints(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        // Calculate differences in x and y coordinates
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        // Return the distance using the Pythagorean theorem
        return sqrt(dx * dx + dy * dy)
    }

    // Private function to convert a point to depth camera coordinates
    private func convertToDepthCameraCoordinates(point: CGPoint) -> CGPoint {
        // Scale the point's x and y coordinates to match the depth camera's resolution
        return CGPoint(x: point.x * CGFloat(depthCameraWidth), y: point.y * CGFloat(depthCameraHeight))
    }
}
