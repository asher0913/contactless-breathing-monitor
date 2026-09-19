import SwiftUI

// Define a structure to hold content for each page, including an ID, optional text, and optional image name
struct PageContent {
    let id: Int          // Unique identifier for the page
    let text: String?    // Optional text content to display on the page
    let imageName: String?  // Optional image name to display on the page
}

// Main view struct that displays a paginated tutorial with swipe gestures
struct ContentView: View {
    // Array of pages with predefined content, including an easter egg page (-1) and tutorial pages (0-4)
    let pages: [PageContent] = [
        PageContent(id: -1, text: "This is an easter egg \n our supervisor Matt and us.", imageName: nil),  // Easter egg page
        PageContent(id: 0, text: "Welcome to Breathing App \n \n Detecting your breathing phase \n \n Swipe down to continue \n", imageName: "breathing"),  // Welcome page
        PageContent(id: 1, text: "Firstly, you need to ensure that the phone is vertically placed on a stable platform \n \n Then, let your upper body appear completely on the screen.", imageName: "guild1"),  // Instruction page 1
        PageContent(id: 2, text: "Make sure there is no obstruction on your face.", imageName: "guild2"),  // Instruction page 2
        PageContent(id: 3, text: "The detection will start after your posture is stable for a few seconds. \n \n Please make sure not to move violently during the whole process.", imageName: nil),  // Instruction page 3
        PageContent(id: 4, text: "We will use a curve to represent your breathing state like above.", imageName: "curve"),  // Final instruction page with curve image
    ]
    
    @State private var currentPage = 1  // State variable to track the current page index (starts at page 1)
    @State private var textOffset: CGFloat = 0.0  // State variable to control the vertical offset of text during swipe
    @State private var textOpacity: CGFloat = 1.0  // State variable to control the opacity of text during swipe
    @State private var showLastPageMessage = false  // State variable to toggle the visibility of the "last page" message
    
