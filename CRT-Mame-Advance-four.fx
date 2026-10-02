/*
    ===========================================================================
    CRT-Mame-Advance.fx (v3.5 Master Edition)
    State-of-the-art CRT simulation engineered specifically for MAME64.
    Pre-configured with user-calibrated master defaults.

    Bake Summary:
    - Curvature: Enabled (Warp 0.100/0.100, CornerSize 0.000)
    - Beam Dynamics: MinBeam 2.00, MaxBeam 1.50, Sharpness 6.00, Gain 1.50
    - DPX: Enabled (Gain 1.00, Strength 0.20, Contrast 0.12, Colorfulness 1.00, Saturation 1.00)
    - Optics & Color: BlackLevel -0.015, BrightBoost 1.24, Gamma 2.40/2.40
    - Blur: Symmetric 5-Tap Gaussian at 2.00 width
    - Mask: Slot Mask (Type 2) at 0.30 strength, 0.20 bloom
    - Performance: Fast-path single-fetch deconvergence optimization applied
    ===========================================================================
*/

#include "ReShade.fxh"

#ifndef BUFFER_PIXEL_SIZE
#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#endif

#ifndef BUFFER_SCREEN_SIZE
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#endif

// =========================================================================
// Feature switches (compile-time, 0 = removed completely)
// =========================================================================

#ifndef CRT_FX_HALATION
#define CRT_FX_HALATION 0
#endif
#ifndef CRT_FX_WIDE_GLOW
#define CRT_FX_WIDE_GLOW 0
#endif
#ifndef CRT_FX_PERSISTENCE
#define CRT_FX_PERSISTENCE 0
#endif
#ifndef CRT_FX_INTERLACE
#define CRT_FX_INTERLACE 0
#endif
#ifndef CRT_FX_COMPOSITE
#define CRT_FX_COMPOSITE 0
#endif
#ifndef CRT_FX_AUTO_MASK_COMP
#define CRT_FX_AUTO_MASK_COMP 0
#endif
#ifndef CRT_FX_VIGNETTE
#define CRT_FX_VIGNETTE 0
#endif
#ifndef CRT_FX_GLASS_GLOSS
#define CRT_FX_GLASS_GLOSS 0
#endif
#ifndef CRT_FX_DITHER
#define CRT_FX_DITHER 0
#endif

#if CRT_FX_INTERLACE || CRT_FX_COMPOSITE
uniform int framecount < source = "framecount"; >;
#endif

// =========================================================================
// UI Uniforms
// =========================================================================

// ===================== DPX FILMIC BRIGHTNESS & PUNCH =====================
uniform bool DPX_Enable <
    ui_label = "Enable DPX Filmic Punch";
    ui_tooltip = "Applies the authentic SweetFX DPX filmic curve: lifts midtones and enriches color without clipping whites.";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = true;

uniform float DPX_Gain <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 2.0;
    ui_step = 0.02;
    ui_label = "DPX Brightness Lift";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = 1.00;

uniform float DPX_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.02;
    ui_label = "DPX Effect Strength";
    ui_tooltip = "Blends the DPX filmic curve into the original image.";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = 0.20;

uniform float DPX_Contrast <
    ui_type = "drag";
    ui_min = -0.50;
    ui_max = 0.50;
    ui_step = 0.01;
    ui_label = "DPX Contrast";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = 0.12;

uniform float3 DPX_RGB_Curve <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 16.0;
    ui_step = 0.05;
    ui_label = "DPX RGB Curve (R / G / B)";
    ui_tooltip = "Steepness of the filmic S-curve.";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = float3(7.950, 8.000, 8.000);

uniform float3 DPX_RGB_C <
    ui_type = "drag";
    ui_min = 0.10;
    ui_max = 0.60;
    ui_step = 0.005;
    ui_label = "DPX RGB Center (R / G / B)";
    ui_tooltip = "Midtone pivot point.";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = float3(0.400, 0.355, 0.300);

uniform float DPX_Colorfulness <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 4.0;
    ui_step = 0.05;
    ui_label = "DPX Colorfulness";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = 1.00;

uniform float DPX_Saturation <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "DPX Saturation";
    ui_category = "=== DPX Filmic Brightness & Punch ===";
> = 1.00;

// ===================== CUSTOM ANALOG BLUR ENGINE =====================
uniform bool Blur_Enable <
    ui_label = "Enable Signal Blur / Bandwidth";
    ui_tooltip = "Toggle horizontal analog beam filtering on or off.";
    ui_category = "=== Custom Analog Blur Engine ===";
> = true;

uniform int Blur_Type <
    ui_type = "combo";
    ui_items = "Symmetric 5-Tap Gaussian\0Asymmetric Analog RC Bleed (JAMMA Cable)\0Flyback Focus Defocus (Dual-Axis)\0";
    ui_label = "Blur Type";
    ui_tooltip = "Choose between symmetric smoothing, asymmetric analog amplifier bleed (decay tail to the right), or flyback focus knob defocus.";
    ui_category = "=== Custom Analog Blur Engine ===";
> = 0;

uniform float Blur_Width <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 4.0;
    ui_step = 0.05;
    ui_label = "Blur Width / Defocus Amount";
    ui_tooltip = "Overall width of the beam blur.";
    ui_category = "=== Custom Analog Blur Engine ===";
> = 2.00;

