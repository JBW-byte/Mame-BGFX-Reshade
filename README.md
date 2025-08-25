# Mame-BGFX-Reshade
Scanlines, image and brightness with reshade. Will require dedicated GFX card or recent onboard. can run bgfx only for performance. can use with HLSL as well.


BGFX crt-geom-deluxe.json - put this file in mame\bgfx\chains for my defaults.

mame .268+ Aug 2024 (may work with earlier versions), crt-geom-deluxe.json https://drive.google.com/file/d/1S9rYcUZEVSiZcKPovk4OlVwTiCqhsr16/view?usp=sharing

set bgfx in mame video settings and select crt-geom-deluxe as the screen chain(effect) in your mame.ini or front end settings.

OSD VIDEO OPTIONS
video bgfx

BGFX POST-PROCESSING OPTIONS
bgfx_screen_chains crt-geom-deluxe

REshade - make a copy of your mame folder to try this out, download reshade and install using the mame.exe as the game to install, select direct3d 10/11/12, install all the ticked files*, when it says succeeded! in top left you can just close the installer.

*install the extra shader crt_royal-reshade by akgunter to try this new port of CRT Royal on its own or on top of my settings, turn on crt-royale.fx in reshade. it looks good but uses a lot of performance.

RESHADE PRESET, Updated Apr/25

https://drive.google.com/file/d/1OiYts_8r1J3BZmyIzAopg3_uqjvnASfe/view?usp=sharing

home key opens reshade if it installed correctly, select the mame preset above, plenty of tweaking is possible to get the look you prefer.

These settings depend on your monitor settings and the game defaults for brightness and contrast in many cases.
Now using the Delta 4x2.rgb mask in bgfx, seems to provide a nice looking subtle rgb pattern, easy to change in the slider settings in-game(TAB menu). Iv tried to keep the settings simple to maintain as much performance as possible.
