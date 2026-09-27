using UnityEditor;
using UnityEngine;

public sealed class GlassShaderGUI : ShaderGUI
{
    private static class Styles
    {
        public static readonly GUIContent Refraction = new GUIContent("Refraction");
        public static readonly GUIContent RefractionBlur = new GUIContent("Refraction Blur");
        public static readonly GUIContent Rain = new GUIContent("Rain");
        public static readonly GUIContent TexturesAndShading = new GUIContent("Textures And Shading");
        public static readonly GUIContent GlassBodyThicknessColor = new GUIContent("Glass Body (Thickness & Color)");
        public static readonly GUIContent FallbackAndInputs = new GUIContent("Fallback And Inputs");
        public static readonly GUIContent Debug = new GUIContent("Debug");

        public static readonly GUIContent BaseTint = new GUIContent("Reserved RGB / Effect Blend (A)");
        public static readonly GUIContent TransmittanceAtDistance = new GUIContent("Transmittance At Reference Distance");
        public static readonly GUIContent ReferenceDistance = new GUIContent("Reference Distance (Meters)");
        public static readonly GUIContent TransmittanceInfluence = new GUIContent("Transmittance Influence");
        public static readonly GUIContent Scattering = new GUIContent("Internal Scattering (1/m)");
        public static readonly GUIContent TransmittanceCurvePower = new GUIContent("Transmittance Curve Power");
        public static readonly GUIContent DepthTintStrength = new GUIContent("Depth Tint Strength");
        public static readonly GUIContent DepthTintCurve = new GUIContent("Depth Tint Curve");
        public static readonly GUIContent ThicknessScale = new GUIContent("Thickness Scale");
        public static readonly GUIContent ThicknessBias = new GUIContent("Thickness Bias (Meters)");
        public static readonly GUIContent MaxThickness = new GUIContent("Max Thickness (Meters)");
        public static readonly GUIContent FallbackThickness = new GUIContent("Fallback Thickness (Meters)");
        public static readonly GUIContent FallbackUseAngle = new GUIContent("Fallback Use Angle Correction");
        public static readonly GUIContent UseBoundsFallback = new GUIContent("Use Bounds Thickness Fallback");
        public static readonly GUIContent BoundsFallbackBlend = new GUIContent("Bounds Fallback Blend");
        public static readonly GUIContent FallbackBoundsMin = new GUIContent("Fallback Bounds Min (Object)");
        public static readonly GUIContent FallbackBoundsMax = new GUIContent("Fallback Bounds Max (Object)");
        public static readonly GUIContent FallbackAbsorptionScale = new GUIContent("Fallback Absorption Scale");
        public static readonly GUIContent FallbackMinDot = new GUIContent("Fallback Min |N.V|");
        public static readonly GUIContent GrazingAssistNdotV = new GUIContent("Grazing Assist NdotV");
        public static readonly GUIContent GrazingThicknessAssist = new GUIContent("Grazing Thickness Assist");
        public static readonly GUIContent NearCameraFadeDistance = new GUIContent("Near Camera Fade Distance (Meters)");
        public static readonly GUIContent BackDepthEdgeFixRadius = new GUIContent("Back Depth Edge Fix Radius (Pixels)");

        public static readonly GUIContent RefractionStrength = new GUIContent("Refraction Strength");
        public static readonly GUIContent RefractionModel = new GUIContent("Refraction Model");
        public static readonly GUIContent DistortionFace = new GUIContent("Distortion (Face)");
        public static readonly GUIContent DistortionEdge = new GUIContent("Distortion (Edge)");
        public static readonly GUIContent BackfaceVisibility = new GUIContent("Backface Visibility");
        public static readonly GUIContent UseChromaticAberration = new GUIContent("Use Chromatic Aberration");
        public static readonly GUIContent ChromaticAberration = new GUIContent("Chromatic Aberration (Pixels)");
        public static readonly GUIContent RefractionScreenEdgeFade = new GUIContent("Refraction Screen Edge Fade (Pixels)");
        public static readonly GUIContent UseRefractionBlur = new GUIContent("Use Refraction Blur");
        public static readonly GUIContent RefractionBlurStrength = new GUIContent("Blur Strength");
        public static readonly GUIContent RefractionBlurMaxPixels = new GUIContent("Max Blur Radius (Pixels)");
        public static readonly GUIContent RefractionBlurRoughnessInfluence = new GUIContent("Roughness Influence");
        public static readonly GUIContent RefractionBlurThicknessInfluence = new GUIContent("Thickness Influence");
        public static readonly GUIContent RefractionBlurScale = new GUIContent("Physical Blur Scale");
        public static readonly GUIContent RefractionBlurKernelSigma = new GUIContent("Kernel Softness");

        public static readonly GUIContent GlassRainEnabled = new GUIContent("Enable Rain");
        public static readonly GUIContent GlassRainMode = new GUIContent("Mode");
        public static readonly GUIContent GlassRainNormalBlend = new GUIContent("Normal Blend");
        public static readonly GUIContent GlassRainWetness = new GUIContent("Wetness");
        public static readonly GUIContent GlassRainStrength = new GUIContent("Droplet Strength");
        public static readonly GUIContent GlassRainSpeed = new GUIContent("Droplet Speed");
        public static readonly GUIContent GlassRainTiling = new GUIContent("Droplet Tiling (XY)");
        public static readonly GUIContent GlassRainSheetRows = new GUIContent("Sheet Rows");
        public static readonly GUIContent GlassRainSheetColumns = new GUIContent("Sheet Columns");
        public static readonly GUIContent GlassRainDynamicDroplets = new GUIContent("Dynamic Droplets");
        public static readonly GUIContent GlassRainRippleStrength = new GUIContent("Ripple Strength");
        public static readonly GUIContent GlassRainRippleScale = new GUIContent("Ripple Scale");
        public static readonly GUIContent GlassRainRippleSpeed = new GUIContent("Ripple Speed");
        public static readonly GUIContent GlassRainRippleDensity = new GUIContent("Ripple Density");
        public static readonly GUIContent GlassRainAutoThreshold = new GUIContent("Auto Angle Threshold");
        public static readonly GUIContent GlassRainAutoBlend = new GUIContent("Auto Angle Blend");
        public static readonly GUIContent GlassRainMask = new GUIContent("Rain Mask");
        public static readonly GUIContent GlassRainMaskChannel = new GUIContent("Rain Mask Channel");
        public static readonly GUIContent GlassRainSheet = new GUIContent("Rain Texture Sheet");
        public static readonly GUIContent GlassRainDropletMask = new GUIContent("Rain Droplet Mask");
        public static readonly GUIContent GlassRainNoiseTex = new GUIContent("Rain Noise Texture");