uniform float RC_Bleed <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 3.0;
    ui_step = 0.05;
    ui_label = "RC Asymmetric Decay Tail";
    ui_tooltip = "Active when using 'Asymmetric Analog RC Bleed'. Simulates horizontal capacitor discharge.";
    ui_category = "=== Custom Analog Blur Engine ===";
> = 1.25;

// ===================== VIEWPORT & FRAMING =====================
uniform int UI_AspectMode <
    ui_type = "combo";
    ui_items = "Fullscreen / Handled by MAME\0Fit 4:3 Tube (Standard 16:9 Display)\0Fit 3:4 Tube (Vertical TATE on 16:9)\0Manual Padding\0";
    ui_label = "Arcade Tube Framing";
    ui_tooltip = "Locks the CRT curvature, corners, and scanlines to the active arcade cabinet screen without stretching your game.";
    ui_category = "=== Screen Framing & Viewport ===";
> = 0;

uniform float2 UI_ManualPad <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.40;
    ui_step = 0.005;
    ui_label = "Manual Pillarbox Padding (X / Y)";
    ui_category = "=== Screen Framing & Viewport ===";
> = float2(0.125, 0.000);

uniform bool C_TateMode <
    ui_label = "TATE Mode (Vertical Raster)";
    ui_tooltip = "Rotate electron gun raster sweep 90 degrees for vertically oriented shmups.";
    ui_category = "=== System & Architecture ===";
> = false;

uniform int C_LineMode <
    ui_type = "combo";
    ui_items = "CPS / Neo-Geo (224 Lines)\0Standard Arcade / NES (240 Lines)\0PC Engine / Midway (256 Lines)\0Sega Model 2/3 Medium-Res (384 Lines)\0Naomi / VGA (480 Lines)\0Custom / Manual\0";
    ui_label = "Arcade Raster Line Preset";
    ui_tooltip = "Must match the game's real vertical resolution (in TATE: horizontal), otherwise scanlines will beat against the source pixels.";
    ui_category = "=== System & Architecture ===";
> = 0;

uniform float C_CustomLines <
    ui_type = "drag";
    ui_min = 100.0;
    ui_max = 1200.0;
    ui_step = 1.0;
    ui_label = "Custom Line Count";
    ui_category = "=== System & Architecture ===";
> = 224.0;

uniform float C_ScanlineScale <
    ui_type = "drag";
    ui_min = 0.25;
    ui_max = 3.0;
    ui_step = 0.025;
    ui_label = "Scanline Density Multiplier";
    ui_category = "=== System & Architecture ===";
> = 1.0;

// ===================== ELECTRON BEAM DYNAMICS =====================
uniform float B_MinBeam <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 3.0;
    ui_step = 0.02;
    ui_label = "Dark Beam Thickness (Gap Size)";
    ui_tooltip = "Higher = thinner beam and wider black scanline gaps in shadows.";
    ui_category = "=== Electron Beam & Scanlines ===";
> = 2.00;

uniform float B_MaxBeam <
    ui_type = "drag";
    ui_min = 0.4;
    ui_max = 2.5;
    ui_step = 0.02;
    ui_label = "Bright Beam Dilation (Bloom)";
    ui_tooltip = "Lower = beam expands significantly on white highlights, closing the scanline gap.";
    ui_category = "=== Electron Beam & Scanlines ===";
> = 1.50;

uniform float B_Sharpness <
    ui_type = "drag";
    ui_min = 1.5;
    ui_max = 10.0;
    ui_step = 0.10;
    ui_label = "Beam Gaussian Sharpness";
    ui_tooltip = "Sharpness profile of the raster beam.";
    ui_category = "=== Electron Beam & Scanlines ===";
> = 6.00;

uniform float B_Gain <
    ui_type = "drag";
    ui_min = 0.8;
    ui_max = 3.0;
    ui_step = 0.02;
    ui_label = "Scanline Brightness Compensation";
    ui_tooltip = "Makes up for the light lost in the dark gaps between scanlines.";
    ui_category = "=== Electron Beam & Scanlines ===";
> = 1.50;

// ===================== PHOSPHOR MASK =====================
uniform int M_Type <
    ui_type = "combo";
    ui_items = "Off\0Aperture Grille (Sony Trinitron)\0Arcade Slot Mask (Nanao / Wells-Gardner)\0Shadow Mask (Dot Triad)\0";
    ui_label = "Phosphor Mask Type";
    ui_category = "=== Phosphor Mask ===";
> = 2;

uniform float M_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.025;
    ui_label = "Mask Strength";
    ui_category = "=== Phosphor Mask ===";
> = 0.30;

uniform float M_Bloom <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Highlight Mask Bloom (Fade)";
    ui_tooltip = "Fades the dark mask gaps under high electron saturation for authentic peak brightness.";
    ui_category = "=== Phosphor Mask ===";
> = 0.20;

uniform float M_Size <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 3.0;
    ui_step = 1.0;
    ui_label = "Mask Scale";
    ui_tooltip = "1.0 for 1080p/1440p; 2.0 for 4K.";
    ui_category = "=== Phosphor Mask ===";
> = 1.0;

uniform bool M_LayoutBGR <
    ui_label = "Subpixel Layout: BGR";
    ui_category = "=== Phosphor Mask ===";
> = false;

uniform float M_BrightBoost <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 2.0;
    ui_step = 0.02;
    ui_label = "Mask Brightness Compensation";
    ui_category = "=== Phosphor Mask ===";
> = 1.24;

