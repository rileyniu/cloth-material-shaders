// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/test1" {
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_Offset ("Ratio 1", Vector) = (0.005, -0.006, 0.007, 0.008)
		_Min ("Min ", Float) = 2.5
		_Max ("Max", Float) = 2.51
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;	
				float2 uv2: TEXCOORD1;		
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 wPos : TEXCOORD2;
			};

			float4 _Offset;
			float _Min;
			float _Max;

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
						
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv  = TRANSFORM_TEX(v.uv, _MainTex);	
				o.uv2 = TRANSFORM_TEX(v.uv, _NoiseTex);	
				o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normal = mul(unity_ObjectToWorld, float4(v.normal,0)).xyz;						
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float3 normal = normalize(i.normal);
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.wPos));
				float3 reflDir = reflect(-viewDir, normal);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float specular = saturate(dot(reflDir, lightDirection));	
				specular = pow(specular,1.5);


				fixed4 col = tex2D(_MainTex, i.uv);
				float p1 = tex2D(_NoiseTex, i.uv2 + float2(0             , _Time.y * _Offset.x ));
				// float p2 = tex2D(_NoiseTex, i.uv2 + float2(0             , _Time.y * _Offset.y));
				// float p3 = tex2D(_NoiseTex, i.uv2 + float2(_Time.y * _Offset.z, 0             ));
				// float sum = p1+p2+p3;
				// if (sum > _Min && sum < _Max){
				// 	col = fixed4(1,1, 1, 1);
				// }
				return col * p1;
			}
			ENDCG
		}
	}
}
