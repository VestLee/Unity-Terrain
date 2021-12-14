Shader "UWAShaders/UWA3LayersTexture2DArray"
{
    Properties
    {
        _Textures("Textures", 2DArray) = "" {}
        _SplatMapsTexArr("SplatMaps Array", 2DArray) = "" {}
        _BlendIDTex("BlendIDTex", 2D) = "white" {}

    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        // LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        //#pragma exclude_renderers d3d11

        #pragma target 3.5
        //#pragma exclude_renderers gles
        #include "UnityCG.cginc"

        //#define TERRAIN_STANDARD_SHADER
        //#define _NORMALMAP
        //#define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard

        UNITY_DECLARE_TEX2DARRAY(_Textures);
        UNITY_DECLARE_TEX2DARRAY(_SplatMapsTexArr);


        sampler2D _BlendIDTex;

        struct Input
        {
            float2 uv_BlendIDTex;
            float2 uv_SplatMapsTexArr;
            float2 uv_Textures;
        };

        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
        UNITY_INSTANCING_BUFFER_END(Props)

        float GetWeight(float4 clr, int index)
        {
            return index == 0 ? clr.r : (index == 1 ? clr.g : (index == 2 ? clr.b : clr.a));
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {

            //Index
            float3 encodedIndices = tex2D(_BlendIDTex, IN.uv_BlendIDTex).xyz;
            int3 ThreeHorizontalIndices = floor(encodedIndices * 16.0);
            int3 ThreeVerticalIndices = floor((encodedIndices * 256.0)) - (16.0 * ThreeHorizontalIndices);

            float3 BlockMainTexIndex;
            BlockMainTexIndex.x = float(ThreeVerticalIndices.x + ThreeHorizontalIndices.x / 4);
            BlockMainTexIndex.y = float(ThreeVerticalIndices.y + ThreeHorizontalIndices.y / 4);
            BlockMainTexIndex.z = float(ThreeVerticalIndices.z + ThreeHorizontalIndices.z / 4);

            float3 SplatMapIndex;
            SplatMapIndex.x = float((ThreeVerticalIndices.x + ThreeHorizontalIndices.x / 4) / 4);
            SplatMapIndex.y = float((ThreeVerticalIndices.y + ThreeHorizontalIndices.x / 4) / 4);
            SplatMapIndex.z = float((ThreeVerticalIndices.z + ThreeHorizontalIndices.x / 4) / 4);

            int WeightFlagR = ThreeHorizontalIndices.x / 4 % 4;
            int WeightFlagG = ThreeHorizontalIndices.y / 4 % 4;
            int WeightFlagB = ThreeHorizontalIndices.z / 4 % 4;

            float4 col0 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(IN.uv_Textures, BlockMainTexIndex.x));
            float4 col1 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(IN.uv_Textures, BlockMainTexIndex.y));
            float4 col2 = UNITY_SAMPLE_TEX2DARRAY(_Textures, float3(IN.uv_Textures, BlockMainTexIndex.z));

            float WeightR = GetWeight(UNITY_SAMPLE_TEX2DARRAY(_SplatMapsTexArr, float3(IN.uv_SplatMapsTexArr, SplatMapIndex.x)), WeightFlagR);
            float WeightG = GetWeight(UNITY_SAMPLE_TEX2DARRAY(_SplatMapsTexArr, float3(IN.uv_SplatMapsTexArr, SplatMapIndex.y)), WeightFlagG);
            float WeightB = GetWeight(UNITY_SAMPLE_TEX2DARRAY(_SplatMapsTexArr, float3(IN.uv_SplatMapsTexArr, SplatMapIndex.z)), WeightFlagB);

            // Blend the two textures
            float4 col = col0 * (1 - WeightG - WeightB) + col1 * WeightG + col2 * WeightB;

            o.Albedo = col.rgb; 
            o.Alpha = col.a;
        }
        ENDCG
    }
        Fallback "Nature/Terrain/Diffuse"
}
