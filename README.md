# 🎮 MAME BGFX + ReShade Scanline CRT Setup



Bring authentic CRT vibes back to your MAME experience!
This setup combines BGFX screen chains with ReShade shaders for customizable scanlines, brightness, and image effects. Perfect for retro gaming enthusiasts who want that classic arcade look.  

Im not claiming to be an expert on the visuals/colors it just looks decent to me.

Added my custom ReShade Shader, CRT-Mame-Advance-four.fx add to your mame\reshade-shaders\Shaders, deselect all other options and turn off bgfx.


## ✨ Features

- CRT-style scanlines & glow  
- Brightness & image tuning  
- Includes crt-geom-deluxe chain as a ready-to-use preset
- Optional my custom made CRT-Mame-Advance-four.fx for ReShade (disable all other options)
- Optional CRT-Royale (ReShade) for extra realism (heavy on performance)  



## ⚙️ Requirements

MAME .268+ (recommended)  
Dedicated GPU or modern onboard graphics  
Windows with Direct3D 10/11/12 support  

  
  ![Screenshot April 2025](https://raw.githubusercontent.com/JBW-byte/Screenshots/refs/heads/main/sfiii_sep.png)  
    
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

Install all default shaders, *install the extra shader crt_royal-reshade by akgunter.    
When “Succeeded!” close installer.

Add CRT-Mame-Advance-four.fx to mame\reshade-shaders\Shaders



## 🎛️ ReShade Preset (Updated Sep 2025)  

📥 [Download here - Standard](https://github.com/JBW-byte/Mame-BGFX-Reshade/blob/main/Mame_preset1.ini)  
📥 [Download here - CRT_Royal](https://github.com/JBW-byte/Mame-BGFX-Reshade/blob/main/Mame_preset-crt_royal.ini) disable mask in bgfx settings, TAB(Slider Control) in-game.  

Press Home to open the ReShade menu in-game
Load the preset  

Place file in mame\reshade-shaders <img width="1200" height="675" alt="image" src="https://github.com/user-attachments/assets/4421e315-5b07-4902-b81d-18f2952f5ad7" />


In ReShade settings, DPX strength and Levels black point will have a big effect on the image.




## 🖼️ Visual Notes

Adjust brightness/contrast in the Mame tab menu(Slider Control) if too bright in some games, good default Street Fighter II CE e.g. Brightness .970, Contrast 1.1, Gamma .800 

These settings depend on your monitor settings

Uses Delta 4x2.rgb mask in BGFX → subtle, natural RGB pattern

All settings are kept lightweight to balance performance & visuals

Extra tweaking available via Mame in-game TAB → Slider Control and ReShade Home key.  

 ![Screenshot April 2025](https://github.com/JBW-byte/Screenshots/blob/main/Neon_mame_banner.png)

