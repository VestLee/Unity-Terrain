using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using UnityEngine;
using UnityEditor;

public class FastTerrain : MonoBehaviour
{
    public Texture2D albedoAtlas;
    public Texture2D WeightAtlas;
    public Texture2D normalAtlas;

    public Texture2DArray albedoArray;
    public Texture2DArray WeightArray;

    //slplat 区分id和Weight 主要是因为 id不能插值 但weight需要插值 如果分辨率精度够大 point 采样够平滑 就不需要分2张
    public Texture2D splatID;
    public Texture2D splatWeight;
    public Shader terrainShader;
    public TerrainData normalTerrainData;
    public TerrainData empytTerrainData;
    [ContextMenu("MakeAlbedoAtlas")]
    void MakeAlbedoAtlas()
    {
        int sqrCount = 4;
        int wid = normalTerrainData.terrainLayers[0].diffuseTexture.width;
        int hei =normalTerrainData.terrainLayers[0].diffuseTexture.height;


        albedoAtlas = new Texture2D(sqrCount * wid, sqrCount * hei, TextureFormat.RGBA32, true);
        //normalAtlas = new Texture2D(sqrCount * wid, sqrCount * hei, TextureFormat.RGBA32, true);

        for (int i = 0; i < sqrCount; i++)
        {
            for (int j = 0; j < sqrCount; j++)
            {
                int index = i * sqrCount + j;

                if (index >= normalTerrainData.terrainLayers.Length) break;
                albedoAtlas.SetPixels(j * (wid), i * (hei), wid, hei,
                    normalTerrainData.terrainLayers[index].diffuseTexture.GetPixels());
                //normalAtlas.SetPixels(j * (wid), i * (hei), wid, hei,
                //    normalTerrainData.terrainLayers[index].normalMapTexture.GetPixels());
            }
        }

        albedoAtlas.Apply();
        //normalAtlas.Apply();
        File.WriteAllBytes(Application.dataPath+ "/Terrain Assets/TerrainAtlas/albedoAtlas.png", albedoAtlas.EncodeToPNG());
        //File.WriteAllBytes(Application.dataPath+"/normalAtlas.png",normalAtlas.EncodeToPNG());
        DestroyImmediate(albedoAtlas);
        //DestroyImmediate(normalAtlas);
    }

    [ContextMenu("MakeWeightMapAtlas")]
    void MakeWeightMapAtlas()
    {
        int sqrCount = 2;
        int wid = normalTerrainData.alphamapTextures[0].width;
        int hei = normalTerrainData.alphamapTextures[0].height;


        WeightAtlas = new Texture2D(sqrCount * wid, sqrCount * hei, TextureFormat.RGBA32, true);
        //normalAtlas = new Texture2D(sqrCount * wid, sqrCount * hei, TextureFormat.RGBA32, true);

        for (int i = 0; i < sqrCount; i++)
        {
            for (int j = 0; j < sqrCount; j++)
            {
                int index = i * sqrCount + j;

                if (index >= normalTerrainData.alphamapTextures.Length) break;
                WeightAtlas.SetPixels(j * (wid), i * (hei), wid, hei,
                    normalTerrainData.alphamapTextures[index].GetPixels());
                //normalAtlas.SetPixels(j * (wid), i * (hei), wid, hei,
                //    normalTerrainData.terrainLayers[index].normalMapTexture.GetPixels());
            }
        }

        WeightAtlas.Apply();
        //normalAtlas.Apply();
        File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMaps/WeightMapAtlas.png", WeightAtlas.EncodeToPNG());
        //File.WriteAllBytes(Application.dataPath+"/normalAtlas.png",normalAtlas.EncodeToPNG());
        DestroyImmediate(WeightAtlas);
        //DestroyImmediate(normalAtlas);
    }


    struct SplatData2Layers
    {
        public int id;
        public float weight;
    }
    struct SplatData
    {
        public int id;
        public float weight;
        public float nearWeight;
    }

    [ContextMenu("MakeRawSplats")]
    void MakeRawSplat()
    {
        for (int i = 0; i < normalTerrainData.alphamapTextures.Length; i++)
        {
            File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMAps/SplatMap" + i + ".png", normalTerrainData.alphamapTextures[i].EncodeToPNG());
        }
    }

