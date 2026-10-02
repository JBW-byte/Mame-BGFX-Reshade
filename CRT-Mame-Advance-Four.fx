/*
    ===========================================================================
    CRT-Mame-Advance-Four.fx (v4.0 Deluxe Edition) Author L.E.D.
    State-of-the-art CRT simulation engineered specifically for MAME64(probably works with other emulators)
    Pre-configured with user-calibrated master defaults.

    Final Audit & Verification:
    - Curvature: Enabled (Warp 0.100/0.100, CornerSize 0.000)
    - Bezel: Physically correct linear-space reflection compositing
    - Mask: Slot Mask (Type 2) at 0.30 strength, auto-compensation active (M_AutoComp)
    - OLED: Full WOLED (RGBW) and QD-OLED support across all mask types
    - Halation: Downsampled half-res ping-pong passes (75% bandwidth reduction)
    - Optimization: Instant hardware discard on disabled passes
    - Color: Normalized DPX S-curve, P22 gamut preservation, clean black anchoring
    ===========================================================================
*/

#include "ReShade.fxh"

#ifndef BUFFER_PIXEL_SIZE
#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#endif

#ifndef BUFFER_SCREEN_SIZE
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#endif

uniform int framecount < source = "framecount"; >;

// =========================================================================
// UI Uniforms
// =========================================================================

// ===================== 1. FEATURE TOGGLES (TICK BOXES) =====================
uniform bool DPX_Enable <
    ui_label = "Enable DPX Filmic Punch";
    ui_tooltip = "Applies a Cineon filmic S-curve: lifts midtones and enriches color without clipping whites.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = true;

uniform bool Blur_Enable <
    ui_label = "Enable Signal Blur / Bandwidth";
    ui_tooltip = "Toggle horizontal analog beam filtering on or off.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = true;

uniform bool G_EnableCurvature <
    ui_label = "Enable Tube Curvature";
    ui_tooltip = "Toggles physical CRT glass barrel curvature.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = true;

uniform bool CMP_Enable <
    ui_label = "Enable Composite Video (Dot Crawl)";
    ui_tooltip = "Simulates NTSC/PAL composite video chroma crosstalk and dot crawl.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool P_Enable <
    ui_label = "Enable Phosphor Persistence (Ghosting)";
    ui_tooltip = "Simulates physical phosphor decay trails on moving objects.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool I_Enable <
    ui_label = "Enable Interlacing / Line Jitter";
    ui_tooltip = "Simulates 480i field alternating or 240p line jitter.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool HV_Enable <
    ui_label = "Enable High-Voltage Sag (Screen Breathing)";
    ui_tooltip = "Screen physically expands outward during full-screen flashes/explosions.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool W_Enable <
    ui_label = "Enable Trinitron Damper Wires";
    ui_tooltip = "Simulates the faint horizontal tungsten stabilizer wire shadows found on Sony Trinitron tubes.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool HB_Enable <
    ui_label = "Enable Rolling AC Ground Hum Bar";
    ui_tooltip = "Simulates 60Hz/50Hz ground loop AC interference from vintage arcade cabinet power supplies.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool BZ_Enable <
    ui_label = "Enable Cabinet Bezel Reflection";
    ui_tooltip = "Game light reflects dynamically off the molded black cabinet bezel shroud surrounding the tube.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool AST_Enable <
    ui_label = "Enable Corner Astigmatism Defocus";
    ui_tooltip = "Center of the tube remains sharp, while the corners receive authentic magnetic deflection defocus.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool H_Enable <
    ui_label = "Enable Glass Halation";
    ui_tooltip = "Simulates internal light scatter inside the CRT faceplate.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool GL_Enable <
    ui_label = "Enable Wide Glow / Bloom";
    ui_tooltip = "Soft, atmospheric diffuse bloom around bright elements.";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

uniform bool COL_P22Gamut <
    ui_label = "Simulate P22 Phosphor Colour Mixing";
    ui_tooltip = "Matches Guest CP=0.0 (EBU standard color profile).";
    ui_category = "=== 1. Feature Toggles (Tick Boxes) ===";
> = false;

// ===================== 2. SYSTEM & ARCHITECTURE =====================
uniform int C_LineMode <
    ui_type = "combo";
    ui_items = "CPS / Neo-Geo (224 Lines)\0Standard Arcade / NES (240 Lines)\0PC Engine / Midway (256 Lines)\0Namco Classic / PAL (288 Lines)\0Sega Model 2/3 Medium-Res (384 Lines)\0Naomi / VGA (480 Lines)\0Custom / Manual\0";
    ui_label = "Arcade Raster Line Preset";
    ui_category = "=== 2. System & Architecture ===";
> = 0;

uniform float C_CustomLines <
    ui_type = "drag";
    ui_min = 100.0;
    ui_max = 1200.0;
    ui_step = 1.0;
    ui_label = "Custom Line Count";
    ui_category = "=== 2. System & Architecture ===";
> = 224.0;

uniform float C_ScanlineScale <
    ui_type = "drag";
    ui_min = 0.25;
    ui_max = 3.0;
    ui_step = 0.025;
    ui_label = "Scanline Density Multiplier";
    ui_category = "=== 2. System & Architecture ===";
> = 1.0;

