#ifndef GLASS_PASS_SHARED_INCLUDED
#define GLASS_PASS_SHARED_INCLUDED

inline float2 ClampSceneUV(float2 uv)
{
    float padding = saturate(_UVClamp);
    return clamp(uv, padding, 1.0 - padding);
}

inline float2 GetScreenTexelSize()
{
    return 1.0 / max(_ScreenParams.xy, float2(1.0, 1.0));
}

inline float3 SampleStereoSceneColor(float2 uv)
{
    return GlassIsStereoEyeRight() ? tex2D(_UdonGlassSceneColorR, uv).rgb : tex2D(_UdonGlassSceneColorL, uv).rgb;
}

inline float3 SampleGrabColor(float4 grabPos)
{
    float invW = 1.0 / max(grabPos.w, 1e-5);
    float2 uv = ClampSceneUV(grabPos.xy * invW);
    return tex2D(_GrabTexture, uv).rgb;
}

inline float3 SampleSceneColor(float2 uv, float4 grabPos)
{
    if (_UseSceneColorTexture > 0.5)
    {
        if (_UseUdonStereoTextures > 0.5)
        {
            return SampleStereoSceneColor(uv);
        }
        return tex2D(_SceneColorTex, uv).rgb;
    }

    if (_UseGrabPassFallback > 0.5)
    {
        if (grabPos.w <= 1e-5)
        {
            return tex2D(_GrabTexture, ClampSceneUV(uv)).rgb;
        }
        return SampleGrabColor(grabPos);
    }

    return 0.0.xxx;
}

inline float3 ComputeNormalWS(Varyings input, float2 normalUV)
{
    float3 normalTS = GlassUnpackNormalTS(_NormalMap, normalUV, _NormalScale);
    float tangentLen2 = dot(input.tangentWS, input.tangentWS);
    float3 normalWS = normalize(input.normalWS);

    if (tangentLen2 > 1e-5)
    {
        normalWS = GlassTransformTangentToWorld(normalTS, input.tangentWS, input.bitangentWS, input.normalWS);
    }

    return normalWS;
}

inline float3 SampleChromaticSceneColor(float2 refractedUV, float4 refractedGrabPos, float2 refractionOffset, float chromaScale)
{
    float2 pixelSize = GetScreenTexelSize();
    float2 chromaDir = normalize(refractionOffset + float2(1e-6, 0.0));
    // Dispersion scales with how much the light is actually bent; unbent light shows no fringes.
    float chromaFade = saturate(min(chromaScale, length(refractionOffset)) / max(_RefractionStrength, 1e-5));
    float2 chromaOffset = chromaDir * (_ChromaticAberration * pixelSize * chromaFade);

    float2 uvR = ClampSceneUV(refractedUV + chromaOffset);
    float2 uvB = ClampSceneUV(refractedUV - chromaOffset);
    float4 grabPosR = refractedGrabPos;
    float4 grabPosB = refractedGrabPos;
    grabPosR.xy += chromaOffset * grabPosR.w;
    grabPosB.xy -= chromaOffset * grabPosB.w;

    float3 sceneColor;
    sceneColor.r = SampleSceneColor(uvR, grabPosR).r;
    sceneColor.g = SampleSceneColor(refractedUV, refractedGrabPos).g;
    sceneColor.b = SampleSceneColor(uvB, grabPosB).b;
    return sceneColor;
}

inline float3 SampleSceneColorOffset(float2 baseUV, float4 baseGrabPos, float2 uvOffset)
{
    float2 uv = ClampSceneUV(baseUV + uvOffset);
    float4 grabPos = baseGrabPos;
    grabPos.xy += uvOffset * baseGrabPos.w;
    return SampleSceneColor(uv, grabPos);
}