    [ContextMenu("Make2LayersSplats")]
    void Make2LayersSplat()
    {
        int wid = normalTerrainData.alphamapTextures[0].width;
        int hei = normalTerrainData.alphamapTextures[0].height;
        List<Color[]> colors = new List<Color[]>();
        for (int i = 0; i < normalTerrainData.alphamapTextures.Length; i++)
        {
            colors.Add(normalTerrainData.alphamapTextures[i].GetPixels());
        }
        splatID = new Texture2D(wid, hei, TextureFormat.RGBA32, false, true);
        splatID.filterMode = FilterMode.Point;
        var splatIDColors = splatID.GetPixels32();

        for (int i = 0; i < hei; i++)
        {
            for (int j = 0; j < wid; j++)
            {
                List<SplatData2Layers> splatDatas = new List<SplatData2Layers>();
                int index = i * wid + j;
                for (int k = 0; k < colors.Count; k++)
                {
                    SplatData2Layers sd;
                    sd.id = k * 4;
                    sd.weight = colors[k][index].r;
                    splatDatas.Add(sd);

                    sd.id++;
                    sd.weight = colors[k][index].g;

                    splatDatas.Add(sd);
                    sd.id++;
                    sd.weight = colors[k][index].b;

                    splatDatas.Add(sd);
                    sd.id++;
                    sd.weight = colors[k][index].a;

                    splatDatas.Add(sd);
                }
                splatDatas.Sort((x, y) => -(x.weight).CompareTo(y.weight));

                splatIDColors[index].r = (byte)(((splatDatas[0].id % 4 * 4) << 4) + (splatDatas[0].id / 4 * 4));
                splatIDColors[index].g = (byte)(((splatDatas[0].id % 4 * 4) << 4) + (splatDatas[0].id / 4 * 4));
                splatIDColors[index].b = splatDatas[0].weight > 0.5 ? (byte)(splatDatas[0].weight * 256) : (byte)(((1 - splatDatas[0].weight) * 256));
                //Debug.Log("ID:" + splatDatas[0].id + "," + splatDatas[1].id + ",Weight:" + splatDatas[0].weight + ",color:" + splatIDColors[index]);
            }
        }
        splatID.SetPixels32(splatIDColors);
        splatID.Apply();
        File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMaps/splatID2Layers.png", splatID.EncodeToPNG());
        DestroyImmediate(splatID);
    }


    [ContextMenu("Make 2Layers Splat ID&Weight Textures")]
    // Update is called once per frame
    void Make2LayersSplatIDandWeight()
    {
        int wid = normalTerrainData.alphamapTextures[0].width;
        int hei = normalTerrainData.alphamapTextures[0].height;
        List<Color[]> colors = new List<Color[]>();
        for (int i = 0; i < normalTerrainData.alphamapTextures.Length; i++)
        {
            colors.Add(normalTerrainData.alphamapTextures[i].GetPixels());
        }
        splatID = new Texture2D(wid, hei, TextureFormat.RGBA32, false, true);
        splatID.filterMode = FilterMode.Point;
        var splatIDColors = splatID.GetPixels32();

        // 改用图片文件时可设置压缩为R8 代码生成有格式限制 空间有点浪费
        splatWeight = new Texture2D(wid, hei, TextureFormat.RGB24, false, true);
        splatWeight.filterMode = FilterMode.Bilinear;
        var splatWeightColors = splatWeight.GetPixels();
        

        for (int i = 0; i < hei; i++)
        {
            for (int j = 0; j < wid; j++)
            {
                List<SplatData> splatDatas = new List<SplatData>();
                int index = i * wid + j;
                for (int k = 0; k < colors.Count; k++)
                {
                    SplatData sd;
                    sd.id = k * 4;
                    sd.weight = colors[k][index].r;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 0);
                    splatDatas.Add(sd);

                    sd.id++;
                    sd.weight = colors[k][index].g;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 1);

                    splatDatas.Add(sd);
                    sd.id++;
                    sd.weight = colors[k][index].b;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 2);

                    splatDatas.Add(sd);
                    sd.id++;
                    sd.weight = colors[k][index].a;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 3);

