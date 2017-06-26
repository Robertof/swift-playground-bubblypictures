# BubblyPictures

This is the scholarship-winning playground I created for WWDC 2017. It works on both Xcode and the Swift Playgrounds app on iPad with consistent performance.

I had a lot of fun making this playground as it involved using Swift to its fullest.

## How it works

The algorithm is pretty simple and works with any image. Here's a recap of what is done:

- The image is scaled according to the users' preferences to a suitable power of 2.
  This is because to generate the smaller bubbles we divide the size by 2 each time.
- A matrix as large as the size of the image is created and populated with a "bubble view" with the color of each pixel.
- The following layers are generated in the same way, but the color is set to the average colors of the four smaller bubbles of the previous level.
- Finally, the largest bubble is added and animated.

When the user taps on a bubble a composite animation is performed and the bubble reveals the four underlying bubbles.