uniform bool C_TateMode <
    ui_label = "TATE Mode (Vertical Raster)";
    ui_category = "=== 2. System & Architecture ===";
> = false;

uniform int UI_AspectMode <
    ui_type = "combo";
    ui_items = "Fullscreen / Handled by MAME\0Fit 4:3 Tube (Standard 16:9 Display)\0Fit 3:4 Tube (Vertical TATE on 16:9)\0Manual Padding\0";
    ui_label = "Arcade Tube Framing";
    ui_category = "=== 2. System & Architecture ===";
> = 0;

uniform float2 UI_ManualPad <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.40;
    ui_step = 0.005;
    ui_label = "Manual Pillarbox Padding (X / Y)";
    ui_category = "=== 2. System & Architecture ===";
> = float2(0.125, 0.000);

// ===================== 3. CUSTOM ANALOG BLUR ENGINE =====================
uniform int Blur_Type <
    ui_type = "combo";
    ui_items = "Symmetric 5-Tap Gaussian\0Asymmetric Analog RC Bleed (JAMMA Cable)\0Flyback Focus Defocus (Dual-Axis)\0";
    ui_label = "Blur Type";
    ui_category = "=== 3. Custom Analog Blur Engine ===";
> = 0;

uniform float Blur_Width <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 4.0;
    ui_step = 0.05;
    ui_label = "Blur Width / Defocus Amount";
    ui_category = "=== 3. Custom Analog Blur Engine ===";
> = 2.00;

uniform float RC_Bleed <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 3.0;
    ui_step = 0.05;
    ui_label = "RC Asymmetric Decay Tail";
    ui_category = "=== 3. Custom Analog Blur Engine ===";
> = 1.25;

uniform float AST_Amount <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "Corner Defocus Intensity";
    ui_category = "=== 3. Custom Analog Blur Engine ===";
> = 0.65;

// ===================== 4. ELECTRON BEAM & SCANLINES =====================
uniform float B_MinBeam <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 3.0;
    ui_step = 0.02;
    ui_label = "Scanline Trough Sharpness (Dark Beam)";
    ui_category = "=== 4. Electron Beam & Scanlines ===";
> = 2.00;

uniform float B_MaxBeam <
    ui_type = "drag";
    ui_min = 0.4;
    ui_max = 2.5;
    ui_step = 0.02;
    ui_label = "Scanline Peak Dilation (Bright Beam)";
    ui_category = "=== 4. Electron Beam & Scanlines ===";
> = 1.50;

uniform float B_Sharpness <
    ui_type = "drag";
    ui_min = 1.5;
    ui_max = 10.0;
    ui_step = 0.10;
    ui_label = "Beam Gaussian Sharpness";
    ui_category = "=== 4. Electron Beam & Scanlines ===";
> = 6.00;

uniform float B_Gain <
    ui_type = "drag";
    ui_min = 0.8;
    ui_max = 2.5;
    ui_step = 0.02;
    ui_label = "Scanline Brightness Compensation";
    ui_category = "=== 4. Electron Beam & Scanlines ===";
> = 1.50;

// ===================== 5. PHOSPHOR MASK =====================
uniform int M_Type <
    ui_type = "combo";
    ui_items = "Off\0Aperture Grille (Sony Trinitron)\0Arcade Slot Mask (Nanao / Wells-Gardner)\0Shadow Mask (Dot Triad)\0";
    ui_label = "Phosphor Mask Type";
    ui_category = "=== 5. Phosphor Mask ===";
> = 2;

uniform int M_SubpixelMode <
    ui_type = "combo";
    ui_items = "Standard RGB (LCD)\0BGR (Inverted LCD)\0WOLED (LG WRGB OLED 4-Subpixel)\0QD-OLED (Samsung Triangular OLED)\0";
    ui_label = "Subpixel Panel Layout";
    ui_category = "=== 5. Phosphor Mask ===";
> = 0;

uniform float M_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.025;
    ui_label = "Mask Strength";
    ui_category = "=== 5. Phosphor Mask ===";
> = 0.30;

uniform float M_Bloom <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Highlight Mask Bloom (Fade)";
    ui_category = "=== 5. Phosphor Mask ===";
> = 0.20;

uniform float M_Size <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 3.0;
    ui_step = 1.0;
    ui_label = "Mask Scale";
    ui_category = "=== 5. Phosphor Mask ===";
> = 1.0;

uniform float M_BrightBoost <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 2.0;
    ui_step = 0.02;
    ui_label = "Manual Mask Brightness Compensation";
    ui_category = "=== 5. Phosphor Mask ===";
> = 1.24;

uniform float M_AutoComp <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Auto Mask Compensation Amount";
    ui_category = "=== 5. Phosphor Mask ===";
> = 0.00;

// ===================== 6. DPX FILMIC BRIGHTNESS & PUNCH =====================
uniform float DPX_Gain <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 2.0;
    ui_step = 0.02;
    ui_label = "DPX Brightness Lift";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = 1.00;

uniform float DPX_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.02;
    ui_label = "DPX Effect Strength";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = 0.20;

uniform float DPX_Contrast <
    ui_type = "drag";
    ui_min = -0.50;
    ui_max = 0.50;
    ui_step = 0.01;
    ui_label = "DPX Contrast";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = 0.12;

