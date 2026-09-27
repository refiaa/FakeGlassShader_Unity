#ifndef GLASS_FORWARD_PASS_INCLUDED
#define GLASS_FORWARD_PASS_INCLUDED

// FORWARD_BASE pass body (front faces): thickness, refraction, reflection and composition.
#if defined(GLASS_SHARED_GRAB)
// Shared-grab variant: every object reads one screen copy taken before the first glass (see GlassComposeOutput).
#define _GrabTexture _GlassSharedGrabTexture
#endif

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
float _Scattering;
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
float _AbbeNumber;
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

    // An unassigned slot holds Unity's 4x4 default (black; linear depth 0 = invalid), and no screen-space
    // depth target is that small: skip the 5 fetches whenever they could only produce "invalid".
    // The exact thickness only matters when valid (its lerp weight is 0 otherwise), so it is built in the branch.
    float exactValid = 0.0;
    float exactThickness = 0.0;
    bool backDepthUnassigned = _UseUdonStereoTextures < 0.5 && _BackDepthTex_TexelSize.z <= 4.0 && _BackDepthIsLinear > 0.5;
    [branch]
    if (_UseBackDepthTexture > 0.5 && !backDepthUnassigned)
    {
        float backDepth = SampleBackDepthRobust(screenUV, frontDepth, exactValid);
        // Back-front eye depth measures along the camera axis; convert it to the view-ray length.
        float viewRayScale = distance(input.worldPos, _WorldSpaceCameraPos) / max(frontDepth, 1e-4);
        exactThickness = (backDepth - frontDepth) * viewRayScale * _ThicknessScale + _ThicknessBias;
    }
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
    float scattering = max(_Scattering, 0.0);
    sigma += scattering;
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
    float3 geomNormalWS = normalize(input.normalWS);
    float2 refractionOffset = GlassComputeRefraction(
        input.worldPos,
        viewDirWS,
        normalWS,
        geomNormalWS,
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
        sceneColorBase = SampleDispersedSceneColor(
            input.worldPos,
            viewDirWS,
            normalWS,
            geomNormalWS,
            refractionPath,
            refractionScale,
            frontDepth,
            screenUV,
            input.grabPos,
            refractionOffset,
            refractedUV,
            refractedGrabPos);
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

    // ForwardBase only ever gets the main directional light (w = 0), whose direction Unity supplies
    // normalized (or zero when there is none).
    float3 lightDirWS = _WorldSpaceLightPos0.xyz;
    float3 halfDirWS = normalize(lightDirWS + viewDirWS);
    float nDotL = saturate(dot(normalWS, lightDirWS));
    float nDotH = saturate(dot(normalWS, halfDirWS));
    float vDotH = saturate(dot(viewDirWS, halfDirWS));
    float D = GlassDistributionGGX(nDotH, roughnessLinear);
    float V = GlassVisibilitySmith(nDotL, nDotV, roughnessLinear);
    float3 Fh = GlassSchlickFresnelColor(vDotH, specularColor);
    float3 specularBrdf = D * V * Fh;
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
    // exp(-sigma * 2L) = T^2, already at hand.
    reflectionColor *= lerp(1.0.xxx, transmittanceSq, saturate(_ReflectionAbsorption));

    // Same slab sum with the grazing-relaxed reflectance, so the weight stays <= 1.
    float3 transmissionLoss = frontReflectance * (1.0 - saturate(_TransmissionAtGrazing));
    float3 transmissionInterreflection = 1.0 / max(1.0.xxx - transmissionLoss * transmissionLoss * transmittanceSq, 1e-4);
    float3 transmissionWeight = (1.0 - transmissionLoss) * (1.0 - transmissionLoss) * transmissionInterreflection;
    transmissionWeight *= lerp(1.0, oneMinusReflectivity, metallic);
    float3 inScattered = 0.0.xxx;
    [branch]
    if (scattering > 0.0)
    {
        inScattered = GlassComputeInScattering(scattering, sigma, transmittance);
    }
    float3 composedColor = reflectionColor + (sceneColor * transmittance + inScattered) * transmissionWeight;
    float3 finalColor = lerp(sceneColor, composedColor, saturate(_BaseTint.a));
    // How much of the (refracted) scene behind the color carries; used by the shared-grab composition.
    float3 sceneShare = lerp(1.0.xxx, transmittance * transmissionWeight, saturate(_BaseTint.a));

    [branch]
    if (_UseMeshEdge > 0.5)
    {
        float meshEdgeMask = GlassComputeValidatedMeshEdgeMask(input.barycentric, input.edgeKeep);
        float edgeWeight = saturate(meshEdgeMask * _MeshEdgeColor.a * _MeshEdgeIntensity);
        finalColor = lerp(finalColor, _MeshEdgeColor.rgb, edgeWeight);
        sceneShare *= 1.0 - edgeWeight;
    }

    #if defined(_DEBUGVIEW_THICKNESS)
        finalColor = GlassHeatColor(normalizedThickness);
        sceneShare = 0.0;
    #elif defined(_DEBUGVIEW_TRANSMITTANCE)
        finalColor = transmittance;
        sceneShare = 0.0;
    #elif defined(_DEBUGVIEW_FRESNEL)
        finalColor = fresnel.xxx;
        sceneShare = 0.0;
    #endif

    return GlassComposeOutput(finalColor, sceneShare, screenUV, input.grabPos);
}

#endif
