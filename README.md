# 🎮 #MAME BGFX + ReShade CRT Setup



Bring authentic CRT vibes back to your MAME experience!
This setup combines BGFX screen chains with ReShade shaders for customizable scanlines, brightness, and image effects. Perfect for retro gaming enthusiasts who want that classic arcade look.  


## ✨ Features

CRT-style scanlines & glow

Brightness & image tuning

Works with BGFX only for performance, or combine with HLSL

Includes crt-geom-deluxe chain as a ready-to-use preset

Optional CRT-Royale (ReShade) for extra realism (heavy on performance)  



## ⚙️ Requirements

MAME .268+ (Aug 2024 build recommended)

Dedicated GPU or modern onboard graphics

Windows with Direct3D 10/11/12 support  


## 🔧 Setup Instructions  

1. BGFX (MAME Built-in)

Download crt-geom-deluxe.json

Place it in:

mame\bgfx\chains


Edit your mame.ini (or frontend settings) to enable:

video bgfx
bgfx_screen_chains crt-geom-deluxe  


Bring authentic CRT vibes back to your MAME experience!
This setup combines BGFX screen chains with ReShade shaders for customizable scanlines, brightness, and image effects. Perfect for retro gaming enthusiasts who want that classic arcade look.



## ✨ Features

CRT-style scanlines & glow

Brightness & image tuning

Works with BGFX only for performance, or combine with HLSL

Includes crt-geom-deluxe chain as a ready-to-use preset

Optional CRT-Royale (ReShade) for extra realism (heavy on performance)  


## ⚙️ Requirements

MAME .268+ (Aug 2024 build recommended)

Dedicated GPU or modern onboard graphics

Windows with Direct3D 10/11/12 support  


## 🔧 Setup Instructions
1. BGFX (MAME Built-in)

Download crt-geom-deluxe.json

Place it in:

mame\bgfx\chains


Edit your mame.ini (or frontend settings) to enable:

video bgfx
bgfx_screen_chains crt-geom-deluxe



2. ReShade (Optional but Recommended)

Backup your MAME folder

Download ReShade

Run installer → point to mame.exe

Choose Direct3D 10/11/12

Install all default shaders

When “Succeeded!” appears in the top-left, close installer  



## 👉 To use CRT Royale (by akgunter):  

When “Succeeded!” appears in the top-left, close installer

## 👉 To use CRT Royale (by akgunter):  

Install crt_royal-reshade shader

Enable crt-royale.fx in ReShade

Note: Gorgeous results, but demanding on performance  



## 🎛️ ReShade Preset (Updated Apr 2025)  

=======
## 🎛️ ReShade Preset (Updated Apr 2025)  
>>>>>>> 9a5bb2bd8fda227ab5806d1eee40d1ddbbc465a6

📥 Download here

Press Home to open the ReShade menu

Load the preset

Adjust brightness/contrast as needed (depends on your monitor & game defaults)  



Adjust brightness/contrast as needed (depends on your monitor & game defaults)


## 🖼️ Visual Notes

Uses Delta 4x2.rgb mask in BGFX → subtle, natural RGB pattern

All settings are kept lightweight to balance performance & visuals

Extra tweaking available via in-game TAB → Slider Settings  



Extra tweaking available via in-game TAB → Slider Settings


## 💡 Tips

Experiment with scanline intensity & masks for your monitor

Use HLSL + BGFX for a hybrid look


ReShade CRT Royale looks best on high-res monitors (but hits FPS)  


## ⚡ Now your README has arcade CRT-styled neon badges, a cleaner structure, and a polished presentation.


ReShade CRT Royale looks best on high-res monitors (but hits FPS)  


## ⚡ Now your README has arcade CRT-styled neon badges, a cleaner structure, and a polished presentation.

ReShade CRT Royale looks best on high-res monitors (but hits FPS)