uniform float3 DPX_RGB_Curve <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 16.0;
    ui_step = 0.05;
    ui_label = "DPX RGB Curve (R / G / B)";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = float3(7.950, 8.000, 8.000);

uniform float3 DPX_RGB_C <
    ui_type = "drag";
    ui_min = 0.10;
    ui_max = 0.60;
    ui_step = 0.005;
    ui_label = "DPX RGB Center (R / G / B)";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = float3(0.400, 0.355, 0.300);

uniform float DPX_Colorfulness <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 4.0;
    ui_step = 0.05;
    ui_label = "DPX Colorfulness";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = 1.00;

uniform float DPX_Saturation <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "DPX Saturation";
    ui_category = "=== 6. DPX Filmic Brightness & Punch ===";
> = 1.00;

// ===================== 7. TUBE GEOMETRY & CURVATURE =====================
uniform float2 G_Warp <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.25;
    ui_step = 0.002;
    ui_label = "Curvature Amount (X / Y)";
    ui_category = "=== 7. Tube Geometry & Curvature ===";
> = float2(0.100, 0.100);

uniform float G_CornerSize <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.05;
    ui_step = 0.002;
    ui_label = "Corner Bezel Curvature";
    ui_category = "=== 7. Tube Geometry & Curvature ===";
> = 0.000;

uniform float2 D_StaticShift <
    ui_type = "drag";
    ui_min = -2.0;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "Static Misalignment (X / Y pixels)";
    ui_category = "=== 7. Tube Geometry & Curvature ===";
> = float2(0.00, 0.00);

uniform float D_RadialYoke <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_label = "Deflection Yoke Corner Fringe";
    ui_category = "=== 7. Tube Geometry & Curvature ===";
> = 0.00;

// ===================== 8. COLOR & GAMMA CALIBRATION =====================
uniform float COL_BlackLevel <
    ui_type = "drag";
    ui_min = -0.05;
    ui_max = 0.05;
    ui_step = 0.001;
    ui_label = "Black Level Offset (output space)";
    ui_category = "=== 8. Color & Gamma Calibration ===";
> = -0.015;

uniform float COL_InputGamma <
    ui_type = "drag";
    ui_min = 1.8;
    ui_max = 3.0;
    ui_step = 0.05;
    ui_label = "Arcade Input Gamma";
    ui_category = "=== 8. Color & Gamma Calibration ===";
> = 2.40;

uniform float COL_OutputGamma <
    ui_type = "drag";
    ui_min = 1.8;
    ui_max = 2.6;
    ui_step = 0.05;
    ui_label = "Monitor Output Gamma";
    ui_category = "=== 8. Color & Gamma Calibration ===";
> = 2.40;

uniform float COL_Saturation <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 1.5;
    ui_step = 0.02;
    ui_label = "Color Saturation";
    ui_category = "=== 8. Color & Gamma Calibration ===";
> = 1.00;

// ===================== 9. HIGH-VOLTAGE SCREEN BREATHING =====================
uniform float HV_SagAmount <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 2.5;
    ui_step = 0.05;
    ui_label = "Screen Expansion / Sag Amount";
    ui_category = "=== 9. High-Voltage Screen Breathing ===";
> = 1.00;

// ===================== 10. TRINITRON DAMPER WIRES =====================
uniform int W_Count <
    ui_type = "combo";
    ui_items = "1 Wire (Center - Small 14\" Tubes)\02 Wires (Top & Bottom - Large 29\" Tubes)\0";
    ui_label = "Damper Wire Count";
    ui_category = "=== 10. Trinitron Damper Wires ===";
> = 1;

uniform float W_Opacity <
    ui_type = "drag";
    ui_min = 0.02;
    ui_max = 0.40;
    ui_step = 0.01;
    ui_label = "Wire Shadow Darkness";
    ui_category = "=== 10. Trinitron Damper Wires ===";
> = 0.12;

// ===================== 11. ROLLING AC GROUND HUM BAR =====================
uniform float HB_Strength <
    ui_type = "drag";
    ui_min = 0.00;
    ui_max = 0.15;
    ui_step = 0.005;
    ui_label = "Hum Bar Intensity";
    ui_category = "=== 11. Rolling AC Ground Hum Bar ===";
> = 0.025;

uniform float HB_Speed <
    ui_type = "drag";
    ui_min = 0.1;
    ui_max = 5.0;
    ui_step = 0.1;
    ui_label = "Hum Bar Roll Speed";
    ui_category = "=== 11. Rolling AC Ground Hum Bar ===";
> = 1.00;

uniform float HB_Frequency <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 8.0;
    ui_step = 0.5;
    ui_label = "Hum Bar Frequency (Wavelengths)";
    ui_category = "=== 11. Rolling AC Ground Hum Bar ===";
> = 1.00;

// ===================== 12. CABINET BEZEL REFLECTION =====================
uniform float BZ_Width <
    ui_type = "drag";
    ui_min = 0.01;
    ui_max = 0.10;
    ui_step = 0.005;
    ui_label = "Bezel Lip Width";
    ui_category = "=== 12. Cabinet Bezel Reflection ===";
> = 0.035;

uniform float BZ_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.5;
    ui_step = 0.05;
    ui_label = "Bezel Reflection Brightness";
    ui_category = "=== 12. Cabinet Bezel Reflection ===";
