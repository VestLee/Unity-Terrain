Shader "UWAShaders/UWA 16Textures"
{
    Properties
    {
        _TerrainLayers0("TerrainLayers1", 2D) = "white" {}
        _TerrainLayers1("TerrainLayers2", 2D) = "white" {}
        _TerrainLayers2("TerrainLayers3", 2D) = "white" {}
        _TerrainLayers3("TerrainLayers4", 2D) = "white" {}
        _TerrainLayers4("TerrainLayers5", 2D) = "white" {}
        _TerrainLayers5("TerrainLayers6", 2D) = "white" {}
        _TerrainLayers6("TerrainLayers7", 2D) = "white" {}
        _TerrainLayers7("TerrainLayers8", 2D) = "white" {}
        _TerrainLayers8("TerrainLayers9", 2D) = "white" {}
        _TerrainLayers9("TerrainLayers10", 2D) = "white" {}
        _TerrainLayers10("TerrainLayers11", 2D) = "white" {}
        _TerrainLayers11("TerrainLayers12", 2D) = "white" {}
        _TerrainLayers12("TerrainLayers13", 2D) = "white" {}
        _TerrainLayers13("TerrainLayers14", 2D) = "white" {}        
        _TerrainLayers14("TerrainLayers15", 2D) = "white" {}
        _TerrainLayers15("TerrainLayers16", 2D) = "white" {}

        _Splatmap0("Splatmap1", 2D) = "white" {}
        _Splatmap1("Splatmap2", 2D) = "white" {}
        _Splatmap2("Splatmap3", 2D) = "white" {}
        _Splatmap3("Splatmap4", 2D) = "white" {}

        // 高光强度
        _Gloss("Gloss",Range(8,200)) = 10
    }
        SubShader
    {
        Tags {
            "RenderType" = "Opaque"
            "Queue" = "Geometry-100"
        }
        LOD 100

        CGINCLUDE
        #include "Lighting.cginc"
            half _Gloss;
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

                float2 uv_SplatMap0 : TEXCOORD0;
                float2 uv_SplatMap1 : TEXCOORD1;

                float2 uv_Layer1 : TEXCOORD2;
                float2 uv_Layer2 : TEXCOORD3;
                float2 uv_Layer3 : TEXCOORD4;
                float2 uv_Layer4 : TEXCOORD5;

                float2 uv_Layer5 : TEXCOORD6;
                float2 uv_Layer6 : TEXCOORD7;

            };

            struct v2f
            {
                float2 uv_SplatMap0 : TEXCOORD0;
                float2 uv_SplatMap1 : TEXCOORD1;

                float2 uv_Layer1 : TEXCOORD2;
                float2 uv_Layer2 : TEXCOORD3;
                float2 uv_Layer3 : TEXCOORD4;
                float2 uv_Layer4 : TEXCOORD5;

                float2 uv_Layer5 : TEXCOORD6;
                float2 uv_Layer6 : TEXCOORD7;

                float4 vertex : SV_POSITION;
                float3 worldNormalDir : COLOR0;
                float3 worldVertex: COLOR1;
            };

        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _TerrainLayers0;
            float4 _TerrainLayers0_ST;
            sampler2D _TerrainLayers1;
            float4 _TerrainLayers1_ST;
            sampler2D _TerrainLayers2;
            float4 _TerrainLayers2_ST;
            sampler2D _TerrainLayers3;
            float4 _TerrainLayers3_ST;

            sampler2D _TerrainLayers4;
            float4 _TerrainLayers4_ST;
            sampler2D _TerrainLayers5;
            float4 _TerrainLayers5_ST;

            sampler2D _Splatmap0;
            float4 _Splatmap0_ST;
            sampler2D _Splatmap1;
            float4 _Splatmap1_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormalDir = mul(v.normal, (float3x3) unity_WorldToObject);
                o.worldVertex = mul(v.vertex, unity_WorldToObject).xyz;

                o.uv_SplatMap0 = TRANSFORM_TEX(v.uv_SplatMap0, _Splatmap0);
                o.uv_SplatMap1 = TRANSFORM_TEX(v.uv_SplatMap1, _Splatmap1);
                o.uv_Layer1 = TRANSFORM_TEX(v.uv_Layer1, _TerrainLayers0);
                o.uv_Layer2 = TRANSFORM_TEX(v.uv_Layer2, _TerrainLayers1);
                o.uv_Layer3 = TRANSFORM_TEX(v.uv_Layer3, _TerrainLayers2);
                o.uv_Layer4 = TRANSFORM_TEX(v.uv_Layer4, _TerrainLayers3);
                o.uv_Layer5 = TRANSFORM_TEX(v.uv_Layer5, _TerrainLayers4);
                o.uv_Layer6 = TRANSFORM_TEX(v.uv_Layer6, _TerrainLayers5);
                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed3 normalDir = normalize(IN.worldNormalDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 reflectDir = reflect(-lightDir, normalDir);
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldVertex);

                fixed4 splatMapWeight0 = tex2D(_Splatmap0, IN.uv_SplatMap0).rgba;
                fixed4 splatMapWeight1 = tex2D(_Splatmap1, IN.uv_SplatMap1).rgba;

                fixed4 lay1 = tex2D(_TerrainLayers0, IN.uv_Layer1);
                fixed4 lay2 = tex2D(_TerrainLayers1, IN.uv_Layer2);
                fixed4 lay3 = tex2D(_TerrainLayers2, IN.uv_Layer3);
                fixed4 lay4 = tex2D(_TerrainLayers3, IN.uv_Layer4);
                fixed4 lay5 = tex2D(_TerrainLayers4, IN.uv_Layer5);
                fixed4 lay6 = tex2D(_TerrainLayers5, IN.uv_Layer6);

                // sample the texture
                fixed4 col = (
                    lay1 * splatMapWeight0.r
                    + lay2 * splatMapWeight0.g
                    + lay3 * splatMapWeight0.b
                    + lay4 * splatMapWeight0.a
                    + lay5 * splatMapWeight1.r
                    + lay6 * splatMapWeight1.g);

                fixed3 diffuse = _LightColor0.rgb * max(dot(normalDir, lightDir), 0) * col.rgb;
                fixed3 specular = _LightColor0.rgb * pow(max(0, dot(viewDir, reflectDir)), _Gloss) * col.rgb;
                return fixed4(diffuse + specular, col.a);
            }
            ENDCG
        }

        Pass
        {
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _TerrainLayers8;
            float4 _TerrainLayers8_ST;
            sampler2D _TerrainLayers9;
            float4 _TerrainLayers9_ST;
            sampler2D _TerrainLayers10;
            float4 _TerrainLayers10_ST;
            sampler2D _TerrainLayers11;
            float4 _TerrainLayers11_ST;

            sampler2D _TerrainLayers12;
            float4 _TerrainLayers12_ST;
            sampler2D _TerrainLayers13;
            float4 _TerrainLayers13_ST;

            sampler2D _Splatmap2;
            float4 _Splatmap2_ST;
            sampler2D _Splatmap3;
            float4 _Splatmap3_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormalDir = mul(v.normal, (float3x3) unity_WorldToObject);
                o.worldVertex = mul(v.vertex, unity_WorldToObject).xyz;

                o.uv_SplatMap0 = TRANSFORM_TEX(v.uv_SplatMap0, _Splatmap2);
                o.uv_SplatMap1 = TRANSFORM_TEX(v.uv_SplatMap1, _Splatmap3);
                o.uv_Layer1 = TRANSFORM_TEX(v.uv_Layer1, _TerrainLayers8);
                o.uv_Layer2 = TRANSFORM_TEX(v.uv_Layer2, _TerrainLayers9);
                o.uv_Layer3 = TRANSFORM_TEX(v.uv_Layer3, _TerrainLayers10);
                o.uv_Layer4 = TRANSFORM_TEX(v.uv_Layer4, _TerrainLayers11);
                o.uv_Layer5 = TRANSFORM_TEX(v.uv_Layer5, _TerrainLayers12);
                o.uv_Layer6 = TRANSFORM_TEX(v.uv_Layer6, _TerrainLayers13);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed3 normalDir = normalize(IN.worldNormalDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 reflectDir = reflect(-lightDir, normalDir);
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldVertex);

                fixed4 splatMapWeight0 = tex2D(_Splatmap2, IN.uv_SplatMap0).rgba;
                fixed4 splatMapWeight1 = tex2D(_Splatmap3, IN.uv_SplatMap1).rgba;

                fixed4 lay1 = tex2D(_TerrainLayers8, IN.uv_Layer1);
                fixed4 lay2 = tex2D(_TerrainLayers9, IN.uv_Layer2);
                fixed4 lay3 = tex2D(_TerrainLayers10, IN.uv_Layer3);
                fixed4 lay4 = tex2D(_TerrainLayers11, IN.uv_Layer4);
                fixed4 lay5 = tex2D(_TerrainLayers12, IN.uv_Layer5);
                fixed4 lay6 = tex2D(_TerrainLayers13, IN.uv_Layer6);

                // sample the texture
                fixed4 col = (
                    lay1 * splatMapWeight0.r
                    + lay2 * splatMapWeight0.g
                    + lay3 * splatMapWeight0.b
                    + lay4 * splatMapWeight0.a
                    + lay5 * splatMapWeight1.r
                    + lay6 * splatMapWeight1.g);
               
                fixed3 diffuse = _LightColor0.rgb * max(dot(normalDir, lightDir), 0) * col.rgb;
                fixed3 specular = _LightColor0.rgb * pow(max(0, dot(viewDir, reflectDir)), _Gloss) * col.rgb;
                return fixed4(diffuse + specular, col.a);
            }
            ENDCG
        }

        Pass
        {
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _TerrainLayers6;
            float4 _TerrainLayers6_ST;
            sampler2D _TerrainLayers7;
            float4 _TerrainLayers7_ST;

            sampler2D _TerrainLayers14;
            float4 _TerrainLayers14_ST;
            sampler2D _TerrainLayers15;
            float4 _TerrainLayers15_ST;


            sampler2D _Splatmap1;
            float4 _Splatmap1_ST;

            sampler2D _Splatmap3;
            float4 _Splatmap3_ST;


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormalDir = mul(v.normal, (float3x3) unity_WorldToObject);
                o.worldVertex = mul(v.vertex, unity_WorldToObject).xyz;

                o.uv_SplatMap0 = TRANSFORM_TEX(v.uv_SplatMap0, _Splatmap1);
                o.uv_SplatMap1 = TRANSFORM_TEX(v.uv_SplatMap1, _Splatmap3);

                o.uv_Layer1 = TRANSFORM_TEX(v.uv_Layer1, _TerrainLayers6);
                o.uv_Layer2 = TRANSFORM_TEX(v.uv_Layer2, _TerrainLayers7);

                o.uv_Layer3 = TRANSFORM_TEX(v.uv_Layer3, _TerrainLayers14);
                o.uv_Layer4 = TRANSFORM_TEX(v.uv_Layer4, _TerrainLayers15);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT.rgba;
                fixed3 normalDir = normalize(IN.worldNormalDir);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 reflectDir = reflect(-lightDir, normalDir);
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldVertex);

                fixed4 splatMapWeight0 = tex2D(_Splatmap1, IN.uv_SplatMap0).rgba;
                fixed4 splatMapWeight1 = tex2D(_Splatmap3, IN.uv_SplatMap1).rgba;

                fixed4 lay1 = tex2D(_TerrainLayers6, IN.uv_Layer1);
                fixed4 lay2 = tex2D(_TerrainLayers7, IN.uv_Layer2);

                fixed4 lay3 = tex2D(_TerrainLayers14, IN.uv_Layer3);
                fixed4 lay4 = tex2D(_TerrainLayers15, IN.uv_Layer4);

                // sample the texture
                fixed4 col = (
                    lay1 *splatMapWeight0.b
                    + lay2 * splatMapWeight0.a
                    + lay3 * splatMapWeight1.b
                    + lay4 * splatMapWeight1.a
                    );
                
                fixed3 diffuse = _LightColor0.rgb * max(dot(normalDir, lightDir), 0) * col.rgb;
                fixed3 specular = _LightColor0.rgb * pow(max(0, dot(viewDir, reflectDir)), _Gloss) * col.rgb;
                return fixed4(diffuse + specular, col.a) + ambient;
            }
            ENDCG
        }
    }
}