#if CRT_FX_AUTO_MASK_COMP
uniform bool M_AutoComp_Enable <
    ui_label = "Enable Auto Mask Compensation";
    ui_category = "=== Phosphor Mask ===";
> = false;

uniform float M_AutoComp <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Auto Mask Compensation Amount";
    ui_tooltip = "Brightens the image by the exact average light the chosen mask removes.";
    ui_category = "=== Phosphor Mask ===";
> = 0.00;
#endif

// ===================== OPTICS & GLOW =====================
#if CRT_FX_HALATION
uniform float H_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.4;
    ui_step = 0.01;
    ui_label = "Glass Halation Strength";
    ui_category = "=== Halation & Optics ===";
> = 0.00;

uniform float H_Radius <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 8.0;
    ui_step = 0.25;
    ui_label = "Halation Radius (px at 1080p)";
    ui_category = "=== Halation & Optics ===";
> = 2.0;
#endif

#if CRT_FX_WIDE_GLOW
uniform float GL_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.6;
    ui_step = 0.01;
    ui_label = "Wide Glow Strength";
    ui_category = "=== Wide Glow ===";
> = 0.08;

uniform float GL_Radius <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 3.0;
    ui_step = 0.1;
    ui_label = "Wide Glow Radius";
    ui_category = "=== Wide Glow ===";
> = 1.00;

uniform float GL_Threshold <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Wide Glow Threshold";
    ui_category = "=== Wide Glow ===";
> = 0.20;
#endif

uniform float COL_BlackLevel <
    ui_type = "drag";
    ui_min = -0.05;
    ui_max = 0.05;
    ui_step = 0.001;
    ui_label = "Black Level Offset (output space)";
    ui_tooltip = "Adjust black floor.";
    ui_category = "=== Halation & Optics ===";
> = -0.015;

#if CRT_FX_PERSISTENCE
uniform float3 P_Decay <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.95;
    ui_step = 0.01;
    ui_label = "Persistence Decay (R / G / B)";
    ui_category = "=== Phosphor Persistence ===";
> = float3(0.30, 0.35, 0.25);
#endif

// ===================== INTERLACE & COMPOSITE =====================
#if CRT_FX_INTERLACE
uniform int I_Mode <
    ui_type = "combo";
    ui_items = "Interlaced Fields (alternate lines each frame)\0Line Jitter (half-line shift each frame)\0";
    ui_label = "Interlace Mode";
    ui_category = "=== Interlace / Flicker ===";
> = 0;

uniform float I_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Inactive Field Dimming (Fields mode)";
    ui_tooltip = "How much the lines belonging to the other field are dimmed. 1.0 = hard flicker.";
    ui_category = "=== Interlace / Flicker ===";
> = 0.50;
#endif

#if CRT_FX_COMPOSITE
uniform float CMP_ChromaBlur <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 8.0;
    ui_step = 0.1;
    ui_label = "Chroma Bleed (output pixels)";
    ui_category = "=== Composite Video ===";
> = 1.90;

uniform float CMP_Artifacts <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.5;
    ui_step = 0.01;
    ui_label = "Dot Crawl / Colour Artifacts";
    ui_category = "=== Composite Video ===";
> = 0.10;

uniform float CMP_Resolution <
    ui_type = "drag";
    ui_min = 128.0;
    ui_max = 1024.0;
    ui_step = 1.0;
    ui_label = "Source Pixel Clock (pixels across the scan line)";
    ui_category = "=== Composite Video ===";
> = 256.0;

uniform bool CMP_Crawl <
    ui_label = "Animate Dot Crawl";
    ui_category = "=== Composite Video ===";
> = true;
#endif

// ===================== CONVERGENCE & CURVATURE =====================
uniform float2 D_StaticShift <
    ui_type = "drag";
    ui_min = -2.0;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "Static Misalignment (X / Y pixels)";
    ui_category = "=== Convergence Imperfections ===";
> = float2(0.00, 0.00);

uniform float D_RadialYoke <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "Deflection Yoke Corner Fringe";
    ui_category = "=== Convergence Imperfections ===";
> = 0.00;

uniform bool G_EnableCurvature <
    ui_label = "Enable Tube Curvature";
    ui_category = "=== Tube Geometry & Curvature ===";
> = true;

uniform float2 G_Warp <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.25;
    ui_step = 0.002;
    ui_label = "Curvature Amount (X / Y)";
    ui_category = "=== Tube Geometry & Curvature ===";
> = float2(0.100, 0.100);

uniform float G_CornerSize <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.05;
    ui_step = 0.002;
    ui_label = "Corner Bezel Curvature";
    ui_category = "=== Tube Geometry & Curvature ===";
> = 0.000;

// ===================== GLASS, VIGNETTE & COLOR =====================
#if CRT_FX_VIGNETTE
uniform bool V_Enable <
    ui_label = "Enable Vignette";
    ui_category = "=== Vignette & Glass ===";
> = false;

uniform float V_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.02;
    ui_label = "Vignette Strength";
    ui_category = "=== Vignette & Glass ===";
> = 0.30;

uniform float V_Power <
    ui_type = "drag";
    ui_min = 0.1;
    ui_max = 1.0;
    ui_step = 0.02;
    ui_label = "Vignette Falloff";
    ui_category = "=== Vignette & Glass ===";
> = 0.35;
#endif

#if CRT_FX_GLASS_GLOSS
uniform bool GS_Enable <
    ui_label = "Enable Glass Gloss";
    ui_category = "=== Vignette & Glass ===";
