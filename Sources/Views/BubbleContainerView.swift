import UIKit

/// The delegate for BubbleContainerView which notifies of a successful split.
protocol BubbleContainerDelegate: class {
    /// Delegate method called whenever a bubble is successfully split.
    ///
    /// - Parameters:
    ///   - bubble: The bubble that has been/is going to be split.
    ///   - artificial: Whether this operation was artificial (caused by code) or not.
    func bubbleContainer (didSplitBubble bubble: BubbleView, artificial: Bool)
}

/// This is the container view for all the `BubbleView`s. The role of this view is to catch
/// all the touch events relative to the single bubbles and split them whenever possible.
final class BubbleContainerView: UIView {
    /// A delegate which receives updates about successful bubble splits.
    weak var delegate: BubbleContainerDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesMoved (touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Try to retrieve the first touch from the set (which is always one, since multitouch is
        // not enabled).
        guard let touch = touches.first else {
            return
        }
        // Iterate each subview (= bubble) and try to find the one who intersects the user's
        // finger.
        for subview in self.subviews {
            // Using the built-in `point` function, look for intersections.
            if subview.point (inside: touch.location (in: subview), with: event),
                let bubble = subview as? BubbleView {
                // Notify our delegate.
                self.delegate?.bubbleContainer (didSplitBubble: bubble, artificial: false)
                // Split the BubbleView if an intersection is found.
                bubble.split()
                break
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    
    /// Splits all the bubbles found in this view's subviews, recursively.
    @objc func splitAll() { self.splitAll (in: nil) }
    
    /// Splits all the bubbles, recursively.
    @objc func splitAll (in array: [UIView]?) {
        // Establish a delay between split operations, to increase realness.
        var delay = 0.3
        for subview in array ?? self.subviews {
            if let bubble = subview as? BubbleView {
                // After the delay specified before, split the bubbles and notify the delegate.
                DispatchQueue.main.asyncAfter (deadline: .now() + delay) {
                    [unowned self] in
                    bubble.split()
                    self.delegate?.bubbleContainer (didSplitBubble: bubble, artificial: true)
                }
                // Increase the delay slightly.
                delay += 0.005
                if bubble.children != nil {
                    // If there are children, call this function again with a slightly increased
                    // delay to split these children too.
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
                        [unowned self] in
                        self.splitAll(in: bubble.children)
                    }
                }
            }
        }
    }
}
