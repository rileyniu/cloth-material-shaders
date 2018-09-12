// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/test1" {
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Color", Color) = (.5,.5,.5,1)
		_NoiseTex ("Noise Texture", 2D) = "white" {}
    _Min ("Sparkle Threshold", Range(0, 2)) = 0.5
    _Max ("Sparkle Threshold2", Range(0, 2)) = 0.5
		// How spread the sparkles are regarding to the specular position
    _SpecPow ("Specular Power", Range(0, 1)) = 0.1
    _GlitterPow ("Sparkle Power", Range (0, 5)) = 1 // Intensity of Bloom effects
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
				// Calculate view distance
				half viewDis = distance(_WorldSpaceCameraPos, o.wPos);

				fixed3 normal = normalize(i.normal);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
				fixed3 reflDir = reflect(-viewDir, normal);
				fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed specular = saturate(dot(reflDir, lightDir));

				// sample the texture
				fixed4 c = tex2D(_MainTex, i.uv) * _Color;
				half p1 = tex2D(_NoiseTex, s.tc + float2(0 , _Time.y * 2.47 * (_AnimSpeed+ viewDis*0.00001) ));
				half p2 = tex2D(_NoiseTex, s.tc + float2( _Time.x * 1.54  * (_AnimSpeed + viewDis*0.00001), 0));

				half sum = p1 + p2;
				// Specular parameter tuned the sparkles so that they are more cluttered near the specular position
			  sum = lerp(sum * specParam, sum, _SpecPow);

				// Use viewDis to adjust the threshold of sparkles
			  bool aboveMin = sum > (_Min - viewDis * 0.008);
			  bool belowMax = sum < (_Max+ viewDis * 0.008);
			  c = aboveMin && belowMax ? fixed4(1, 1, 1, 1) * _GlitterPow: c;
				return c;
			}
			ENDCG
		}
	}
}