> = false;

uniform float GS_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.3;
    ui_step = 0.005;
    ui_label = "Glass Gloss Strength";
    ui_category = "=== Vignette & Glass ===";
> = 0.04;

uniform float2 GS_Position <
    ui_type = "drag";
    ui_min = -0.5;
    ui_max = 1.5;
    ui_step = 0.01;
    ui_label = "Reflection Position (X / Y)";
    ui_category = "=== Vignette & Glass ===";
> = float2(0.28, 0.18);

uniform float GS_Size <
    ui_type = "drag";
    ui_min = 0.05;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Reflection Size";
    ui_category = "=== Vignette & Glass ===";
> = 0.35;
#endif

uniform bool COL_P22Gamut <
    ui_label = "Simulate P22 Phosphor Colour Mixing";
    ui_category = "=== Color & Gamma Calibration ===";
> = false;

uniform float COL_InputGamma <
    ui_type = "drag";
    ui_min = 1.8;
    ui_max = 3.0;
    ui_step = 0.05;
    ui_label = "Arcade Input Gamma";
    ui_category = "=== Color & Gamma Calibration ===";
> = 2.40;

uniform float COL_OutputGamma <
    ui_type = "drag";
    ui_min = 1.8;
    ui_max = 2.6;
    ui_step = 0.05;
    ui_label = "Monitor Output Gamma";
    ui_category = "=== Color & Gamma Calibration ===";
> = 2.40;

uniform float COL_Saturation <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 1.5;
    ui_step = 0.02;
    ui_label = "Color Saturation";
    ui_category = "=== Color & Gamma Calibration ===";
> = 1.00;

#if CRT_FX_DITHER
uniform bool DT_Enable <
    ui_label = "Enable Output Dithering";
    ui_category = "=== Dithering ===";
> = false;

uniform float DT_Bits <
    ui_type = "drag";
    ui_min = 6.0;
    ui_max = 12.0;
    ui_step = 1.0;
    ui_label = "Dither Target Bit Depth";
    ui_category = "=== Dithering ===";
> = 8.0;
#endif

// =========================================================================
// Render Targets & Textures
// =========================================================================

