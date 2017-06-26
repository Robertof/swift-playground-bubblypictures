import UIKit

/// The class responsible for generating bubbles (circles) for an image,
/// and putting them inside a single, streamlined view.
///
/// In short, the Bubblifier:
/// - reads an image
/// - analyzes color data of it (if possible)
/// - generates different, configurable, layers of bubbles.
open class BubblifierViewController: UIViewController, BubbleContainerDelegate {
    // MARK: Instance variables
    /// The represented `UIImage` object.
    public var image: ImageChoice = .heart
    
    /// An object representing color information about the image.
    private var imageColor: ImageColor!
    
    /// The minimum size of a single bubble.
    public var minimumBubbleSize: BubbleSize = .medium
    
    /// The maximum size of a single bubble.
    public var maximumBubbleSize: BubbleSize = .large
    
    /// Whether bubbles should be bubbles or squares.
    public var useSquares = false
    
    // A StackView containing all the buttons.
    private lazy var buttonsStackView = UIStackView()
    
    // The buttons, courtesy of Swift's computed properties.
    // NOTE: be sure to access this after loadView() is called!
    private lazy var buttons: (redraw: UIButton, complete: UIButton, gallery: UIButton) = {
        (
            redraw: self.buttonsStackView.arrangedSubviews[0] as! UIButton,
            complete: self.buttonsStackView.arrangedSubviews[1] as! UIButton,
            gallery: self.buttonsStackView.arrangedSubviews[2] as! UIButton
        )
    }()
    
    // The subview containing the bubbles.
    private lazy var bubblesView: BubbleContainerView = BubbleContainerView()
    
    // A constraint regulating the size of the bubble view.
    private weak var bubblesViewSizeConstraint: NSLayoutConstraint!
    
    // The size of the smallest & largest bubbles, converted to points.
    // Note: this was originally using a property observer to update on demand the bubbles view
    // size constraint, but these two things aren't always linked together.
    private lazy var bubbleDimensions: (minimum: Int, maximum: Int) = (0, 0)
    
    // Statistics about the bubbles.
    private lazy var bubbleStatistics: (split: Int, total: Int) = (0, 0)
    
    // MARK: Initializers
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    open override func loadView() {
        let rootView = UIView()
        rootView.backgroundColor = .white
        // Add the view that will contain the bubbles.
        rootView.addSubview (self.bubblesView)
        // Configure the StackView.
        self.buttonsStackView.axis = .vertical
        self.buttonsStackView.spacing = 0
        self.buttonsStackView.distribution = .fillProportionally
        // Create & configure the buttons.
        let buttonsConfig: [(title: String, action: Selector?, to: Any)] = [
            (title: "Redraw!",
             action: #selector(draw),
             to: self),
            (title: "Complete it!",
             action: #selector(bubblesView.splitAll as () -> ()),
             to: self.bubblesView),
            (title: "Save to gallery",
             action: #selector(saveToGallery),
             to: self)
        ]
        for cfg in buttonsConfig {
            let button = UIButton (type: .system)
            button.isHidden = true
            button.titleLabel?.font = UIFont.systemFont (ofSize: 20)
            button.setTitle (cfg.title, for: .normal)
            if let selector = cfg.action {
                button.addTarget (cfg.to, action: selector, for: .touchUpInside)
            }
            self.buttonsStackView.addArrangedSubview (button)
        }
        // Add the StackView.
        rootView.addSubview (self.buttonsStackView)
        self.view = rootView
    }
    
