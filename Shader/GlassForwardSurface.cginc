#ifndef GLASS_FORWARD_SURFACE_INCLUDED
#define GLASS_FORWARD_SURFACE_INCLUDED

inline float GlassApplyMapStrength(float baseValue, float mapValue, float strength01)
{
    return saturate(lerp(baseValue, saturate(mapValue), saturate(strength01)));
}

inline float GlassDistributionGGX(float nDotH, float roughnessLinear)
{
    float a = max(roughnessLinear, 0.002);
    float a2 = a * a;
    float d = nDotH * nDotH * (a2 - 1.0) + 1.0;
    return a2 / max(UNITY_PI * d * d, 1e-6);
}

inline float GlassGeometrySchlickGGX(float nDotX, float roughnessLinear)
{
    float a = max(roughnessLinear, 0.002);
    float k = (a + 1.0);
    k = (k * k) * 0.125;
    return nDotX / max(nDotX * (1.0 - k) + k, 1e-6);
}

inline float GlassGeometrySmith(float nDotL, float nDotV, float roughnessLinear)
{
    return GlassGeometrySchlickGGX(nDotL, roughnessLinear) * GlassGeometrySchlickGGX(nDotV, roughnessLinear);
}

inline void SampleSurfaceParameters(float2 baseUV, out float perceptualRoughness, out float roughnessLinear, out float metallic)
{
    float2 roughnessUV = TRANSFORM_TEX(baseUV, _RoughnessMap);
    float2 metallicUV = TRANSFORM_TEX(baseUV, _MetallicMap);

    // Strength 0 returns the base value whatever the map holds, so the fetch is skipped.
    // Derivatives are taken outside the branch; tex2Dgrad with them equals tex2D.
    float4 roughnessDeriv = float4(ddx(roughnessUV), ddy(roughnessUV));
    float4 metallicDeriv = float4(ddx(metallicUV), ddy(metallicUV));
    float roughnessMap = 0.0;
    float metallicMap = 0.0;
    [branch]
    if (_RoughnessMapStrength > 0.0)
    {
        roughnessMap = tex2Dgrad(_RoughnessMap, roughnessUV, roughnessDeriv.xy, roughnessDeriv.zw).r;
    }
    [branch]
    if (_MetallicMapStrength > 0.0)
    {
        metallicMap = tex2Dgrad(_MetallicMap, metallicUV, metallicDeriv.xy, metallicDeriv.zw).r;
    }
    float basePerceptualRoughness = saturate(1.0 - _Smoothness);

    perceptualRoughness = GlassApplyMapStrength(basePerceptualRoughness, roughnessMap, _RoughnessMapStrength);
    roughnessLinear = max(perceptualRoughness * perceptualRoughness, 0.003);
    metallic = GlassApplyMapStrength(0.0, metallicMap, _MetallicMapStrength);
}

inline float3 SampleEnvironmentReflections(float3 reflectionDirWS, float perceptualRoughness)
{
    float envPerceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
    float iblLod = envPerceptualRoughness * 6.0;
    half4 encodedIbl = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectionDirWS, iblLod);
    float3 envReflection = DecodeHDR(encodedIbl, unity_SpecCube0_HDR);

    if (unity_SpecCube0_BoxMin.w < 0.99999)
    {
        half4 encodedIbl1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, reflectionDirWS, iblLod);
        float3 envReflection1 = DecodeHDR(encodedIbl1, unity_SpecCube1_HDR);
        envReflection = lerp(envReflection1, envReflection, unity_SpecCube0_BoxMin.w);
    }

    return envReflection;
}

inline float GlassComputeMeshEdgeMask(float3 barycentric, float3 edgeKeep)
{
    float edge = GlassComputeMeshEdgeRaw(barycentric, edgeKeep);
    float threshold = saturate(_MeshEdgeThreshold);
    return saturate((edge - threshold) / max(1.0 - threshold, 1e-4));
}

inline float GlassComputeValidatedMeshEdgeMask(float3 barycentric, float3 edgeKeep)
{
    float edgeDataValid = GlassComputeEdgeDataValidity(barycentric);
    return GlassComputeMeshEdgeMask(barycentric, edgeKeep) * edgeDataValid;
}

#endif