texture TexLinear { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerLinear { Texture = TexLinear; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexSignal { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerSignal { Texture = TexSignal; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

#if CRT_FX_PERSISTENCE
texture TexPersistPrev { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerPersistPrev { Texture = TexPersistPrev; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexPersistCur { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerPersistCur { Texture = TexPersistCur; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

#define CRT_SIGNAL_SAMPLER SamplerPersistCur
#else
#define CRT_SIGNAL_SAMPLER SamplerSignal
#endif

#if CRT_FX_HALATION
texture TexHalationH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerHalationH { Texture = TexHalationH; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexHalationV { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerHalationV { Texture = TexHalationV; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };
#endif

#if CRT_FX_WIDE_GLOW
texture TexGlowA { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16F; };
sampler SamplerGlowA { Texture = TexGlowA; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexGlowB { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16F; };
sampler SamplerGlowB { Texture = TexGlowB; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };
#endif

// =========================================================================
// Helper Functions
// =========================================================================

float GetTargetLines()
{
    float lines = 240.0;
    if (C_LineMode == 0) lines = 224.0;
    else if (C_LineMode == 1) lines = 240.0;
    else if (C_LineMode == 2) lines = 256.0;
    else if (C_LineMode == 3) lines = 384.0;
    else if (C_LineMode == 4) lines = 480.0;
    else lines = C_CustomLines;

    return lines * max(C_ScanlineScale, 0.1);
}

float2 GetPillarboxPadding()
{
    if (UI_AspectMode == 0) return float2(0.0, 0.0);

    float screenAspect = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
    float targetAspect = 4.0 / 3.0;

    if (UI_AspectMode == 1 || UI_AspectMode == 2)
    {
        if (UI_AspectMode == 2) targetAspect = 3.0 / 4.0;

        if (screenAspect > targetAspect)
            return float2((1.0 - targetAspect / screenAspect) * 0.5, 0.0);
        else
            return float2(0.0, (1.0 - screenAspect / targetAspect) * 0.5);
    }

    return min(UI_ManualPad, float2(0.45, 0.45));
}

float2 WarpCoords(float2 uv)
{
    if (!G_EnableCurvature) return uv;

    uv = uv * 2.0 - 1.0;
    float2 offset = abs(uv.yx) * G_Warp;
    uv = uv + uv * offset * offset;
    return uv * 0.5 + 0.5;
}

float CornerMask(float2 uv)
{
    if (!G_EnableCurvature) return 1.0;

    float r = max(G_CornerSize, 0.001);
    float2 d = abs(uv - 0.5) - 0.5 + r;
    float corner = length(max(d, 0.0)) - r;
    return 1.0 - smoothstep(0.0, 0.002, corner);
}

float BeamWeight(float d, float3 c)
{
    float l = max(max(c.r, c.g), c.b);
    float bw = lerp(B_MinBeam, B_MaxBeam, pow(l, 0.70));
    float g = exp(-B_Sharpness * d * d * bw * bw);
    
    return max(g, 0.18 * exp(-2.0 * d * d));
}

float W5(int i)
{
    int a = abs(i);
    return (a == 0) ? 0.375 : ((a == 1) ? 0.25 : 0.0625);
}

#if CRT_FX_HALATION
float3 HaloGate(float3 c)
{
    float l = max(max(c.r, c.g), c.b);
    return c * smoothstep(0.12, 0.65, l);
}
#endif

#if CRT_FX_WIDE_GLOW
float3 GlowGate(float3 c)
{
    float l = max(max(c.r, c.g), c.b);
    return c * smoothstep(GL_Threshold, GL_Threshold + 0.35, l);
}
#endif

#if CRT_FX_COMPOSITE
float3 ToGamma(float3 c)   { return pow(max(c, 0.0), 1.0 / COL_InputGamma); }
float3 FromGamma(float3 c) { return pow(max(c, 0.0), COL_InputGamma); }

float3 RGBtoYIQ(float3 c)
{
    return float3(dot(c, float3(0.299,  0.587,  0.114)),
                  dot(c, float3(0.596, -0.274, -0.322)),
                  dot(c, float3(0.211, -0.523,  0.312)));
}

float3 YIQtoRGB(float3 q)
{
    return float3(q.x + 0.956 * q.y + 0.621 * q.z,
                  q.x - 0.272 * q.y - 0.647 * q.z,
                  q.x - 1.106 * q.y + 1.703 * q.z);
}
#endif

#if CRT_FX_AUTO_MASK_COMP
float MaskCompensation()
{
    float s = M_Strength;
    float avg = 1.0;
    if (M_Type == 1)      avg = (3.0 - 2.0 * s) / 3.0;
    else if (M_Type == 2) avg = ((3.0 - 2.0 * s) / 3.0) * (1.0 - 0.1875 * s);
    else if (M_Type == 3) avg = (9.0 - 7.0 * s) / 9.0;

    return lerp(1.0, 1.0 / max(avg, 0.05), M_AutoComp);
}
#endif

#if CRT_FX_DITHER
float InterleavedGradient(float2 p)
{
    return frac(52.9829189 * frac(dot(p, float2(0.06711056, 0.00583715))));
}
#endif

// =========================================================================
// Pixel Shaders
// =========================================================================

// Pass 1: Linearization, DPX Filmic S-Curve & P22 Gamut
float4 PS_Linearize(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 color = tex2D(ReShade::BackBuffer, uv).rgb;

    // Authentic SweetFX DPX Sigmoidal Filmic Curve
    if (DPX_Enable)
    {
        float3 dpx = color * DPX_Gain;
        dpx = (dpx - DPX_RGB_C) * (1.0 + DPX_Contrast) + DPX_RGB_C;
        dpx = 1.0 / (1.0 + exp(-DPX_RGB_Curve * (dpx - DPX_RGB_C)));

        float dpxLuma = dot(dpx, float3(0.299, 0.587, 0.114));
        dpx = max(lerp(dpxLuma.xxx, dpx, DPX_Colorfulness * DPX_Saturation), 0.0);

        color = lerp(color, dpx, DPX_Strength);
    }

    color = pow(max(color, 0.0), COL_InputGamma);

    if (COL_P22Gamut)
    {
        const float3x3 P22Matrix = float3x3(
            0.920, 0.055, 0.025,
            0.030, 0.940, 0.030,
            0.015, 0.065, 0.920
        );
        color = mul(P22Matrix, color);
    }

    float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
    color = max(lerp(luma.xxx, color, COL_Saturation), 0.0);

    return float4(color, 1.0);
}

// Pass 2: Custom Analog Blur Engine (Symmetric, Asymmetric RC Bleed, Focus Defocus)
float4 PS_SignalBlur(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
#if CRT_FX_COMPOSITE
    float2 pad = GetPillarboxPadding();
    float2 activeSize = 1.0 - 2.0 * pad;

    if (uv.x < pad.x || uv.x > (1.0 - pad.x) || uv.y < pad.y || uv.y > (1.0 - pad.y))
        return float4(0.0, 0.0, 0.0, 1.0);

    float2 localUV = (uv - pad) / activeSize;

    float2 axis = C_TateMode ? float2(0.0, 1.0) : float2(1.0, 0.0);
    float2 texel = axis * (C_TateMode ? BUFFER_RCP_HEIGHT : BUFFER_RCP_WIDTH);
    float chromaStep = max(CMP_ChromaBlur, Blur_Width);

    float yLuma = 0.0;
    float2 iq = float2(0.0, 0.0);

    [unroll]
    for (int i = -2; i <= 2; i++)
    {
        float wt = W5(i);
        float fi = (float)i;
        yLuma += RGBtoYIQ(ToGamma(tex2D(SamplerLinear, uv + texel * (fi * Blur_Width)).rgb)).x * wt;
        iq    += RGBtoYIQ(ToGamma(tex2D(SamplerLinear, uv + texel * (fi * chromaStep)).rgb)).yz * wt;
    }

    float2 edgeOff = (axis * activeSize) / CMP_Resolution;
    float yA = RGBtoYIQ(ToGamma(tex2D(SamplerLinear, uv + edgeOff).rgb)).x;
    float yB = RGBtoYIQ(ToGamma(tex2D(SamplerLinear, uv - edgeOff).rgb)).x;
    float edge = abs(yA - yB);

    float scanCoord = C_TateMode ? localUV.y : localUV.x;
    float lineCoord = C_TateMode ? localUV.x : localUV.y;
    float srcPx   = floor(scanCoord * CMP_Resolution);
    float lineIdx = floor(lineCoord * GetTargetLines());
    float crawl   = CMP_Crawl ? (float)(framecount % 2) : 0.0;

    float phase = (srcPx * 0.5 + lineIdx + crawl) * 3.14159265;
    iq += CMP_Artifacts * edge * float2(cos(phase), sin(phase));

    float3 rgb = YIQtoRGB(float3(yLuma, iq.x, iq.y));
    return float4(FromGamma(rgb), 1.0);
#else
    if (!Blur_Enable)
    {
        return tex2D(SamplerLinear, uv);
    }

    float2 axis = (C_TateMode ? float2(0.0, BUFFER_RCP_HEIGHT) : float2(BUFFER_RCP_WIDTH, 0.0)) * Blur_Width;

    if (Blur_Type == 1) // Asymmetric Analog RC Bleed
    {
        float3 c = tex2D(SamplerLinear, uv - axis).rgb * 0.15;
        c += tex2D(SamplerLinear, uv).rgb * 0.38;
        c += tex2D(SamplerLinear, uv + axis * (1.0 * RC_Bleed)).rgb * 0.24;
        c += tex2D(SamplerLinear, uv + axis * (2.0 * RC_Bleed)).rgb * 0.15;
        c += tex2D(SamplerLinear, uv + axis * (3.0 * RC_Bleed)).rgb * 0.08;
        return float4(c, 1.0);
    }
    else if (Blur_Type == 2) // Flyback Focus Defocus (Dual-Axis)
    {
        float2 stepY = (C_TateMode ? float2(BUFFER_RCP_WIDTH, 0.0) : float2(0.0, BUFFER_RCP_HEIGHT)) * Blur_Width * 0.40;
        float3 c = tex2D(SamplerLinear, uv).rgb * 0.36;
        c += (tex2D(SamplerLinear, uv + axis).rgb + tex2D(SamplerLinear, uv - axis).rgb) * 0.22;
        c += (tex2D(SamplerLinear, uv + axis * 2.0).rgb + tex2D(SamplerLinear, uv - axis * 2.0).rgb) * 0.06;
        c += (tex2D(SamplerLinear, uv + stepY).rgb + tex2D(SamplerLinear, uv - stepY).rgb) * 0.04;
        return float4(c, 1.0);
    }
    else // Symmetric 5-Tap Gaussian
    {
        float3 c = tex2D(SamplerLinear, uv).rgb * 0.375;
        c += (tex2D(SamplerLinear, uv + axis).rgb       + tex2D(SamplerLinear, uv - axis).rgb)       * 0.25;
        c += (tex2D(SamplerLinear, uv + axis * 2.0).rgb + tex2D(SamplerLinear, uv - axis * 2.0).rgb) * 0.0625;
        return float4(c, 1.0);
    }
#endif
}

#if CRT_FX_PERSISTENCE
float4 PS_PersistUpdate(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 cur  = tex2D(SamplerSignal, uv).rgb;
    float3 prev = tex2D(SamplerPersistPrev, uv).rgb;
    return float4(max(cur, prev * P_Decay), 1.0);
}

float4 PS_PersistCopy(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(SamplerPersistCur, uv);
}
#endif

#if CRT_FX_HALATION
float4 PS_Halation_H(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 stepVec = float2(BUFFER_RCP_WIDTH * H_Radius * (BUFFER_HEIGHT / 1080.0), 0.0);

    float3 result = HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv).rgb) * 0.227027;
    result += (HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv + stepVec * 1.0).rgb) + HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv - stepVec * 1.0).rgb)) * 0.1945946;
    result += (HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv + stepVec * 2.0).rgb) + HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv - stepVec * 2.0).rgb)) * 0.1216216;
    result += (HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv + stepVec * 3.0).rgb) + HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv - stepVec * 3.0).rgb)) * 0.0540540;
    result += (HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv + stepVec * 4.0).rgb) + HaloGate(tex2D(CRT_SIGNAL_SAMPLER, uv - stepVec * 4.0).rgb)) * 0.0162160;

    return float4(result, 1.0);
}

