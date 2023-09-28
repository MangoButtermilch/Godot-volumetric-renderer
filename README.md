# Godot-volumetric-renderer
Volumetric rendering approach for clouds or nebulae for Godot 4.0

![Alt text](Screenshots/preview.png?raw=true "Settings")

## Setup
- Drag the shader and resources into your Godot project folder
- Create a cube and attach a shader material to it and assign the shader (using a 10 x 10 x 10 in my case)
- Done

## Rough shader explanation
This shader uses volumetric raymarching for rendering the clouds / nebulae.

The idea is basically to create a ray from the mesh surface and cast it in the direction the camera is looking at.

The ray then takes many steps with a fixed size (in contrast to normal ray marching where the stepsize changes). At every step we sample a 3D texture with the 3D position of the ray and collect the density (texture value between 0 and 1). Optionally we can take multiple additional steps towards the light source for some more realistic lighting.

The collected density is then used to generate the color of the pixel.

The shader has two modes: 
- Default mode:
![Alt text](Screenshots/cloud_render_lighting.png?raw=true "Settings")
- Performance mode (without light steps):
![Alt text](Screenshots/cloud_render_performance.png?raw=true "Settings")

## Kown issues
- The shader is not completley finished and you may find some naming/performance etc. issues
- The shader will cause sorting issues with objects inside/outside the volume since it's a spatial shader. Some people already told me to try and convert it into a fog shader but I didn't manage to that yet.
- The render distance is currently pretty low. I've tried to increase the step size the further away from the camera we are but had no success yet
- Changing the mesh that the shader is rendered on may cause some weird issues

### Maybe you can help me improve this shader :)

## Main Settings explained

You'll have these main defines in the shader
- #define USE_PERFORMANCE_MODE - If set, will skip the iterations for lighting calculations and thus will not have any shadowing
- #define USE_BOX_BORDER - If set, will respect the _epslion unfirom that defines a bonding box for the volume
- #define RENDER_REVERSE - If set, will start the raymarching from the end and starts it towards the camera. This results in a greater view distance but you can not really fly through the nebulae any more.

- uniform _maxSteps - Defines how many steps our ray takes. More steps = higher viewdistance but also higher performance costs.
- uniform _stepSize - Defines how large the step of the ray is. Higher = lower detail but greater viewdistance.
- uniform _maxLightSteps - Same as _maxSteps but for shadowing. Be carefull with this setting as this might cause heavy performance problems since in the worst case the shader will take _maxSteps * _maxLightSteps amount of steps. 
- uniform _lightStepSize - Same as _stepSize but for the light step. Usually a greater value to create bigger shadows
- uniform _epslion - Bounding box
- uniform _maxLightDistance - Same as _epslion but just for the lighting loop

## Example Settings

![Alt text](Screenshots/example_settings.png?raw=true "Settings")


## About the 3D Textures
The provided texture is made with my free tool to generate 3D textures. It was previously designed to create nebulae-like textures so it's maybe not suited for clouds.

You can find it here: https://acetix.itch.io/pseudo-volume-generator