inline float GlassComputeBlurTapWeight(float normalizedRadius, float kernelSigma)
{
    float clampedRadius = saturate(normalizedRadius);
    float gaussian = GlassGaussianWeight(clampedRadius * (float)GLASS_REFRACTION_BLUR_RADIUS, kernelSigma);
    float centerBias = lerp(1.0, 0.88, clampedRadius);
    return gaussian * centerBias;
}

inline float GlassInterleavedGradientNoise(float2 pixelCoord)
{
    return frac(52.9829189 * frac(dot(pixelCoord, float2(0.06711056, 0.00583715))));
}

inline float2 GlassVogelDiskOffset(int sampleIndex, float sampleCount, float phase)
{
    const float kGoldenAngle = 2.39996323;
    float fi = (float)sampleIndex + 0.5;
    float r = sqrt(fi / max(sampleCount, 1.0));
    float angle = fi * kGoldenAngle + phase;
    float sinA;
    float cosA;
    sincos(angle, sinA, cosA);
    return float2(cosA, sinA) * r;
}

inline void AccumulateRefractionBlurTap(
    float2 baseUV,
    float4 baseGrabPos,
    float2 blurRadiusUV,
    float2 normalizedOffset,
    float weight,
    inout float3 accum,
    inout float weightSum)
{
    float2 uvOffset = blurRadiusUV * normalizedOffset;
    accum += SampleSceneColorOffset(baseUV, baseGrabPos, uvOffset) * weight;
    weightSum += weight;
}

inline float3 SampleRefractionBlurredSceneColor(
    float2 baseUV,
    float4 baseGrabPos,
    float2 blurRadiusUV,
    float blurRadiusPixels,
    float kernelSigma,
    float highQuality)
{
    if (blurRadiusPixels <= 0.35)
    {
        return SampleSceneColor(baseUV, baseGrabPos);
    }

    int tapCount = 6;
    [branch]
    if (blurRadiusPixels >= 0.75) tapCount = 10;
    [branch]
    if (highQuality > 0.5 && blurRadiusPixels >= 1.20) tapCount = 14;
    float tapCountF = (float)tapCount;

    float wCenter = GlassComputeBlurTapWeight(0.0, kernelSigma);
    float3 accum = 0.0.xxx;
    float weightSum = 0.0;

    // Deterministic phase jitter suppresses visible rings/stripes without temporal flicker.
    float2 kernelTileCoord = floor(baseUV * _ScreenParams.xy * 0.5 + 0.5);
    float kernelNoise = GlassInterleavedGradientNoise(kernelTileCoord);
    float kernelPhase = kernelNoise * 6.28318531;

    // Center
    AccumulateRefractionBlurTap(baseUV, baseGrabPos, blurRadiusUV, float2(0.0, 0.0), wCenter, accum, weightSum);

    const int kMaxVogelTaps = 14;
    [loop]
    for (int i = 0; i < kMaxVogelTaps; i++)
    {
        if (i >= tapCount) break;
        float2 sampleOffset = GlassVogelDiskOffset(i, tapCountF, kernelPhase);
        float weight = GlassComputeBlurTapWeight(length(sampleOffset), kernelSigma);
        AccumulateRefractionBlurTap(baseUV, baseGrabPos, blurRadiusUV, sampleOffset, weight, accum, weightSum);
    }

    return accum / max(weightSum, 1e-5);
}

inline float GlassComputeEdgeDataValidity(float3 barycentric)
{
    float barySum = barycentric.x + barycentric.y + barycentric.z;
    float baryMin = min(barycentric.x, min(barycentric.y, barycentric.z));
    float baryMax = max(barycentric.x, max(barycentric.y, barycentric.z));
    float edgeDataValid = 1.0 - step(0.01, abs(barySum - 1.0));
    edgeDataValid *= step(-0.001, baryMin) * step(baryMax, 1.001);
    return edgeDataValid;
}