    open override func viewDidLoad() {
        // Calculate the minimum bubble size by exploiting the fact that the maximum value of our
        // BubbleSize enum is also the largest exponent we're interested in.
        // This size does not vary across screen dimensions, so we can just pre-calculate it.
        self.bubbleDimensions.minimum = 2 * self.minimumBubbleSize.size (
            relativeToExponent: BubbleSize.maxSubtrahend)
        // Tell bubblesView that we are its delegate.
        self.bubblesView.delegate = self
        // Prepare a constraint containing the size of the view that has to be altered.
        self.bubblesViewSizeConstraint = NSLayoutConstraint (item: self.bubblesView,
                                                             attribute: .width,
                                                             relatedBy: .equal,
                                                             toItem: nil,
                                                             attribute: .notAnAttribute,
                                                             multiplier: 1,
                                                             constant: 0)
        // Add constraints to guarantee the proper alignment of `bubblesView` and `btnStackView`.
        self.bubblesView.translatesAutoresizingMaskIntoConstraints = false
        self.buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate ([
            self.bubblesViewSizeConstraint,
            // Constraint: buttonsStackView.centerX = view.centerX
            NSLayoutConstraint(item: self.buttonsStackView,
                               attribute: .centerX,
                               relatedBy: .equal,
                               toItem: self.view,
                               attribute: .centerX,
                               multiplier: 1,
                               constant: 0),
            // Constraint: buttonsStackView.top = bubblesView.bottom + 10
            NSLayoutConstraint(item: self.buttonsStackView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self.bubblesView,
                               attribute: .bottom,
                               multiplier: 1,
                               constant: 10),
            // Constraint: bubblesView.height = bubblesView.width
            NSLayoutConstraint(item: self.bubblesView,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: self.bubblesView,
                               attribute: .width,
                               multiplier: 1,
                               constant: 0),
            // Constraint: bubblesView.centerX = view.centerX
            NSLayoutConstraint(item: self.bubblesView,
                               attribute: .centerX,
                               relatedBy: .equal,
                               toItem: self.view,
                               attribute: .centerX,
                               multiplier: 1,
                               constant: 0),
            // Constraint: bubblesView.centerY = view.centerY
            NSLayoutConstraint(item: self.bubblesView,
                               attribute: .centerY,
                               relatedBy: .equal,
                               toItem: self.view,
                               attribute: .centerY,
                               multiplier: 1,
                               constant: 0)
        ])
    }
    
    open override func viewDidLayoutSubviews() {
        // When we're layouting subviews, recalculate the maximum dimension of the bubbles.
        // Calculate the maximum bubble size relative to the view estate we have at our disposal.
        self.bubbleDimensions.maximum = self.maximumBubbleSize.size (
            relativeTo: min(self.view.frame.width, self.view.frame.height) - 50)
        // Generate a ratio between the two dimensions, which is the effective size the input
        // image will be cropped to.
        let size = CGFloat (self.bubbleDimensions.maximum / self.bubbleDimensions.minimum)
        // If the ratio currently calculated is exactly the same as the one we had before,
        // then return. There's a catch though: we only allow this when the transformation on
        // `bubblesView` is identity, which means it isn't scaled, and also if the redraw button
        // is hidden. Otherwise, for these conditions, then it makes sense for our ratio to be the
        // same as the previous one!
        if size == self.imageColor?.image.size.width, self.bubblesView.transform.isIdentity,
            self.buttons.redraw.isHidden {
            return
        }
        // If we have previously executed a draw operation, act differently based on the difference
        // between the previous ratio and the current one.
        if self.imageColor != nil {
            // If the new possible drawing size is greater than the old one, then give the user
            // the possibility to redraw the circles with a bigger size.
            if size > self.imageColor.image.size.width {
                self.buttons.redraw.isHidden = false
                self.bubblesView.transform = .identity
            }
            // Otherwise, if we actually got less space than before (e.g. if the user switched
            // from landscape to portrait), then avoid a redrawing process and just transform
            // the bubbleView to an appropriate size.
            else if size < self.imageColor.image.size.width {
                // Avoid re-creating an unnecessary transform if it's already applied.
                guard self.bubblesView.transform.isIdentity else {
                    return
                }
                let scaleFactor = size / self.imageColor.image.size.width
                self.bubblesView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
                // Ensure that a previously shown redraw button isn't shown here.
                self.buttons.redraw.isHidden = true
            } else {
                // This happens only when a transform exists, or when the redraw button should be
                // hidden. If so -- fix these conditions.
                self.bubblesView.transform = .identity
                self.buttons.redraw.isHidden = true
            }
        } else {
            self.draw()
        }
    }
    
