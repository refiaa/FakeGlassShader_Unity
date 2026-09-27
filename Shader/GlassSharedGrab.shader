Shader "refiaa/glass (Shared Grab)"
{
    Properties
    {
        [Header(Core Absorption)]
        _BaseTint("Reserved RGB / Effect Blend (A)", Color) = (1, 1, 1, 1)
        _TransmissionColorAtDistance("Transmittance At Reference Distance", Color) = (0.97647, 1.00000, 0.99608, 1)
        _ReferenceDistance("Reference Distance (Meters)", Range(0.001, 0.250)) = 0.010
        _TransmittanceInfluence("Transmittance Influence", Range(0.000, 1.000)) = 0.350
        _TransmittanceCurvePower("Transmittance Curve Power", Range(0.250, 4.000)) = 1.000
        _DepthTintStrength("Depth Tint Strength", Range(0.000, 3.000)) = 0.450
        _DepthTintCurve("Depth Tint Curve", Range(0.250, 4.000)) = 1.250
        _Scattering("Internal Scattering (1/m)", Range(0.000, 5.000)) = 0.000
        _ThicknessScale("Thickness Scale", Range(0.010, 10.000)) = 0.500
        _ThicknessBias("Thickness Bias (Meters)", Range(-0.020, 0.020)) = 0.020
        _MaxThickness("Max Thickness (Meters)", Range(0.001, 2.000)) = 0.200
        _FallbackThickness("Fallback Thickness (Meters)", Range(0.0001, 0.1000)) = 0.0001
        [Toggle] _FallbackUseAngle("Fallback Use Angle Correction", Float) = 1
        [Toggle] _UseBoundsThicknessFallback("Use Bounds Thickness Fallback", Float) = 1
        _BoundsFallbackBlend("Bounds Fallback Blend", Range(0.000, 1.000)) = 1.000
        _FallbackBoundsMin("Fallback Bounds Min (Object)", Vector) = (-0.5, -0.5, -0.5, 0)
        _FallbackBoundsMax("Fallback Bounds Max (Object)", Vector) = (0.5, 0.5, 0.5, 0)
        _FallbackAbsorptionScale("Fallback Absorption Scale", Range(0.000, 1.000)) = 1.000
        _MinViewDot("Fallback Min |N.V|", Range(0.010, 1.000)) = 0.030
        _GrazingAssistNdotV("Grazing Assist NdotV", Range(0.050, 0.600)) = 0.250
        _GrazingThicknessAssist("Grazing Thickness Assist", Range(0.000, 2.000)) = 0.000
        _NearFadeDistance("Near Camera Fade Distance (Meters)", Range(0.000, 0.200)) = 0.040
        _DepthEdgeFixPixels("Back Depth Edge Fix Radius (Pixels)", Range(0.0, 3.0)) = 1.500

        [Header(Refraction)]
        _RefractionStrength("Refraction Strength", Range(0.000, 0.200)) = 0.010
        [Enum(Thin Pane,0, Solid,1)] _RefractionModel("Refraction Model", Float) = 0
        _DistortionFace("Distortion (Face)", Range(0.000, 1.000)) = 0.000
        _DistortionEdge("Distortion (Edge)", Range(0.000, 1.000)) = 0.000
        _BackfaceVisibility("Backface Visibility", Range(0.000, 1.000)) = 0.350
        [Toggle] _UseChromaticAberration("Use Chromatic Aberration", Float) = 1
        _ChromaticAberration("Max Dispersion (Pixels)", Range(0.000, 3.000)) = 3.000
        _AbbeNumber("Abbe Number", Range(10.000, 90.000)) = 58.000
        _ScreenEdgeFadePixels("Refraction Screen Edge Fade (Pixels)", Range(0.0, 32.0)) = 32.000

        [Header(Refraction Blur)]
        [Toggle] _UseRefractionBlur("Use Refraction Blur", Float) = 0
        _RefractionBlurStrength("Blur Strength", Range(0.000, 2.000)) = 1.000
        _RefractionBlurMaxPixels("Max Blur Radius (Pixels)", Range(0.000, 24.000)) = 6.000
        _RefractionBlurRoughnessInfluence("Roughness Influence", Range(0.000, 1.000)) = 0.500
        _RefractionBlurThicknessInfluence("Thickness Influence", Range(0.000, 1.000)) = 0.500
        _RefractionBlurScale("Physical Blur Scale", Range(0.001, 0.100)) = 0.030
        _RefractionBlurKernelSigma("Kernel Softness", Range(0.350, 3.000)) = 1.350

        [Header(Rain)]
        [Toggle] _GlassRainEnabled("Enable Rain", Float) = 0
        [Enum(Off,0, Droplets,1, Ripples,2, Automatic,3)] _GlassRainMode("Mode", Float) = 1
        _GlassRainNormalBlend("Normal Blend", Range(0.000, 1.000)) = 1.000
        _GlassRainWetness("Wetness", Range(0.000, 1.000)) = 0.250
        _GlassRainStrength("Droplet Strength", Range(0.000, 2.000)) = 0.350
        _GlassRainSpeed("Droplet Speed", Range(0.000, 120.000)) = 40.000
        _GlassRainTiling("Droplet Tiling (XY)", Vector) = (1.5, 1.5, 0, 0)
        _GlassRainSheetRows("Sheet Rows", Range(1.000, 16.000)) = 8.000
        _GlassRainSheetColumns("Sheet Columns", Range(1.000, 16.000)) = 8.000
        _GlassRainDynamicDroplets("Dynamic Droplets", Range(0.000, 1.000)) = 0.500
        _GlassRainRippleStrength("Ripple Strength", Range(0.000, 2.000)) = 0.350
        _GlassRainRippleScale("Ripple Scale", Range(1.000, 64.000)) = 20.000
        _GlassRainRippleSpeed("Ripple Speed", Range(0.000, 10.000)) = 2.000
        _GlassRainRippleDensity("Ripple Density", Range(0.500, 8.000)) = 1.000
        _GlassRainAutoThreshold("Auto Angle Threshold", Range(0.000, 1.000)) = 0.350
        _GlassRainAutoBlend("Auto Angle Blend", Range(0.010, 0.500)) = 0.200
        _GlassRainMask("Rain Mask", 2D) = "white" {}
        [Enum(Red,0, Green,1, Blue,2, Alpha,3)] _GlassRainMaskChannel("Rain Mask Channel", Float) = 0
        [NoScaleOffset] _GlassRainSheet("Rain Texture Sheet", 2D) = "black" {}
        [NoScaleOffset] _GlassRainDropletMask("Rain Droplet Mask", 2D) = "white" {}
        [NoScaleOffset] _GlassRainNoiseTex("Rain Noise Texture", 2D) = "gray" {}

        [Header(Reflection)]
        _IOR("Index Of Refraction", Range(1.000, 2.000)) = 1.500
        _ReflectionTint("Reflection Tint", Color) = (1, 1, 1, 1)
        _EnvReflectionStrength("Environment Reflection Strength", Range(0.000, 4.000)) = 1.500
        _SpecularStrength("Direct Specular Strength", Range(0.000, 4.000)) = 0.250
        _Smoothness("Smoothness", Range(0.000, 1.000)) = 1.000
        _FresnelBoost("Fresnel Boost", Range(0.000, 2.000)) = 0.850
        _TransmissionAtGrazing("Transmission At Grazing", Range(0.000, 1.000)) = 0.300
        _ReflectionAbsorption("Reflection Absorption Coupling", Range(0.000, 1.000)) = 0.500

        [Header(Mesh Edge Highlight)]
        [Toggle] _UseMeshEdge("Use Mesh Edge Highlight", Float) = 0
        _MeshEdgeColor("Mesh Edge Color", Color) = (1, 1, 1, 1)
        _MeshEdgeWidth("Mesh Edge Width", Range(0.000, 8.000)) = 1.500
        _MeshEdgeThreshold("Mesh Edge Threshold", Range(0.000, 1.000)) = 0.000
        _MeshEdgeSoftness("Mesh Edge Softness", Range(0.001, 1.000)) = 0.100
        _MeshEdgeIntensity("Mesh Edge Intensity", Range(0.000, 4.000)) = 1.000

        [Header(Surface Detail)]
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0.000, 2.000)) = 1.000
        _RoughnessMap("Roughness Map", 2D) = "black" {}
        _RoughnessMapStrength("Roughness Map Strength", Range(0.000, 1.000)) = 1.000
        _MetallicMap("Metalic Map", 2D) = "black" {}
        _MetallicMapStrength("Metalic Map Strength", Range(0.000, 1.000)) = 1.000

        [Header(External Inputs)]
        [NoScaleOffset] _BackDepthTex("Back Depth Texture (Linear Eye)", 2D) = "black" {}
        [NoScaleOffset] _SceneColorTex("Scene Color Texture", 2D) = "black" {}
        [Toggle] _UseSceneColorTexture("Use External Scene Color Texture", Float) = 0
        [Toggle] _UseBackDepthTexture("Use Back Depth Texture", Float) = 1
        [Toggle] _BackDepthIsLinear("Back Depth Is Linear Eye Depth", Float) = 1
        [Toggle] _UseUdonStereoTextures("Use Udon Stereo Textures", Float) = 0
        [Toggle] _UseGrabPassFallback("Use GrabPass Fallback", Float) = 1
        _UVClamp("UV Clamp Padding", Range(0.000, 0.010)) = 0.001

        [Header(Debug)]
        [KeywordEnum(None, Thickness, Transmittance, Fresnel)] _DebugView("Debug View", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
            "VRCFallback" = "Transparent"
            "DisableBatching" = "True"
        }

        LOD 400
        Cull Back
        ZWrite Off
        ZTest LEqual
        Blend One Zero

        // One screen copy per frame, shared by every object using this shader. Transparents drawn after the copy
        // (glass behind glass) are restored by the output composition (see GlassComposeOutput).
        GrabPass
        {
            "_GlassSharedGrabTexture"
        }

        Pass
        {
            Name "FORWARD_BASE"
            Tags { "LightMode" = "ForwardBase" }
            Blend One SrcAlpha

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma shader_feature_local _DEBUGVIEW_NONE _DEBUGVIEW_THICKNESS _DEBUGVIEW_TRANSMITTANCE _DEBUGVIEW_FRESNEL

            #define GLASS_SHARED_GRAB 1
            #include "GlassForwardPass.cginc"
            ENDCG
        }

        Pass
        {
            Name "BACKFACE_OVERLAY"

            Cull Front
            ZWrite Off
            ZTest LEqual
            Blend One SrcAlpha

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vertBack
            #pragma fragment fragBack
            #pragma multi_compile_instancing

            #define GLASS_SHARED_GRAB 1
            #include "GlassBackfacePass.cginc"
            ENDCG
        }
    }

    CustomEditor "GlassShaderGUI"
    Fallback "Transparent/VertexLit"
}