inline float GlassComputeMeshEdgeRaw(float3 barycentric, float3 edgeKeep)
{
    float widthPx = max(_MeshEdgeWidth, 0.0);
    float softnessPx = max(_MeshEdgeSoftness, 0.001);
    float3 fw = max(fwidth(barycentric), 1e-5.xxx);
    float3 edgeLo = fw * widthPx;
    float3 edgeHi = edgeLo + fw * softnessPx;
    float3 edge3 = 1.0 - smoothstep(edgeLo, edgeHi, barycentric);
    edge3 *= saturate(edgeKeep);
    return max(edge3.x, max(edge3.y, edge3.z));
}

inline float GlassComputeValidatedDistortionEdgeMask(float3 barycentric, float3 edgeKeep)
{
    float edgeDataValid = GlassComputeEdgeDataValidity(barycentric);
    float rawEdge = GlassComputeMeshEdgeRaw(barycentric, edgeKeep) * edgeDataValid;
    return saturate(sqrt(saturate(rawEdge)));
}

// Traces the view ray through the glass: Snell refraction on entry, `pathLength` inside, refraction again on exit.
// The exit surface is parallel to the geometric surface (thin pane) or a sphere with the same chord (solid).
// The exit point is projected exactly (physical lateral shift); the exit deviation is carried a virtual distance
// chosen so that refractionScale stays a screen UV offset per unit of deviation.
inline float2 GlassComputeRefraction(
    float3 worldPos,
    float3 viewDirWS,
    float3 normalWS,
    float3 geomNormalWS,
    float pathLength,
    float refractionScale,
    float frontDepth,
    float2 screenUV,
    float4 grabPos,
    out float2 refractedUV,
    out float4 refractedGrabPos)
{
    float ior = max(_IOR, 1.0);
    float path = max(pathLength, 0.0);
    float3 incident = -viewDirWS;
    float3 inside = GlassRefractDirection(incident, normalWS, 1.0 / ior);
    float3 exitPoint = worldPos + inside * path;

    float3 exitNormal = geomNormalWS;
    if (_RefractionModel > 0.5)
    {
        float cosInside = max(abs(dot(inside, geomNormalWS)), 1e-3);
        float radius = max(path / (2.0 * cosInside), 1e-4);
        float3 center = worldPos - geomNormalWS * radius;
        exitNormal = normalize(exitPoint - center);
    }

    float3 outDir = GlassRefractDirection(inside, exitNormal, ior);
    float virtualDistance = max(refractionScale, 0.0) * 2.0 * frontDepth / max(abs(UNITY_MATRIX_P._m11), 1e-4);
    float4 sampleCS = mul(UNITY_MATRIX_VP, float4(exitPoint + (outDir - incident) * virtualDistance, 1.0));

    float2 uvOffset = 0.0.xx;
    float2 grabOffset = 0.0.xx;
    if (sampleCS.w > 1e-4)
    {
        uvOffset = GlassGetScreenUV(ComputeScreenPos(sampleCS)) - screenUV;
        float4 sampleGrab = ComputeGrabScreenPos(sampleCS);
        grabOffset = sampleGrab.xy / sampleGrab.w - grabPos.xy / max(grabPos.w, 1e-5);
    }

    refractedUV = ClampSceneUV(screenUV + uvOffset);
    refractedGrabPos = grabPos;
    refractedGrabPos.xy += grabOffset * grabPos.w;
    return uvOffset;
}

inline float ComputeBaseRefractionScale(float normalizedThickness, float nearFade, float2 screenUV)
{
    float refractionScale = _RefractionStrength * (0.25 + 0.75 * normalizedThickness);
    refractionScale *= nearFade;

    if (_ScreenEdgeFadePixels > 0.01)
    {
        float2 borderDistance01 = min(screenUV, 1.0 - screenUV);
        float minBorderDistance = min(borderDistance01.x, borderDistance01.y);
        float pixelDistance = minBorderDistance * min(_ScreenParams.x, _ScreenParams.y);
        float edgeFade = saturate(pixelDistance / _ScreenEdgeFadePixels);
        refractionScale *= edgeFade;
    }

    return refractionScale;
}

#endif