    // MARK: Methods
    /// This function generates the bubbles. It is composed of a multi-step generation.
    func draw() {
        // Try to analyze color information about the image.
        // If we can't, then bail out right now and let the user know.
        guard
            let scaledImage = UIImage (named: self.image.rawValue)?.scale (toSquareOfSize:
                self.bubbleDimensions.maximum / self.bubbleDimensions.minimum),
            let imageColor = scaledImage.color else {
            // Normally, we'd use exceptions or return a nil value, but since this is a
            // playground we are allowed to let the user know about the issue "roughly".
            fatalError("Can't gather color info about your image -- I'm terribly sorry!")
        }
        self.imageColor = imageColor
        // Obtain the size of the image, which is the base for our generation.
        var picSize = Int (self.imageColor.image.size.width) // it's a square, so width == height
        // Obtain the size of the smallest bubbles (the first generated).
        var bubbleSize = self.bubbleDimensions.minimum
        // Initialize the generation. Each layer is a bidimensional matrix, whose coordinates
        // (indices) are mapped to the image's pixels.
        // The generation begins by creating the first layer, which is the smallest one.
        var firstLayer = Matrix<BubbleView>(rows: picSize, columns: picSize)
        // Since we're dealing with a matrix, to populate it we need two cycles.
        for position in firstLayer.size {
            let cgPosition = position.cgPoint
            // Try to retrieve the color of the image for this position.
            guard let color = self.imageColor.color (at: cgPosition) else {
                fatalError("Bubble generation failed: failed to retrieve color at \(position)")
            }
            // Initialize a new Bubble object and add it to the first layer.
            let bubble = BubbleView(size: bubbleSize,
                                    position: cgPosition,
                                    color: color,
                                    roundCorners: !self.useSquares)
            firstLayer[position] = bubble
        }
        self.bubbleStatistics.total += firstLayer.size.total
        // Prepare to build the next layers. We do it procedurally, so we store a reference
        // to the previous layer and then build up on it.
        var currentLayer: Matrix<BubbleView>!, previousLayer = firstLayer
        // Proceed until we reach the max size.
        while (bubbleSize < self.bubbleDimensions.maximum) {
            // Cut in half the size of the image and double the size of our bubbles.
            picSize /= 2
            bubbleSize *= 2
            // Create a new layer.
            currentLayer = Matrix<BubbleView>(rows: picSize, columns: picSize)
            // Now, generate the bubbles for this layer, using the same method as before.
            for position in currentLayer.size {
                // This bubble is double the size: this means that there are four previous bubbles
                // we can make use of in the previous layer.
                let bubbles = [
                    previousLayer[2 * position.row,     2 * position.column],
                    previousLayer[2 * position.row + 1, 2 * position.column],
                    previousLayer[2 * position.row,     2 * position.column + 1],
                    previousLayer[2 * position.row + 1, 2 * position.column + 1]
                ]
                // Calculate the average of the four bubble colors.
                let averageColor = bubbles.map { $0.backgroundColor! }.average
                // Create the appropriate bubble, and assign its children.
                let bubble = BubbleView(size: bubbleSize,
                                        position: position.cgPoint,
                                        color: averageColor,
                                        roundCorners: !self.useSquares)
                bubble.children = bubbles
                currentLayer[position] = bubble
            }
            self.bubbleStatistics.total += currentLayer.size.total
            previousLayer = currentLayer
        }
        // Hooray! We're done! Add the latest layer (the biggest one) to the view.
        self.bubblesView.subviews.first?.removeFromSuperview()
        self.bubblesView.addSubview(currentLayer[0, 0])
        
        // Don't forget to update the constraint representing our size.
        self.bubblesViewSizeConstraint.constant = CGFloat (bubbleSize)

        // Now, it wouldn't be fun if we hadn't some animations! We are going to animate the
        // `centerY` constraint (the one that vertically centers the main bubble). To do that,
        // we first need to find it.
        // NOTE: if any other `centerY` constraint is added to the main view, remember to update
        // the search closure!
        if let constraint = (self.view.constraints.first { $0.firstAttribute == .centerY }) {
            // Once found, disable it temporarily (since it's active by default) and call
            // layoutIfNeeded() to update the view.
            constraint.isActive = false
            self.view.layoutIfNeeded()
            // Employ the nice and underrated spring-style animation provided by UIView.animate,
            // with values carefully chosen by testing.
            UIView.animate (withDuration: 2,
                            delay: 0.3,
                            usingSpringWithDamping: 0.5,
                            initialSpringVelocity: 0.6,
                            options: .curveEaseInOut,
                            animations: {
                                constraint.isActive = true
                                self.view.layoutIfNeeded()
                            })
        }
    }
    