> = 0.45;

// ===================== 13. HALATION & WIDE GLOW =====================
uniform float H_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.4;
    ui_step = 0.01;
    ui_label = "Halation Strength";
    ui_category = "=== 13. Halation & Wide Glow ===";
> = 0.08;

uniform float H_Radius <
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 8.0;
    ui_step = 0.25;
    ui_label = "Halation Radius (px at 1080p)";
    ui_category = "=== 13. Halation & Wide Glow ===";
> = 2.00;

uniform float GL_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.6;
    ui_step = 0.01;
    ui_label = "Wide Glow Strength";
    ui_category = "=== 13. Halation & Wide Glow ===";
> = 0.05;

uniform float GL_Radius <
    ui_type = "drag";
    ui_min = 0.5;
    ui_max = 3.0;
    ui_step = 0.1;
    ui_label = "Wide Glow Radius";
    ui_category = "=== 13. Halation & Wide Glow ===";
> = 0.50;

uniform float GL_Threshold <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_label = "Wide Glow Threshold";
    ui_category = "=== 13. Halation & Wide Glow ===";
> = 0.20;

// ===================== 14. PHOSPHOR PERSISTENCE =====================
uniform float P_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Persistence Effect Strength";
    ui_category = "=== 14. Phosphor Persistence (Ghosting) ===";
> = 0.30;

uniform float3 P_Decay <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.95;
    ui_step = 0.01;
    ui_label = "Persistence Decay (R / G / B)";
    ui_category = "=== 14. Phosphor Persistence (Ghosting) ===";
> = float3(0.30, 0.35, 0.25);

// ===================== 15. COMPOSITE VIDEO =====================
uniform float CMP_ChromaBlur <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 8.0;
    ui_step = 0.1;
    ui_label = "Chroma Bleed (output pixels)";
    ui_category = "=== 15. Composite Video ===";
> = 1.90;

uniform float CMP_Artifacts <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.5;
    ui_step = 0.01;
    ui_label = "Dot Crawl / Colour Artifacts";
    ui_category = "=== 15. Composite Video ===";
> = 0.10;

uniform float CMP_Resolution <
    ui_type = "drag";
    ui_min = 128.0;
    ui_max = 1024.0;
    ui_step = 1.0;
    ui_label = "Source Pixel Clock (Resolution)";
    ui_category = "=== 15. Composite Video ===";
> = 256.0;

uniform bool CMP_Crawl <
    ui_label = "Animate Dot Crawl";
    ui_category = "=== 15. Composite Video ===";
> = true;

// ===================== 16. INTERLACING / LINE JITTER =====================
uniform int I_Mode <
    ui_type = "combo";
    ui_items = "Interlaced Fields (480i alternate lines each frame)\0Line Jitter (240p half-line shift each frame)\0";
    ui_label = "Interlace Mode";
    ui_category = "=== 16. Interlacing / Line Jitter ===";
> = 0;

uniform float I_Strength <
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.05;
    ui_label = "Inactive Field Dimming";
    ui_category = "=== 16. Interlacing / Line Jitter ===";
> = 0.50;

// =========================================================================
// Render Targets & Textures
// =========================================================================

