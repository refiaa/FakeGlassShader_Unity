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
    // GrabPass targets carry no mips: LOD 0 equals tex2D without derivative work (also valid inside loops).
    return tex2Dlod(_GrabTexture, float4(uv, 0.0, 0.0)).rgb;
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
            return tex2Dlod(_GrabTexture, float4(ClampSceneUV(uv), 0.0, 0.0)).rgb;
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

inline float3 SampleSceneColorOffset(float2 baseUV, float4 baseGrabPos, float2 uvOffset)
{
    float2 uv = ClampSceneUV(baseUV + uvOffset);
    float4 grabPos = baseGrabPos;
    grabPos.xy += uvOffset * baseGrabPos.w;
    return SampleSceneColor(uv, grabPos);
}

// sqrt(i + 0.5) for the Vogel taps; the radius of tap i is this times sqrt(1 / tapCount).
static const float kVogelSqrtIndex[14] = { 0.7071068, 1.2247449, 1.5811388, 1.8708287, 2.1213203, 2.3452079, 2.5495098, 2.7386128, 2.9154759, 3.0822070, 3.2403703, 3.3911650, 3.5355339, 3.6742346 };

inline float GlassInterleavedGradientNoise(float2 pixelCoord)
{
    return frac(52.9829189 * frac(dot(pixelCoord, float2(0.06711056, 0.00583715))));
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

    float3 accum = 0.0.xxx;
    float weightSum = 0.0;

    // Deterministic phase jitter suppresses visible rings/stripes without temporal flicker.
    float2 kernelTileCoord = floor(baseUV * _ScreenParams.xy * 0.5 + 0.5);
    float kernelNoise = GlassInterleavedGradientNoise(kernelTileCoord);
    float kernelPhase = kernelNoise * 6.28318531;

    // Center (radius 0: Gaussian 1, bias 1)
    AccumulateRefractionBlurTap(baseUV, baseGrabPos, blurRadiusUV, float2(0.0, 0.0), 1.0, accum, weightSum);

    // Vogel disk by recurrence instead of per-tap trigonometry:
    // - tap i sits at angle (i + 0.5) * golden + phase, so its direction is the previous one times the
    //   unit complex number (cos g, sin g): one sincos per pixel;
    // - its radius^2 = (i + 0.5) / N is linear in i, so the Gaussian exp(-(R r)^2 / (2 sigma^2)) is a geometric
    //   series: one exp per pixel. Weight = Gaussian * (1 - 0.12 r), the former lerp(1, 0.88, r).
    const float kGoldenAngle = 2.39996323;
    const float2 kGoldenRotation = float2(-0.7373689, 0.6754903);
    float invTapCount = 1.0 / tapCountF;
    float radiusScale = sqrt(invTapCount);
    float sigmaSafe = max(kernelSigma, 0.35);
    float blurRadiusTaps = (float)GLASS_REFRACTION_BLUR_RADIUS;
    float gaussianStep = exp(-blurRadiusTaps * blurRadiusTaps * invTapCount * 0.5 / (sigmaSafe * sigmaSafe));
    float gaussian = sqrt(gaussianStep);
    float2 direction;
    sincos(0.5 * kGoldenAngle + kernelPhase, direction.y, direction.x);

    const int kMaxVogelTaps = 14;
    [loop]
    for (int i = 0; i < kMaxVogelTaps; i++)
    {
        if (i >= tapCount) break;
        float r = kVogelSqrtIndex[i] * radiusScale;
        AccumulateRefractionBlurTap(baseUV, baseGrabPos, blurRadiusUV, direction * r, gaussian * (1.0 - 0.12 * r), accum, weightSum);
        direction = float2(
            direction.x * kGoldenRotation.x - direction.y * kGoldenRotation.y,
            direction.x * kGoldenRotation.y + direction.y * kGoldenRotation.x);
        gaussian *= gaussianStep;
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
inline void GlassTraceRefraction(
    float ior,
    float3 worldPos,
    float3 viewDirWS,
    float3 normalWS,
    float3 geomNormalWS,
    float pathLength,
    float refractionScale,
    float frontDepth,
    float2 screenUV,
    float4 grabPos,
    out float2 uvOffset,
    out float2 grabOffset)
{
    ior = max(ior, 1.0);
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

    uvOffset = 0.0.xx;
    grabOffset = 0.0.xx;
    if (sampleCS.w > 1e-4)
    {
        // Screen and grab positions share the clip-space w: one reciprocal serves both.
        float invW = 1.0 / sampleCS.w;
        uvOffset = GlassScreenUVFromPos(ComputeScreenPos(sampleCS), invW) - screenUV;
        grabOffset = ComputeGrabScreenPos(sampleCS).xy * invW - grabPos.xy / max(grabPos.w, 1e-5);
    }
}

// Traces the d-line (green) ray, which sets the refracted sample position for all channels.
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
    float2 uvOffset;
    float2 grabOffset;
    GlassTraceRefraction(_IOR, worldPos, viewDirWS, normalWS, geomNormalWS, pathLength, refractionScale, frontDepth, screenUV, grabPos, uvOffset, grabOffset);

    refractedUV = ClampSceneUV(screenUV + uvOffset);
    refractedGrabPos = grabPos;
    refractedGrabPos.xy += grabOffset * grabPos.w;
    return uvOffset;
}

// Limits a channel's separation from green to _ChromaticAberration pixels (a safety cap; physical values rarely reach it).
inline float GlassDispersionCapScale(float2 separationUV)
{
    float2 separationPixels = separationUV * _ScreenParams.xy;
    float pixelsSq = dot(separationPixels, separationPixels);
    // Compare squared lengths; the square root is only needed when the cap applies.
    return pixelsSq > _ChromaticAberration * _ChromaticAberration ? _ChromaticAberration * rsqrt(max(pixelsSq, 1e-10)) : 1.0;
}

// Physical dispersion: B is traced with its own index (Abbe number) through the same path as G, so fringes
// follow the actual bending and vanish where light is not bent. The shift is linear in the index to within
// O(dn^2) (dn ~ 0.006), and Cauchy fixes nR - nd = -0.4301695 * (nF - nd) for every glass, so R needs no trace.
inline float3 SampleDispersedSceneColor(
    float3 worldPos,
    float3 viewDirWS,
    float3 normalWS,
    float3 geomNormalWS,
    float pathLength,
    float refractionScale,
    float frontDepth,
    float2 screenUV,
    float4 grabPos,
    float2 refractionOffset,
    float2 refractedUV,
    float4 refractedGrabPos)
{
    const float dispersionRatioR = -0.4301695; // (1/lC^2 - 1/ld^2) / (1/lF^2 - 1/ld^2)
    float3 dispersedIor = GlassDispersedIor(_IOR, _AbbeNumber);
    float2 uvOffsetB;
    float2 grabOffsetB;
    GlassTraceRefraction(dispersedIor.b, worldPos, viewDirWS, normalWS, geomNormalWS, pathLength, refractionScale, frontDepth, screenUV, grabPos, uvOffsetB, grabOffsetB);

    float2 grabOffsetG = (refractedGrabPos.xy - grabPos.xy) / max(grabPos.w, 1e-5);
    float2 separationB = uvOffsetB - refractionOffset;
    float2 grabSeparationB = grabOffsetB - grabOffsetG;
    float2 separationR = separationB * dispersionRatioR;
    float capR = GlassDispersionCapScale(separationR);
    float capB = GlassDispersionCapScale(separationB);

    float4 grabPosR = refractedGrabPos;
    float4 grabPosB = refractedGrabPos;
    grabPosR.xy += grabSeparationB * (dispersionRatioR * capR * refractedGrabPos.w);
    grabPosB.xy += grabSeparationB * (capB * refractedGrabPos.w);

    float3 sceneColor;
    sceneColor.r = SampleSceneColor(ClampSceneUV(refractedUV + separationR * capR), grabPosR).r;
    sceneColor.g = SampleSceneColor(refractedUV, refractedGrabPos).g;
    sceneColor.b = SampleSceneColor(ClampSceneUV(refractedUV + separationB * capB), grabPosB).b;
    return sceneColor;
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

// Final output. Per-object GrabPass: the color as is (Blend One Zero).
// Shared GrabPass: the copy lacks transparents drawn after it (e.g. glass behind this one) while the target holds
// them. With Blend One SrcAlpha the hardware adds share * (target - grab) back, where share is how much of the scene
// behind the color carries (scalar: the smallest channel). Where nothing transparent is behind, target == grab and
// the result equals the per-object one exactly.
inline float4 GlassComposeOutput(float3 color, float3 sceneShare, float2 screenUV, float4 grabPos)
{
#if defined(GLASS_SHARED_GRAB)
    float share = min(sceneShare.r, min(sceneShare.g, sceneShare.b));
    return float4(color - share * SampleSceneColor(screenUV, grabPos), share);
#else
    return float4(color, 1.0);
#endif
}

// Back-face overlay output. Per-object: alpha-blended (Blend SrcAlpha OneMinusSrcAlpha).
// Shared: the same blend written for Blend One SrcAlpha, plus the share * (target - grab) correction.
inline float4 GlassComposeOverlayOutput(float3 color, float alpha, float3 sceneShare, float2 screenUV, float4 grabPos)
{
#if defined(GLASS_SHARED_GRAB)
    float share = min(sceneShare.r, min(sceneShare.g, sceneShare.b));
    return float4(alpha * (color - share * SampleSceneColor(screenUV, grabPos)), 1.0 - alpha * (1.0 - share));
#else
    return float4(color, alpha);
#endif
}

// An overlay that leaves the target untouched under either blend mode.
inline float4 GlassEmptyOverlayOutput()
{
#if defined(GLASS_SHARED_GRAB)
    return float4(0.0, 0.0, 0.0, 1.0);
#else
    return float4(0.0, 0.0, 0.0, 0.0);
#endif
}

#endif
