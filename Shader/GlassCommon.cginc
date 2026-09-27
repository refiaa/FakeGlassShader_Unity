#ifndef GLASS_COMMON_INCLUDED
#define GLASS_COMMON_INCLUDED

#include "UnityCG.cginc"

static const float GLASS_EPSILON = 1e-5;

inline float GlassSafePositive(float value)
{
    return max(value, GLASS_EPSILON);
}

inline float GlassSafeRcp(float value)
{
    return 1.0 / GlassSafePositive(abs(value));
}

inline float2 GlassGetScreenUV(float4 screenPos)
{
    float2 uv = screenPos.xy * GlassSafeRcp(screenPos.w);
#if UNITY_UV_STARTS_AT_TOP
    if (_ProjectionParams.x < 0.0)
    {
        uv.y = 1.0 - uv.y;
    }
#endif
    return uv;
}

inline float3 GlassSigmaFromReferenceColor(float3 transmittanceAtReference, float referenceDistance)
{
    float3 safeColor = max(transmittanceAtReference, float3(GLASS_EPSILON, GLASS_EPSILON, GLASS_EPSILON));
    float safeDistance = GlassSafePositive(referenceDistance);
    return -log(safeColor) / safeDistance;
}

inline float3 GlassComputeTransmittance(float3 sigma, float thickness)
{
    return exp(-sigma * max(thickness, 0.0));
}

inline float GlassNormalizeThickness(float thickness, float maxThickness)
{
    float safeMax = GlassSafePositive(maxThickness);
    return max(thickness, 0.0) / safeMax;
}

inline float GlassApplyTransmittanceCurve(float normalizedThickness, float curvePower)
{
    float x = max(normalizedThickness, 0.0);
    float p = max(curvePower, 1e-4);
    float shaped = pow(x, p);

    if (p <= 1.0)
    {
        return shaped;
    }

    // For p > 1, progressively boost thick regions so darkening accelerates with thickness.
    return shaped * (1.0 + (p - 1.0) * x);
}

inline float GlassComputeDepthTintBoost(float normalizedThickness, float strength, float curvePower)
{
    float x = saturate(normalizedThickness);
    float s = max(strength, 0.0);
    float p = max(curvePower, 1e-4);
    return 1.0 + s * pow(x, p);
}

inline float GlassOneMinusCosPow5(float cosTheta)
{
    float oneMinusCos = 1.0 - saturate(cosTheta);
    float oneMinusCos2 = oneMinusCos * oneMinusCos;
    return oneMinusCos2 * oneMinusCos2 * oneMinusCos;
}

inline float GlassSchlickFresnel(float cosTheta, float f0)
{
    float oneMinusCos5 = GlassOneMinusCosPow5(cosTheta);
    return f0 + (1.0 - f0) * oneMinusCos5;
}

inline float3 GlassSchlickFresnelColor(float cosTheta, float3 f0)
{
    float oneMinusCos5 = GlassOneMinusCosPow5(cosTheta);
    return f0 + (1.0.xxx - f0) * oneMinusCos5;
}

// Cosine of the transmitted angle inside a medium of the given index (Snell's law).
inline float GlassRefractedCos(float cosIncident, float ior)
{
    float eta = 1.0 / max(ior, 1.0);
    float sin2T = eta * eta * saturate(1.0 - cosIncident * cosIncident);
    return sqrt(saturate(1.0 - sin2T));
}

// Refracts a ray through an interface; the normal may face either side.
// Returns the unrefracted direction on total internal reflection.
inline float3 GlassRefractDirection(float3 incident, float3 normal, float eta)
{
    float3 n = dot(incident, normal) > 0.0 ? -normal : normal;
    float3 refracted = refract(incident, n, eta);
    return dot(refracted, refracted) > 1e-6 ? normalize(refracted) : incident;
}

// Converts a path measured along the view ray into the path along the refracted ray (slab: cos_i / cos_t).
inline float GlassViewToRefractedPath(float cosIncident, float ior)
{
    return (cosIncident + 1e-4) / (GlassRefractedCos(cosIncident, ior) + 1e-4);
}

inline float GlassComputeApproxThickness(float fallbackThickness, float3 normalWS, float3 viewDirWS, float minDenominator)
{
    float ndotv = abs(dot(normalize(normalWS), normalize(viewDirWS)));
    float denom = max(ndotv, GlassSafePositive(minDenominator));
    return fallbackThickness / denom;
}

inline float3 GlassUnpackNormalTS(sampler2D normalMap, float2 uv, float scale)
{
    float3 normalTS = UnpackNormal(tex2D(normalMap, uv));
    normalTS.xy *= scale;
    normalTS.z = sqrt(saturate(1.0 - dot(normalTS.xy, normalTS.xy)));
    return normalTS;
}

inline float3 GlassTransformTangentToWorld(float3 normalTS, float3 tangentWS, float3 bitangentWS, float3 normalWS)
{
    float3x3 tbn = float3x3(normalize(tangentWS), normalize(bitangentWS), normalize(normalWS));
    return normalize(mul(normalTS, tbn));
}

inline float3 GlassHeatColor(float value01)
{
    float t = saturate(value01);
    float3 c;
    c.r = saturate(1.5 - abs(2.0 * t - 1.0) * 3.0);
    c.g = saturate(1.5 - abs(2.0 * t - 0.5) * 3.0);
    c.b = saturate(1.5 - abs(2.0 * t - 0.0) * 3.0);
    return c;
}

inline float GlassLuminance(float3 color)
{
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

inline bool GlassIsStereoEyeRight()
{
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED) || defined(UNITY_SINGLE_PASS_STEREO)
    return unity_StereoEyeIndex == 1;
#else
    return false;
#endif
}

#endif