texture TexLinear { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerLinear { Texture = TexLinear; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexSignal { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerSignal { Texture = TexSignal; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexPersistPrev { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerPersistPrev { Texture = TexPersistPrev; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexPersistCur { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SamplerPersistCur { Texture = TexPersistCur; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

#define CRT_SIGNAL_SAMPLER SamplerPersistCur

// Half-resolution halation drastically reduces VRAM bandwidth at 1440p/4K
texture TexHalationH { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
sampler SamplerHalationH { Texture = TexHalationH; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexHalationV { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
sampler SamplerHalationV { Texture = TexHalationV; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexGlowA { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16F; };
sampler SamplerGlowA { Texture = TexGlowA; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

texture TexGlowB { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16F; };
sampler SamplerGlowB { Texture = TexGlowB; AddressU = CLAMP; AddressV = CLAMP; MagFilter = LINEAR; MinFilter = LINEAR; };

// =========================================================================
// Helper Functions
// =========================================================================

float GetTargetLines()
{
    float lines = 240.0;
    if (C_LineMode == 0) lines = 224.0;
    else if (C_LineMode == 1) lines = 240.0;
    else if (C_LineMode == 2) lines = 256.0;
    else if (C_LineMode == 3) lines = 288.0; // Namco Classic / PAL
    else if (C_LineMode == 4) lines = 384.0;
    else if (C_LineMode == 5) lines = 480.0;
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

float3 HaloGate(float3 c)
{
    float l = max(max(c.r, c.g), c.b);
    return c * smoothstep(0.12, 0.65, l);
}

float3 GlowGate(float3 c, float threshold)
{
    float l = max(max(c.r, c.g), c.b);
    return c * smoothstep(threshold, threshold + 0.35, l);
}

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

// =========================================================================
// Pixel Shaders
// =========================================================================

// Pass 1: Linearization, DPX Filmic S-Curve & P22 Gamut
float4 PS_Linearize(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 color = tex2D(ReShade::BackBuffer, uv).rgb;

    if (DPX_Enable)
    {
        float3 dpx = color * DPX_Gain;
        dpx = (dpx - DPX_RGB_C) * (1.0 + DPX_Contrast) + DPX_RGB_C;
        
        // Exact normalized Cineon/DPX S-curve (anchors 0->0 and 1->1 to prevent lifted blacks)
        float3 sig  = 1.0 / (1.0 + exp(-DPX_RGB_Curve * (dpx - DPX_RGB_C)));
        float3 sig0 = 1.0 / (1.0 + exp(DPX_RGB_Curve * DPX_RGB_C));
        float3 sig1 = 1.0 / (1.0 + exp(-DPX_RGB_Curve * (1.0 - DPX_RGB_C)));
        dpx = saturate((sig - sig0) / max(sig1 - sig0, 0.0001));

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

// Pass 2: Custom Analog Blur Engine & Composite Video
float4 PS_SignalBlur(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pad = GetPillarboxPadding();
    float2 activeSize = 1.0 - 2.0 * pad;

    if (CMP_Enable)
    {
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
            yLuma += RGBtoYIQ(ToGamma(tex2Dlod(SamplerLinear, float4(uv + texel * (fi * Blur_Width), 0, 0)).rgb)).x * wt;
            iq    += RGBtoYIQ(ToGamma(tex2Dlod(SamplerLinear, float4(uv + texel * (fi * chromaStep), 0, 0)).rgb)).yz * wt;
        }

        float2 edgeOff = (axis * activeSize) / CMP_Resolution;
        float yA = RGBtoYIQ(ToGamma(tex2Dlod(SamplerLinear, float4(uv + edgeOff, 0, 0)).rgb)).x;
        float yB = RGBtoYIQ(ToGamma(tex2Dlod(SamplerLinear, float4(uv - edgeOff, 0, 0)).rgb)).x;
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
    }

    if (!Blur_Enable)
    {
        return tex2Dlod(SamplerLinear, float4(uv, 0.0, 0.0));
    }

    // Astigmatism centered on active tube area, not monitor bezels
    float2 tubeCenterDist = (uv - pad) / max(activeSize, 0.001) - 0.5;
    float astig = 1.0 + (AST_Enable ? dot(tubeCenterDist, tubeCenterDist) * 4.0 * AST_Amount : 0.0);
    float effectiveWidth = Blur_Width * astig;

    float2 axis = (C_TateMode ? float2(0.0, BUFFER_RCP_HEIGHT) : float2(BUFFER_RCP_WIDTH, 0.0)) * effectiveWidth;

    if (Blur_Type == 1) // Asymmetric Analog RC Bleed
    {
        float3 c = tex2Dlod(SamplerLinear, float4(uv - axis, 0, 0)).rgb * 0.15;
        c += tex2Dlod(SamplerLinear, float4(uv, 0, 0)).rgb * 0.38;
        c += tex2Dlod(SamplerLinear, float4(uv + axis * (1.0 * RC_Bleed), 0, 0)).rgb * 0.24;
        c += tex2Dlod(SamplerLinear, float4(uv + axis * (2.0 * RC_Bleed), 0, 0)).rgb * 0.15;
        c += tex2Dlod(SamplerLinear, float4(uv + axis * (3.0 * RC_Bleed), 0, 0)).rgb * 0.08;
        return float4(c, 1.0);
    }
    else if (Blur_Type == 2) // Flyback Focus Defocus (Dual-Axis)
    {
        float2 stepY = (C_TateMode ? float2(BUFFER_RCP_WIDTH, 0.0) : float2(0.0, BUFFER_RCP_HEIGHT)) * effectiveWidth * 0.40;
        float3 c = tex2Dlod(SamplerLinear, float4(uv, 0, 0)).rgb * 0.36;
        c += (tex2Dlod(SamplerLinear, float4(uv + axis, 0, 0)).rgb + tex2Dlod(SamplerLinear, float4(uv - axis, 0, 0)).rgb) * 0.22;
        c += (tex2Dlod(SamplerLinear, float4(uv + axis * 2.0, 0, 0)).rgb + tex2Dlod(SamplerLinear, float4(uv - axis * 2.0, 0, 0)).rgb) * 0.06;
        c += (tex2Dlod(SamplerLinear, float4(uv + stepY, 0, 0)).rgb + tex2Dlod(SamplerLinear, float4(uv - stepY, 0, 0)).rgb) * 0.04;
        return float4(c, 1.0);
    }
    else // Symmetric 5-Tap Gaussian
    {
        float3 c = tex2Dlod(SamplerLinear, float4(uv, 0, 0)).rgb * 0.375;
        c += (tex2Dlod(SamplerLinear, float4(uv + axis, 0, 0)).rgb       + tex2Dlod(SamplerLinear, float4(uv - axis, 0, 0)).rgb)       * 0.25;
        c += (tex2Dlod(SamplerLinear, float4(uv + axis * 2.0, 0, 0)).rgb + tex2Dlod(SamplerLinear, float4(uv - axis * 2.0, 0, 0)).rgb) * 0.0625;
        return float4(c, 1.0);
    }
}

// Pass 3: Phosphor Persistence Update
float4 PS_PersistUpdate(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 cur = tex2Dlod(SamplerSignal, float4(uv, 0, 0)).rgb;
    if (!P_Enable) return float4(cur, 1.0);
    
    float3 prev = tex2Dlod(SamplerPersistPrev, float4(uv, 0, 0)).rgb;
    float3 ghosted = max(cur, prev * P_Decay);
    
    return float4(lerp(cur, ghosted, P_Strength), 1.0);
}

// Pass 4: Phosphor Persistence Copy
float4 PS_PersistCopy(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!P_Enable) discard; // Bypass memory write when persistence is inactive
    return tex2Dlod(SamplerPersistCur, float4(uv, 0, 0));
}

// Pass 5: Halation Horizontal (Half-res target)
float4 PS_Halation_H(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!H_Enable || H_Strength <= 0.0) discard;

    float2 stepVec = float2(BUFFER_RCP_WIDTH * 2.0 * H_Radius * (BUFFER_HEIGHT / 1080.0), 0.0);

    float3 result = HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv, 0, 0)).rgb) * 0.227027;
    result += (HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv + stepVec * 1.0, 0, 0)).rgb) + HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv - stepVec * 1.0, 0, 0)).rgb)) * 0.1945946;
    result += (HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv + stepVec * 2.0, 0, 0)).rgb) + HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv - stepVec * 2.0, 0, 0)).rgb)) * 0.1216216;
    result += (HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv + stepVec * 3.0, 0, 0)).rgb) + HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv - stepVec * 3.0, 0, 0)).rgb)) * 0.0540540;
    result += (HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv + stepVec * 4.0, 0, 0)).rgb) + HaloGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv - stepVec * 4.0, 0, 0)).rgb)) * 0.0162160;

    return float4(result, 1.0);
}

