import UIKit

class BubbleView: UIView {
    /// The children of this BubbleView. Note that the first layer does not have any children.
    var children: [BubbleView]?
    
    /// Creates a new `BubbleView`.
    ///
    /// - Parameters:
    ///   - size: The size of the bubble
    ///   - position: Where the bubble should be placed. Note that this must be relative position,
    ///               i.e. it must not account for the bubble's size.
    ///   - color: The color of this bubble.
    ///   - roundCorners: Whether this should be a bubble or a square.
    init (size: Int, position: CGPoint, color: UIColor, roundCorners: Bool = true) {
        // Before initializing the bubble, convert the supplied relative position to a real
        // position.
        var position = position
        position.x *= CGFloat(size)
        position.y *= CGFloat(size)
        super.init (frame: CGRect (origin: position,
                                   size: CGSize (width: size, height: size)))
        self.backgroundColor = color
        if roundCorners {
            self.layer.cornerRadius = CGFloat (size) / 2
        }
        // Disable user interaction, as this allows correct propagation of events to the container.
        self.isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Splits a bubble in four smaller bubbles, if applicable.
    func split() {
        if let bubbleChildren = self.children {
            for child in bubbleChildren {
                let group = CAAnimationGroup()
                
                // When a bubble is split, its children perform three animations:
                // 1. The position shift
                // The children temporarily positions itself to the same position of the parent.
                // When the animation completes, the original position of the children is restored.
                let positionAnimation = CABasicAnimation(keyPath: "position")
                positionAnimation.fromValue = self.layer.position
                positionAnimation.toValue = child.layer.position
                
                // 2. The size shift
                // The children temporarily sizes itself as the parent.
                // When the animation completes, the original size of the children is restored.
                let sizeAnimation = CABasicAnimation(keyPath: "bounds")
                sizeAnimation.fromValue = self.layer.bounds
                sizeAnimation.toValue = child.layer.bounds
                
                // 3. The continuous circle-ization
                // The corner radius gets adjusted to match the size of the parent.
                // When the animation completes, the original corner radius (if set) is restored.
                let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
                cornerRadiusAnimation.fromValue = self.layer.cornerRadius
                cornerRadiusAnimation.toValue = child.layer.cornerRadius
                
                // The total duration of the animations is 0.3 seconds, and we're using easeInOut
                // as the timing function.
                group.animations = [positionAnimation, sizeAnimation, cornerRadiusAnimation]
                group.duration = 0.3
                group.timingFunction = CAMediaTimingFunction (
                    name: kCAMediaTimingFunctionEaseInEaseOut)
                
                child.layer.add(group, forKey: "childrenSpawn")
                self.superview?.addSubview(child)
            }
            // After all of our children have been added to our superview, we're done. Goodbye!
            self.removeFromSuperview()
        }
    }
}
