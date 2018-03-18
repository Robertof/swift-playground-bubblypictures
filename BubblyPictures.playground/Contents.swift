//#-hidden-code
import UIKit
import PlaygroundSupport
let bubblifier = BubblifierViewController()
//#-end-hidden-code

/*:
 ## The Picture Bubblifier
 Welcome! This playground takes your favorite image and splits it in numerous, *fancy bubbles*.
 You are free to test this playground both on Xcode and on Swift Playgrounds on an iPad.
 
 To get started, run this playground and move your finger over the bubble!
 Try to get revelead as much as possible of the image, and see what happens.
 
 ### Customization
 First off, let's choose the image you prefer. Just tap on the image
 currently selected and look at the available options!
*/
bubblifier.image = .kitten
/*:
 If you think the smallest bubbles are _too small_ (or too big), then try to fiddle around with their size here.
*/
bubblifier.minimumBubbleSize = .medium
/*:
 You can also customize their maximum size! What happens when you choose the smallest one? Try it!
 */
bubblifier.maximumBubbleSize = .large
/*:
 What if, instead of bubbles, we used squares? I took care of that for you -- just switch this from `false`
 to `true` to enjoy **big** pixels becoming *small* pixels.
 */
bubblifier.useSquares = false

/*:
 ### Footnotes
 Made by Roberto Frenna - thanks for trying me!
 
 Please feel free to inspect the source code of the other files to learn how this works.
 
 All the code is documented and should be easy to understand even for a Swift beginner.
*/
//#-hidden-code
PlaygroundPage.current.liveView = bubblifier
//#-end-hidden-code
