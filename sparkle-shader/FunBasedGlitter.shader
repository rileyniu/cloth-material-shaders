Shader "Custom/Glitter" {
	Properties
	{
		[Header(Colors)]
		_Color ("Color", Color) = (.5,.5,.5,1)
		_SpecColor ("Specular Color", Color) = (.5,.5,.5,1)
		_MainTex ("Texture", 2D) = "white" {}
		[Header(Specular)]
		_SpecPow ("Specular Power", Range (1, 50)) = 24
		_GlitterPow ("Glitter Power", Range (1, 10)) = 5
        [Header(Sparkles)]
		_SparkleDepth ("Sparkle Depth", Range (0, 5)) = 1
		_NoiseScale ("noise Scale", Range (0, 5)) = 1
		_AnimSpeed ("Animation Speed", Range (0, 5)) = 1
	}
	SubShader
	{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		 ZWrite Off
         Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Simplex3D.cginc"
			// #include "Simplex3D1.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD1;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color, _SpecColor;
			float _SpecPow, _GlitterPow;

			v2f vert (appdata v)
			{
				v2f o;
				
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normal = mul(unity_ObjectToWorld, float4(v.normal,0)).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			float _NoiseScale;
			float _AnimSpeed;
			float _SparkleDepth;
			float Sparkles(float2 viewDir, float2 wPos)
			{
				float noiseScale = _NoiseScale * 30;
				float sparkles = snoise(wPos * noiseScale - viewDir * _SparkleDepth + _Time.x * _AnimSpeed)* snoise(wPos * noiseScale + _Time.x * _AnimSpeed);
				sparkles = smoothstep(.5,.8, sparkles);
				return sparkles;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				//Light Calculation
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
				float3 reflDir = reflect(-viewDir, normal);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float specular = saturate(dot(reflDir, lightDir));
				specular = pow(specular,_SpecPow);
				
				float glitterSpecular = pow(specular,_GlitterPow * 0.1);
				

				//Sparkles, replaced 3D calculation with 2D coordinates
				// float sparkles = Sparkles(viewDir,i.wPos);
				float2 viewDir2d = float2(viewDir.x , viewDir.y);
				float sparkles = Sparkles(viewDir2d, i.uv);
				//Sample the texture
				fixed4 col = tex2D(_MainTex, i.uv)* _Color;
				// // col = col*fmod(col.a,0.3);
				// col *= col.a - floor(col.a * (1.0 / 0.3)) * 0.3;
				// //Apply Specular and sparkles
				col +=  _SpecColor * (saturate(sparkles * glitterSpecular*8) + specular*0.5);
				
				return col;
			}
			ENDCG
		}
	}
}
