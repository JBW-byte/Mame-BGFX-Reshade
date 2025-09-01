# 🎮 MAME BGFX + ReShade Scanline CRT Setup



Bring authentic CRT vibes back to your MAME experience!
This setup combines BGFX screen chains with ReShade shaders for customizable scanlines, brightness, and image effects. Perfect for retro gaming enthusiasts who want that classic arcade look.  


## ✨ Features

- CRT-style scanlines & glow  
- Brightness & image tuning  
- Includes crt-geom-deluxe chain as a ready-to-use preset  
- Optional CRT-Royale (ReShade) for extra realism (heavy on performance)  



## ⚙️ Requirements

MAME .268+ (Aug 2024 build recommended)  
Dedicated GPU or modern onboard graphics  
Windows with Direct3D 10/11/12 support  

  
  ![Screenshot April 2025](https://raw.githubusercontent.com/JBW-byte/Screenshots/refs/heads/main/sfiii.webp)  
    
  ![Screenshot April 2025](https://raw.githubusercontent.com/JBW-byte/Screenshots/refs/heads/main/marvelvsSF.webp)  


    
## 🔧 Setup Instructions  

### 1. BGFX (MAME Built-in)

Download [crt-geom-deluxe.json](https://github.com/JBW-byte/Mame-BGFX-Reshade/blob/main/crt-geom-deluxe.json).

Place it in: mame\bgfx\chains  

Edit your mame.ini (or frontend settings) to enable:

OSD VIDEO OPTIONS  
video bgfx  

BGFX POST-PROCESSING OPTIONS  
bgfx_screen_chains crt-geom-deluxe  

  
    
### 2. ReShade

Backup your MAME folder

Download [ReShade](https://reshade.me/) 

Run installer → point to mame.exe

Choose Direct3D 10/11/12

Install all default shaders, *install the extra shader crt_royal-reshade by akgunter, turn on crt-royale.fx in reshade. may need to disable mask in bgfx settings, TAB(Slider Control) in-game, it looks good but uses a lot of performance.

When “Succeeded!” appears in the top-left, close installer  



## 🎛️ ReShade Preset (Updated Apr 2025)  

📥 [Download here](https://github.com/JBW-byte/Mame-BGFX-Reshade/blob/main/Mame_preset1.ini)  

Press Home to open the ReShade menu in-game
Load the preset  

Place file in mame\reshade-shaders <img width="1200" height="675" alt="image" src="https://github.com/user-attachments/assets/4421e315-5b07-4902-b81d-18f2952f5ad7" />


Adjust brightness/contrast in the tab menu(Slider Control) (These settings depend on your monitor settings and the game defaults for brightness and contrast in many cases.)turn brightness down a bit and contrast up to 1.1.  



## 🖼️ Visual Notes

Uses Delta 4x2.rgb mask in BGFX → subtle, natural RGB pattern

All settings are kept lightweight to balance performance & visuals

Extra tweaking available via Mame in-game TAB → Slider Control and ReShade Home key.  

 ![Screenshot April 2025](https://github.com/JBW-byte/Screenshots/blob/main/Neon_mame_banner.png)