        public static readonly GUIContent IndexOfRefraction = new GUIContent("Index Of Refraction");
        public static readonly GUIContent ReflectionTint = new GUIContent("Reflection Tint");
        public static readonly GUIContent EnvReflectionStrength = new GUIContent("Environment Reflection Strength");
        public static readonly GUIContent DirectSpecularStrength = new GUIContent("Direct Specular Strength");
        public static readonly GUIContent Smoothness = new GUIContent("Smoothness");
        public static readonly GUIContent FresnelBoost = new GUIContent("Fresnel Boost");
        public static readonly GUIContent TransmissionAtGrazing = new GUIContent("Transmission At Grazing");
        public static readonly GUIContent ReflectionAbsorptionCoupling = new GUIContent("Reflection Absorption Coupling");
        public static readonly GUIContent UseMeshEdge = new GUIContent("Use Mesh Edge Highlight");
        public static readonly GUIContent MeshEdgeColor = new GUIContent("Mesh Edge Color");
        public static readonly GUIContent MeshEdgeWidth = new GUIContent("Mesh Edge Width");
        public static readonly GUIContent MeshEdgeThreshold = new GUIContent("Mesh Edge Threshold");
        public static readonly GUIContent MeshEdgeSoftness = new GUIContent("Mesh Edge Softness");
        public static readonly GUIContent MeshEdgeIntensity = new GUIContent("Mesh Edge Intensity");

        public static readonly GUIContent NormalMap = new GUIContent("Normal Map");
        public static readonly GUIContent NormalScale = new GUIContent("Normal Scale");
        public static readonly GUIContent RoughnessMap = new GUIContent("Roughness Map");
        public static readonly GUIContent RoughnessMapStrength = new GUIContent("Roughness Map Strength");
        public static readonly GUIContent MetallicMap = new GUIContent("Metallic Map");
        public static readonly GUIContent MetallicMapStrength = new GUIContent("Metallic Map Strength");

        public static readonly GUIContent BackDepthTexture = new GUIContent("Back Depth Texture (Linear Eye)");
        public static readonly GUIContent SceneColorTexture = new GUIContent("Scene Color Texture");
        public static readonly GUIContent UseSceneColorTexture = new GUIContent("Use External Scene Color Texture");
        public static readonly GUIContent UseBackDepthTexture = new GUIContent("Use Back Depth Texture");
        public static readonly GUIContent BackDepthIsLinear = new GUIContent("Back Depth Is Linear Eye Depth");
        public static readonly GUIContent UseUdonStereoTextures = new GUIContent("Use Udon Stereo Textures");
        public static readonly GUIContent UseGrabPassFallback = new GUIContent("Use GrabPass Fallback");
        public static readonly GUIContent UVClamp = new GUIContent("UV Clamp Padding");

        public static readonly GUIContent DebugView = new GUIContent("Debug View");
    }

    private static readonly string[] DebugViewOptions = { "None", "Thickness", "Transmittance", "Fresnel" };

    private static class Names
    {
        public const string BaseTint = "_BaseTint";
        public const string TransmissionColorAtDistance = "_TransmissionColorAtDistance";
        public const string ReferenceDistance = "_ReferenceDistance";
        public const string TransmittanceInfluence = "_TransmittanceInfluence";
        public const string Scattering = "_Scattering";
        public const string TransmittanceCurvePower = "_TransmittanceCurvePower";
        public const string DepthTintStrength = "_DepthTintStrength";
        public const string DepthTintCurve = "_DepthTintCurve";
        public const string ThicknessScale = "_ThicknessScale";
        public const string ThicknessBias = "_ThicknessBias";
        public const string MaxThickness = "_MaxThickness";
        public const string FallbackThickness = "_FallbackThickness";
        public const string FallbackUseAngle = "_FallbackUseAngle";
        public const string UseBoundsThicknessFallback = "_UseBoundsThicknessFallback";
        public const string BoundsFallbackBlend = "_BoundsFallbackBlend";
        public const string FallbackBoundsMin = "_FallbackBoundsMin";
        public const string FallbackBoundsMax = "_FallbackBoundsMax";
        public const string FallbackAbsorptionScale = "_FallbackAbsorptionScale";
        public const string MinViewDot = "_MinViewDot";
        public const string GrazingAssistNdotV = "_GrazingAssistNdotV";
        public const string GrazingThicknessAssist = "_GrazingThicknessAssist";
        public const string NearFadeDistance = "_NearFadeDistance";
        public const string DepthEdgeFixPixels = "_DepthEdgeFixPixels";

        public const string RefractionStrength = "_RefractionStrength";
        public const string RefractionModel = "_RefractionModel";
        public const string DistortionFace = "_DistortionFace";
        public const string DistortionEdge = "_DistortionEdge";
        public const string BackfaceVisibility = "_BackfaceVisibility";
        public const string UseChromaticAberration = "_UseChromaticAberration";
        public const string ChromaticAberration = "_ChromaticAberration";
        public const string ScreenEdgeFadePixels = "_ScreenEdgeFadePixels";
        public const string UseRefractionBlur = "_UseRefractionBlur";
        public const string RefractionBlurStrength = "_RefractionBlurStrength";
        public const string RefractionBlurMaxPixels = "_RefractionBlurMaxPixels";
        public const string RefractionBlurRoughnessInfluence = "_RefractionBlurRoughnessInfluence";
        public const string RefractionBlurThicknessInfluence = "_RefractionBlurThicknessInfluence";
        public const string RefractionBlurScale = "_RefractionBlurScale";
        public const string RefractionBlurKernelSigma = "_RefractionBlurKernelSigma";

