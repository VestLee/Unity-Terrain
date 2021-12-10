Shader "UWAShaders/UWAAtlas3Layers"
{
    Properties
    {
        _BlockMainTex("BlockMainTex", 2D) = "white" {}
        _BlendIDTex("BlendIDTex", 2D) = "white" {}
        _BlendWeightTex("BlendWeightTex", 2D) = "white" {}
        _BlockScale("BlockScale", Float) = 0.022

    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            // LOD 200

            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma surface surf Standard fullforwardshadows

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            #pragma exclude_renderers gles
            #include "UnityPBSLighting.cginc"

            #define TERRAIN_STANDARD_SHADER
            #define _NORMALMAP
            #define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard

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
            float2 uv_BlendIDTex;
            float2 uv_BlendWeightTex;
            float2 uv_BlockMainTex;
            float3 worldPos;
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
            // // Albedo comes from a texture tinted by color
            // fixed4 c = tex2D (_BlockMainTex, IN.uv_BlockMainTex) * _Color;
            // o.Albedo = c.rgb;
            // // Metallic and smoothness come from slider variables
            // o.Metallic = _Metallic;
            // o.Smoothness = _Glossiness;
            // o.Alpha = c.a;

            //Index
            float3 encodedIndices = tex2D(_BlendIDTex, IN.uv_BlendIDTex).xyz;
            float3 ThreeHorizontalIndices = floor((encodedIndices * 16.0));
            float3 ThreeVerticalIndices = (floor((encodedIndices * 256.0)) - (16.0 * ThreeHorizontalIndices));

            float2 WeightIndicesG = float2((int)ThreeVerticalIndices.y / 4 % 2 * 0.5, (int)ThreeVerticalIndices.y / 4 / 2 * 0.5);
            int WeightFlagG = (int)ThreeHorizontalIndices.y / 4 % 4;
            float2 WeightIndicesB = float2((int)ThreeVerticalIndices.z / 4 % 2 * 0.5, (int)ThreeVerticalIndices.z / 4 / 2 * 0.5);
            int WeightFlagB = (int)ThreeHorizontalIndices.z / 4 % 4;

            ThreeHorizontalIndices = floor(ThreeHorizontalIndices / 4) * 0.25;
            ThreeVerticalIndices = floor(ThreeVerticalIndices / 4) * 0.25;
            //

            //
            float2 worldScale = (IN.worldPos.xz * _BlockScale);
            //float2 worldUv = 0.25 * frac(worldScale);
            float2 worldUv = 0.234375 * frac(worldScale) + 0.0078125;
            float2 dx = clamp(0.234375 * ddx(worldScale), -0.0078125, 0.0078125);
            float2 dy = clamp(0.234375 * ddy(worldScale), -0.0078125, 0.0078125);
            float2 uv0 = worldUv.xy + float2(ThreeHorizontalIndices.x, ThreeVerticalIndices.x);
            float2 uv1 = worldUv.xy + float2(ThreeHorizontalIndices.y, ThreeVerticalIndices.y);
            float2 uv2 = worldUv.xy + float2(ThreeHorizontalIndices.z, ThreeVerticalIndices.z);
            // Sample the two texture
            float4 col0 = tex2D(_BlockMainTex, uv0, dx, dy);
            float4 col1 = tex2D(_BlockMainTex, uv1, dx, dy);
            float4 col2 = tex2D(_BlockMainTex, uv2, dx, dy);

            float WeightG = GetWeight(tex2D(_BlendWeightTex, IN.uv_BlendWeightTex / 2 + WeightIndicesG), WeightFlagG);
            float WeightB = GetWeight(tex2D(_BlendWeightTex, IN.uv_BlendWeightTex / 2 + WeightIndicesB), WeightFlagB);
            

            //float4 col0 = tex2D(_BlockMainTex, uv0);
            //float4 col1 = tex2D(_BlockMainTex, uv1);
            // Blend the two textures
            float4 col = col0 * (1 - WeightG - WeightB)
                +col1 * WeightG
                + col2 * WeightB;
            
            o.Albedo = col.rgb;
            o.Alpha = col.a;
        }
        ENDCG
        }
            Fallback "Nature/Terrain/Diffuse"
}