                    splatDatas.Add(sd);
                }

                splatDatas.Sort((x, y) => -(x.weight).CompareTo(y.weight));
                splatIDColors[index].r = (byte)(((splatDatas[0].id % 4 * 4) << 4) + (splatDatas[0].id / 4 * 4));
                //Debug.Log(splatIDColors[index].r);
                splatWeightColors[index].r = splatDatas[0].weight;// / (splatDatas[0].weight + splatDatas[1].weight);
                //Debug.Log("行：" + i + "、列：" + j + "、id：" + splatDatas[0].id + "、weight：" + splatWeightColors[index].r);

                splatDatas.Sort((x, y) => -(x.weight + x.nearWeight / 2).CompareTo(y.weight + y.nearWeight / 2));
                splatIDColors[index].g = (byte)(((splatDatas[0].id % 4 * 4) << 4) + (splatDatas[0].id / 4 * 4));

                if (splatIDColors[index].r == splatIDColors[index].g)
                    splatIDColors[index].g = (byte)(((splatDatas[1].id % 4 * 4) << 4) + (splatDatas[1].id / 4 * 4));
                //Debug.Log("ID:" + splatDatas[0].id + "& Weight:" + splatDatas[0].weight + "," + "ID:" + splatDatas[1].id + "& Weight:" + splatDatas[1].weight + ","+ "ID:" + splatDatas[2].id + "& Weight:" + splatDatas[2].weight + ","+ "ID:" + splatDatas[3].id + "& Weight:" + splatDatas[3].weight );
                //Debug.Log("行：" + i + "、列：" + j + "、id：" + splatDatas[0].id + " or" + splatDatas[1].id);
                splatIDColors[index].b = 0;
                splatWeightColors[index].g = splatWeightColors[index].b = 0;

                int swapID = 0;
                if (j > 0)
                {
                    if (splatIDColors[index].r == splatIDColors[index - 1].g ||
                        splatIDColors[index].g == splatIDColors[index - 1].r)
                    {
                        swapID = 1;
                    }
                }

                if (i > 0)
                {
                    if (splatIDColors[index].r == splatIDColors[index - wid].g ||
                        splatIDColors[index].g == splatIDColors[index - wid].r)
                    {
                        swapID = 1;
                    }
                }

                if (swapID == 1)
                {
                    byte tmp = splatIDColors[index].r;
                    splatIDColors[index].r = splatIDColors[index].g;
                    splatIDColors[index].g = tmp;
                    splatWeightColors[index].r = 1 - splatWeightColors[index].r;
                }
                //只存最重要2个图层 用一点压缩方案可以一张图存更多图层 ,这里最多支持16张
                //Debug.Log(splatDatas[0].id + " & " + splatDatas[1].id + " Swap " + splatDatas[swapID].id + " & " + splatDatas[1 - swapID].id);

                //splatWeightColors[index].r = splatDatas[swapID].weight;
                //splatWeightColors[index].r = splatDatas[swapID].weight > 0.5 ? splatDatas[swapID].weight : 1 - splatDatas[swapID].weight;
                //splatWeightColors[index].r = splatDatas[swapID].weight + (1 - splatDatas[0].weight - splatDatas[1].weight) / 2; //2张以后丢弃的权重平均加到这2张


                //只存最重要2个图层 用一点压缩方案可以一张图存更多图层 ,这里最多支持16张
                //splatIDColors[index].r = 1/ 16f; //
                //splatIDColors[index].g = 1 / 16f;
                //splatIDColors[index].b = 0;
                //splatWeightColors[index].r = 0.6f;//2张以后丢弃的权重平均加到这2张
                //splatWeightColors[index].g = splatWeightColors[index].b = 0;

                //Debug.Log("ID:" + splatDatas[0].id + "," + splatDatas[1].id + ",Weight:" + splatDatas[0].weight + ",color:" + splatIDColors[index]);
            }
        }

        splatID.SetPixels32(splatIDColors);
        splatID.Apply();

        splatWeight.SetPixels(splatWeightColors);
        splatWeight.Apply();

        File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMaps/SplatID2LayersSorted.png", splatID.EncodeToPNG());
        File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMaps/SplatWeight2LayersDorted.png", splatWeight.EncodeToPNG());
        DestroyImmediate(splatID);
        DestroyImmediate(splatWeight);
    }

    [ContextMenu("Make 3Layers Splat ID&Weight Textures")]
    // Update is called once per frame
    void Make3LayersSplatIDandWeight()
    {
        int wid = normalTerrainData.alphamapTextures[0].width;
        int hei = normalTerrainData.alphamapTextures[0].height;
        List<Color[]> colors = new List<Color[]>();
        for (int i = 0; i < normalTerrainData.alphamapTextures.Length; i++)
        {
            colors.Add(normalTerrainData.alphamapTextures[i].GetPixels());
        }
        splatID = new Texture2D(wid, hei, TextureFormat.RGBA32, false, true);
        splatID.filterMode = FilterMode.Point;
        var splatIDColors = splatID.GetPixels32();

        // 改用图片文件时可设置压缩为R8 代码生成有格式限制 空间有点浪费
        splatWeight = new Texture2D(wid, hei, TextureFormat.RGB24, false, true);
        splatWeight.filterMode = FilterMode.Bilinear;
        var splatWeightColors = splatWeight.GetPixels();


        for (int i = 0; i < hei; i++)
        {
            for (int j = 0; j < wid; j++)
            {
                List<SplatData> splatDatas = new List<SplatData>();
                int index = i * wid + j;
                for (int k = 0; k < colors.Count; k++)
                {
                    SplatData sd;
                    sd.id = k * 4;
                    sd.weight = colors[k][index].r;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 0);
                    splatDatas.Add(sd);

                    sd.id++;
                    sd.weight = colors[k][index].g;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 1);

                    splatDatas.Add(sd);
                    sd.id++;
                    sd.weight = colors[k][index].b;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 2);

                    splatDatas.Add(sd);
                    sd.id++;
                    sd.weight = colors[k][index].a;
                    sd.nearWeight = getNearWeight(colors[k], index, wid, 3);

                    splatDatas.Add(sd);
                }

                splatDatas.Sort((x, y) => -(x.weight).CompareTo(y.weight));
                splatIDColors[index].r = (byte)(((splatDatas[0].id % 4 * 4) << 4) + (splatDatas[0].id / 4 * 4));
                splatWeightColors[index].r = splatDatas[0].weight;
                //Debug.Log("行：" + i + "、列：" + j + "、id：" + splatDatas[0].id + "、weight：" + splatWeightColors[index].r);

                splatDatas.Sort((x, y) => -(x.weight + x.nearWeight / 2).CompareTo(y.weight + y.nearWeight / 2));
                splatIDColors[index].g = (byte)(((splatDatas[0].id % 4 * 4) << 4) + (splatDatas[0].id / 4 * 4));
                splatIDColors[index].b = (byte)(((splatDatas[1].id % 4 * 4) << 4) + (splatDatas[1].id / 4 * 4));
                splatWeightColors[index].g = splatDatas[0].weight;
                splatWeightColors[index].b = splatDatas[1].weight;
                splatWeightColors[index].r = 1 - splatDatas[0].weight - splatDatas[1].weight;

                if (splatIDColors[index].r == splatIDColors[index].g)
                {
                    splatIDColors[index].g = (byte)(((splatDatas[1].id % 4 * 4) << 4) + (splatDatas[1].id / 4 * 4));
                    splatIDColors[index].b = (byte)(((splatDatas[2].id % 4 * 4) << 4) + (splatDatas[2].id / 4 * 4));

                    splatWeightColors[index].g = splatDatas[1].weight;
                    splatWeightColors[index].b = splatDatas[2].weight;
                    splatWeightColors[index].r = 1 - splatDatas[1].weight - splatDatas[2].weight;
                }
                else if (splatIDColors[index].r == splatIDColors[index].b)
                {
                    splatIDColors[index].b = (byte)(((splatDatas[2].id % 4 * 4) << 4) + (splatDatas[2].id / 4 * 4));
                    splatWeightColors[index].g = splatDatas[0].weight;
                    splatWeightColors[index].b = splatDatas[2].weight;
                    splatWeightColors[index].r = 1 - splatDatas[0].weight - splatDatas[2].weight;
                }

            }
        }

        splatID.SetPixels32(splatIDColors);
        splatID.Apply();

        splatWeight.SetPixels(splatWeightColors);
        splatWeight.Apply();

        File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMaps/SplatID3LayersSorted.png", splatID.EncodeToPNG());
        File.WriteAllBytes(Application.dataPath + "/Terrain Assets/SplatMaps/SplatWeight3LayersDorted.png", splatWeight.EncodeToPNG());
        DestroyImmediate(splatID);
        DestroyImmediate(splatWeight);
    }

    [ContextMenu("Make 3Layers Texture2DArray")]
    // Update is called once per frame
    void Make3LayersTexture2DArray()
    {
        int alphamapTextureswid = normalTerrainData.alphamapTextures[0].width;
        int alphamapTextureshei = normalTerrainData.alphamapTextures[0].height;
        WeightArray = new Texture2DArray(alphamapTextureswid, alphamapTextureshei, normalTerrainData.alphamapTextures.Length, TextureFormat.RGBA32, false);
        for (int index = 0; index < normalTerrainData.alphamapTextures.Length; index++)
        {
            WeightArray.SetPixels32(normalTerrainData.alphamapTextures[index].GetPixels32(), index, 0);
        }
        WeightArray.Apply();
        WeightArray.wrapMode = TextureWrapMode.Clamp;
        WeightArray.filterMode = FilterMode.Bilinear;


        int terrainLayerwid = normalTerrainData.terrainLayers[0].diffuseTexture.width;
        int terrainLayerhei = normalTerrainData.terrainLayers[0].diffuseTexture.height;
        albedoArray = new Texture2DArray(terrainLayerwid, terrainLayerhei, normalTerrainData.terrainLayers.Length, TextureFormat.RGBA32, false);
        for (int index = 0; index < normalTerrainData.terrainLayers.Length; index++)
        {
            albedoArray.SetPixels(normalTerrainData.terrainLayers[index].diffuseTexture.GetPixels(), index, 0);
        }
        albedoArray.Apply();
        albedoArray.wrapMode = TextureWrapMode.Clamp;
        albedoArray.filterMode = FilterMode.Bilinear;

        AssetDatabase.CreateAsset(albedoArray, "Assets/Terrain Assets/Texture2DArray/AlbedoArray.asset");
        AssetDatabase.CreateAsset(WeightArray, "Assets/Terrain Assets/Texture2DArray/weightArray.asset");
        //AssetDatabase.CreateAsset(albedoArray, Application.dataPath + "/Terrain Assets/Texture2DArray/AlbedoArray.asset");
        //AssetDatabase.CreateAsset(WeightArray, Application.dataPath + "/Terrain Assets/Texture2DArray/weightArray.asset");
        //DestroyImmediate(albedoArray);
        //DestroyImmediate(WeightArray);
    }


    private float getNearWeight(Color[] colors, int index, int wid, int rgba)
    {
        float value = 0;
        for (int i = 1; i <= 3; i++)
        {
            value += colors[(index + colors.Length - i) % colors.Length][rgba];
            value += colors[(index + colors.Length + i) % colors.Length][rgba];
            value += colors[(index + colors.Length - wid * i) % colors.Length][rgba];
            value += colors[(index + colors.Length + wid * i) % colors.Length][rgba];
            value += colors[(index + colors.Length + (-1 - wid) * i) % colors.Length][rgba];
            value += colors[(index + colors.Length + (-1 + wid) * i) % colors.Length][rgba];
            value += colors[(index + colors.Length + (1 - wid) * i) % colors.Length][rgba];
            value += colors[(index + colors.Length + (1 + wid) * i) % colors.Length][rgba];
        }

        return value / (8 * 3);
    }


  
    [ContextMenu("UseFastMode")]
    void useFastMode()
    {
        Terrain t = GetComponent<Terrain>();
        t.terrainData = empytTerrainData;
       
        t.materialType = Terrain.MaterialType.Custom;
        if (t.materialTemplate == null)
        {
            t.materialTemplate = new Material(terrainShader);
        }
        else
        {
            t.materialTemplate.shader = terrainShader;
        }

        Shader.SetGlobalTexture("SpaltIDTex", splatID);
        Shader.SetGlobalTexture("SpaltWeightTex", splatWeight);
        Shader.SetGlobalTexture("AlbedoAtlas", albedoAtlas);
        Shader.SetGlobalTexture("NormalAtlas", normalAtlas);
    }

    [ContextMenu("UseBuildinMode")]
    void useBuildinMode()
    {
        Terrain t = GetComponent<Terrain>();
        t.terrainData = normalTerrainData;
        t.materialType = Terrain.MaterialType.BuiltInStandard;
        t.materialTemplate = null;
    }


    private bool fastMode = false;

    private void OnGUI()
    {
        if (GUILayout.Button(fastMode ? "自定义渲染ing" : "引擎默认渲染ing"))
        {
            fastMode = !fastMode;
            if (fastMode)
            {
                useFastMode();
            }
            else
            {
                useBuildinMode();
            }
        }
    }
}