        public const string GlassRainEnabled = "_GlassRainEnabled";
        public const string GlassRainMode = "_GlassRainMode";
        public const string GlassRainNormalBlend = "_GlassRainNormalBlend";
        public const string GlassRainWetness = "_GlassRainWetness";
        public const string GlassRainStrength = "_GlassRainStrength";
        public const string GlassRainSpeed = "_GlassRainSpeed";
        public const string GlassRainTiling = "_GlassRainTiling";
        public const string GlassRainSheetRows = "_GlassRainSheetRows";
        public const string GlassRainSheetColumns = "_GlassRainSheetColumns";
        public const string GlassRainDynamicDroplets = "_GlassRainDynamicDroplets";
        public const string GlassRainRippleStrength = "_GlassRainRippleStrength";
        public const string GlassRainRippleScale = "_GlassRainRippleScale";
        public const string GlassRainRippleSpeed = "_GlassRainRippleSpeed";
        public const string GlassRainRippleDensity = "_GlassRainRippleDensity";
        public const string GlassRainAutoThreshold = "_GlassRainAutoThreshold";
        public const string GlassRainAutoBlend = "_GlassRainAutoBlend";
        public const string GlassRainMask = "_GlassRainMask";
        public const string GlassRainMaskChannel = "_GlassRainMaskChannel";
        public const string GlassRainSheet = "_GlassRainSheet";
        public const string GlassRainDropletMask = "_GlassRainDropletMask";
        public const string GlassRainNoiseTex = "_GlassRainNoiseTex";

        public const string Ior = "_IOR";
        public const string ReflectionTint = "_ReflectionTint";
        public const string EnvReflectionStrength = "_EnvReflectionStrength";
        public const string SpecularStrength = "_SpecularStrength";
        public const string Smoothness = "_Smoothness";
        public const string FresnelBoost = "_FresnelBoost";
        public const string TransmissionAtGrazing = "_TransmissionAtGrazing";
        public const string ReflectionAbsorption = "_ReflectionAbsorption";
        public const string UseMeshEdge = "_UseMeshEdge";
        public const string MeshEdgeColor = "_MeshEdgeColor";
        public const string MeshEdgeWidth = "_MeshEdgeWidth";
        public const string MeshEdgeThreshold = "_MeshEdgeThreshold";
        public const string MeshEdgeSoftness = "_MeshEdgeSoftness";
        public const string MeshEdgeIntensity = "_MeshEdgeIntensity";

        public const string NormalMap = "_NormalMap";
        public const string NormalScale = "_NormalScale";
        public const string RoughnessMap = "_RoughnessMap";
        public const string RoughnessMapStrength = "_RoughnessMapStrength";
        public const string MetallicMap = "_MetallicMap";
        public const string MetallicMapStrength = "_MetallicMapStrength";

        public const string BackDepthTex = "_BackDepthTex";
        public const string SceneColorTex = "_SceneColorTex";
        public const string UseSceneColorTexture = "_UseSceneColorTexture";
        public const string UseBackDepthTexture = "_UseBackDepthTexture";
        public const string BackDepthIsLinear = "_BackDepthIsLinear";
        public const string UseUdonStereoTextures = "_UseUdonStereoTextures";
        public const string UseGrabPassFallback = "_UseGrabPassFallback";
        public const string UvClamp = "_UVClamp";

        public const string DebugView = "_DebugView";
    }

    private static class DebugKeywords
    {
        public const string None = "_DEBUGVIEW_NONE";
        public const string Thickness = "_DEBUGVIEW_THICKNESS";
        public const string Transmittance = "_DEBUGVIEW_TRANSMITTANCE";
        public const string Fresnel = "_DEBUGVIEW_FRESNEL";
    }

    private static readonly string[] DebugKeywordOrder =
    {
        DebugKeywords.None,
        DebugKeywords.Thickness,
        DebugKeywords.Transmittance,
        DebugKeywords.Fresnel
    };

    private static bool _showRefraction = true;
    private static bool _showRefractionBlur = true;
    private static bool _showRain;
    private static bool _showTexturesAndShading = true;
    private static bool _showGlassBodyThicknessColor = true;
    private static bool _showFallbackAndInputs;
    private static bool _showDebug;

    private static GUIStyle _sectionFoldoutStyle;

    private MaterialProperty _baseTint;
    private MaterialProperty _transmissionColorAtDistance;
    private MaterialProperty _referenceDistance;
    private MaterialProperty _transmittanceInfluence;
    private MaterialProperty _scattering;
    private MaterialProperty _transmittanceCurvePower;
    private MaterialProperty _depthTintStrength;
    private MaterialProperty _depthTintCurve;
    private MaterialProperty _thicknessScale;
    private MaterialProperty _thicknessBias;
    private MaterialProperty _maxThickness;
    private MaterialProperty _fallbackThickness;
    private MaterialProperty _fallbackUseAngle;
    private MaterialProperty _useBoundsThicknessFallback;
    private MaterialProperty _boundsFallbackBlend;
    private MaterialProperty _fallbackBoundsMin;
    private MaterialProperty _fallbackBoundsMax;
    private MaterialProperty _fallbackAbsorptionScale;
    private MaterialProperty _minViewDot;
    private MaterialProperty _grazingAssistNdotV;
    private MaterialProperty _grazingThicknessAssist;
    private MaterialProperty _nearFadeDistance;
    private MaterialProperty _depthEdgeFixPixels;

    private MaterialProperty _refractionStrength;
    private MaterialProperty _refractionModel;
    private MaterialProperty _distortionFace;
    private MaterialProperty _distortionEdge;
    private MaterialProperty _backfaceVisibility;
    private MaterialProperty _useChromaticAberration;
    private MaterialProperty _chromaticAberration;
    private MaterialProperty _screenEdgeFadePixels;
    private MaterialProperty _useRefractionBlur;
    private MaterialProperty _refractionBlurStrength;
    private MaterialProperty _refractionBlurMaxPixels;
    private MaterialProperty _refractionBlurRoughnessInfluence;
    private MaterialProperty _refractionBlurThicknessInfluence;
    private MaterialProperty _refractionBlurScale;
    private MaterialProperty _refractionBlurKernelSigma;

