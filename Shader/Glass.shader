Shader "refiaa/glass"
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
        _ChromaticAberration("Chromatic Aberration (Pixels)", Range(0.000, 3.000)) = 3.000
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

        GrabPass
        {
        }

        Pass
        {
            Name "FORWARD_BASE"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma shader_feature_local _DEBUGVIEW_NONE _DEBUGVIEW_THICKNESS _DEBUGVIEW_TRANSMITTANCE _DEBUGVIEW_FRESNEL

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "GlassCommon.cginc"
            #include "GlassRefractionBlur.cginc"

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float4 edgeData0 : TEXCOORD3;
                float4 edgeData1 : TEXCOORD4;
                float4 thicknessData : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 grabPos : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 normalWS : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
                float3 bitangentWS : TEXCOORD6;
                float3 barycentric : TEXCOORD7;
                float3 edgeKeep : TEXCOORD8;
                float bakedThickness : TEXCOORD9;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _NormalMap;
            sampler2D _RoughnessMap;
            sampler2D _MetallicMap;
            sampler2D _BackDepthTex;
            float4 _BackDepthTex_TexelSize;
            sampler2D _SceneColorTex;
            sampler2D _GrabTexture;
            sampler2D _UdonGlassBackDepthL;
            sampler2D _UdonGlassBackDepthR;
            sampler2D _UdonGlassSceneColorL;
            sampler2D _UdonGlassSceneColorR;

            float4 _BaseTint;
            float4 _TransmissionColorAtDistance;
            float4 _ReflectionTint;
            float4 _NormalMap_ST;
            float4 _RoughnessMap_ST;
            float4 _MetallicMap_ST;
            float _ReferenceDistance;
            float _TransmittanceInfluence;
            float _TransmittanceCurvePower;
            float _DepthTintStrength;
            float _DepthTintCurve;
            float _ThicknessScale;
            float _ThicknessBias;
            float _MaxThickness;
            float _FallbackThickness;
            float _FallbackUseAngle;
            float _UseBoundsThicknessFallback;
            float _BoundsFallbackBlend;
            float4 _FallbackBoundsMin;
            float4 _FallbackBoundsMax;
            float _FallbackAbsorptionScale;
            float _MinViewDot;
            float _GrazingAssistNdotV;
            float _GrazingThicknessAssist;
            float _NearFadeDistance;
            float _DepthEdgeFixPixels;
            float _RefractionStrength;
            float _RefractionModel;
            float _DistortionFace;
            float _DistortionEdge;
            float _UseChromaticAberration;
            float _ChromaticAberration;
            float _ScreenEdgeFadePixels;
            float _UseRefractionBlur;
            float _RefractionBlurStrength;
            float _RefractionBlurMaxPixels;
            float _RefractionBlurRoughnessInfluence;
            float _RefractionBlurThicknessInfluence;
            float _RefractionBlurScale;
            float _RefractionBlurKernelSigma;
            float _IOR;
            float _EnvReflectionStrength;
            float _SpecularStrength;
            float _Smoothness;
            float _FresnelBoost;
            float _TransmissionAtGrazing;
            float _ReflectionAbsorption;
            float _UseMeshEdge;
            float4 _MeshEdgeColor;
            float _MeshEdgeWidth;
            float _MeshEdgeThreshold;
            float _MeshEdgeSoftness;
            float _MeshEdgeIntensity;
            float _NormalScale;
            float _RoughnessMapStrength;
            float _MetallicMapStrength;
            float _UseSceneColorTexture;
            float _UseBackDepthTexture;
            float _BackDepthIsLinear;
            float _UseUdonStereoTextures;
            float _UseGrabPassFallback;
            float _UVClamp;

            #include "GlassPassShared.cginc"
            #include "GlassRain.cginc"
            #include "GlassForwardThickness.cginc"
            #include "GlassForwardSurface.cginc"

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_OUTPUT(Varyings, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = UnityObjectToClipPos(input.vertex);
                output.uv = input.uv;
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.grabPos = ComputeGrabScreenPos(output.positionCS);
                output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;

                output.normalWS = UnityObjectToWorldNormal(input.normal);
                output.tangentWS = UnityObjectToWorldDir(input.tangent.xyz);
                float tangentSign = input.tangent.w * unity_WorldTransformParams.w;
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * tangentSign;
                // Baked edge data has UV4.w <= 0; a mesh without UV4 gets substitute data (a 2D UV reads w = 1).
                // Zeroed barycentrics fail the validity check, so unbaked meshes get no edge masks.
                output.barycentric = input.edgeData0.xyz * step(input.edgeData1.w, 0.5);
                output.edgeKeep = float3(input.edgeData0.w, input.edgeData1.x, input.edgeData1.y);
                // Baked inward thickness (object space) scaled to world units along the normal. The baker marks
                // w = -1; a mesh without UV5 does not read zeros (Unity substitutes other data), so trust the marker only.
                float hasBakedThickness = step(input.thicknessData.w, -0.5);
                output.bakedThickness = hasBakedThickness * max(input.thicknessData.x, 0.0) * length(mul((float3x3)unity_ObjectToWorld, input.normal));

                return output;
            }

            float ComputeFaceEdgeDistortionGain(float edgeMask, float frontDepth)
            {
                float edgeBlend = saturate(edgeMask);
                float faceEdgeDistortion = lerp(_DistortionFace, _DistortionEdge, edgeBlend);
                float distanceAttenuation = 1.5 * rsqrt(max(frontDepth, 0.25));
                return saturate(faceEdgeDistortion) * distanceAttenuation;
            }

            float ComposeRefractionScale(float baseRefractionScale, float distortionGain)
            {
                return baseRefractionScale * (1.0 + max(distortionGain, 0.0) * 1.5);
            }

            float4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 viewDirWS = normalize(UnityWorldSpaceViewDir(input.worldPos));
                float2 normalUV = TRANSFORM_TEX(input.uv, _NormalMap);
                float perceptualRoughness;
                float roughnessLinear;
                float metallic;
                SampleSurfaceParameters(input.uv, perceptualRoughness, roughnessLinear, metallic);

                float3 normalWS = ComputeNormalWS(input, normalUV);

                float2 screenUV = ClampSceneUV(GlassGetScreenUV(input.screenPos));
                float frontDepth = max(-mul(UNITY_MATRIX_V, float4(input.worldPos, 1.0)).z, 0.0);

                // Baked geometry thickness when available: pane faces get their thickness, cut edges their width.
                float hasBakedThickness = step(1e-6, input.bakedThickness);
                float baseThickness = lerp(_FallbackThickness, input.bakedThickness, hasBakedThickness);
                float approxThickness = baseThickness;
                if (_FallbackUseAngle > 0.5)
                {
                    approxThickness = GlassComputeApproxThickness(baseThickness, normalWS, viewDirWS, _MinViewDot);
                }

                if (_UseBoundsThicknessFallback > 0.5 && hasBakedThickness < 0.5)
                {
                    float boundsConfidence;
                    float boundsThickness = ComputeBoundsFallbackThickness(input.worldPos, -viewDirWS, _FallbackBoundsMin.xyz, _FallbackBoundsMax.xyz, boundsConfidence);
                    float blendedBoundsThickness = lerp(approxThickness, boundsThickness, saturate(_BoundsFallbackBlend) * boundsConfidence);
                    approxThickness = max(blendedBoundsThickness, approxThickness * 0.05);
                }
                approxThickness = approxThickness * _ThicknessScale + _ThicknessBias;

                // Back-front eye depth measures along the camera axis; convert it to the view-ray length.
                float viewRayScale = distance(input.worldPos, _WorldSpaceCameraPos) / max(frontDepth, 1e-4);

                // An unassigned slot holds Unity's 4x4 default (black; linear depth 0 = invalid), and no screen-space
                // depth target is that small: skip the 5 fetches whenever they could only produce "invalid".
                float exactValid = 0.0;
                float backDepth = frontDepth;
                bool backDepthUnassigned = _UseUdonStereoTextures < 0.5 && _BackDepthTex_TexelSize.z <= 4.0 && _BackDepthIsLinear > 0.5;
                [branch]
                if (_UseBackDepthTexture > 0.5 && !backDepthUnassigned)
                {
                    backDepth = SampleBackDepthRobust(screenUV, frontDepth, exactValid);
                }
                float exactThickness = (backDepth - frontDepth) * viewRayScale * _ThicknessScale + _ThicknessBias;
                float useExactThickness = step(0.5, _UseBackDepthTexture) * exactValid;
                float thickness = lerp(approxThickness, exactThickness, useExactThickness);
                thickness = clamp(thickness, 0.0, _MaxThickness);

                // Side-view robustness: when exact back-front depth collapses at grazing angles,
                // keep physically plausible thickness using the angle-based approximation only near grazing.
                float ndotvAbs = abs(dot(normalWS, viewDirWS));
                float grazing01 = 1.0 - saturate(ndotvAbs / max(_GrazingAssistNdotV, 1e-4));
                float grazingAssistThickness = approxThickness * grazing01 * _GrazingThicknessAssist;
                thickness = max(thickness, grazingAssistThickness * useExactThickness + thickness * (1.0 - useExactThickness));
                thickness = clamp(thickness, 0.0, _MaxThickness);

                float nearFade = 1.0;
                if (_NearFadeDistance > 1e-4)
                {
                    nearFade = saturate(frontDepth / _NearFadeDistance);
                }
                thickness *= nearFade;

                float absorptionThicknessRaw = max(thickness * lerp(saturate(_FallbackAbsorptionScale), 1.0, useExactThickness), 0.0);
                float absorptionThickness = clamp(absorptionThicknessRaw, 0.0, _MaxThickness);

                float3 sigma = GlassSigmaFromReferenceColor(_TransmissionColorAtDistance.rgb, _ReferenceDistance);
                sigma *= saturate(_TransmittanceInfluence);
                float maxThicknessSafe = max(_MaxThickness, 1e-5);
                float normalizedAbsorptionRaw = GlassNormalizeThickness(absorptionThicknessRaw, maxThicknessSafe);
                float thicknessCurve01 = GlassApplyTransmittanceCurve(normalizedAbsorptionRaw, _TransmittanceCurvePower);
                float depthTintBoost = GlassComputeDepthTintBoost(normalizedAbsorptionRaw, _DepthTintStrength, _DepthTintCurve);
                float curvedAbsorptionThickness = thicknessCurve01 * maxThicknessSafe * depthTintBoost;
                float3 transmittance = GlassComputeTransmittance(sigma, curvedAbsorptionThickness);

                float normalizedThickness = saturate(GlassNormalizeThickness(absorptionThickness, maxThicknessSafe));
                GlassApplyRain(input, normalWS, perceptualRoughness, 0.0);
                roughnessLinear = max(perceptualRoughness * perceptualRoughness, 0.003);
                // lerp(face, edge, mask) ignores the mask when both gains match; the condition is uniform.
                float distortionEdgeMask = 0.0;
                [branch]
                if (_DistortionEdge != _DistortionFace)
                {
                    distortionEdgeMask = GlassComputeValidatedDistortionEdgeMask(input.barycentric, input.edgeKeep);
                }
                float baseRefractionScale = ComputeBaseRefractionScale(normalizedThickness, nearFade, screenUV);
                float distortionGain = ComputeFaceEdgeDistortionGain(distortionEdgeMask, frontDepth);
                float refractionScale = ComposeRefractionScale(baseRefractionScale, distortionGain);

                float2 refractedUV;
                float4 refractedGrabPos;
                // Absorption keeps the long view-ray path (deep tint at edges); the image shift uses the
                // bounded path along the refracted ray.
                float refractionPath = thickness * GlassViewToRefractedPath(abs(dot(normalWS, viewDirWS)), _IOR);
                float2 refractionOffset = GlassComputeRefraction(
                    input.worldPos,
                    viewDirWS,
                    normalWS,
                    normalize(input.normalWS),
                    refractionPath,
                    refractionScale,
                    frontDepth,
                    screenUV,
                    input.grabPos,
                    refractedUV,
                    refractedGrabPos);

                float3 sceneColorBase;
                if (_UseChromaticAberration > 0.5)
                {
                    sceneColorBase = SampleChromaticSceneColor(refractedUV, refractedGrabPos, refractionOffset, baseRefractionScale);
                }
                else
                {
                    sceneColorBase = SampleSceneColor(refractedUV, refractedGrabPos);
                }

                float3 sceneColor = sceneColorBase;
                if (_UseRefractionBlur > 0.5)
                {
                    float blurDriver = GlassComputeRefractionBlurDriver(
                        perceptualRoughness,
                        normalizedThickness,
                        _RefractionBlurRoughnessInfluence,
                        _RefractionBlurThicknessInfluence);

                    float blurBlend = saturate(_RefractionBlurStrength * blurDriver);
                    if (blurBlend > 0.01)
                    {
                        float minScreenDim = min(_ScreenParams.x, _ScreenParams.y);
                        float aspect = _ScreenParams.y / max(_ScreenParams.x, 1.0);
                        float blurStep = GlassComputeRefractionBlurStepUV(
                            blurDriver,
                            frontDepth,
                            _RefractionBlurScale,
                            aspect,
                            UNITY_MATRIX_P._m11);

                        blurStep *= max(_RefractionBlurStrength, 0.0);
                        float blurRadius = GlassClampBlurRadiusUVByPixelRadius(
                            blurStep * (float)GLASS_REFRACTION_BLUR_RADIUS,
                            _RefractionBlurMaxPixels,
                            minScreenDim);

                        if (abs(blurRadius) > 1e-5)
                        {
                            float blurRadiusPixels = abs(blurRadius) * minScreenDim;
                            if (blurRadiusPixels > 0.35)
                            {
                                float2 blurRadiusUV = blurRadiusPixels / max(_ScreenParams.xy, float2(1.0, 1.0));
                                float3 blurredSceneColor = SampleRefractionBlurredSceneColor(
                                    refractedUV,
                                    refractedGrabPos,
                                    blurRadiusUV,
                                    blurRadiusPixels,
                                    _RefractionBlurKernelSigma,
                                    1.0);
                                sceneColor = lerp(sceneColorBase, blurredSceneColor, blurBlend);
                            }
                        }
                    }
                }

                float eta = max(_IOR, 1.0001);
                float f0Ratio = (eta - 1.0) / (eta + 1.0);
                float f0Dielectric = f0Ratio * f0Ratio;
                float3 dielectricSpecular = saturate(_ReflectionTint.rgb) * f0Dielectric;
                float3 specularColor = lerp(dielectricSpecular, saturate(_ReflectionTint.rgb), metallic);
                float oneMinusReflectivity = 1.0 - max(specularColor.r, max(specularColor.g, specularColor.b));
                oneMinusReflectivity = saturate(oneMinusReflectivity);

                float nDotV = saturate(dot(normalWS, viewDirWS));
                float grazingTerm = saturate((1.0 - perceptualRoughness) + (1.0 - oneMinusReflectivity));
                float3 fresnelColor = lerp(specularColor, grazingTerm.xxx, GlassOneMinusCosPow5(nDotV));
                fresnelColor = saturate(fresnelColor * _FresnelBoost);
                float fresnel = saturate(GlassLuminance(fresnelColor));

                float3 reflectionDirWS = reflect(-viewDirWS, normalWS);
                float3 envReflection = SampleEnvironmentReflections(reflectionDirWS, perceptualRoughness, input.worldPos);

                float3 lightDirWS = normalize(UnityWorldSpaceLightDir(input.worldPos));
                float3 halfDirWS = normalize(lightDirWS + viewDirWS);
                float nDotL = saturate(dot(normalWS, lightDirWS));
                float nDotH = saturate(dot(normalWS, halfDirWS));
                float vDotH = saturate(dot(viewDirWS, halfDirWS));
                float D = GlassDistributionGGX(nDotH, roughnessLinear);
                float G = GlassGeometrySmith(nDotL, nDotV, roughnessLinear);
                float3 Fh = GlassSchlickFresnelColor(vDotH, specularColor);
                float3 specularBrdf = (D * G * Fh) / max(4.0 * nDotL * nDotV, 1e-4);
                float3 directSpecular = specularBrdf * nDotL * _LightColor0.rgb * _SpecularStrength;

                float surfaceReduction = 1.0 / (roughnessLinear * roughnessLinear + 1.0);
                float horizon = min(1.0 + dot(reflectionDirWS, normalWS), 1.0);
                float3 frontReflectance = fresnelColor * surfaceReduction * horizon * horizon;

                // Two interfaces with absorption between them, internal bounces summed:
                //   R = F + (1-F)^2 F T^2 / (1 - F^2 T^2)
                //   T = (1-F)^2 T / (1 - F^2 T^2)
                float3 transmittanceSq = transmittance * transmittance;
                float3 interreflection = 1.0 / max(1.0.xxx - frontReflectance * frontReflectance * transmittanceSq, 1e-4);
                float3 backReflectance = (1.0 - frontReflectance) * (1.0 - frontReflectance) * frontReflectance * transmittanceSq * interreflection;
                float3 reflectionColor = envReflection * _EnvReflectionStrength * (frontReflectance + backReflectance) + directSpecular;
                float3 reflectionAbsorption = GlassComputeTransmittance(sigma, curvedAbsorptionThickness * 2.0);
                reflectionColor *= lerp(1.0.xxx, reflectionAbsorption, saturate(_ReflectionAbsorption));

                // Same slab sum with the grazing-relaxed reflectance, so the weight stays <= 1.
                float3 transmissionLoss = frontReflectance * (1.0 - saturate(_TransmissionAtGrazing));
                float3 transmissionInterreflection = 1.0 / max(1.0.xxx - transmissionLoss * transmissionLoss * transmittanceSq, 1e-4);
                float3 transmissionWeight = (1.0 - transmissionLoss) * (1.0 - transmissionLoss) * transmissionInterreflection;
                transmissionWeight *= lerp(1.0, oneMinusReflectivity, metallic);
                float3 composedColor = reflectionColor + sceneColor * transmittance * transmissionWeight;
                float3 finalColor = lerp(sceneColor, composedColor, saturate(_BaseTint.a));

                [branch]
                if (_UseMeshEdge > 0.5)
                {
                    float meshEdgeMask = GlassComputeValidatedMeshEdgeMask(input.barycentric, input.edgeKeep);
                    float edgeWeight = saturate(meshEdgeMask * _MeshEdgeColor.a * _MeshEdgeIntensity);
                    finalColor = lerp(finalColor, _MeshEdgeColor.rgb, edgeWeight);
                }

                #if defined(_DEBUGVIEW_THICKNESS)
                    finalColor = GlassHeatColor(normalizedThickness);
                #elif defined(_DEBUGVIEW_TRANSMITTANCE)
                    finalColor = transmittance;
                #elif defined(_DEBUGVIEW_FRESNEL)
                    finalColor = fresnel.xxx;
                #endif

                return float4(finalColor, 1.0);
            }
            ENDCG
        }

        Pass
        {
            Name "BACKFACE_OVERLAY"

            Cull Front
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vertBack
            #pragma fragment fragBack
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "GlassCommon.cginc"
            #include "GlassRefractionBlur.cginc"

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float4 edgeData0 : TEXCOORD3;
                float4 edgeData1 : TEXCOORD4;
                float4 thicknessData : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 grabPos : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 normalWS : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
                float3 bitangentWS : TEXCOORD6;
                float3 barycentric : TEXCOORD7;
                float3 edgeKeep : TEXCOORD8;
                float bakedThickness : TEXCOORD9;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _NormalMap;
            sampler2D _RoughnessMap;
            sampler2D _SceneColorTex;
            sampler2D _GrabTexture;
            sampler2D _UdonGlassSceneColorL;
            sampler2D _UdonGlassSceneColorR;

            float4 _BaseTint;
            float4 _TransmissionColorAtDistance;
            float4 _NormalMap_ST;
            float4 _RoughnessMap_ST;
            float _ReferenceDistance;
            float _TransmittanceInfluence;
            float _FallbackThickness;
            float _FallbackUseAngle;
            float _MinViewDot;
            float _ThicknessScale;
            float _ThicknessBias;
            float _MaxThickness;
            float _NearFadeDistance;
            float _RefractionStrength;
            float _RefractionModel;
            float _DistortionFace;
            float _DistortionEdge;
            float _BackfaceVisibility;
            float _UseChromaticAberration;
            float _ChromaticAberration;
            float _ScreenEdgeFadePixels;
            float _UseRefractionBlur;
            float _RefractionBlurStrength;
            float _RefractionBlurMaxPixels;
            float _RefractionBlurRoughnessInfluence;
            float _RefractionBlurThicknessInfluence;
            float _RefractionBlurScale;
            float _RefractionBlurKernelSigma;
            float _MeshEdgeWidth;
            float _MeshEdgeSoftness;
            float _NormalScale;
            float _Smoothness;
            float _RoughnessMapStrength;
            float _UseSceneColorTexture;
            float _UseUdonStereoTextures;
            float _UseGrabPassFallback;
            float _IOR;
            float _UVClamp;

            #include "GlassPassShared.cginc"
            #include "GlassRain.cginc"

            Varyings vertBack(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_OUTPUT(Varyings, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = UnityObjectToClipPos(input.vertex);
                output.uv = input.uv;
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.grabPos = ComputeGrabScreenPos(output.positionCS);
                output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;

                output.normalWS = UnityObjectToWorldNormal(input.normal);
                output.tangentWS = UnityObjectToWorldDir(input.tangent.xyz);
                float tangentSign = input.tangent.w * unity_WorldTransformParams.w;
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * tangentSign;
                // Baked edge data has UV4.w <= 0; a mesh without UV4 gets substitute data (a 2D UV reads w = 1).
                // Zeroed barycentrics fail the validity check, so unbaked meshes get no edge masks.
                output.barycentric = input.edgeData0.xyz * step(input.edgeData1.w, 0.5);
                output.edgeKeep = float3(input.edgeData0.w, input.edgeData1.x, input.edgeData1.y);
                // Baked inward thickness (object space) scaled to world units along the normal. The baker marks
                // w = -1; a mesh without UV5 does not read zeros (Unity substitutes other data), so trust the marker only.
                float hasBakedThickness = step(input.thicknessData.w, -0.5);
                output.bakedThickness = hasBakedThickness * max(input.thicknessData.x, 0.0) * length(mul((float3x3)unity_ObjectToWorld, input.normal));

                // A zero-strength overlay blends alpha 0 (SrcAlpha/OneMinusSrcAlpha) and leaves the target untouched:
                // move the triangle outside the clip volume so it is never rasterized.
                if (saturate(_BackfaceVisibility) * saturate(_BaseTint.a) <= 1e-4)
                {
                    output.positionCS = float4(2.0, 2.0, 2.0, 1.0);
                }

                return output;
            }

            float SamplePerceptualRoughness(float2 baseUV)
            {
                float2 roughnessUV = TRANSFORM_TEX(baseUV, _RoughnessMap);
                float2 roughnessDdx = ddx(roughnessUV);
                float2 roughnessDdy = ddy(roughnessUV);
                float roughnessMap = 0.0;
                [branch]
                if (_RoughnessMapStrength > 0.0)
                {
                    roughnessMap = tex2Dgrad(_RoughnessMap, roughnessUV, roughnessDdx, roughnessDdy).r;
                }
                return GlassComputePerceptualRoughness(_Smoothness, roughnessMap, _RoughnessMapStrength);
            }

            float ComputeFaceEdgeDistortionGain(float edgeMask, float frontDepth)
            {
                float edgeBlend = saturate(edgeMask);
                float faceEdgeDistortion = lerp(_DistortionFace, _DistortionEdge, edgeBlend);
                float depthSafe = max(frontDepth, 1e-3);
                float minimumDistortion = max(_RefractionStrength * 2.0, 0.0);
                return max(faceEdgeDistortion, minimumDistortion) / depthSafe;
            }

            float ComposeRefractionScale(float baseRefractionScale, float distortionGain)
            {
                return min(baseRefractionScale + max(distortionGain, 0.0), 0.25);
            }

            float4 fragBack(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float overlayStrength = saturate(_BackfaceVisibility) * saturate(_BaseTint.a);
                if (overlayStrength <= 1e-4)
                {
                    return float4(0.0, 0.0, 0.0, 0.0);
                }

                float3 viewDirWS = normalize(UnityWorldSpaceViewDir(input.worldPos));
                float2 normalUV = TRANSFORM_TEX(input.uv, _NormalMap);
                float3 normalWS = ComputeNormalWS(input, normalUV);
                float perceptualRoughness = SamplePerceptualRoughness(input.uv);

                float2 screenUV = ClampSceneUV(GlassGetScreenUV(input.screenPos));
                float frontDepth = max(-mul(UNITY_MATRIX_V, float4(input.worldPos, 1.0)).z, 0.0);

                // Baked geometry thickness when available: pane faces get their thickness, cut edges their width.
                float hasBakedThickness = step(1e-6, input.bakedThickness);
                float baseThickness = lerp(_FallbackThickness, input.bakedThickness, hasBakedThickness);
                float approxThickness = baseThickness;
                if (_FallbackUseAngle > 0.5)
                {
                    approxThickness = GlassComputeApproxThickness(baseThickness, normalWS, viewDirWS, _MinViewDot);
                }

                approxThickness = approxThickness * _ThicknessScale + _ThicknessBias;
                approxThickness = clamp(approxThickness, 0.0, _MaxThickness);

                float nearFade = 1.0;
                if (_NearFadeDistance > 1e-4)
                {
                    nearFade = saturate(frontDepth / _NearFadeDistance);
                }
                approxThickness *= nearFade;

                float maxThicknessSafe = max(_MaxThickness, 1e-5);
                float normalizedThickness = saturate(GlassNormalizeThickness(approxThickness, maxThicknessSafe));
                GlassApplyRain(input, normalWS, perceptualRoughness, 1.0);

                float distortionEdgeMask = 0.0;
                [branch]
                if (_DistortionEdge != _DistortionFace)
                {
                    distortionEdgeMask = GlassComputeValidatedDistortionEdgeMask(input.barycentric, input.edgeKeep);
                }
                float baseRefractionScale = ComputeBaseRefractionScale(normalizedThickness, nearFade, screenUV);
                float distortionGain = ComputeFaceEdgeDistortionGain(distortionEdgeMask, frontDepth);
                float refractionScale = ComposeRefractionScale(baseRefractionScale, distortionGain);

                // Back faces point away from the viewer; flip so the same entry/exit trace applies.
                float2 refractedUV;
                float4 refractedGrabPos;
                float2 refractionOffset = GlassComputeRefraction(
                    input.worldPos,
                    viewDirWS,
                    -normalWS,
                    -normalize(input.normalWS),
                    approxThickness * GlassViewToRefractedPath(abs(dot(normalWS, viewDirWS)), _IOR),
                    refractionScale,
                    frontDepth,
                    screenUV,
                    input.grabPos,
                    refractedUV,
                    refractedGrabPos);

                float3 sceneColorBase;
                if (_UseChromaticAberration > 0.5)
                {
                    sceneColorBase = SampleChromaticSceneColor(refractedUV, refractedGrabPos, refractionOffset, baseRefractionScale);
                }
                else
                {
                    sceneColorBase = SampleSceneColor(refractedUV, refractedGrabPos);
                }

                float3 sceneColor = sceneColorBase;
                if (_UseRefractionBlur > 0.5)
                {
                    float blurDriver = GlassComputeRefractionBlurDriver(
                        perceptualRoughness,
                        normalizedThickness,
                        _RefractionBlurRoughnessInfluence,
                        _RefractionBlurThicknessInfluence);

                    float blurBlend = saturate(_RefractionBlurStrength * blurDriver);
                    float blurContribution = blurBlend * overlayStrength;
                    if (blurContribution > 0.01)
                    {
                        float minScreenDim = min(_ScreenParams.x, _ScreenParams.y);
                        float aspect = _ScreenParams.y / max(_ScreenParams.x, 1.0);
                        float blurStep = GlassComputeRefractionBlurStepUV(
                            blurDriver,
                            frontDepth,
                            _RefractionBlurScale,
                            aspect,
                            UNITY_MATRIX_P._m11);

                        blurStep *= max(_RefractionBlurStrength, 0.0);
                        float blurRadius = GlassClampBlurRadiusUVByPixelRadius(
                            blurStep * (float)GLASS_REFRACTION_BLUR_RADIUS,
                            _RefractionBlurMaxPixels,
                            minScreenDim);

                        if (abs(blurRadius) > 1e-5)
                        {
                            float blurRadiusPixels = abs(blurRadius) * minScreenDim;
                            if (blurRadiusPixels > 0.35)
                            {
                                float2 blurRadiusUV = blurRadiusPixels / max(_ScreenParams.xy, float2(1.0, 1.0));
                                float3 blurredSceneColor = SampleRefractionBlurredSceneColor(
                                    refractedUV,
                                    refractedGrabPos,
                                    blurRadiusUV,
                                    blurRadiusPixels,
                                    _RefractionBlurKernelSigma,
                                    0.0);
                                sceneColor = lerp(sceneColorBase, blurredSceneColor, blurBlend);
                            }
                        }
                    }
                }

                float3 sigma = GlassSigmaFromReferenceColor(_TransmissionColorAtDistance.rgb, _ReferenceDistance);
                sigma *= saturate(_TransmittanceInfluence);
                float3 transmittance = GlassComputeTransmittance(sigma, approxThickness);

                float3 finalColor = sceneColor * transmittance;

                float alpha = saturate(overlayStrength);
                return float4(finalColor, alpha);
            }
            ENDCG
        }
    }

    CustomEditor "GlassShaderGUI"
    Fallback "Transparent/VertexLit"
}
