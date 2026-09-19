//
//  TestView.swift
//  breathing
//
//
import SwiftUI  // Import SwiftUI framework for building declarative user interfaces

// A SwiftUI view that wraps a UIKit UIVisualEffectView to apply a blur effect
struct BlurView: UIViewRepresentable {
    // The style of the blur effect to apply
    let style: UIBlurEffect.Style

    // Create and return the underlying UIKit view with the specified blur effect
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    // Update the UIKit view (empty implementation as no updates are needed)
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// The main test view displaying camera feed, depth curve, and controls
struct TestView: View {
    // Access to the presentation mode environment variable for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    // State object for managing depth data processing
    @StateObject private var depthDataProcessor = DepthDataProcessor.shared
    // State object for drawing the depth curve
    @StateObject private var curveDrawer = DepthDataCurveDrawer()
    // State object for managing camera-related state
    @StateObject private var cameraViewModel = CameraViewModel.shared

    // State variable to track whether depth processing is active
    @State private var isProcessing = false
    // State variable to force camera view refresh by changing its ID
    @State private var cameraRestartKey = UUID()

    // The body of the view, defining its structure and layout
    var body: some View {
        // A stack aligning content at the bottom
        ZStack(alignment: .bottom) {
            // Display the camera feed
            CameraView()
                .id(cameraRestartKey)  // Use a unique ID to force refresh when needed
                .edgesIgnoringSafeArea(.all)  // Extend the camera view to all edges

            // Overlay an image with adjustable opacity based on shoulder lock state
            Image("body")
                .resizable()  // Allow the image to resize
                .aspectRatio(contentMode: .fill)  // Fill the frame while preserving aspect ratio
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // Fill the available space
                .edgesIgnoringSafeArea(.all)  // Extend the image to all edges
                .blendMode(.overlay)  // Apply an overlay blend mode
                .opacity(cameraViewModel.isShoulderLocked ? 0.1 : 0.8)  // Adjust opacity based on shoulder lock
                .animation(.easeInOut, value: cameraViewModel.isShoulderLocked)  // Animate opacity changes

            // Vertical stack for curve and control elements
            VStack {
                // Conditionally display the curve drawing area when shoulders are locked
                if cameraViewModel.isShoulderLocked {
                    ZStack {
                        // Apply a blur effect as the background for the curve
                        BlurView(style: .systemUltraThinMaterialDark)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))  // Round the corners

                        // Draw the depth curve using a Canvas
                        Canvas { context, size in
                            let path = curveDrawer.drawDepthCurve(in: size)  // Get the curve path
                            context.stroke(path, with: .color(.mint), lineWidth: 3)  // Stroke the path with a mint color
                        }
                    }
                    .frame(height: 200)  // Set a fixed height for the curve area
                    .padding(.horizontal)  // Add horizontal padding
                    .padding(.top)  // Add top padding
                    .shadow(radius: 10)  // Apply a shadow effect
                    .transition(.opacity)  // Fade in/out when appearing/disappearing
                }

                Spacer()  // Push content to the bottom

                // Display status message and control buttons
                VStack(spacing: 16) {
                    // Show a status message based on shoulder lock state
                    Text(cameraViewModel.isShoulderLocked ? "✅ Detecting..." : "⚠️ Ensure shoulders visible")
                        .foregroundColor(.white)  // Set text color to white
                        .font(.headline)  // Use headline font style
                        .padding()  // Add padding around the text
                        .frame(maxWidth: .infinity)  // Fill the available width
                        .background(cameraViewModel.isShoulderLocked ? Color.green.opacity(0.8) : Color.red.opacity(0.8))  // Set background color based on state
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))  // Round the corners
                        .shadow(radius: 5)  // Apply a shadow effect
                        .animation(.easeInOut, value: cameraViewModel.isShoulderLocked)  // Animate background changes

                    // Horizontal stack for control buttons
                    HStack(spacing: 15) {
                        // Button to clear the curve data
                        Button(action: {
                            withAnimation {
                                curveDrawer.reset()  // Reset the curve data with animation
                            }
                        }) {
                            Label("Clear", systemImage: "waveform.path.ecg")  // Button label with icon
                                .font(.headline)  // Use headline font style
                                .frame(maxWidth: .infinity)  // Fill the available width
                                .padding()  // Add padding inside the button
                                .background(Color.red)  // Set button background color
                                .foregroundColor(.white)  // Set button text color
                                .clipShape(RoundedRectangle(cornerRadius: 15))  // Round the corners
                                .shadow(radius: 5)  // Apply a shadow effect
                        }

                        // Button to restart detection
                        Button(action: {
                            withAnimation {
                                cameraRestartKey = UUID()  // Refresh the camera view
                                curveDrawer.reset()  // Reset the curve data
                                isProcessing = false  // Stop processing
                                depthDataProcessor.stopTracking()  // Stop depth tracking
                            }
                        }) {
                            Label("Re-detect", systemImage: "arrow.counterclockwise")  // Button label with icon
                                .font(.headline)  // Use headline font style
                                .frame(maxWidth: .infinity)  // Fill the available width
                                .padding()  // Add padding inside the button
                                .background(Color.gray)  // Set button background color
                                .foregroundColor(.white)  // Set button text color
                                .clipShape(RoundedRectangle(cornerRadius: 15))  // Round the corners
                                .shadow(radius: 5)  // Apply a shadow effect
                        }
                    }
                }
                .padding()  // Add padding around the control area
                .background(.ultraThinMaterial)  // Apply a material background
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))  // Round the corners
                .shadow(radius: 15)  // Apply a shadow effect
                .padding(.horizontal)  // Add horizontal padding
                .padding(.bottom, 30)  // Add bottom padding
            }
        }
        // Respond to changes in shoulder lock state
        .onChange(of: cameraViewModel.isShoulderLocked) {
            withAnimation {
                if cameraViewModel.isShoulderLocked {
                    isProcessing = true  // Start processing when shoulders are locked
                    depthDataProcessor.startTracking()  // Start depth tracking
                } else {
                    isProcessing = false  // Stop processing when shoulders are unlocked
                    depthDataProcessor.stopTracking()  // Stop depth tracking
                }
            }
        }
        // Respond to changes in depth history
        .onChange(of: depthDataProcessor.depthHistory) {
            // Update the curve with the latest depth value if processing is active
            if isProcessing, let lastDepth = depthDataProcessor.depthHistory.last {
                curveDrawer.updateDepthData(lastDepth)
            }
        }
    }
}