    /// Saves the current `bubbleView` to the gallery.
    func saveToGallery() {
        UIGraphicsBeginImageContext (self.bubblesView.frame.size)
        defer { UIGraphicsEndImageContext() }
        // Render the current bubblesView to the freshly created image context.
        self.bubblesView.layer.render (in: UIGraphicsGetCurrentContext()!)
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            // Detect if we're running on a simulator, and if so, don't save the picture.
            #if !(arch(i386) || arch(x86_64)) && os(iOS)
                UIImageWriteToSavedPhotosAlbum (
                    image, self,
                    #selector(saveToGalleryCompletion(_:didFinishSavingWithError:contextInfo:)),
                    nil)
            #else
                self.saveToGalleryCompletion(image,
                                             didFinishSavingWithError: nil,
                                             contextInfo: nil)
            #endif
        }
    }
    
    /// Called whenever we successfully saved an image to the gallery.
    func saveToGalleryCompletion(_ image: UIImage,
                                 didFinishSavingWithError error: NSError?,
                                 contextInfo: UnsafeRawPointer?) {
        // Let the user know that we did it! :-)
        let alert = UIAlertController(title: "Ok!",
                                      message: "Done! Enjoy :-)",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    // MARK: BubbleContainerDelegate
    func bubbleContainer (didSplitBubble bubble: BubbleView, artificial: Bool) {
        self.bubbleStatistics.split += 1
        let progress = Float (self.bubbleStatistics.split) / Float (self.bubbleStatistics.total)
        if progress >= 1 {
            self.buttons.gallery.isHidden = false
        } else if progress >= 0.3 {
            self.buttons.complete.isHidden = artificial
            if artificial { self.bubblesView.isUserInteractionEnabled = false }
        }
    }
    
    // MARK: Misc
    public enum ImageChoice: String {
        case appleLogo, heart, wwdc16, kitten
    }
    
    /// This enum contains possible bubble sizes.
    ///
    /// Since the final dimension of the bubbles has to be a power of `2` for layering reasons,
    /// the different sizes are equal to the exponent that has to be subtracted from the biggest
    /// one.
    ///
    /// Consider this example:
    /// The determined maximum power suitable for a view size is **2⁷**, and as such the exponent
    /// is `7`.
    /// In this case:
    /// - The largest bubble size has `7` as its maximum exponent.
    /// - The medium bubble size, mapped to the subtrahend `1`, has `6` as its maximum exponent.
    /// - The smallest bubble size, mapped to the subtrahend `2`, has `5` as its maximum exponent.
    public enum BubbleSize: Int {
        case large = 0, medium, small
        
        /// The largest exponent subtrahend, corresponding to the smallest size.
        static var maxSubtrahend = BubbleSize.small.rawValue
        
        /// Given a length, returns the largest value corresponding to this bubble size that fits
        /// in the specified length.
        ///
        /// - Parameter length: The maximum space usable to contain this bubble size.
        /// - Returns: The power of two corresponding to this bubble size that fits in `length`.
        func size (relativeTo length: CGFloat) -> Int {
            return self.size (relativeToExponent: Int (length).closerExponentOf2)
        }
        
        /// Given an exponent, returns `2` raised to the power of that exponent minus the
        /// subtrahend of this bubble size.
        ///
        /// - Parameter exponent: An exponent.
        /// - Returns: `2` raised to the power of that exponent minus the value of this bubble size
        func size (relativeToExponent exponent: Int) -> Int {
            // Thank you bitshifts!
            return 1 << (exponent - self.rawValue)
        }
    }
}

extension Int {
    /// The largest exponent of `2` that is within this integer.
    ///
    /// Example: `[129, 250, 10].map { $0.closerExponentOf2 } == [128, 128, 8]`
    public var closerExponentOf2: Int {
        return Int (floor (log2 (Double (self))))
    }
}
