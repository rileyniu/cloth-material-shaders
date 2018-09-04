// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/test1" {
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_Color ("Color", Color) = (.5,.5,.5,1)
		_Min ("Sparkle Threshold", Range(1, 5)) = 1.3
		// Intensity of Bloom effects
		_GlitterPow ("Sparkle Power", Range (0, 1)) = 0.9
		// How spread the sparkles are regarding to the specular position
		_SpreadPow ("Specular Power", Range(0,1)) = 0.2
		_AnimSpeed ("Animation Speed", Range (0, 0.01)) = 0.005

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

			struct appdata
			{
				fixed4 vertex : POSITION;
				fixed2 uv : TEXCOORD0;
				fixed3 normal : NORMAL;
			};

			struct v2f
			{
				fixed2 uv : TEXCOORD0;
				fixed2 uv2: TEXCOORD1;
				fixed4 vertex : SV_POSITION;
				fixed3 normal : NORMAL;
				fixed3 wPos : TEXCOORD2;
			};

			fixed _Min;
			fixed _GlitterPow;
      fixed _SpreadPow;
			fixed _AnimSpeed;


			fixed4 _Color;
			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			sampler2D _NoiseTex;
			fixed4 _NoiseTex_ST;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv  = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.uv, _NoiseTex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normal = mul(unity_ObjectToWorld, fixed4(v.normal,0)).xyz;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{

				fixed3 normal = normalize(i.normal);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
				fixed3 reflDir = reflect(-viewDir, normal);
				fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed specular = saturate(dot(reflDir, lightDir));
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				float p1 = tex2D(_NoiseTex, i.uv2 + float2(0             , _Time.y * 1.17 * _AnimSpeed ));
				float p2 = tex2D(_NoiseTex, i.uv2 + float2( _Time.y * 1.54  * _AnimSpeed, 0 ));

        // Specular parameter tuned the sparkles so that they are more cluttered near the specular position
				float sum = (p1+p2) + specular* _SpreadPow;
				col = sum > _Min ? fixed4(1, 1, 1, 1) * _GlitterPow: col;
				return col;
			}
			ENDCG
		}
	}
}
