# 🎮 #MAME BGFX + ReShade CRT Setup



Bring authentic CRT vibes back to your MAME experience!
This setup combines BGFX screen chains with ReShade shaders for customizable scanlines, brightness, and image effects. Perfect for retro gaming enthusiasts who want that classic arcade look.  


## ✨ Features

CRT-style scanlines & glow

Brightness & image tuning

Includes crt-geom-deluxe chain as a ready-to-use preset

Optional CRT-Royale (ReShade) for extra realism (heavy on performance)  



## ⚙️ Requirements

MAME .268+ (Aug 2024 build recommended)

Dedicated GPU or modern onboard graphics

Windows with Direct3D 10/11/12 support  

  ![Screenshot April 2025](https://github.com/JBW-byte/Mame-BGFX-Reshade/blob/main/vwuwyv2fltse1.webp)

  ![Screenshot April 2025](https://github.com/JBW-byte/Mame-BGFX-Reshade/blob/main/ye4jrgrdltse1.webp)


## 🔧 Setup Instructions  

### 1. BGFX (MAME Built-in)

Download [crt-geom-deluxe.json](https://drive.google.com/file/d/1S9rYcUZEVSiZcKPovk4OlVwTiCqhsr16/view?usp=sharing).

Place it in:

mame\bgfx\chains


Edit your mame.ini (or frontend settings) to enable:

OSD VIDEO OPTIONS  
video bgfx  

BGFX POST-PROCESSING OPTIONS  
bgfx_screen_chains crt-geom-deluxe  

  
    
### 2. ReShade (Optional but Recommended)

Backup your MAME folder

Download [ReShade](https://reshade.me/) 

Run installer → point to mame.exe

Choose Direct3D 10/11/12

Install all default shaders, *install the extra shader crt_royal-reshade by akgunter to try this new port of CRT Royal on its own or on top of my settings, turn on crt-royale.fx in reshade. it looks good but uses a lot of performance.

When “Succeeded!” appears in the top-left, close installer  

Note: Gorgeous results, but demanding on performance  



## 🎛️ ReShade Preset (Updated Apr 2025)  

📥 [Download here](https://drive.google.com/file/d/1OiYts_8r1J3BZmyIzAopg3_uqjvnASfe/view?usp=sharing)

Press Home to open the ReShade menu

Load the preset

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

