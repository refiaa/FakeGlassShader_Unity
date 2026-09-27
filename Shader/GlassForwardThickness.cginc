#ifndef GLASS_FORWARD_THICKNESS_INCLUDED
#define GLASS_FORWARD_THICKNESS_INCLUDED

inline float SampleStereoBackDepth(float2 uv)
{
    return GlassIsStereoEyeRight() ? tex2D(_UdonGlassBackDepthR, uv).r : tex2D(_UdonGlassBackDepthL, uv).r;
}

inline float SampleBackDepthRaw(float2 uv)
{
    if (_UseUdonStereoTextures > 0.5)
    {
        return SampleStereoBackDepth(uv);
    }

    return tex2D(_BackDepthTex, uv).r;
}

inline float SampleBackDepth(float2 uv)
{
    float rawDepth = SampleBackDepthRaw(uv);

    if (_BackDepthIsLinear > 0.5)
    {
        return rawDepth;
    }

    return LinearEyeDepth(rawDepth);
}

inline float BackDepthIsValid(float backDepth, float frontDepth)
{
    return step(frontDepth + 1e-4, backDepth) * step(1e-5, backDepth);
}

inline void UpdateBestBackDepth(float depth, float valid, inout float bestDepth, inout float bestValid)
{
    if (valid > 0.5 && (bestValid < 0.5 || depth > bestDepth))
    {
        bestDepth = depth;
        bestValid = valid;
    }
}

inline void SampleAndUpdateBackDepth(float2 uv, float frontDepth, inout float bestDepth, inout float bestValid)
{
    float depth = SampleBackDepth(uv);
    float valid = BackDepthIsValid(depth, frontDepth);
    UpdateBestBackDepth(depth, valid, bestDepth, bestValid);
}

inline float SampleBackDepthRobust(float2 uv, float frontDepth, out float valid)
{
    float bestDepth = SampleBackDepth(uv);
    float bestValid = BackDepthIsValid(bestDepth, frontDepth);

    if (_DepthEdgeFixPixels > 0.01)
    {
        float2 texel = GetScreenTexelSize();
        float2 offset = texel * _DepthEdgeFixPixels;

        float2 uv1 = ClampSceneUV(uv + float2(offset.x, 0.0));
        float2 uv2 = ClampSceneUV(uv - float2(offset.x, 0.0));
        float2 uv3 = ClampSceneUV(uv + float2(0.0, offset.y));
        float2 uv4 = ClampSceneUV(uv - float2(0.0, offset.y));

        SampleAndUpdateBackDepth(uv1, frontDepth, bestDepth, bestValid);
        SampleAndUpdateBackDepth(uv2, frontDepth, bestDepth, bestValid);
        SampleAndUpdateBackDepth(uv3, frontDepth, bestDepth, bestValid);
        SampleAndUpdateBackDepth(uv4, frontDepth, bestDepth, bestValid);
    }

    valid = bestValid;
    return bestDepth;
}

inline float ComputeBoundsFallbackThickness(float3 worldPos, float3 rayDirWS, float3 boundsMinOS, float3 boundsMaxOS, out float confidence)
{
    float3 bMin = min(boundsMinOS, boundsMaxOS);
    float3 bMax = max(boundsMinOS, boundsMaxOS);

    float3 startOS = mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
    float3 dirOS = mul((float3x3)unity_WorldToObject, normalize(rayDirWS));

    float3 dirSign = lerp(-1.0.xxx, 1.0.xxx, step(0.0.xxx, dirOS));
    float3 smallMask = 1.0.xxx - step(1e-5.xxx, abs(dirOS));
    float3 safeDirOS = dirOS + dirSign * smallMask * 1e-5;
    float3 invDirOS = 1.0 / safeDirOS;

    startOS += normalize(safeDirOS) * 1e-4;

    float3 t0 = (bMin - startOS) * invDirOS;
    float3 t1 = (bMax - startOS) * invDirOS;
    float3 tMin = min(t0, t1);
    float3 tMax = max(t0, t1);

    float tNear = max(max(tMin.x, tMin.y), tMin.z);
    float tFar = min(min(tMax.x, tMax.y), tMax.z);

    // The box only describes this mesh when the shaded point lies on its boundary.
    // Points deep inside or outside it (object space not matching the bounds) get no weight.
    float span = max(tFar - tNear, 1e-5);
    confidence = 1.0 - smoothstep(0.02, 0.1, abs(tNear) / span);

    return max(0.0, tFar - max(tNear, 0.0));
}

#endif