    private MaterialProperty _glassRainEnabled;
    private MaterialProperty _glassRainMode;
    private MaterialProperty _glassRainNormalBlend;
    private MaterialProperty _glassRainWetness;
    private MaterialProperty _glassRainStrength;
    private MaterialProperty _glassRainSpeed;
    private MaterialProperty _glassRainTiling;
    private MaterialProperty _glassRainSheetRows;
    private MaterialProperty _glassRainSheetColumns;
    private MaterialProperty _glassRainDynamicDroplets;
    private MaterialProperty _glassRainRippleStrength;
    private MaterialProperty _glassRainRippleScale;
    private MaterialProperty _glassRainRippleSpeed;
    private MaterialProperty _glassRainRippleDensity;
    private MaterialProperty _glassRainAutoThreshold;
    private MaterialProperty _glassRainAutoBlend;
    private MaterialProperty _glassRainMask;
    private MaterialProperty _glassRainMaskChannel;
    private MaterialProperty _glassRainSheet;
    private MaterialProperty _glassRainDropletMask;
    private MaterialProperty _glassRainNoiseTex;

    private MaterialProperty _ior;
    private MaterialProperty _reflectionTint;
    private MaterialProperty _envReflectionStrength;
    private MaterialProperty _specularStrength;
    private MaterialProperty _smoothness;
    private MaterialProperty _fresnelBoost;
    private MaterialProperty _transmissionAtGrazing;
    private MaterialProperty _reflectionAbsorption;
    private MaterialProperty _useMeshEdge;
    private MaterialProperty _meshEdgeColor;
    private MaterialProperty _meshEdgeWidth;
    private MaterialProperty _meshEdgeThreshold;
    private MaterialProperty _meshEdgeSoftness;
    private MaterialProperty _meshEdgeIntensity;

    private MaterialProperty _normalMap;
    private MaterialProperty _normalScale;
    private MaterialProperty _roughnessMap;
    private MaterialProperty _roughnessMapStrength;
    private MaterialProperty _metallicMap;
    private MaterialProperty _metallicMapStrength;

    private MaterialProperty _backDepthTex;
    private MaterialProperty _sceneColorTex;
    private MaterialProperty _useSceneColorTexture;
    private MaterialProperty _useBackDepthTexture;
    private MaterialProperty _backDepthIsLinear;
    private MaterialProperty _useUdonStereoTextures;
    private MaterialProperty _useGrabPassFallback;
    private MaterialProperty _uvClamp;

    private MaterialProperty _debugView;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        FindProperties(properties);

        EditorGUI.BeginChangeCheck();

        _showGlassBodyThicknessColor = DrawSectionHeader(Styles.GlassBodyThicknessColor, _showGlassBodyThicknessColor);
        if (_showGlassBodyThicknessColor)
        {
            BeginSectionBody();
            DrawGlassBodyThicknessColor(materialEditor);
            EndSectionBody();
        }

        _showTexturesAndShading = DrawSectionHeader(Styles.TexturesAndShading, _showTexturesAndShading);
        if (_showTexturesAndShading)
        {
            BeginSectionBody();
            DrawTexturesAndShading(materialEditor);
            EndSectionBody();
        }

        _showRefraction = DrawSectionHeader(Styles.Refraction, _showRefraction);
        if (_showRefraction)
        {
            BeginSectionBody();
            DrawRefraction(materialEditor);
            EndSectionBody();
        }

        _showRefractionBlur = DrawSectionHeader(Styles.RefractionBlur, _showRefractionBlur);
        if (_showRefractionBlur)
        {
            BeginSectionBody();
            DrawRefractionBlur(materialEditor);
            EndSectionBody();
        }

        _showRain = DrawSectionHeader(Styles.Rain, _showRain);
        if (_showRain)
        {
            BeginSectionBody();
            DrawRain(materialEditor);
            EndSectionBody();
        }

        _showFallbackAndInputs = DrawSectionHeader(Styles.FallbackAndInputs, _showFallbackAndInputs);
        if (_showFallbackAndInputs)
        {
            BeginSectionBody();
            DrawFallbackAndInputs(materialEditor);
            EndSectionBody();
        }

        _showDebug = DrawSectionHeader(Styles.Debug, _showDebug);
        if (_showDebug)
        {
            BeginSectionBody();
            DrawDebug(materialEditor);
            EndSectionBody();
        }

        if (EditorGUI.EndChangeCheck())
        {
            foreach (Object target in materialEditor.targets)
            {
                Material material = target as Material;
                if (material == null)
                {
                    continue;
                }

                ApplyDebugKeywords(material, Mathf.RoundToInt(_debugView != null ? _debugView.floatValue : 0f));
            }
        }

