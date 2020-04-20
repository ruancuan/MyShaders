// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Toon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_LightMap("LightMap",2D)="white"{}
		_Shiness("Shiness",Range(0,1))=1
		_LightSpecColor("LightSpecColor",COLOR)=(1,1,1,1)
		_SpecScale("Spcelar",Range(0,1))=1
		_EmissionBloomFactor("EmissionBloomFactor",Range(0,1))=1
		_EmissionBloomColor("EmissionBloomColor",COLOR)=(1,1,1,1)
		_FirstShadow("FirstShadowMultColor",Range(0,1))=1
		_SecondShadow("SecondShadowMultColor",Range(0,1))=1
		_FirstShadowMultColor("FirstShadowMultColor",COLOR)=(1,1,1,1)
		_SecondShadowMultColor("SecondShadowMultColor",COLOR)=(1,1,1,1)
		_CoolColor("CoolColor",COLOR)=(1,1,1,1)
		_WarmColor("WarmColor",COLOR)=(1,1,1,1)
		_CoolColorScale("CoolColorScale",Range(0,1))=1
		_WarmColorScale("WarmColorScale",Range(0,1))=1

    }
    SubShader
    {
		Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        { 
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"       

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 color:COLOR;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
				float4 col:COLOR;
				float4 worldPos:TEXCOORD1;
				float3 normal:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _LightMap;
			float4 _LightMap_ST;

			float _Shiness;
			float4 _LightSpecColor;
			float _SpecScale;
			float _EmissionBloomFactor;
			float4 _EmissionBloomColor;

			float _FirstShadow;
			float _SecondShadow;
			float4 _FirstShadowMultColor;
			float4 _SecondShadowMultColor;

			float4 _CoolColor;
			float4 _WarmColor;
			float _CoolColorScale;
			float _WarmColorScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw=TRANSFORM_TEX(v.uv,_LightMap);
				o.col=v.color;
				o.normal=v.normal;
				o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv.xy);
				fixed4 lightMask=tex2D(_LightMap,i.uv.zw);
				float3 worldNormal=normalize(UnityObjectToWorldNormal(i.normal));
				float3 worldPos=i.worldPos;
				float3 lightDir=normalize(UnityWorldSpaceLightDir(worldPos));
				float3 viewDir=normalize(UnityWorldSpaceViewDir(worldPos));
				float3 halfVec=normalize(lightDir+viewDir);
				float halfLamert=dot(worldNormal,lightDir)*0.5+0.5;

				float diffuseMask=lightMask.g*i.col.x;
				float3 diffuseColor=float3(1,1,1);
				float3 firstShadowColor=col.rgb*_FirstShadowMultColor.rgb;
				float3 secondShadowColor=col.rgb*_SecondShadowMultColor.rgb;
				float3 colorShine=(diffuseMask+halfLamert)*0.5>=_FirstShadow?col:firstShadowColor;
				float3 colorDark=(diffuseMask+halfLamert)*0.5>=_SecondShadow?firstShadowColor:secondShadowColor;
				diffuseColor=diffuseMask>=0.1?colorShine:colorDark;

				float shinepow=pow(max(dot(worldNormal,halfVec),0),_Shiness);
				float3 spec=(shinepow+lightMask.b)>1?lightMask.r*_LightSpecColor*_SpecScale:float3(0,0,0);

				float4 emission;
				emission.xyz=col.rgb*_EmissionBloomColor;
				
				float3 result=col.rgb*emission*_EmissionBloomFactor+(1-_EmissionBloomFactor)*(diffuseColor+spec);
                return fixed4(result,1);
            }
            ENDCG
        }
    }
}