float4 PS_Halation_V(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 stepVec = float2(0.0, BUFFER_RCP_HEIGHT * H_Radius * (BUFFER_HEIGHT / 1080.0));

    float3 result = tex2D(SamplerHalationH, uv).rgb * 0.227027;
    result += (tex2D(SamplerHalationH, uv + stepVec * 1.0).rgb + tex2D(SamplerHalationH, uv - stepVec * 1.0).rgb) * 0.1945946;
    result += (tex2D(SamplerHalationH, uv + stepVec * 2.0).rgb + tex2D(SamplerHalationH, uv - stepVec * 2.0).rgb) * 0.1216216;
    result += (tex2D(SamplerHalationH, uv + stepVec * 3.0).rgb + tex2D(SamplerHalationH, uv - stepVec * 3.0).rgb) * 0.0540540;
    result += (tex2D(SamplerHalationH, uv + stepVec * 4.0).rgb + tex2D(SamplerHalationH, uv - stepVec * 4.0).rgb) * 0.0162160;

    return float4(result, 1.0);
}
#endif

#if CRT_FX_WIDE_GLOW
float4 PS_GlowDown(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 sum = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int ix = 0; ix < 4; ix++)
    {
        [unroll]
        for (int iy = 0; iy < 4; iy++)
        {
            float2 o = (float2((float)ix, (float)iy) - 1.5) * 2.0 * BUFFER_PIXEL_SIZE;
            sum += GlowGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv + o, 0.0, 0.0)).rgb);
        }
    }

    return float4(sum / 16.0, 1.0);
}