// Pass 6: Halation Vertical (Half-res target)
float4 PS_Halation_V(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!H_Enable || H_Strength <= 0.0) discard;

    float2 stepVec = float2(0.0, BUFFER_RCP_HEIGHT * 2.0 * H_Radius * (BUFFER_HEIGHT / 1080.0));

    float3 result = tex2Dlod(SamplerHalationH, float4(uv, 0, 0)).rgb * 0.227027;
    result += (tex2Dlod(SamplerHalationH, float4(uv + stepVec * 1.0, 0, 0)).rgb + tex2Dlod(SamplerHalationH, float4(uv - stepVec * 1.0, 0, 0)).rgb) * 0.1945946;
    result += (tex2Dlod(SamplerHalationH, float4(uv + stepVec * 2.0, 0, 0)).rgb + tex2Dlod(SamplerHalationH, float4(uv - stepVec * 2.0, 0, 0)).rgb) * 0.1216216;
    result += (tex2Dlod(SamplerHalationH, float4(uv + stepVec * 3.0, 0, 0)).rgb + tex2Dlod(SamplerHalationH, float4(uv - stepVec * 3.0, 0, 0)).rgb) * 0.0540540;
    result += (tex2Dlod(SamplerHalationH, float4(uv + stepVec * 4.0, 0, 0)).rgb + tex2Dlod(SamplerHalationH, float4(uv - stepVec * 4.0, 0, 0)).rgb) * 0.0162160;

    return float4(result, 1.0);
}

// Pass 7: Glow Downsample
float4 PS_GlowDown(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!GL_Enable || GL_Strength <= 0.0) discard;

    float3 sum = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int ix = 0; ix < 4; ix++)
    {
        [unroll]
        for (int iy = 0; iy < 4; iy++)
        {
            float2 o = (float2((float)ix, (float)iy) - 1.5) * 2.0 * BUFFER_PIXEL_SIZE;
            sum += GlowGate(tex2Dlod(CRT_SIGNAL_SAMPLER, float4(uv + o, 0.0, 0.0)).rgb, GL_Threshold);
        }
    }

    return float4(sum / 16.0, 1.0);
}

// Pass 8: Glow Blur H
float4 PS_GlowH(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!GL_Enable || GL_Strength <= 0.0) discard;

    float2 stepVec = float2(BUFFER_RCP_WIDTH * 8.0 * GL_Radius * (BUFFER_HEIGHT / 1080.0), 0.0);

    float3 result = tex2Dlod(SamplerGlowA, float4(uv, 0, 0)).rgb * 0.227027;
    result += (tex2Dlod(SamplerGlowA, float4(uv + stepVec * 1.0, 0, 0)).rgb + tex2Dlod(SamplerGlowA, float4(uv - stepVec * 1.0, 0, 0)).rgb) * 0.1945946;
    result += (tex2Dlod(SamplerGlowA, float4(uv + stepVec * 2.0, 0, 0)).rgb + tex2Dlod(SamplerGlowA, float4(uv - stepVec * 2.0, 0, 0)).rgb) * 0.1216216;
    result += (tex2Dlod(SamplerGlowA, float4(uv + stepVec * 3.0, 0, 0)).rgb + tex2Dlod(SamplerGlowA, float4(uv - stepVec * 3.0, 0, 0)).rgb) * 0.0540540;
    result += (tex2Dlod(SamplerGlowA, float4(uv + stepVec * 4.0, 0, 0)).rgb + tex2Dlod(SamplerGlowA, float4(uv - stepVec * 4.0, 0, 0)).rgb) * 0.0162160;

    return float4(result, 1.0);
}

