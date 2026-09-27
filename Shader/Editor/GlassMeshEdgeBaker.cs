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
    private const int ThicknessUvChannel = 5;

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
        int upgradedMeshCount = 0;

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

                Mesh baked = GetOrCreateBakedMesh(meshFilter.sharedMesh, bakedBySource, ref bakedMeshCount, ref upgradedMeshCount);
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

                Mesh baked = GetOrCreateBakedMesh(skinned.sharedMesh, bakedBySource, ref bakedMeshCount, ref upgradedMeshCount);
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
            $"Baked meshes: {bakedMeshCount}\nThickness added to existing baked meshes: {upgradedMeshCount}\nRenderers updated: {rendererCount}\nOutput: {OutputFolder}",
            "OK");
    }

    [MenuItem(MenuPath, true)]
    private static bool ValidateBakeSelected()
    {
        return Selection.gameObjects != null && Selection.gameObjects.Length > 0;
    }

    private static Mesh GetOrCreateBakedMesh(Mesh source, Dictionary<Mesh, Mesh> bakedBySource, ref int bakedMeshCount, ref int upgradedMeshCount)
    {
        if (source == null)
        {
            return null;
        }

        // Unity renames the mesh to its asset file name, which may carry a " 1" style suffix.
        if (source.name.Contains("_GlassEdge"))
        {
            // Meshes baked before thickness existed only need the thickness channel added in place.
            if (!bakedBySource.ContainsKey(source) &&
                !HasThicknessData(source) &&
                AssetDatabase.GetAssetPath(source).EndsWith(".asset"))
            {
                BakeThickness(source);
                EditorUtility.SetDirty(source);
                upgradedMeshCount++;
            }

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
                new Vector4(keep.y, keep.z, 0.0f, -1.0f),
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
                new Vector4(keep.y, keep.z, 0.0f, -1.0f),
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
                new Vector4(keep.y, keep.z, 0.0f, -1.0f),
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
        BakeThickness(baked);
        return baked;
    }

    private static bool HasThicknessData(Mesh mesh)
    {
        var uv = new List<Vector4>();
        mesh.GetUVs(ThicknessUvChannel, uv);
        return uv.Count == mesh.vertexCount && (uv.Count == 0 || uv[0].w < -0.5f);
    }

    // Stores per vertex (UV5.x, object space; UV5.w = -1 marks baked data) how far light travels through the body when entering along
    // the face normal: a pane gets its thickness on the faces and its width on the cut edges.
    // Faces whose inward ray leaves the mesh open (single-sided surfaces) get 0, and the shader falls back.
    private static void BakeThickness(Mesh mesh)
    {
        const float rayEpsilon = 1e-5f;

        Vector3[] vertices = mesh.vertices;
        int count = vertices.Length;
        float scale = mesh.bounds.size.magnitude;
        if (count == 0 || scale <= 0f)
        {
            return;
        }

        // Work in unit-size space so epsilons hold for any import scale (e.g. Blender FBX at 0.01).
        var local = new Vector3[count];
        for (int i = 0; i < count; i++)
        {
            local[i] = vertices[i] / scale;
        }

        var sum = new float[count];
        var hits = new int[count];
        for (int submesh = 0; submesh < mesh.subMeshCount; submesh++)
        {
            if (mesh.GetTopology(submesh) != MeshTopology.Triangles)
            {
                continue;
            }

            int[] indices = mesh.GetIndices(submesh);
            var bvh = new TriangleBvh(local, indices);
            for (int i = 0; i + 2 < indices.Length; i += 3)
            {
                Vector3 a = local[indices[i]];
                Vector3 b = local[indices[i + 1]];
                Vector3 c = local[indices[i + 2]];
                Vector3 normal = Vector3.Cross(b - a, c - a);
                if (normal.sqrMagnitude <= 1e-20f)
                {
                    continue;
                }

                // Not Normalize(): it returns zero below 1e-5 length, which thin cut-edge triangles reach here.
                normal /= Mathf.Sqrt(normal.sqrMagnitude);
                Vector3 origin = (a + b + c) / 3f - normal * rayEpsilon;
                float t = bvh.Raycast(origin, -normal, i / 3);
                if (t < 0f)
                {
                    continue;
                }

                float thickness = (t + rayEpsilon) * scale;
                for (int k = 0; k < 3; k++)
                {
                    sum[indices[i + k]] += thickness;
                    hits[indices[i + k]]++;
                }
            }
        }

        // Baked meshes are unwelded; average corners that share position and normal so smooth surfaces stay smooth.
        Vector3[] normals = mesh.normals;
        bool hasNormals = normals != null && normals.Length == count;
        var groups = new Dictionary<(Vector3, Vector3), Vector2>();
        for (int i = 0; i < count; i++)
        {
            var key = (vertices[i], hasNormals ? normals[i] : Vector3.zero);
            groups.TryGetValue(key, out Vector2 acc);
            groups[key] = acc + new Vector2(sum[i], hits[i]);
        }

        var uv = new List<Vector4>(count);
        for (int i = 0; i < count; i++)
        {
            Vector2 acc = groups[(vertices[i], hasNormals ? normals[i] : Vector3.zero)];
            uv.Add(new Vector4(acc.y > 0f ? acc.x / acc.y : 0f, 0f, 0f, -1f));
        }

        mesh.SetUVs(ThicknessUvChannel, uv);
    }

    // Median-split BVH over one submesh for closest-hit raycasts (two-sided).
    private sealed class TriangleBvh
    {
        private const int LeafSize = 4;

        private struct Node
        {
            public Vector3 Min;
            public Vector3 Max;
            public int Left;
            public int Right;
            public int Start;
            public int Count;
        }

        private readonly Vector3[] _v0;
        private readonly Vector3[] _e1;
        private readonly Vector3[] _e2;
        private readonly int[] _tris;
        private readonly List<Node> _nodes = new List<Node>();
        private readonly Stack<int> _stack = new Stack<int>();

        public TriangleBvh(Vector3[] vertices, int[] indices)
        {
            int triCount = indices.Length / 3;
            _v0 = new Vector3[triCount];
            _e1 = new Vector3[triCount];
            _e2 = new Vector3[triCount];
            _tris = new int[triCount];
            var centroids = new Vector3[triCount];
            for (int t = 0; t < triCount; t++)
            {
                Vector3 a = vertices[indices[t * 3]];
                Vector3 b = vertices[indices[t * 3 + 1]];
                Vector3 c = vertices[indices[t * 3 + 2]];
                _v0[t] = a;
                _e1[t] = b - a;
                _e2[t] = c - a;
                centroids[t] = (a + b + c) / 3f;
                _tris[t] = t;
            }

            if (triCount > 0)
            {
                Build(0, triCount, centroids);
            }
        }

        private int Build(int start, int count, Vector3[] centroids)
        {
            var node = new Node
            {
                Min = Vector3.positiveInfinity,
                Max = Vector3.negativeInfinity,
                Left = -1,
                Right = -1,
                Start = start,
                Count = count
            };

            Vector3 cMin = Vector3.positiveInfinity;
            Vector3 cMax = Vector3.negativeInfinity;
            for (int i = start; i < start + count; i++)
            {
                int t = _tris[i];
                Vector3 a = _v0[t];
                Vector3 b = a + _e1[t];
                Vector3 c = a + _e2[t];
                node.Min = Vector3.Min(node.Min, Vector3.Min(a, Vector3.Min(b, c)));
                node.Max = Vector3.Max(node.Max, Vector3.Max(a, Vector3.Max(b, c)));
                cMin = Vector3.Min(cMin, centroids[t]);
                cMax = Vector3.Max(cMax, centroids[t]);
            }

            int nodeIndex = _nodes.Count;
            _nodes.Add(node);

            Vector3 extent = cMax - cMin;
            int axis = extent.x >= extent.y && extent.x >= extent.z ? 0 : (extent.y >= extent.z ? 1 : 2);
            if (count > LeafSize && extent[axis] > 0f)
            {
                System.Array.Sort(_tris, start, count,
                    Comparer<int>.Create((x, y) => centroids[x][axis].CompareTo(centroids[y][axis])));
                int half = count / 2;
                node.Left = Build(start, half, centroids);
                node.Right = Build(start + half, count - half, centroids);
                node.Count = 0;
                _nodes[nodeIndex] = node;
            }

            return nodeIndex;
        }

        // Returns the distance to the closest triangle hit (excluding skipTri), or -1.
        public float Raycast(Vector3 origin, Vector3 dir, int skipTri)
        {
            if (_nodes.Count == 0)
            {
                return -1f;
            }

            var invDir = new Vector3(SafeRcp(dir.x), SafeRcp(dir.y), SafeRcp(dir.z));
            float best = float.MaxValue;
            _stack.Clear();
            _stack.Push(0);
            while (_stack.Count > 0)
            {
                Node node = _nodes[_stack.Pop()];
                if (!HitBox(node, origin, invDir, best))
                {
                    continue;
                }

                if (node.Left < 0)
                {
                    for (int i = node.Start; i < node.Start + node.Count; i++)
                    {
                        int t = _tris[i];
                        if (t == skipTri)
                        {
                            continue;
                        }

                        float hit = IntersectTriangle(origin, dir, t);
                        if (hit > 1e-7f && hit < best)
                        {
                            best = hit;
                        }
                    }
                }
                else
                {
                    _stack.Push(node.Left);
                    _stack.Push(node.Right);
                }
            }

            return best < float.MaxValue ? best : -1f;
        }

        private float IntersectTriangle(Vector3 origin, Vector3 dir, int t)
        {
            Vector3 e1 = _e1[t];
            Vector3 e2 = _e2[t];
            Vector3 p = Vector3.Cross(dir, e2);
            float det = Vector3.Dot(e1, p);
            if (Mathf.Abs(det) < 1e-12f)
            {
                return -1f;
            }

            float invDet = 1f / det;
            Vector3 s = origin - _v0[t];
            float u = Vector3.Dot(s, p) * invDet;
            if (u < 0f || u > 1f)
            {
                return -1f;
            }

            Vector3 q = Vector3.Cross(s, e1);
            float v = Vector3.Dot(dir, q) * invDet;
            if (v < 0f || u + v > 1f)
            {
                return -1f;
            }

            return Vector3.Dot(e2, q) * invDet;
        }

        private static bool HitBox(Node node, Vector3 origin, Vector3 invDir, float maxT)
        {
            float t0 = 0f;
            float t1 = maxT;
            for (int axis = 0; axis < 3; axis++)
            {
                float near = (node.Min[axis] - origin[axis]) * invDir[axis];
                float far = (node.Max[axis] - origin[axis]) * invDir[axis];
                if (near > far)
                {
                    float tmp = near;
                    near = far;
                    far = tmp;
                }

                t0 = Mathf.Max(t0, near);
                t1 = Mathf.Min(t1, far);
                if (t0 > t1)
                {
                    return false;
                }
            }

            return true;
        }

        private static float SafeRcp(float value)
        {
            return Mathf.Abs(value) > 1e-12f ? 1f / value : (value >= 0f ? 1e12f : -1e12f);
        }
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