    // Define the view's body, which contains the UI layout and behavior
    var body: some View {
        NavigationStack {  // Wrap the content in a NavigationStack to enable navigation links
            ZStack {  // Use ZStack to layer background, content, and top message
                Color(.systemBackground)  // Set the background color to the system's default background
                    .ignoresSafeArea()  // Extend the background color to cover the entire screen, including safe areas
                
                VStack {  // Vertical stack to arrange image, text, and buttons
                    // Display an image if the current page has an associated image name
                    if let imageName = pages[currentPage].imageName {
                        Image(imageName)  // Load the image with the specified name
                            .resizable()  // Allow the image to be resized
                            .scaledToFit()  // Scale the image to fit within its frame while maintaining aspect ratio
                            .frame(
                                maxWidth: currentPage == 1 ? 200 : 350,  // Set max width: 200 for page 1, 350 for others
                                maxHeight: currentPage == 1 ? 200 : 350  // Set max height: 200 for page 1, 350 for others
                            )
                            .accessibilityIdentifier("image_\(currentPage)")  // Add accessibility identifier for testing
                    }
                    
                    // Display text if the current page has associated text content
                    if let text = pages[currentPage].text {
                        Text(text)  // Display the text content
                            .font(.system(size: currentPage == 1 ? 22 : 28, weight: .medium, design: .rounded))  // Set font size: 22 for page 1, 28 for others
                            .foregroundColor(.black)  // Set text color to black
                            .multilineTextAlignment(.center)  // Center-align the text for multiple lines
                            .padding()  // Add padding around the text
                            .offset(y: currentPage == 5 ? 0 : textOffset)  // Apply vertical offset during swipe, except on the last page
                            .opacity(currentPage == 5 ? 1.0 : textOpacity)  // Apply opacity during swipe, except on the last page
                            .accessibilityIdentifier("text_\(currentPage)")  // Add accessibility identifier for testing
                    }
                    
                    // Show a "skip tutorial" button only on page 1
                    if currentPage == 1 {
                        NavigationLink(destination: TestView()) {  // Link to TestView when clicked
                            Text("You can click here to skip the tutorial")  // Button text
                                .padding()  // Add padding inside the button
                                .background(Color.blue)  // Set button background to blue
                                .foregroundColor(.white)  // Set text color to white
                                .cornerRadius(10)  // Round the button corners
                                .accessibilityIdentifier("skipButton")  // Add accessibility identifier for testing
                        }
                        .padding(.top, 20)  // Add top padding to separate from text
                    }
                    
                    // Show a "let's start" button only on the last page (index 5)
                    if currentPage == 5 {
                        NavigationLink(destination: TestView()) {  // Link to TestView when clicked
                            Text("let's start")  // Button text
                                .padding()  // Add padding inside the button
                                .background(Color.green)  // Set button background to green
                                .foregroundColor(.white)  // Set text color to white
                                .cornerRadius(10)  // Round the button corners
                                .accessibilityIdentifier("startButton")  // Add accessibility identifier for testing
                        }
                        .padding(.top, 20)  // Add top padding to separate from text
                    }
                }
                
                // Display a message at the top when the user swipes up on the last page
                if showLastPageMessage {
                    VStack {  // Vertical stack for the message
                        Text("This is the last page.")  // Message text
                            .font(.headline)  // Use headline font style
                            .foregroundColor(.white)  // Set text color to white
                            .padding()  // Add padding around the text
                            .background(Color.gray.opacity(0.8))  // Set a semi-transparent gray background
                            .cornerRadius(10)  // Round the corners of the background
                            .transition(.move(edge: .top).combined(with: .opacity))  // Animate appearance from top with opacity
                        Spacer()  // Push the message to the top of the ZStack
                    }
                    .padding(.top, 50)  // Add top padding to position the message below the status bar
                    .zIndex(1)  // Ensure the message appears above other content
                }
            }
            .gesture(  // Add a drag gesture to handle swipe navigation
                DragGesture()
                    .onChanged { gesture in  // Handle changes during the drag
                        let verticalMovement = gesture.translation.height  // Get the vertical distance of the drag
                        if verticalMovement < 0 {  // User is swiping up
                            if currentPage != 5 {  // If not on the last page, animate text movement and fading
                                textOffset = verticalMovement  // Move text upward
                                textOpacity = max(0, 1 - (-verticalMovement / 200))  // Fade text out based on swipe distance
                            } else {  // On the last page, show the "last page" message
                                showLastPageMessage = true
                            }
                        } else if verticalMovement > 0 && currentPage != 5 {  // User is swiping down (not on last page)
                            textOffset = verticalMovement  // Move text downward
                        }
                    }
                    .onEnded { gesture in  // Handle the end of the drag
                        let verticalMovement = gesture.translation.height  // Get the final vertical distance
                        if verticalMovement < -50 {  // Swipe up exceeds threshold (go to next page)
                            if currentPage < pages.count - 1 {  // Check if not already on the last page
                                withAnimation(.easeInOut(duration: 0.3)) {  // Animate page transition
                                    currentPage += 1  // Move to the next page
                                    textOffset = 0.0  // Reset text offset
                                    textOpacity = 0.0  // Fade text out
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  // Delay fade-in slightly
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        textOpacity = 1.0  // Fade text back in
                                    }
                                }
                            }
                            // Hide the "last page" message after swipe ends
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLastPageMessage = false
                            }
                        } else if verticalMovement > 50 {  // Swipe down exceeds threshold (go to previous page)
                            if currentPage > 0 {  // Check if not already on the first page
                                withAnimation(.easeInOut(duration: 0.3)) {  // Animate page transition
                                    currentPage -= 1  // Move to the previous page
                                    textOffset = 0.0  // Reset text offset
                                    textOpacity = 0.0  // Fade text out
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {  // Delay fade-in slightly
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        textOpacity = 1.0  // Fade text back in
                                    }
                                }
                            }
                            // Hide the "last page" message after swipe ends
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLastPageMessage = false
                            }
                        } else {  // Swipe didn’t exceed threshold, reset to original state
                            withAnimation(.easeInOut(duration: 0.3)) {
                                textOffset = 0.0  // Reset text offset
                                if currentPage != 5 {  // Reset opacity unless on the last page
                                    textOpacity = 1.0
                                }
                                showLastPageMessage = false  // Hide the message
                            }
                        }
                    }
            )
            .onAppear {  // Handle view appearance
                withAnimation(.easeInOut(duration: 0.5)) {  // Fade in text when the view first appears
                    textOpacity = 1.0
                }
            }
        }
    }
}
