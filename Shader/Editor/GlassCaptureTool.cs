using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

// Captures the Scene view at a fixed size and compares the last two captures pixel by pixel,
// so shader changes can be checked for "identical on screen" or reviewed side by side.
// Captures go to <Project>/GlassCaptures, outside Assets, so they are never imported or committed.
public static class GlassCaptureTool
{
    private const string CaptureMenuPath = "Tools/Glass Shader/Capture View";
    private const string CompareMenuPath = "Tools/Glass Shader/Compare Last Two Captures";
    private const int CaptureWidth = 1920;
    private const int CaptureHeight = 1080;
    private const int DiffAmplification = 16;

    private static string CaptureFolder => Path.GetFullPath(Path.Combine(Application.dataPath, "..", "GlassCaptures"));

    [MenuItem(CaptureMenuPath)]
    private static void CaptureView()
    {
        Camera camera = SceneView.lastActiveSceneView != null ? SceneView.lastActiveSceneView.camera : Camera.main;
        if (camera == null)
        {
            EditorUtility.DisplayDialog("Glass Capture", "Open a Scene view or add a Main Camera.", "OK");
            return;
        }

        var renderTexture = RenderTexture.GetTemporary(CaptureWidth, CaptureHeight, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        RenderTexture previousTarget = camera.targetTexture;
        RenderTexture previousActive = RenderTexture.active;
        var image = new Texture2D(CaptureWidth, CaptureHeight, TextureFormat.RGBA32, false);
        try
        {
            camera.targetTexture = renderTexture;
            camera.Render();
            RenderTexture.active = renderTexture;
            image.ReadPixels(new Rect(0, 0, CaptureWidth, CaptureHeight), 0, 0);
            image.Apply();
        }
        finally
        {
            camera.targetTexture = previousTarget;
            RenderTexture.active = previousActive;
            RenderTexture.ReleaseTemporary(renderTexture);
        }

        Directory.CreateDirectory(CaptureFolder);
        string path = Path.Combine(CaptureFolder, System.DateTime.Now.ToString("yyyyMMdd_HHmmss_fff") + ".png");
        File.WriteAllBytes(path, image.EncodeToPNG());
        Object.DestroyImmediate(image);
        Debug.Log($"[GlassCaptureTool] Captured {path}");
    }

    [MenuItem(CompareMenuPath)]
    private static void CompareLastTwo()
    {
        string[] captures = Directory.Exists(CaptureFolder)
            ? Directory.GetFiles(CaptureFolder, "*.png").Where(p => !p.EndsWith("_diff.png")).OrderBy(p => p).ToArray()
            : new string[0];
        if (captures.Length < 2)
        {
            EditorUtility.DisplayDialog("Glass Capture", "Capture the view at least twice first.", "OK");
            return;
        }

        string beforePath = captures[captures.Length - 2];
        string afterPath = captures[captures.Length - 1];
        Texture2D before = LoadPng(beforePath);
        Texture2D after = LoadPng(afterPath);
        try
        {
            if (before.width != after.width || before.height != after.height)
            {
                EditorUtility.DisplayDialog("Glass Capture", "The two captures differ in size.", "OK");
                return;
            }

            Color32[] a = before.GetPixels32();
            Color32[] b = after.GetPixels32();
            var diff = new Color32[a.Length];
            int changedPixels = 0;
            int maxDelta = 0;
            long deltaSum = 0;
            for (int i = 0; i < a.Length; i++)
            {
                int dr = Mathf.Abs(a[i].r - b[i].r);
                int dg = Mathf.Abs(a[i].g - b[i].g);
                int db = Mathf.Abs(a[i].b - b[i].b);
                int delta = Mathf.Max(dr, Mathf.Max(dg, db));
                if (delta > 0)
                {
                    changedPixels++;
                }

                maxDelta = Mathf.Max(maxDelta, delta);
                deltaSum += dr + dg + db;
                diff[i] = new Color32(
                    (byte)Mathf.Min(255, dr * DiffAmplification),
                    (byte)Mathf.Min(255, dg * DiffAmplification),
                    (byte)Mathf.Min(255, db * DiffAmplification),
                    255);
            }

            var diffImage = new Texture2D(before.width, before.height, TextureFormat.RGBA32, false);
            diffImage.SetPixels32(diff);
            diffImage.Apply();
            string diffPath = Path.ChangeExtension(afterPath, null) + "_diff.png";
            File.WriteAllBytes(diffPath, diffImage.EncodeToPNG());
            Object.DestroyImmediate(diffImage);

            float changedPercent = 100f * changedPixels / a.Length;
            float meanDelta = deltaSum / (3f * a.Length);
            string report =
                $"Before: {Path.GetFileName(beforePath)}\nAfter: {Path.GetFileName(afterPath)}\n\n" +
                $"Changed pixels: {changedPixels} ({changedPercent:0.###}%)\n" +
                $"Max channel delta: {maxDelta} / 255\nMean channel delta: {meanDelta:0.####}\n\n" +
                $"Diff (x{DiffAmplification}): {Path.GetFileName(diffPath)}";
            Debug.Log("[GlassCaptureTool] " + report.Replace("\n\n", "\n"));
            EditorUtility.DisplayDialog(changedPixels == 0 ? "Glass Capture: identical" : "Glass Capture: differs", report, "OK");
        }
        finally
        {
            Object.DestroyImmediate(before);
            Object.DestroyImmediate(after);
        }
    }

    private static Texture2D LoadPng(string path)
    {
        var texture = new Texture2D(2, 2, TextureFormat.RGBA32, false);
        texture.LoadImage(File.ReadAllBytes(path));
        return texture;
    }
}