float4 PS_GlowH(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 stepVec = float2(BUFFER_RCP_WIDTH * 8.0 * GL_Radius * (BUFFER_HEIGHT / 1080.0), 0.0);

    float3 result = tex2D(SamplerGlowA, uv).rgb * 0.227027;
    result += (tex2D(SamplerGlowA, uv + stepVec * 1.0).rgb + tex2D(SamplerGlowA, uv - stepVec * 1.0).rgb) * 0.1945946;
    result += (tex2D(SamplerGlowA, uv + stepVec * 2.0).rgb + tex2D(SamplerGlowA, uv - stepVec * 2.0).rgb) * 0.1216216;
    result += (tex2D(SamplerGlowA, uv + stepVec * 3.0).rgb + tex2D(SamplerGlowA, uv - stepVec * 3.0).rgb) * 0.0540540;
    result += (tex2D(SamplerGlowA, uv + stepVec * 4.0).rgb + tex2D(SamplerGlowA, uv - stepVec * 4.0).rgb) * 0.0162160;

    return float4(result, 1.0);
}

float4 PS_GlowV(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 stepVec = float2(0.0, BUFFER_RCP_HEIGHT * 8.0 * GL_Radius * (BUFFER_HEIGHT / 1080.0));

    float3 result = tex2D(SamplerGlowB, uv).rgb * 0.227027;
    result += (tex2D(SamplerGlowB, uv + stepVec * 1.0).rgb + tex2D(SamplerGlowB, uv - stepVec * 1.0).rgb) * 0.1945946;
    result += (tex2D(SamplerGlowB, uv + stepVec * 2.0).rgb + tex2D(SamplerGlowB, uv - stepVec * 2.0).rgb) * 0.1216216;
    result += (tex2D(SamplerGlowB, uv + stepVec * 3.0).rgb + tex2D(SamplerGlowB, uv - stepVec * 3.0).rgb) * 0.0540540;
    result += (tex2D(SamplerGlowB, uv + stepVec * 4.0).rgb + tex2D(SamplerGlowB, uv - stepVec * 4.0).rgb) * 0.0162160;

    return float4(result, 1.0);
}
#endif

// Pass 4: Rasterizer & Compositor
float4 PS_Raster_Composite(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pad = GetPillarboxPadding();
    float2 activeSize = 1.0 - 2.0 * pad;

    if (uv.x < pad.x || uv.x > (1.0 - pad.x) || uv.y < pad.y || uv.y > (1.0 - pad.y))
        return float4(0.0, 0.0, 0.0, 1.0);

    float2 localUV = (uv - pad) / activeSize;
    float2 warpedLocalUV = WarpCoords(localUV);

    float maskClip = CornerMask(warpedLocalUV);
    if (maskClip <= 0.0)
        return float4(0.0, 0.0, 0.0, 1.0);

    float2 clampedWarpedUV = clamp(warpedLocalUV, 0.0005, 0.9995);

    // Deflection yoke deconvergence
    float2 centerDist = clampedWarpedUV - 0.5;
    float radialFactor = dot(centerDist, centerDist) * D_RadialYoke * 4.0;
    float2 shift = (D_StaticShift + centerDist * radialFactor) * BUFFER_PIXEL_SIZE;
    bool hasDecon = (dot(D_StaticShift, D_StaticShift) + D_RadialYoke > 0.00001);

    // Scanlines
    float targetLines = GetTargetLines();
    float rasterPos = C_TateMode ? (clampedWarpedUV.x * targetLines) : (clampedWarpedUV.y * targetLines);

#if CRT_FX_INTERLACE
    float fieldPhase = (float)(framecount % 2);
    if (I_Mode == 1) rasterPos += 0.5 * fieldPhase;
#endif

    float lineBase = floor(rasterPos);
    float dist = rasterPos - lineBase - 0.5;

    float3 color = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int k = -1; k <= 1; k++)
    {
        float centerLocal = (lineBase + (float)k + 0.5) / targetLines;
        centerLocal = clamp(centerLocal, 0.0005, 0.9995);

        float2 lineCenterLocalUV = C_TateMode 
            ? float2(centerLocal, clampedWarpedUV.y) 
            : float2(clampedWarpedUV.x, centerLocal);

        float2 sampleLineUV = pad + lineCenterLocalUV * activeSize;

        float3 c;
        // Fast-path: Skip redundant texture fetches if deconvergence is disabled
        if (hasDecon)
        {
            c.r = tex2Dlod(CRT_SIGNAL_SAMPLER, float4(sampleLineUV + shift, 0.0, 0.0)).r;
            c.g = tex2Dlod(CRT_SIGNAL_SAMPLER, float4(sampleLineUV,         0.0, 0.0)).g;
            c.b = tex2Dlod(CRT_SIGNAL_SAMPLER, float4(sampleLineUV - shift, 0.0, 0.0)).b;
        }
        else
        {
            c = tex2Dlod(CRT_SIGNAL_SAMPLER, float4(sampleLineUV, 0.0, 0.0)).rgb;
        }

        float beam = BeamWeight(dist - (float)k, c);

#if CRT_FX_INTERLACE
        if (I_Mode == 0)
        {
            float parity = fmod(lineBase + (float)k + fieldPhase + 2.0, 2.0);
            beam *= lerp(1.0, 1.0 - I_Strength, step(0.5, parity));
        }
#endif

        color += c * beam;
    }

    // Dynamic highlight gain
    float rawLuma = max(max(color.r, color.g), color.b);
    float dynamicGain = lerp(B_Gain, 1.0, pow(saturate(rawLuma), 1.5));
    color *= dynamicGain;

    // Phosphor mask
    float3 mask = float3(1.0, 1.0, 1.0);
    float2 screenCoord = uv * BUFFER_SCREEN_SIZE / max(M_Size, 1.0);

    if (C_TateMode) screenCoord = screenCoord.yx;

    int px = int(floor(screenCoord.x));
    int py = int(floor(screenCoord.y));

    if (M_Type == 1) // Aperture Grille
    {
        int x = px % 3;
        if (x == 0) mask = float3(1.0, 1.0 - M_Strength, 1.0 - M_Strength);
        else if (x == 1) mask = float3(1.0 - M_Strength, 1.0, 1.0 - M_Strength);
        else mask = float3(1.0 - M_Strength, 1.0 - M_Strength, 1.0);
    }
    else if (M_Type == 2) // Arcade Slot Mask
    {
        int x = px % 3;
        int y = py % 4;

        float3 triad = (1.0 - M_Strength).xxx;
        if (x == 0) triad.r = 1.0;
        else if (x == 1) triad.g = 1.0;
        else triad.b = 1.0;

        float slot = 1.0;
        int x6 = px % 6;
        if ((x6 < 3 && y == 0) || (x6 >= 3 && y == 2))
            slot = 1.0 - M_Strength * 0.75;

        mask = triad * slot;
    }
    else if (M_Type == 3) // Shadow Mask Dot Triad
    {
        int x = px % 3;
        int rowShift = (int(floor(screenCoord.x / 3.0)) % 2) * 2;
        int y = (py + rowShift) % 3;

        mask = (1.0 - M_Strength).xxx;
        if (x == 0 && y != 0) mask.r = 1.0;
        else if (x == 1 && y != 1) mask.g = 1.0;
        else if (x == 2 && y != 2) mask.b = 1.0;
    }

    if (M_LayoutBGR) mask = mask.bgr;

    float luma = max(max(color.r, color.g), color.b);
    mask = lerp(mask, float3(1.0, 1.0, 1.0), pow(saturate(luma), 1.5) * M_Bloom);

    color *= mask * M_BrightBoost;