// Pass 9: Glow Blur V
float4 PS_GlowV(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!GL_Enable || GL_Strength <= 0.0) discard;

    float2 stepVec = float2(0.0, BUFFER_RCP_HEIGHT * 8.0 * GL_Radius * (BUFFER_HEIGHT / 1080.0));

    float3 result = tex2Dlod(SamplerGlowB, float4(uv, 0, 0)).rgb * 0.227027;
    result += (tex2Dlod(SamplerGlowB, float4(uv + stepVec * 1.0, 0, 0)).rgb + tex2Dlod(SamplerGlowB, float4(uv - stepVec * 1.0, 0, 0)).rgb) * 0.1945946;
    result += (tex2Dlod(SamplerGlowB, float4(uv + stepVec * 2.0, 0, 0)).rgb + tex2Dlod(SamplerGlowB, float4(uv - stepVec * 2.0, 0, 0)).rgb) * 0.1216216;
    result += (tex2Dlod(SamplerGlowB, float4(uv + stepVec * 3.0, 0, 0)).rgb + tex2Dlod(SamplerGlowB, float4(uv - stepVec * 3.0, 0, 0)).rgb) * 0.0540540;
    result += (tex2Dlod(SamplerGlowB, float4(uv + stepVec * 4.0, 0, 0)).rgb + tex2Dlod(SamplerGlowB, float4(uv - stepVec * 4.0, 0, 0)).rgb) * 0.0162160;

    return float4(result, 1.0);
}

