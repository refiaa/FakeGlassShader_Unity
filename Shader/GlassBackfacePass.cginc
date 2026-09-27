#ifndef GLASS_BACKFACE_PASS_INCLUDED
#define GLASS_BACKFACE_PASS_INCLUDED

// BACKFACE_OVERLAY pass body (back faces): refracted, absorbed view of the far side.
#if defined(GLASS_SHARED_GRAB)
// Shared-grab variant: every object reads one screen copy taken before the first glass (see GlassComposeOutput).
#define _GrabTexture _GlassSharedGrabTexture
#endif

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
float _Scattering;
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
float _AbbeNumber;
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
        return GlassEmptyOverlayOutput();
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
    float3 facingNormalWS = -normalWS;
    float3 facingGeomNormalWS = -normalize(input.normalWS);
    float refractionPath = approxThickness * GlassViewToRefractedPath(abs(dot(normalWS, viewDirWS)), _IOR);
    float2 refractionOffset = GlassComputeRefraction(
        input.worldPos,
        viewDirWS,
        facingNormalWS,
        facingGeomNormalWS,
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
            facingNormalWS,
            facingGeomNormalWS,
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
    sigma += max(_Scattering, 0.0);
    float3 transmittance = GlassComputeTransmittance(sigma, approxThickness);

    float3 finalColor = sceneColor * transmittance;

    float alpha = saturate(overlayStrength);
    return GlassComposeOverlayOutput(finalColor, alpha, transmittance, screenUV, input.grabPos);
}

#endif