#if CRT_FX_AUTO_MASK_COMP
    if (M_AutoComp_Enable)
        color *= MaskCompensation();
#endif

    float2 sampleUV = pad + clampedWarpedUV * activeSize;

#if CRT_FX_HALATION
    if (H_Strength > 0.0)
        color += tex2Dlod(SamplerHalationV, float4(sampleUV, 0.0, 0.0)).rgb * H_Strength;
#endif

#if CRT_FX_WIDE_GLOW
    color += tex2Dlod(SamplerGlowA, float4(sampleUV, 0.0, 0.0)).rgb * GL_Strength;
#endif

#if CRT_FX_VIGNETTE
    if (V_Enable)
    {
        float2 q = saturate(clampedWarpedUV);
        float vig = pow(max(16.0 * q.x * (1.0 - q.x) * q.y * (1.0 - q.y), 0.0001), V_Power);
        color *= lerp(1.0, vig, V_Strength);
    }
#endif

    color = pow(max(color, 0.0), 1.0 / COL_OutputGamma);
    color = max(color + COL_BlackLevel.xxx, 0.0);

#if CRT_FX_GLASS_GLOSS
    if (GS_Enable)
    {
        float tubeAspect = (BUFFER_WIDTH * activeSize.x) / (BUFFER_HEIGHT * activeSize.y);
        float2 gd = (clampedWarpedUV - GS_Position) * float2(tubeAspect, 1.0);
        float gloss = exp(-dot(gd, gd) / (GS_Size * GS_Size));
        color += gloss * GS_Strength;
    }
#endif

#if CRT_FX_DITHER
    if (DT_Enable)
    {
        float dm = saturate(max(color.r, max(color.g, color.b)) * 64.0);
        float n = InterleavedGradient(pos.xy) + InterleavedGradient(pos.xy + float2(5.588238, 5.588238)) - 1.0;
        color += n * dm / (exp2(DT_Bits) - 1.0);
    }
#endif

    color *= maskClip;

    return float4(color, 1.0);
}

// =========================================================================
// Technique Definition
// =========================================================================

technique CRT_Mame_Advance
{
    pass Linearize
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Linearize;
        RenderTarget = TexLinear;
    }
    pass SignalBlur
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SignalBlur;
        RenderTarget = TexSignal;
    }
#if CRT_FX_PERSISTENCE
    pass PersistUpdate
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PersistUpdate;
        RenderTarget = TexPersistCur;
    }
    pass PersistCopy
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PersistCopy;
        RenderTarget = TexPersistPrev;
    }
#endif
#if CRT_FX_HALATION
    pass Halation_Horizontal
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Halation_H;
        RenderTarget = TexHalationH;
    }
    pass Halation_Vertical
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Halation_V;
        RenderTarget = TexHalationV;
    }
#endif
#if CRT_FX_WIDE_GLOW
    pass GlowDown
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_GlowDown;
        RenderTarget = TexGlowA;
    }
    pass GlowBlurH
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_GlowH;
        RenderTarget = TexGlowB;
    }
    pass GlowBlurV
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_GlowV;
        RenderTarget = TexGlowA;
    }
#endif
    pass Raster_Composite
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Raster_Composite;
    }
}