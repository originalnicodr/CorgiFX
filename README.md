# <span style="color:#bb4400">CorgiFX</span>

Just shaders that i edit or make.

I am new at writing shaders so please take that in mind while reading the code. Any code used from other shaders will be stated in the shader comments.

# <p align="center"><span style="color:#bb0044">CanvasFog</span></p>

If you are familiar with the Adaptive Fog shader then you know how the fog from that shader looks like, if not its basically a color you choose to blend with the depth. Taking that as an initial point i added the option to use gradients in the fog instead of a single color.

## Features

- **Gradients**: The available gradients are lineal, radial and strip, which they all have they'r own settings
- **Colors with alpha channel**: Besides having the option to choose 2 colors in the gradient, you can also change the alpha channel values to play around
- **Color samplers**: You can pick the colors of the gradients from the screen
- **Fog Types**: The name isnt the best, but it means that you can choose to use the adaptive fog-type or the emphasize fog-type wich isnt a fog technically speaking, but it affects the "surface" of objects in the fog range. Will let some pictures bellow.
- **Blending modes**: I added different ways for the fog to blend with the screen. The available blending modes are the following:
    - Normal
    - Multiply
    - Screen
    - Overlay
    - Darken
    - Lighten
    - Color Dodge
    - Color Burn
    - Hard Light
    - Soft Light
    - Difference
    - Exclusion
    - Hue
    - Saturation
    - Color
    - Luminosity

## Some example images
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476225-9eedbc80-4370-11ea-8a58-57447dadf76e.png">
<i>Simple adaptive-type fog with linear gradient and normal blending</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476249-a745f780-4370-11ea-8b9a-72c1f0d28f88.png">
<i>Adaptive-type fog with linear gradient using color mode</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476250-a7de8e00-4370-11ea-8d36-cb49df021fba.png">
<i>Adaptive-type fog with linear gradient using a color with transparency</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476254-a7de8e00-4370-11ea-9af2-2b1df0a66b2c.png">
<i>Radial gradient with high gradient sharpness</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476256-a8772480-4370-11ea-8579-7dd8df7e8755.png">
<i>Strip type gradient with one of the colors with 0 alpha value</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476258-a8772480-4370-11ea-8184-d2b90a51fcfe.png">
<i>Radial gradient with screen blending mode</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476261-a8772480-4370-11ea-85e7-735c53225421.png">
<i>You can alter the x and y values separately on the radial gradient as well as rotating it</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476265-a9a85180-4370-11ea-924d-98513728f30c.png">
<i>Emphasize-type fog with lineal gradient and color blending mode</i></p>


<p align="center"> <font size="+3"><span style="color:#bb0044">CanvasMasking</span></font></p>

While doing the CanvasFog shader i thought that it would be cool to have these gradient stuff alongside the depth buffer to use as a mask, so here it is.

Its basically has the same features from the CanvasFog shader (that are relevant for a masking shaders), not very much to add.

## Some example images

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476266-a9a85180-4370-11ea-8d86-d723fe54d3b3.png">
<i>Using emphasize-type mask with a LUT shader</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476267-a9a85180-4370-11ea-9ea3-51acd224bb12.png">
<i>Using emphasize-type mask with the Comic shader</i></p>

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476269-aa40e800-4370-11ea-82b0-11361c59dc63.png">
<i>Using adaptivefog-type mask with the DisplayDepth shader</i></p>

# <p align="center"><span style="color:#bb0044">StageDepthPlus</span></p>

So again in one of those "i want to control x from shader y" moments i made some changes to the StageDepth shader. Here are the stuff it can do.

- **Scale**: Possibility to adjust the scale of the image in both axis individually
- **Rotation**: This one speaks for itself, you can rotate the image
- **Blending Modes**: I wrote them for the CanvasFog shader and figured out they can be usefuls applied to an image
- **Depth Control**: It already was in the original StageDepth. It uses the depth buffer to decide to show the image or not

## Some example images

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476247-a745f780-4370-11ea-930c-fe813ae3200b.png">
<i>I like corgis</i></p>