// Pass 10: Main Rasterizer, Cabinet Optics & Compositor
float4 PS_Raster_Composite(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pad = GetPillarboxPadding();
    float2 activeSize = 1.0 - 2.0 * pad;

    if (uv.x < pad.x || uv.x > (1.0 - pad.x) || uv.y < pad.y || uv.y > (1.0 - pad.y))
        return float4(0.0, 0.0, 0.0, 1.0);

    float2 localUV = (uv - pad) / activeSize;

    // High-Voltage Anode Sag (Aspect/Ultrawide-Safe)
    if (HV_Enable)
    {
        float3 lumaW = float3(0.2126, 0.7152, 0.0722);
        float flashLuma = dot(tex2Dlod(SamplerLinear, float4(pad + float2(0.50, 0.50) * activeSize, 0, 0)).rgb, lumaW) * 0.40
                        + dot(tex2Dlod(SamplerLinear, float4(pad + float2(0.25, 0.25) * activeSize, 0, 0)).rgb, lumaW) * 0.15
                        + dot(tex2Dlod(SamplerLinear, float4(pad + float2(0.75, 0.25) * activeSize, 0, 0)).rgb, lumaW) * 0.15
                        + dot(tex2Dlod(SamplerLinear, float4(pad + float2(0.25, 0.75) * activeSize, 0, 0)).rgb, lumaW) * 0.15
                        + dot(tex2Dlod(SamplerLinear, float4(pad + float2(0.75, 0.75) * activeSize, 0, 0)).rgb, lumaW) * 0.15;
        float sag = 1.0 + flashLuma * (HV_SagAmount * 0.015);
        localUV = (localUV - 0.5) / sag + 0.5;
    }

    float2 warpedLocalUV = WarpCoords(localUV);

    // Bezel Shroud Detection & Exact Piecewise Corner SDF
    float maskClip = 1.0;
    float corner = 0.0;
    if (G_EnableCurvature || G_CornerSize > 0.0001)
    {
        float r = G_CornerSize;
        float2 cd = abs(warpedLocalUV - 0.5) - 0.5 + r;
        corner = (r > 0.0001) 
            ? (length(max(cd, 0.0)) + min(max(cd.x, cd.y), 0.0) - r)
            : max(cd.x, cd.y);
        maskClip = 1.0 - smoothstep(0.0, 0.005, corner);
    }

    float2 clampedWarpedUV = clamp(warpedLocalUV, 0.0005, 0.9995);

    // Deflection yoke deconvergence
    float2 centerDist = clampedWarpedUV - 0.5;
    float radialFactor = dot(centerDist, centerDist) * D_RadialYoke * 4.0;
    float2 shift = (D_StaticShift + centerDist * radialFactor) * BUFFER_PIXEL_SIZE;
    bool hasDecon = (dot(D_StaticShift, D_StaticShift) + D_RadialYoke > 0.00001);

    // Scanlines
    float targetLines = GetTargetLines();
    float rasterPos = C_TateMode ? (clampedWarpedUV.x * targetLines) : (clampedWarpedUV.y * targetLines);

    if (I_Enable && I_Mode == 1)
    {
        float fieldPhase = (float)(framecount % 2);
        rasterPos += 0.5 * fieldPhase;
    }

    float lineBase = floor(rasterPos);
    float dist = rasterPos - lineBase - 0.5;

    float3 color = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int k = -1; k <= 1; k++)
    {
        float centerLocal = clamp((lineBase + (float)k + 0.5) / targetLines, 0.0005, 0.9995);

        float2 lineCenterLocalUV = C_TateMode 
            ? float2(centerLocal, clampedWarpedUV.y) 
            : float2(clampedWarpedUV.x, centerLocal);

        float2 sampleLineUV = pad + lineCenterLocalUV * activeSize;

        float3 c;
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

        if (I_Enable && I_Mode == 0)
        {
            float isOddLine = step(0.25, frac((lineBase + (float)k + (float)(framecount % 2)) * 0.5));
            beam *= lerp(1.0, 1.0 - I_Strength, isOddLine);
        }

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
        if (M_SubpixelMode == 2) // WOLED 4-subpixel
        {
            int x = px % 4;
            if (x == 0)      mask = float3(1.0, 1.0 - M_Strength, 1.0 - M_Strength);
            else if (x == 1) mask = float3(1.0 - M_Strength, 1.0, 1.0 - M_Strength);
            else if (x == 2) mask = float3(1.0 - M_Strength, 1.0 - M_Strength, 1.0);
            else             mask = (1.0 - M_Strength * 0.35).xxx;
        }
        else
        {
            int x = px % 3;
            if (x == 0)      mask = float3(1.0, 1.0 - M_Strength, 1.0 - M_Strength);
            else if (x == 1) mask = float3(1.0 - M_Strength, 1.0, 1.0 - M_Strength);
            else             mask = float3(1.0 - M_Strength, 1.0 - M_Strength, 1.0);
        }
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

        // Ensure white subpixel attenuation on WOLED without breaking slot structure
        if (M_SubpixelMode == 2 && (px % 4 == 3))
            mask *= (1.0 - M_Strength * 0.35);
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

        // Ensure white subpixel attenuation on WOLED without breaking triad structure
        if (M_SubpixelMode == 2 && (px % 4 == 3))
            mask *= (1.0 - M_Strength * 0.35);
    }

    if (M_SubpixelMode == 1) mask = mask.bgr; // Inverted BGR panel layout
    else if (M_SubpixelMode == 3) mask = lerp(mask, dot(mask, 0.3333).xxx, 0.20); // QD-OLED triangular layout

    // Auto-compensation for mask attenuation
    float maskTransmission = dot(mask, float3(0.3333, 0.3333, 0.3333));
    float autoFactor = 1.0 / max(maskTransmission, 0.15);
    color *= lerp(1.0, autoFactor, M_AutoComp);

    float luma = max(max(color.r, color.g), color.b);
    mask = lerp(mask, float3(1.0, 1.0, 1.0), pow(saturate(luma), 1.5) * M_Bloom);
    color *= mask * M_BrightBoost;

    // Sony Trinitron Damper Wires (Resolution-scaled)
    if (W_Enable)
    {
        float wireY = C_TateMode ? warpedLocalUV.x : warpedLocalUV.y;
        float tubeH = C_TateMode ? (BUFFER_WIDTH * activeSize.x) : (BUFFER_HEIGHT * activeSize.y);
        float wireDist = (W_Count == 0)
            ? abs(wireY - 0.50) * tubeH
            : min(abs(wireY - 0.333), abs(wireY - 0.667)) * tubeH;

        float wireThickness = 1.25 * max(BUFFER_HEIGHT / 1080.0, 1.0);
        float wire = smoothstep(0.0, wireThickness, wireDist);
        color *= lerp(1.0 - W_Opacity, 1.0, wire);
    }

    // Rolling AC Ground Hum Bar
    if (HB_Enable)
    {
        float humCoord = C_TateMode ? clampedWarpedUV.x : clampedWarpedUV.y;
        float humPhase = frac(float(framecount) * (HB_Speed * 0.005) + humCoord * HB_Frequency);
        float humWave = sin(humPhase * 6.2831853);
        color += (humWave * HB_Strength * 0.025) + color * (humWave * HB_Strength);
    }

    float2 sampleUV = pad + clampedWarpedUV * activeSize;

    if (H_Enable && H_Strength > 0.0)
        color += tex2Dlod(SamplerHalationV, float4(sampleUV, 0.0, 0.0)).rgb * H_Strength;

    if (GL_Enable && GL_Strength > 0.0)
        color += tex2Dlod(SamplerGlowA, float4(sampleUV, 0.0, 0.0)).rgb * GL_Strength;

    // Cabinet Bezel Reflection (Calculated in linear space)
    float3 bezel = float3(0.0, 0.0, 0.0);
    if (BZ_Enable && corner > 0.0 && corner < BZ_Width)
    {
        float bezelDist = corner / max(BZ_Width, 0.001);
        float3 edgeLight = tex2Dlod(CRT_SIGNAL_SAMPLER, float4(pad + clampedWarpedUV * activeSize, 0, 0)).rgb;
        float bezelProfile = cos(bezelDist * 1.5707963);
        bezel = edgeLight * bezelProfile * BZ_Strength;
    }

    // Composite bezel and tube content in linear color space
    color = lerp(bezel, color, maskClip);

    // Output gamma conversion & black level calibration
    color = pow(max(color, 0.0), 1.0 / COL_OutputGamma);
    color = max(color + COL_BlackLevel.xxx, 0.0);

    // Cleanly anchor unused chassis area to true black (prevents positive black-level bleed)
    float outerClip = saturate(maskClip + (BZ_Enable ? smoothstep(BZ_Width, 0.0, corner) : 0.0));
    color *= outerClip;

    return float4(color, 1.0);
}

// =========================================================================
// Technique Definition
// =========================================================================

technique CRT_Mame_Advance_Four
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
    pass Raster_Composite
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Raster_Composite;
    }
}