        DrawWarnings(materialEditor.target as Material);
    }

    private void FindProperties(MaterialProperty[] properties)
    {
        BindProperty(ref _baseTint, Names.BaseTint, properties);
        BindProperty(ref _transmissionColorAtDistance, Names.TransmissionColorAtDistance, properties);
        BindProperty(ref _referenceDistance, Names.ReferenceDistance, properties);
        BindProperty(ref _transmittanceInfluence, Names.TransmittanceInfluence, properties);
        BindProperty(ref _scattering, Names.Scattering, properties);
        BindProperty(ref _transmittanceCurvePower, Names.TransmittanceCurvePower, properties);
        BindProperty(ref _depthTintStrength, Names.DepthTintStrength, properties);
        BindProperty(ref _depthTintCurve, Names.DepthTintCurve, properties);
        BindProperty(ref _thicknessScale, Names.ThicknessScale, properties);
        BindProperty(ref _thicknessBias, Names.ThicknessBias, properties);
        BindProperty(ref _maxThickness, Names.MaxThickness, properties);
        BindProperty(ref _fallbackThickness, Names.FallbackThickness, properties);
        BindProperty(ref _fallbackUseAngle, Names.FallbackUseAngle, properties);
        BindProperty(ref _useBoundsThicknessFallback, Names.UseBoundsThicknessFallback, properties);
        BindProperty(ref _boundsFallbackBlend, Names.BoundsFallbackBlend, properties);
        BindProperty(ref _fallbackBoundsMin, Names.FallbackBoundsMin, properties);
        BindProperty(ref _fallbackBoundsMax, Names.FallbackBoundsMax, properties);
        BindProperty(ref _fallbackAbsorptionScale, Names.FallbackAbsorptionScale, properties);
        BindProperty(ref _minViewDot, Names.MinViewDot, properties);
        BindProperty(ref _grazingAssistNdotV, Names.GrazingAssistNdotV, properties);
        BindProperty(ref _grazingThicknessAssist, Names.GrazingThicknessAssist, properties);
        BindProperty(ref _nearFadeDistance, Names.NearFadeDistance, properties);
        BindProperty(ref _depthEdgeFixPixels, Names.DepthEdgeFixPixels, properties);

        BindProperty(ref _refractionStrength, Names.RefractionStrength, properties);
        BindProperty(ref _refractionModel, Names.RefractionModel, properties);
        BindProperty(ref _distortionFace, Names.DistortionFace, properties);
        BindProperty(ref _distortionEdge, Names.DistortionEdge, properties);
        BindProperty(ref _backfaceVisibility, Names.BackfaceVisibility, properties);
        BindProperty(ref _useChromaticAberration, Names.UseChromaticAberration, properties);
        BindProperty(ref _chromaticAberration, Names.ChromaticAberration, properties);
        BindProperty(ref _screenEdgeFadePixels, Names.ScreenEdgeFadePixels, properties);
        BindProperty(ref _useRefractionBlur, Names.UseRefractionBlur, properties);
        BindProperty(ref _refractionBlurStrength, Names.RefractionBlurStrength, properties);
        BindProperty(ref _refractionBlurMaxPixels, Names.RefractionBlurMaxPixels, properties);
        BindProperty(ref _refractionBlurRoughnessInfluence, Names.RefractionBlurRoughnessInfluence, properties);
        BindProperty(ref _refractionBlurThicknessInfluence, Names.RefractionBlurThicknessInfluence, properties);
        BindProperty(ref _refractionBlurScale, Names.RefractionBlurScale, properties);
        BindProperty(ref _refractionBlurKernelSigma, Names.RefractionBlurKernelSigma, properties);

        BindProperty(ref _glassRainEnabled, Names.GlassRainEnabled, properties);
        BindProperty(ref _glassRainMode, Names.GlassRainMode, properties);
        BindProperty(ref _glassRainNormalBlend, Names.GlassRainNormalBlend, properties);
        BindProperty(ref _glassRainWetness, Names.GlassRainWetness, properties);
        BindProperty(ref _glassRainStrength, Names.GlassRainStrength, properties);
        BindProperty(ref _glassRainSpeed, Names.GlassRainSpeed, properties);
        BindProperty(ref _glassRainTiling, Names.GlassRainTiling, properties);
        BindProperty(ref _glassRainSheetRows, Names.GlassRainSheetRows, properties);
        BindProperty(ref _glassRainSheetColumns, Names.GlassRainSheetColumns, properties);
        BindProperty(ref _glassRainDynamicDroplets, Names.GlassRainDynamicDroplets, properties);
        BindProperty(ref _glassRainRippleStrength, Names.GlassRainRippleStrength, properties);
        BindProperty(ref _glassRainRippleScale, Names.GlassRainRippleScale, properties);
        BindProperty(ref _glassRainRippleSpeed, Names.GlassRainRippleSpeed, properties);
        BindProperty(ref _glassRainRippleDensity, Names.GlassRainRippleDensity, properties);
        BindProperty(ref _glassRainAutoThreshold, Names.GlassRainAutoThreshold, properties);
        BindProperty(ref _glassRainAutoBlend, Names.GlassRainAutoBlend, properties);
        BindProperty(ref _glassRainMask, Names.GlassRainMask, properties);
        BindProperty(ref _glassRainMaskChannel, Names.GlassRainMaskChannel, properties);
        BindProperty(ref _glassRainSheet, Names.GlassRainSheet, properties);
        BindProperty(ref _glassRainDropletMask, Names.GlassRainDropletMask, properties);
        BindProperty(ref _glassRainNoiseTex, Names.GlassRainNoiseTex, properties);

        BindProperty(ref _ior, Names.Ior, properties);
        BindProperty(ref _reflectionTint, Names.ReflectionTint, properties);
        BindProperty(ref _envReflectionStrength, Names.EnvReflectionStrength, properties);
        BindProperty(ref _specularStrength, Names.SpecularStrength, properties);
        BindProperty(ref _smoothness, Names.Smoothness, properties);
        BindProperty(ref _fresnelBoost, Names.FresnelBoost, properties);
        BindProperty(ref _transmissionAtGrazing, Names.TransmissionAtGrazing, properties);
        BindProperty(ref _reflectionAbsorption, Names.ReflectionAbsorption, properties);
        BindProperty(ref _useMeshEdge, Names.UseMeshEdge, properties);
        BindProperty(ref _meshEdgeColor, Names.MeshEdgeColor, properties);
        BindProperty(ref _meshEdgeWidth, Names.MeshEdgeWidth, properties);
        BindProperty(ref _meshEdgeThreshold, Names.MeshEdgeThreshold, properties);
        BindProperty(ref _meshEdgeSoftness, Names.MeshEdgeSoftness, properties);
        BindProperty(ref _meshEdgeIntensity, Names.MeshEdgeIntensity, properties);

        BindProperty(ref _normalMap, Names.NormalMap, properties);
        BindProperty(ref _normalScale, Names.NormalScale, properties);
        BindProperty(ref _roughnessMap, Names.RoughnessMap, properties);
        BindProperty(ref _roughnessMapStrength, Names.RoughnessMapStrength, properties);
        BindProperty(ref _metallicMap, Names.MetallicMap, properties);
        BindProperty(ref _metallicMapStrength, Names.MetallicMapStrength, properties);

        BindProperty(ref _backDepthTex, Names.BackDepthTex, properties);
        BindProperty(ref _sceneColorTex, Names.SceneColorTex, properties);
        BindProperty(ref _useSceneColorTexture, Names.UseSceneColorTexture, properties);
        BindProperty(ref _useBackDepthTexture, Names.UseBackDepthTexture, properties);
        BindProperty(ref _backDepthIsLinear, Names.BackDepthIsLinear, properties);
        BindProperty(ref _useUdonStereoTextures, Names.UseUdonStereoTextures, properties);
        BindProperty(ref _useGrabPassFallback, Names.UseGrabPassFallback, properties);
        BindProperty(ref _uvClamp, Names.UvClamp, properties);

        BindProperty(ref _debugView, Names.DebugView, properties);
    }

    private void BindProperty(ref MaterialProperty property, string name, MaterialProperty[] properties)
    {
        property = FindProperty(name, properties, false);
    }

    private static void EnsureSectionStyles()
    {
        if (_sectionFoldoutStyle != null)
        {
            return;
        }

        _sectionFoldoutStyle = new GUIStyle(EditorStyles.foldout)
        {
            fontStyle = FontStyle.Bold
        };
    }

    private static bool DrawSectionHeader(GUIContent title, bool isExpanded)
    {
        EnsureSectionStyles();
        EditorGUILayout.Space(6f);

        Rect rect = GUILayoutUtility.GetRect(16f, 20f, GUILayout.ExpandWidth(true));
        if (Event.current.type == EventType.Repaint)
        {
            EditorGUI.DrawRect(rect, new Color(0.24f, 0.24f, 0.24f, 1f));
        }

        Rect foldoutRect = new Rect(rect.x + 6f, rect.y + 1f, rect.width - 12f, rect.height - 2f);
        return EditorGUI.Foldout(foldoutRect, isExpanded, title, true, _sectionFoldoutStyle);
    }

    private static void BeginSectionBody()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);
    }

    private static void EndSectionBody()
    {
        EditorGUILayout.EndVertical();
    }

    private void DrawRefraction(MaterialEditor materialEditor)
    {
        DrawProperty(materialEditor, _refractionStrength, Styles.RefractionStrength);
        DrawProperty(materialEditor, _refractionModel, Styles.RefractionModel);
        DrawProperty(materialEditor, _distortionFace, Styles.DistortionFace);
        DrawProperty(materialEditor, _distortionEdge, Styles.DistortionEdge);
        DrawProperty(materialEditor, _backfaceVisibility, Styles.BackfaceVisibility);
        DrawToggle(_useChromaticAberration, Styles.UseChromaticAberration);
        using (new EditorGUI.DisabledScope(!GetToggleValue(_useChromaticAberration)))
        {
            DrawProperty(materialEditor, _chromaticAberration, Styles.ChromaticAberration);
        }

        DrawProperty(materialEditor, _screenEdgeFadePixels, Styles.RefractionScreenEdgeFade);
    }

    private void DrawRefractionBlur(MaterialEditor materialEditor)
    {
        DrawToggle(_useRefractionBlur, Styles.UseRefractionBlur);

        using (new EditorGUI.DisabledScope(!GetToggleValue(_useRefractionBlur)))
        {
            DrawProperty(materialEditor, _refractionBlurStrength, Styles.RefractionBlurStrength);
            DrawProperty(materialEditor, _refractionBlurMaxPixels, Styles.RefractionBlurMaxPixels);
            DrawProperty(materialEditor, _refractionBlurRoughnessInfluence, Styles.RefractionBlurRoughnessInfluence);
            DrawProperty(materialEditor, _refractionBlurThicknessInfluence, Styles.RefractionBlurThicknessInfluence);
            DrawProperty(materialEditor, _refractionBlurScale, Styles.RefractionBlurScale);
            DrawProperty(materialEditor, _refractionBlurKernelSigma, Styles.RefractionBlurKernelSigma);
        }
    }

    private void DrawRain(MaterialEditor materialEditor)
    {
        DrawToggle(_glassRainEnabled, Styles.GlassRainEnabled);

        using (new EditorGUI.DisabledScope(!GetToggleValue(_glassRainEnabled)))
        {
            DrawProperty(materialEditor, _glassRainMode, Styles.GlassRainMode);
            DrawProperty(materialEditor, _glassRainNormalBlend, Styles.GlassRainNormalBlend);
            DrawProperty(materialEditor, _glassRainWetness, Styles.GlassRainWetness);

            DrawProperty(materialEditor, _glassRainStrength, Styles.GlassRainStrength);
            DrawProperty(materialEditor, _glassRainSpeed, Styles.GlassRainSpeed);
            DrawProperty(materialEditor, _glassRainTiling, Styles.GlassRainTiling);
            DrawProperty(materialEditor, _glassRainSheetRows, Styles.GlassRainSheetRows);
            DrawProperty(materialEditor, _glassRainSheetColumns, Styles.GlassRainSheetColumns);
            DrawProperty(materialEditor, _glassRainDynamicDroplets, Styles.GlassRainDynamicDroplets);

            DrawProperty(materialEditor, _glassRainRippleStrength, Styles.GlassRainRippleStrength);
            DrawProperty(materialEditor, _glassRainRippleScale, Styles.GlassRainRippleScale);
            DrawProperty(materialEditor, _glassRainRippleSpeed, Styles.GlassRainRippleSpeed);
            DrawProperty(materialEditor, _glassRainRippleDensity, Styles.GlassRainRippleDensity);
            DrawProperty(materialEditor, _glassRainAutoThreshold, Styles.GlassRainAutoThreshold);
            DrawProperty(materialEditor, _glassRainAutoBlend, Styles.GlassRainAutoBlend);

            if (_glassRainMask != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.GlassRainMask, _glassRainMask, _glassRainMaskChannel);
                materialEditor.TextureScaleOffsetProperty(_glassRainMask);
            }
            else
            {
                DrawProperty(materialEditor, _glassRainMaskChannel, Styles.GlassRainMaskChannel);
            }

            DrawTexture(materialEditor, _glassRainSheet, Styles.GlassRainSheet);
            DrawTexture(materialEditor, _glassRainDropletMask, Styles.GlassRainDropletMask);
            DrawTexture(materialEditor, _glassRainNoiseTex, Styles.GlassRainNoiseTex);
        }
    }

    private void DrawTexturesAndShading(MaterialEditor materialEditor)
    {
        if (_normalMap != null)
        {
            materialEditor.TexturePropertySingleLine(Styles.NormalMap, _normalMap, _normalScale);
            materialEditor.TextureScaleOffsetProperty(_normalMap);
        }
        else
        {
            DrawProperty(materialEditor, _normalScale, Styles.NormalScale);
        }

        if (_roughnessMap != null)
        {
            if (_roughnessMapStrength != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.RoughnessMap, _roughnessMap, _roughnessMapStrength);
            }
            else
            {
                materialEditor.TexturePropertySingleLine(Styles.RoughnessMap, _roughnessMap);
            }
            materialEditor.TextureScaleOffsetProperty(_roughnessMap);
        }
        else
        {
            DrawProperty(materialEditor, _roughnessMapStrength, Styles.RoughnessMapStrength);
        }

        if (_metallicMap != null)
        {
            if (_metallicMapStrength != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.MetallicMap, _metallicMap, _metallicMapStrength);
            }
            else
            {
                materialEditor.TexturePropertySingleLine(Styles.MetallicMap, _metallicMap);
            }
            materialEditor.TextureScaleOffsetProperty(_metallicMap);
        }
        else
        {
            DrawProperty(materialEditor, _metallicMapStrength, Styles.MetallicMapStrength);
        }

        DrawProperty(materialEditor, _smoothness, Styles.Smoothness);
        DrawProperty(materialEditor, _ior, Styles.IndexOfRefraction);
        DrawColor(materialEditor, _reflectionTint, Styles.ReflectionTint);
        DrawProperty(materialEditor, _envReflectionStrength, Styles.EnvReflectionStrength);
        DrawProperty(materialEditor, _specularStrength, Styles.DirectSpecularStrength);
        DrawProperty(materialEditor, _fresnelBoost, Styles.FresnelBoost);

        DrawToggle(_useMeshEdge, Styles.UseMeshEdge);
        using (new EditorGUI.DisabledScope(!GetToggleValue(_useMeshEdge)))
        {
            DrawColor(materialEditor, _meshEdgeColor, Styles.MeshEdgeColor);
            DrawProperty(materialEditor, _meshEdgeWidth, Styles.MeshEdgeWidth);
            DrawProperty(materialEditor, _meshEdgeThreshold, Styles.MeshEdgeThreshold);
            DrawProperty(materialEditor, _meshEdgeSoftness, Styles.MeshEdgeSoftness);
            DrawProperty(materialEditor, _meshEdgeIntensity, Styles.MeshEdgeIntensity);
        }
    }

    private void DrawGlassBodyThicknessColor(MaterialEditor materialEditor)
    {
        DrawColor(materialEditor, _baseTint, Styles.BaseTint);
        DrawColor(materialEditor, _transmissionColorAtDistance, Styles.TransmittanceAtDistance);
        DrawProperty(materialEditor, _referenceDistance, Styles.ReferenceDistance);
        DrawProperty(materialEditor, _transmittanceInfluence, Styles.TransmittanceInfluence);
        DrawProperty(materialEditor, _transmittanceCurvePower, Styles.TransmittanceCurvePower);
        DrawProperty(materialEditor, _depthTintStrength, Styles.DepthTintStrength);
        DrawProperty(materialEditor, _depthTintCurve, Styles.DepthTintCurve);
        DrawProperty(materialEditor, _scattering, Styles.Scattering);
        DrawProperty(materialEditor, _thicknessScale, Styles.ThicknessScale);
        DrawProperty(materialEditor, _thicknessBias, Styles.ThicknessBias);
        DrawProperty(materialEditor, _maxThickness, Styles.MaxThickness);
        DrawProperty(materialEditor, _transmissionAtGrazing, Styles.TransmissionAtGrazing);
        DrawProperty(materialEditor, _reflectionAbsorption, Styles.ReflectionAbsorptionCoupling);
    }

    private void DrawFallbackAndInputs(MaterialEditor materialEditor)
    {
        DrawTexture(materialEditor, _backDepthTex, Styles.BackDepthTexture);
        DrawTexture(materialEditor, _sceneColorTex, Styles.SceneColorTexture);
        DrawToggle(_useSceneColorTexture, Styles.UseSceneColorTexture);
        DrawToggle(_useBackDepthTexture, Styles.UseBackDepthTexture);

        using (new EditorGUI.DisabledScope(!GetToggleValue(_useBackDepthTexture)))
        {
            DrawToggle(_backDepthIsLinear, Styles.BackDepthIsLinear);
        }

        DrawToggle(_useUdonStereoTextures, Styles.UseUdonStereoTextures);
        DrawToggle(_useGrabPassFallback, Styles.UseGrabPassFallback);
        DrawProperty(materialEditor, _uvClamp, Styles.UVClamp);

        DrawProperty(materialEditor, _fallbackThickness, Styles.FallbackThickness);
        DrawToggle(_fallbackUseAngle, Styles.FallbackUseAngle);
        DrawProperty(materialEditor, _fallbackAbsorptionScale, Styles.FallbackAbsorptionScale);
        DrawProperty(materialEditor, _minViewDot, Styles.FallbackMinDot);

        DrawToggle(_useBoundsThicknessFallback, Styles.UseBoundsFallback);
        using (new EditorGUI.DisabledScope(!GetToggleValue(_useBoundsThicknessFallback)))
        {
            DrawProperty(materialEditor, _boundsFallbackBlend, Styles.BoundsFallbackBlend);
            DrawProperty(materialEditor, _fallbackBoundsMin, Styles.FallbackBoundsMin);
            DrawProperty(materialEditor, _fallbackBoundsMax, Styles.FallbackBoundsMax);
        }

        DrawProperty(materialEditor, _grazingAssistNdotV, Styles.GrazingAssistNdotV);
        DrawProperty(materialEditor, _grazingThicknessAssist, Styles.GrazingThicknessAssist);
        DrawProperty(materialEditor, _nearFadeDistance, Styles.NearCameraFadeDistance);
        DrawProperty(materialEditor, _depthEdgeFixPixels, Styles.BackDepthEdgeFixRadius);
    }

    private void DrawDebug(MaterialEditor materialEditor)
    {
        if (_debugView == null)
        {
            return;
        }

        int current = Mathf.Clamp(Mathf.RoundToInt(_debugView.floatValue), 0, DebugViewOptions.Length - 1);
        EditorGUI.showMixedValue = _debugView.hasMixedValue;
        EditorGUI.BeginChangeCheck();
        int next = EditorGUILayout.Popup(Styles.DebugView, current, DebugViewOptions);
        if (EditorGUI.EndChangeCheck())
        {
            materialEditor.RegisterPropertyChangeUndo(Styles.DebugView.text);
            _debugView.floatValue = next;
        }
        EditorGUI.showMixedValue = false;
    }

    private void DrawWarnings(Material material)
    {
        if (material == null)
        {
            return;
        }

        if (GetToggleValue(_useBackDepthTexture) && material.GetTexture(Names.BackDepthTex) == null)
        {
            EditorGUILayout.HelpBox("Use Back Depth Texture is enabled, but Back Depth Texture is not assigned.", MessageType.Warning);
        }

        bool sceneColorEnabled = GetToggleValue(_useSceneColorTexture);
        bool grabFallbackEnabled = GetToggleValue(_useGrabPassFallback);
        if (sceneColorEnabled && material.GetTexture(Names.SceneColorTex) == null && !grabFallbackEnabled)
        {
            EditorGUILayout.HelpBox("Scene Color Texture is enabled but missing, and GrabPass fallback is disabled.", MessageType.Warning);
        }

        if (GetToggleValue(_useRefractionBlur) && !sceneColorEnabled && !grabFallbackEnabled)
        {
            EditorGUILayout.HelpBox("Refraction Blur is enabled, but both Scene Color Texture and GrabPass fallback are disabled.", MessageType.Warning);
        }

        if (GetToggleValue(_useRefractionBlur))
        {
            float smoothness = _smoothness != null ? _smoothness.floatValue : 1.0f;
            float roughnessInfluence = _refractionBlurRoughnessInfluence != null ? _refractionBlurRoughnessInfluence.floatValue : 1.0f;
            float roughnessMapStrength = _roughnessMapStrength != null ? _roughnessMapStrength.floatValue : 0.0f;
            bool roughnessMapAssigned = _roughnessMap != null && material.GetTexture(Names.RoughnessMap) != null;

            if (roughnessInfluence >= 0.8f && smoothness >= 0.9f && (!roughnessMapAssigned || roughnessMapStrength <= 0.05f))
            {
                EditorGUILayout.HelpBox("Blur may look inactive with very high smoothness and high roughness influence. Lower Smoothness or Roughness Influence.", MessageType.Info);
            }
        }

        if (_ior != null && _ior.floatValue <= 1.01f)
        {
            EditorGUILayout.HelpBox("Index Of Refraction is very close to 1.0; Fresnel and glass realism may look weak.", MessageType.Info);
        }

        if (GetToggleValue(_glassRainEnabled))
        {
            if (material.GetTexture(Names.GlassRainMask) == null)
            {
                EditorGUILayout.HelpBox("Rain is enabled but Rain Mask is not assigned.", MessageType.Warning);
            }

            if (material.GetTexture(Names.GlassRainSheet) == null)
            {
                EditorGUILayout.HelpBox("Rain is enabled but Rain Texture Sheet is not assigned.", MessageType.Warning);
            }

            if (material.GetTexture(Names.GlassRainDropletMask) == null)
            {
                EditorGUILayout.HelpBox("Rain is enabled but Rain Droplet Mask is not assigned.", MessageType.Warning);
            }

            if (material.GetTexture(Names.GlassRainNoiseTex) == null)
            {
                EditorGUILayout.HelpBox("Rain is enabled but Rain Noise Texture is not assigned.", MessageType.Warning);
            }
        }

        if (GetToggleValue(_useMeshEdge))
        {
            EditorGUILayout.HelpBox("Mesh Edge Highlight requires baked edge data. Use Tools > Glass Shader > Bake Selected Mesh Edge Data.", MessageType.Info);
        }
    }

    private static void DrawProperty(MaterialEditor materialEditor, MaterialProperty property, GUIContent label)
    {
        if (property == null)
        {
            return;
        }

        materialEditor.ShaderProperty(property, label.text);
    }

    private static void DrawColor(MaterialEditor materialEditor, MaterialProperty property, GUIContent label)
    {
        if (property == null)
        {
            return;
        }

        materialEditor.ColorProperty(property, label.text);
    }

    private static void DrawTexture(MaterialEditor materialEditor, MaterialProperty property, GUIContent label)
    {
        if (property == null)
        {
            return;
        }

        materialEditor.TexturePropertySingleLine(label, property);
    }

    private static void DrawToggle(MaterialProperty property, GUIContent label)
    {
        if (property == null)
        {
            return;
        }

        EditorGUI.showMixedValue = property.hasMixedValue;
        EditorGUI.BeginChangeCheck();
        bool value = EditorGUILayout.Toggle(label, property.floatValue > 0.5f);
        if (EditorGUI.EndChangeCheck())
        {
            property.floatValue = value ? 1f : 0f;
        }
        EditorGUI.showMixedValue = false;
    }

    private static bool GetToggleValue(MaterialProperty property)
    {
        return property != null && property.floatValue > 0.5f;
    }

    private static void ApplyDebugKeywords(Material material, int debugView)
    {
        for (int i = 0; i < DebugKeywordOrder.Length; i++)
        {
            material.DisableKeyword(DebugKeywordOrder[i]);
        }

        int keywordIndex = debugView;
        if (keywordIndex < 0 || keywordIndex >= DebugKeywordOrder.Length)
        {
            keywordIndex = 0;
        }

        material.EnableKeyword(DebugKeywordOrder[keywordIndex]);
    }
}
