using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class GlassMeshEdgeBaker
{
    private const string MenuPath = "Tools/Glass Shader/Bake Selected Mesh Edge Data";
    private const string OutputFolder = "Assets/GlassShader_Unity/MeshEdgeBaked";
    private const float HardEdgeAngleDegrees = 1.0f;

    [MenuItem(MenuPath)]
    private static void BakeSelected()
    {
        GameObject[] selected = Selection.gameObjects;
        if (selected == null || selected.Length == 0)
        {
            EditorUtility.DisplayDialog("Glass Edge Baker", "Select at least one GameObject.", "OK");
            return;
        }

        EnsureOutputFolder();

        var bakedBySource = new Dictionary<Mesh, Mesh>();
        int rendererCount = 0;
        int bakedMeshCount = 0;

        foreach (GameObject root in selected)
        {
            if (root == null)
            {
                continue;
            }

            foreach (MeshFilter meshFilter in root.GetComponentsInChildren<MeshFilter>(true))
            {
                if (meshFilter == null || meshFilter.sharedMesh == null)
                {
                    continue;
                }

                Mesh baked = GetOrCreateBakedMesh(meshFilter.sharedMesh, bakedBySource, ref bakedMeshCount);
                if (baked == null)
                {
                    continue;
                }

                Undo.RecordObject(meshFilter, "Assign Baked Mesh Edge Data");
                meshFilter.sharedMesh = baked;
                EditorUtility.SetDirty(meshFilter);
                rendererCount++;
            }

            foreach (SkinnedMeshRenderer skinned in root.GetComponentsInChildren<SkinnedMeshRenderer>(true))
            {
                if (skinned == null || skinned.sharedMesh == null)
                {
                    continue;
                }

                Mesh baked = GetOrCreateBakedMesh(skinned.sharedMesh, bakedBySource, ref bakedMeshCount);
                if (baked == null)
                {
                    continue;
                }

                Undo.RecordObject(skinned, "Assign Baked Mesh Edge Data");
                skinned.sharedMesh = baked;
                EditorUtility.SetDirty(skinned);
                rendererCount++;
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        EditorUtility.DisplayDialog(
            "Glass Edge Baker",
            $"Baked meshes: {bakedMeshCount}\nRenderers updated: {rendererCount}\nOutput: {OutputFolder}",
            "OK");
    }

    [MenuItem(MenuPath, true)]
    private static bool ValidateBakeSelected()
    {
        return Selection.gameObjects != null && Selection.gameObjects.Length > 0;
    }

    private static Mesh GetOrCreateBakedMesh(Mesh source, Dictionary<Mesh, Mesh> bakedBySource, ref int bakedMeshCount)
    {
        if (source == null)
        {
            return null;
        }

        // Unity renames the mesh to its asset file name, which may carry a " 1" style suffix.
        if (source.name.Contains("_GlassEdge"))
        {
            bakedBySource[source] = source;
            return source;
        }

        if (bakedBySource.TryGetValue(source, out Mesh cached))
        {
            return cached;
        }

        Mesh baked;
        try
        {
            baked = BakeMesh(source, HardEdgeAngleDegrees);
        }
        catch (System.Exception ex)
        {
            Debug.LogWarning($"[GlassMeshEdgeBaker] Failed to bake '{source.name}': {ex.Message}");
            return null;
        }
        if (baked == null)
        {
            return null;
        }

        string path = AssetDatabase.GenerateUniqueAssetPath(
            Path.Combine(OutputFolder, source.name + "_GlassEdge.asset").Replace("\\", "/"));
        AssetDatabase.CreateAsset(baked, path);
        bakedBySource[source] = baked;
        bakedMeshCount++;
        return baked;
    }

    private static void EnsureOutputFolder()
    {
        string[] parts = OutputFolder.Split('/');
        if (parts.Length < 2 || parts[0] != "Assets")
        {
            return;
        }

        string current = "Assets";
        for (int i = 1; i < parts.Length; i++)
        {
            string next = current + "/" + parts[i];
            if (!AssetDatabase.IsValidFolder(next))
            {
                AssetDatabase.CreateFolder(current, parts[i]);
            }
            current = next;
        }
    }

    private struct EdgeKey
    {
        public readonly int A;
        public readonly int B;

        public EdgeKey(int i0, int i1)
        {
            if (i0 < i1)
            {
                A = i0;
                B = i1;
            }
            else
            {
                A = i1;
                B = i0;
            }
        }

        public override bool Equals(object obj)
        {
            if (!(obj is EdgeKey))
            {
                return false;
            }

            EdgeKey other = (EdgeKey)obj;
            return A == other.A && B == other.B;
        }

        public override int GetHashCode()
        {
            unchecked
            {
                return (A * 397) ^ B;
            }
        }
    }

    private struct TriangleInfo
    {
        public int Submesh;
        public int I0;
        public int I1;
        public int I2;
        public Vector3 Normal;
    }

    private static Mesh BakeMesh(Mesh source, float hardEdgeAngleDegrees)
    {
        if (source == null)
        {
            return null;
        }

        int sourceVertexCount = source.vertexCount;
        if (sourceVertexCount <= 0)
        {
            return null;
        }

        for (int s = 0; s < source.subMeshCount; s++)
        {
            if (source.GetTopology(s) != MeshTopology.Triangles)
            {
                Debug.LogWarning($"[GlassMeshEdgeBaker] Skipped '{source.name}': submesh {s} is not triangle topology.");
                return null;
            }
        }

        Vector3[] srcVertices = source.vertices;
        Vector3[] srcNormals = source.normals;
        Vector4[] srcTangents = source.tangents;
        Color[] srcColors = source.colors;
        BoneWeight[] srcBoneWeights = source.boneWeights;
        Matrix4x4[] srcBindposes = source.bindposes;

        List<Vector4>[] srcUv = new List<Vector4>[8];
        for (int channel = 0; channel < srcUv.Length; channel++)
        {
            srcUv[channel] = new List<Vector4>();
            source.GetUVs(channel, srcUv[channel]);
        }

        var triangles = new List<TriangleInfo>(source.triangles.Length / 3);
        var edgeToTriangles = new Dictionary<EdgeKey, List<int>>();

        for (int submesh = 0; submesh < source.subMeshCount; submesh++)
        {
            int[] indices = source.GetIndices(submesh);
            for (int i = 0; i + 2 < indices.Length; i += 3)
            {
                int i0 = indices[i + 0];
                int i1 = indices[i + 1];
                int i2 = indices[i + 2];

                Vector3 normal = ComputeFaceNormal(srcVertices[i0], srcVertices[i1], srcVertices[i2]);

                var tri = new TriangleInfo
                {
                    Submesh = submesh,
                    I0 = i0,
                    I1 = i1,
                    I2 = i2,
                    Normal = normal
                };

                int triId = triangles.Count;
                triangles.Add(tri);

                AddEdge(edgeToTriangles, new EdgeKey(i1, i2), triId);
                AddEdge(edgeToTriangles, new EdgeKey(i2, i0), triId);
                AddEdge(edgeToTriangles, new EdgeKey(i0, i1), triId);
            }
        }

        float cosThreshold = Mathf.Cos(hardEdgeAngleDegrees * Mathf.Deg2Rad);

        var dstVertices = new List<Vector3>(triangles.Count * 3);
        var dstNormals = new List<Vector3>(triangles.Count * 3);
        var dstTangents = new List<Vector4>(triangles.Count * 3);
        var dstColors = new List<Color>(triangles.Count * 3);
        var dstBoneWeights = new List<BoneWeight>(triangles.Count * 3);
        var dstSourceIndices = new List<int>(triangles.Count * 3);
        var dstUv = new List<Vector4>[8];
        for (int channel = 0; channel < dstUv.Length; channel++)
        {
            dstUv[channel] = new List<Vector4>(triangles.Count * 3);
        }

        var dstSubmeshIndices = new List<int>[source.subMeshCount];
        for (int submesh = 0; submesh < source.subMeshCount; submesh++)
        {
            dstSubmeshIndices[submesh] = new List<int>();
        }

        for (int triId = 0; triId < triangles.Count; triId++)
        {
            TriangleInfo tri = triangles[triId];
            Vector3 keep = new Vector3(
                ComputeEdgeKeep(edgeToTriangles, triangles, triId, new EdgeKey(tri.I1, tri.I2), cosThreshold),
                ComputeEdgeKeep(edgeToTriangles, triangles, triId, new EdgeKey(tri.I2, tri.I0), cosThreshold),
                ComputeEdgeKeep(edgeToTriangles, triangles, triId, new EdgeKey(tri.I0, tri.I1), cosThreshold));

            int baseIndex = dstVertices.Count;

            AppendVertex(
                tri.I0,
                new Vector4(1.0f, 0.0f, 0.0f, keep.x),
                new Vector4(keep.y, keep.z, 0.0f, 0.0f),
                sourceVertexCount,
                srcVertices,
                srcNormals,
                srcTangents,
                srcColors,
                srcBoneWeights,
                srcUv,
                dstVertices,
                dstNormals,
                dstTangents,
                dstColors,
                dstBoneWeights,
                dstUv);

            AppendVertex(
                tri.I1,
                new Vector4(0.0f, 1.0f, 0.0f, keep.x),
                new Vector4(keep.y, keep.z, 0.0f, 0.0f),
                sourceVertexCount,
                srcVertices,
                srcNormals,
                srcTangents,
                srcColors,
                srcBoneWeights,
                srcUv,
                dstVertices,
                dstNormals,
                dstTangents,
                dstColors,
                dstBoneWeights,
                dstUv);

            AppendVertex(
                tri.I2,
                new Vector4(0.0f, 0.0f, 1.0f, keep.x),
                new Vector4(keep.y, keep.z, 0.0f, 0.0f),
                sourceVertexCount,
                srcVertices,
                srcNormals,
                srcTangents,
                srcColors,
                srcBoneWeights,
                srcUv,
                dstVertices,
                dstNormals,
                dstTangents,
                dstColors,
                dstBoneWeights,
                dstUv);

            dstSourceIndices.Add(tri.I0);
            dstSourceIndices.Add(tri.I1);
            dstSourceIndices.Add(tri.I2);

            dstSubmeshIndices[tri.Submesh].Add(baseIndex + 0);
            dstSubmeshIndices[tri.Submesh].Add(baseIndex + 1);
            dstSubmeshIndices[tri.Submesh].Add(baseIndex + 2);
        }

        var baked = new Mesh
        {
            name = source.name + "_GlassEdge"
        };

        baked.indexFormat = dstVertices.Count > 65535 ? IndexFormat.UInt32 : IndexFormat.UInt16;
        baked.SetVertices(dstVertices);

        if (dstNormals.Count == dstVertices.Count)
        {
            baked.SetNormals(dstNormals);
        }
        else
        {
            baked.RecalculateNormals();
        }

        if (dstTangents.Count == dstVertices.Count)
        {
            baked.SetTangents(dstTangents);
        }

        if (dstColors.Count == dstVertices.Count)
        {
            baked.SetColors(dstColors);
        }

        for (int channel = 0; channel < dstUv.Length; channel++)
        {
            if (dstUv[channel].Count == dstVertices.Count)
            {
                baked.SetUVs(channel, dstUv[channel]);
            }
        }

        if (dstBoneWeights.Count == dstVertices.Count && srcBindposes != null && srcBindposes.Length > 0)
        {
            baked.boneWeights = dstBoneWeights.ToArray();
            baked.bindposes = srcBindposes;
        }

        if (source.blendShapeCount > 0 && dstSourceIndices.Count == dstVertices.Count)
        {
            CopyBlendShapes(source, baked, dstSourceIndices);
        }

        baked.subMeshCount = source.subMeshCount;
        for (int submesh = 0; submesh < source.subMeshCount; submesh++)
        {
            baked.SetIndices(dstSubmeshIndices[submesh], MeshTopology.Triangles, submesh, false);
        }

        baked.RecalculateBounds();
        return baked;
    }

    private static void CopyBlendShapes(Mesh source, Mesh baked, List<int> dstSourceIndices)
    {
        int srcCount = source.vertexCount;
        int dstCount = dstSourceIndices.Count;
        var srcDeltaVertices = new Vector3[srcCount];
        var srcDeltaNormals = new Vector3[srcCount];
        var srcDeltaTangents = new Vector3[srcCount];
        var dstDeltaVertices = new Vector3[dstCount];
        var dstDeltaNormals = new Vector3[dstCount];
        var dstDeltaTangents = new Vector3[dstCount];

        for (int shape = 0; shape < source.blendShapeCount; shape++)
        {
            string shapeName = source.GetBlendShapeName(shape);
            int frameCount = source.GetBlendShapeFrameCount(shape);
            for (int frame = 0; frame < frameCount; frame++)
            {
                source.GetBlendShapeFrameVertices(shape, frame, srcDeltaVertices, srcDeltaNormals, srcDeltaTangents);
                for (int i = 0; i < dstCount; i++)
                {
                    int src = dstSourceIndices[i];
                    dstDeltaVertices[i] = srcDeltaVertices[src];
                    dstDeltaNormals[i] = srcDeltaNormals[src];
                    dstDeltaTangents[i] = srcDeltaTangents[src];
                }

                baked.AddBlendShapeFrame(
                    shapeName,
                    source.GetBlendShapeFrameWeight(shape, frame),
                    dstDeltaVertices,
                    dstDeltaNormals,
                    dstDeltaTangents);
            }
        }
    }

    private static void AppendVertex(
        int sourceIndex,
        Vector4 edgeData0,
        Vector4 edgeData1,
        int sourceVertexCount,
        Vector3[] srcVertices,
        Vector3[] srcNormals,
        Vector4[] srcTangents,
        Color[] srcColors,
        BoneWeight[] srcBoneWeights,
        List<Vector4>[] srcUv,
        List<Vector3> dstVertices,
        List<Vector3> dstNormals,
        List<Vector4> dstTangents,
        List<Color> dstColors,
        List<BoneWeight> dstBoneWeights,
        List<Vector4>[] dstUv)
    {
        if (sourceIndex < 0 || sourceIndex >= sourceVertexCount)
        {
            return;
        }

        dstVertices.Add(srcVertices[sourceIndex]);

        if (srcNormals != null && srcNormals.Length == sourceVertexCount)
        {
            dstNormals.Add(srcNormals[sourceIndex]);
        }

        if (srcTangents != null && srcTangents.Length == sourceVertexCount)
        {
            dstTangents.Add(srcTangents[sourceIndex]);
        }

        if (srcColors != null && srcColors.Length == sourceVertexCount)
        {
            dstColors.Add(srcColors[sourceIndex]);
        }

        if (srcBoneWeights != null && srcBoneWeights.Length == sourceVertexCount)
        {
            dstBoneWeights.Add(srcBoneWeights[sourceIndex]);
        }

        for (int channel = 0; channel < srcUv.Length; channel++)
        {
            if (channel == 3)
            {
                dstUv[channel].Add(edgeData0);
                continue;
            }

            if (channel == 4)
            {
                dstUv[channel].Add(edgeData1);
                continue;
            }

            if (srcUv[channel] != null && srcUv[channel].Count == sourceVertexCount)
            {
                dstUv[channel].Add(srcUv[channel][sourceIndex]);
            }
        }
    }

    private static void AddEdge(Dictionary<EdgeKey, List<int>> edgeToTriangles, EdgeKey edge, int triId)
    {
        if (!edgeToTriangles.TryGetValue(edge, out List<int> list))
        {
            list = new List<int>(2);
            edgeToTriangles.Add(edge, list);
        }

        list.Add(triId);
    }

    private static float ComputeEdgeKeep(
        Dictionary<EdgeKey, List<int>> edgeToTriangles,
        List<TriangleInfo> triangles,
        int triId,
        EdgeKey edge,
        float cosThreshold)
    {
        if (!edgeToTriangles.TryGetValue(edge, out List<int> tris) || tris.Count == 0)
        {
            return 1.0f;
        }

        if (tris.Count == 1)
        {
            return 1.0f;
        }

        if (tris.Count > 2)
        {
            return 1.0f;
        }

        int otherTriId = tris[0] == triId ? tris[1] : tris[0];
        if (otherTriId < 0 || otherTriId >= triangles.Count)
        {
            return 1.0f;
        }

        float dot = Vector3.Dot(triangles[triId].Normal, triangles[otherTriId].Normal);
        return dot <= cosThreshold ? 1.0f : 0.0f;
    }

    private static Vector3 ComputeFaceNormal(Vector3 p0, Vector3 p1, Vector3 p2)
    {
        Vector3 n = Vector3.Cross(p1 - p0, p2 - p0);
        float lenSq = n.sqrMagnitude;
        if (lenSq <= 1e-12f)
        {
            return Vector3.up;
        }

        return n / Mathf.Sqrt(lenSq);
    }
}
