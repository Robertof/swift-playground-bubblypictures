import UIKit

/// This class provides color information about a specific UIImage.
/// Specifically, it allows you to determine the color of a particular pixel of an image, or
/// to obtain aggregate information (e.g. an average) of colors of a portion of the image.
open class ImageColor {
    public let image: UIImage
    public let colorData: Data
    
    /// Initializes a new ImageColor object. This constructor tries to fetch color data about the
    /// image, and if it fails for any reason it returns `nil`.
    public init?(of image: UIImage) {
        self.image = image
        // Try to retrieve the pixel information about this UIImage. If we can't (e.g. because
        // there's no data provider available), then bail out right now.
        guard let pixelData = image.cgImage?.dataProvider?.data as Data? else {
            return nil
        }
        // We did it! Assign the retrieved color data to the class.
        self.colorData = pixelData
    }
    
    /// Returns the color at the specified position of the image represented by this object.
    ///
    /// - Parameter position: The position of a pixel of the image.
    /// - Returns: The color of the pixel, if found.
    public func color (at position: CGPoint) -> UIColor? {
        // Calculate the base index usable to access image data, accounting for:
        // - the column specified in the position (imageWidth * specifiedColumn)
        // - the row specified in the position
        // - the total number of subpixels (RGB + alpha, which amounts to 4)
        let baseIndex = Int (self.image.size.width * position.y + position.x) * 4
        // Ensure that the specified index actually exists in our data.
        guard self.colorData.count > baseIndex else { return nil }
        // ** FIXME: why are we getting BGR colors instead of RGB? :\
        // ** For now, switching to parsing colors as BGR instead of RGB.
        // Using the base index, create an UIColor. UIColor values are in a different scale
        // (0 to 1 instead of 0 to 255), so account for that by dividing everything by 255.
        return UIColor (red:   CGFloat (self.colorData[baseIndex + 2]) / 255,
                        green: CGFloat (self.colorData[baseIndex + 1]) / 255,
                        blue:  CGFloat (self.colorData[baseIndex]) / 255,
                        alpha: CGFloat (self.colorData[baseIndex + 3]) / 255)
    }
    
}

/// A convenient UIImage extension which provides an easy way to get an ImageColor image from
/// an UIImage.
extension UIImage {
    /// Generates an `ImageColor` object, containing color information about an image.
    public var color: ImageColor? {
        return ImageColor(of: self)
    }
    
    /// Scales this image to the square of the specified size.
    /// - Warning: At the moment, this doesn't take proportions in account!
    ///
    /// - Parameter size: The length of the side of a square.
    /// - Returns: This image scaled to the square of the specified size.
    func scale (toSquareOfSize size: Int) -> UIImage? {
        let scaledRect = CGRect (x: 0, y: 0, width: size, height: size)
        UIGraphicsBeginImageContextWithOptions (scaledRect.size, false, self.scale)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
            UIGraphicsPushContext(context)
            self.draw(in: scaledRect)
            UIGraphicsPopContext()
            let newImage = UIImage (cgImage: context.makeImage()!,
                                    scale: self.scale,
                                    orientation: .up)
            UIGraphicsEndImageContext()
            return newImage
        }
        return nil
    }
}

/// Extension for collections of UIColors used to calculate the average color.
extension Sequence where Iterator.Element == UIColor {
    /// A color composed of the average values of the components in this collection.
    var average: UIColor {
        // Allocate an array of arrays of CGFloats to hold the components of all the colors.
        var components = [[CGFloat]](repeating: [], count: 4)
        
        // Iterate each color of this sequence.
        for color in self {
            if let colorComponents = color.cgColor.components {
                // For each component of this color, add it to the right position of the
                // components array.
                colorComponents.enumerated().forEach {
                    components[$0.offset].append($0.element)
                }
            }
        }
        
        // Now calculate the actual average of the color components by summing each component
        // and dividing it by the total of colors.
        let color = components.map { $0.reduce (0, +) / CGFloat ($0.count) }
        
        // We're done!
        return UIColor(red: color[0],
                       green: color[1],
                       blue: color[2],
                       alpha: color[3])
    }
}
