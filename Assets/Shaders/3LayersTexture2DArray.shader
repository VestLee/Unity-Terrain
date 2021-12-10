Shader "UWAShaders/UWA3LayersTexture2DArray"
{
    Properties
    {
        _BlockMainTexArr("BlockMainTex Array", 2DArray) = "" {}
        _SplatMapsTexArr("SplatMaps Array", 2DArray) = "" {}
        _BlendIDTex("BlendIDTex", 2D) = "white" {}

    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            // LOD 200

            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members uv_BlendIDTex)
            #pragma exclude_renderers d3d11
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma surface surf Standard fullforwardshadows

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            #pragma exclude_renderers gles
            #include "UnityPBSLighting.cginc"

            #define TERRAIN_STANDARD_SHADER
            #define _NORMALMAP
            #define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard

            UNITY_DECLARE_TEX2DARRAY(_BlockMainTexArr);
            UNITY_DECLARE_TEX2DARRAY(_SplatMapsTexArr);

            //
            sampler2D _BlockMainTex;
            float4 _BlockMainTex_ST;
            sampler2D _BlendIDTex;
            //float4 _BlendIDTex_ST;
            sampler2D _BlendWeightTex;
            //float4 _BlendWeightTex_ST;

            float _BlockScale;
            //

            struct Input
        {
            float4 pos : SV_POSITION;
            float2 uv_BlendIDTex;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float GetWeight(float4 clr, int index)
        {
            return index == 0 ? clr.r : (index == 1 ? clr.g : (index == 2 ? clr.b : clr.a));
        }

        void surf(Input IN, inout SurfaceOutputStandard o)
        {

            //Index
            float3 encodedIndices = tex2D(_BlendIDTex, IN.uv_BlendIDTex).xyz;
            float3 ThreeHorizontalIndices = floor((encodedIndices * 16.0));
            float3 ThreeVerticalIndices = (floor((encodedIndices * 256.0)) - (16.0 * ThreeHorizontalIndices));

            float3 BlockMainTexIndex = ThreeVerticalIndices + ThreeHorizontalIndices / 4;
            float3 SplatMapIndex = ThreeVerticalIndices / 4 + ThreeHorizontalIndices / 4 / 2;

            int WeightFlagG = (int)ThreeHorizontalIndices.y / 4 % 4;
            int WeightFlagB = (int)ThreeHorizontalIndices.z / 4 % 4;
            //

            //
            //float3 uv0 = float3(IN.uv, BlockMainTexIndex.x);
            float3 uv0 = float3(IN.uv_BlendIDTex, 0);
            float3 uv1 = float3(IN.uv_BlendIDTex, BlockMainTexIndex.y);
            float3 uv2 = float3(IN.uv_BlendIDTex, BlockMainTexIndex.z);
            // Sample the two texture
            float4 col0 = UNITY_SAMPLE_TEX2DARRAY(_BlockMainTexArr, uv0);
            float4 col1 = UNITY_SAMPLE_TEX2DARRAY(_BlockMainTexArr, uv1);
            float4 col2 = UNITY_SAMPLE_TEX2DARRAY(_BlockMainTexArr, uv2);

            float WeightG = GetWeight(UNITY_SAMPLE_TEX2DARRAY(_SplatMapsTexArr, float3(IN.uv_BlendIDTex, SplatMapIndex.y)), WeightFlagG);
            float WeightB = GetWeight(UNITY_SAMPLE_TEX2DARRAY(_SplatMapsTexArr, float3(IN.uv_BlendIDTex, SplatMapIndex.z)), WeightFlagB);


            //float4 col0 = tex2D(_BlockMainTex, uv0);
            //float4 col1 = tex2D(_BlockMainTex, uv1);
            // Blend the two textures
            float4 col = col0 * (1 - WeightG - WeightB)
                + col1 * WeightG
                + col2 * WeightB;

            o.Albedo = col0.rgb;
            o.Alpha = col.a;
        }
        ENDCG
        }
            Fallback "Nature/Terrain/Diffuse"
}
