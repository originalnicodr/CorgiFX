# CorgiFX

CorgiFX is a collection of shaders primarily designed for Virtual Photography, utilizing the ReShade FX language.

For instructions on using multiple instances of a shader simultaneously, please refer to [this section](https://framedsc.com/ReshadeGuides/setupreshade.htm#shader-duplication) in the Framed ReShade guide.
 
# CanvasFog

CanvasFog enables you to apply various types of gradients to the game scene, interacting with the depth buffer. This allows you to manually add gradients to the sky, create contrast between subjects and the background, produce silhouettes, and more.

I have reused code from similar shaders (with proper credits given) like AdaptiveFog, Emphasize, and DepthSlicer. If you are familiar with these shaders, you should have no trouble adjusting to the parameters of CanvasFog.
 
## Features
 
- **Gradients**: Choose from a variety of gradients (Linear, Radial, Strip, Diamond), each with its own customizable settings.
- **Colors with alpha channel**: In addition to selecting two colors for the gradient, you can also adjust the alpha channel to create color spots.
- **HSV gradients**: Utilize HSV gradients for smoother color transitions.
- **Color pickers**: Capture colors from pixels on the screen and incorporate them into the gradient.
- **Fog Types**: The fog type refers to the algorithm used to display the gradients. Currently, there are three types available: Adaptive Fog, Emphasize, and Depth Slicer. The first two function similarly to Frans' shaders of the same name, while the latter utilizes Prod80's shaders for depth control. In my experience, Depth Slicer is the easiest one to use.
- **Fog rotation (WIP)**: This feature allows you to rotate the fog "wall" within the game world, creating more interestic interactions with the games' depth buffer. Currently, it is only available in AdaptiveFog.
- **Blending modes**: Apply various blending modes (Multiply, Screen, Overlay, etc.) to blend the colors of the gradient with the scene.
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476225-9eedbc80-4370-11ea-8a58-57447dadf76e.png">
<i>Simple adaptive-type fog with linear gradient and normal blending</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476249-a745f780-4370-11ea-8b9a-72c1f0d28f88.png">
<i>Adaptive-type fog with linear gradient using color mode</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476250-a7de8e00-4370-11ea-8d36-cb49df021fba.png">
<i>Adaptive-type fog with linear gradient using a color with zero alpha</i></p>
 
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
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/74173946-d0d50d80-4c11-11ea-8d39-b7df1f82a613.png">
<i>Adaptive-type fog with diamond gradient and CanvasMask</i></p>
 
 
# CanvasMask

Similar to CanvasFog, CanvasMask allows you to mask other shaders. It combines the "fog" controls and gradients to determine which shaders should be displayed. To use CanvasMask, place the shaders you want to mask between the `BeforeCanvasFog` and `AfterCanvasFog` techniques.

You can enable the debug option to visualize the mask being edited, making it easier to fine-tune the settings.
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476266-a9a85180-4370-11ea-8d86-d723fe54d3b3.png">
<i>Using emphasize-type mask with a LUT shader</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476267-a9a85180-4370-11ea-9ea3-51acd224bb12.png">
<i>Using emphasize-type mask with the Comic shader</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476269-aa40e800-4370-11ea-82b0-11361c59dc63.png">
<i>Using adaptivefog-type mask with the DisplayDepth shader</i></p>
 
# StageDepthPlus

Using the StageDepth shader as a foundation, I have added several features that seemed natural for drawing an image on the screen.
 
 ## Features

- **Scale**: Adjust the scale of the image individually in both axes.
- **Rotation**: Rotate the image as needed.
- **Flip**: Horizontally and vertically flip the image.
- **Blending Modes**: Apply blending modes to the image, offering more versatile usage.
- **Depth Control**: This feature was already present in the original StageDepth shader. It utilizes the depth buffer to determine whether to display the image.
- **Depth map usage**: An experimental feature that allows you to provide a depth map image alongside the stageplus image. The depth map determines whether the image is shown or not.
- **Masking**: Use an image as a mask in conjunction with the image itself.
- **AR Correction**: Enter the resolution of the image being used as preprocessor definitions, enabling automatic loading with those values.
- **Smooth depth control**: Smooth out the "depth" of the image, making it easier to integrate images like fog or smoke.
- **Repeat image**: Repeat the loaded image across the entire screen.

## StageDepthPlus_WithDepthBufferMod.fx

Inside the `StageDepthPlus with depth buffer modification` folder, you will find a version of StageDepthPlus that allows blending a depth map image with the game's actual depth buffer. This enables you to load an image of a subject and incorporate it into the depth buffer, enabling interaction with other shaders that utilize the depth buffer. To use this shader, replace the ReShade.fxh file in your shaders folder with the one provided in the repository's folder. Also, edit the global preprocessor definition `RESHADE_MIX_STAGE_DEPTH_PLUS_MAP` to 1.
 
Please note that this feature is highly experimental, and due to limitations within ReShade, you will need to set up the image controls (scale, position, rotation, etc.) individually in each shader that interacts with the depth buffer. Additional controls will appear in each shader alongside the preprocessor definitions from StageDepthPlus, but you can ignore those. I apologize for any inconvenience in its usage. In the future, it may be more appropriate to develop this as a separate add-on, as it would make more sense that way.

I have edited the `ReShade.fxh` file based on reshade version 4.9.1. Please keep in mind that it may not work with newer or older versions of ReShade.

<p align="center"><img src="https://user-images.githubusercontent.com/24371572/73476247-a745f780-4370-11ea-930c-fe813ae3200b.png">
<i>I like corgis</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/74969051-abf34e00-53fa-11ea-9448-d93621c3c9c2.png">
<i>Image using a depth map</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/74969102-b57cb600-53fa-11ea-81ad-6df4c1623e59.png">
<i>Same image using CineDOF while mixing the image depth map with the depth buffer</i></p>
 
# FreezeShot

With this shader, you can capture real-time images of the game and manipulate them as if they were textures being used by StageDepthPlus, providing similar controls. Furthermore, when you freeze the image, the shader saves the depth buffer, allowing the image layer to interact with the scene.

Please note that the image is stored in memory, so it will be lost upon reloading ReShade (which occurs, for instance, during hotsampling). Some users have utilized this shader without freezing the image itself, for creating reflections for example, or to rotate a portrait shot in a game that doesnt support vertical aspect ratios resolutions, so maybe you find more uses for it.
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/74969164-caf1e000-53fa-11ea-8291-c80527ea385b.jpg">
<i>Freezing and flipping the image</i></p>
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/74975605-12319e00-5406-11ea-850a-828c13f42636.png">
<i>Frozen image using the saved depth to interact with the scene</i></p>
 
 
# Flip
 
I can't take credit for this one since it's a really easy shader Marty wrote in the reshade forums, I just added a couple of bools parameters to choose if you want to flip the image horizontally or vertically. I put it here since it can be useful for artistic purposes like the image below.
 
<p align="center"><img src="https://user-images.githubusercontent.com/24371572/74970280-d6dea180-53fc-11ea-8ed6-7b9c6ff15004.png">
<i>Flip shader with a couple of instance of CanvasMask</i></p>
 
# Color Mask
 
As the title suggests, this shader is specifically designed for masking purposes, using colors as the target. The objective was to replicate the masking functionality found in Substance Designer. Thanks to Dread for the valuable feedback during the development process.

## Features
 
- **Target Hue**: You can use an eyedropper to select the specific hue and/or luma values you want to target.
- **Masks**:
    - **Hue Mask**: Allows you to select the chroma target that will interact with the selection. You can adjust its range, smoothness of the step, and opacity.
    - **Luma Mask**: Lets you select the luma target that will interact with the selection. You can adjust its range, smoothness of the step, and opacity.
- **Blending Mode**: Choose a blending mode to determine how the two masks should interact with each other. You can opt for "addition" or "multiplication" to achieve different effects. This feature is especially useful if you want to select specific elements such as red shadows (multiply) or both reds and shadows (add).
 
<p align="center"><img src="https://cdn.discordapp.com/attachments/804451693853016085/1015703965352067183/UnityEmpty3d_2022-09-03_15-58-38_overlay.png">

<p align="center"><img src="https://cdn.discordapp.com/attachments/804451693853016085/1015703965704405223/UnityEmpty3d_2022-09-03_15-55-30_overlay.png">

# AspectRatioMultiGrid

While I frequently utilize `AspectRatioComposition`, I encountered certain features that I wished it had. As a result, I created my own variation of the concept.

## Features:

- Disable AR bars if you only want to use the grids.
- Select different aspect ratios from a customizable list within the ReShade UI (refer to the tooltip for instructions on how to edit it).
- Choose a specific aspect ratio using sliders, similar to AspectRatioComposition.
- Display multiple types of grids simultaneously.
- Enable the grid color to contrast with the pixels behind it, creating a distinctive visual effect against the game's screen.
- Adjust the width of the grid lines for better visibility, especially when utilizing DSR (Dynamic Super Resolution).
- Move lines to create custom grids or utilize a custom grid image if desired.

And more!

<p align="center"><img src="https://cdn.discordapp.com/attachments/804451693853016085/1015704440264728737/UnityEmpty3d_2022-09-03_11-50-44_overlay.png">


# Things to do
- Refactor CanvasFog, CanvasMask and StageDepthPlus. I wrote thos when I didnt know how scaling and rotation matrices worked, so the code use pure ad-hoc horror.

- Refactor CanvasFog, CanvasMask, and StageDepthPlus. These shaders were initially created without a proper understanding of scaling and rotation matrices, so the code use pure ad-hoc horror.

- Fix the Strip gradient in CanvasFog so that it maintains the scale correctly while changing the angle.
- Adjust the Diamond gradient in CanvasFog to rotate properly with modifications made in the x and y axes.
- Implement different types of scaling algorithms in StageDepthPlus for more flexibility.
 
If you encounter any bugs or have any suggestions, please feel free to reach out to me. Your feedback is greatly appreciated.
 
# Support and donations
I genuinely appreciate your support, and a simple thank you is more than enough. However, if you would like to further assist me, you can contribute through [PayPal](https://www.paypal.com/paypalme/originalnicodr). I am incredibly grateful to the kind individuals who have already supported me. Your generosity is truly appreciated and motivates me to continue my work.

## Top Donators
 
- **Dread**
