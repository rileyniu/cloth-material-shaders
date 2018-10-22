Shader "Custom/Gem3" {
	Properties {
		
		// _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_IridescentTileValue("Iridescent Tile Value", Range(0,5)) = .1
		_FresnelPow("Fresnel Power", Range(0,5)) = .5
		_Emission("Emission", Range(0,5)) = .1
		_RimIntensity("Rim Intensity", Range(0,5)) = 2
		_MinOpacity("Minimum Opacity", Range(0, 1))=.8
		_RimColor ("Rim Color", Color) = (1,1,1,1)
		_IridescentColor ("Iridescent Color", Color) = (1,1,1,1)

	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		///sampler2D _MainTex;

		struct Input {
			float2 uv;
			float3 normal;

		};

		half _Glossiness;
		half _Metallic;
		fixed4 _RimColor;
		fixed4 _IridescentColor;

		float _IridescentTileValue;
		float _FresnelPow;
		float _Emission;
		float _RimIntensity;
		float _MinOpacity;

		float Fresnel_Crystal(float NoV,float Exp)
		{
			return saturate(pow((1-NoV),Exp)+0.02);
		}

		float3 Rim_Crystal(float3 Color , float NoV)
		{
			float F = Fresnel_Crystal(NoV,1.5);
			return Color * F * _RimIntensity;
		}


		float3 IridescentFresnel(float NoV, float3 N , float3 Color)
		{
			float3 k = normalize(float3(1,1,1));
			float t = NoV * 3.142 * _IridescentTileValue;
			float3 v = Color * N;
			float3 C = v * cos(t) + cross(k,v)* sin(t) + k* dot(k,v)*(1-cos(t));
			C = lerp(float3(0,0,0),C,Fresnel_Crystal(NoV, _FresnelPow)) * _Emission;
			return C;
		}
		
		float3 Emission(float NoV, float3 N , float3 Color,float3 RimColor)
		{
			float3 C = IridescentFresnel(NoV,N,Color);
			C += Rim_Crystal(RimColor , NoV);
			return C;
		}

		float Opacity(float NoV)
		{
			float F = Fresnel_Crystal(NoV,1.5);
			return lerp(_MinOpacity,1,F);
		}


		inline fixed4 CrystalLighting(SurfaceOutputStandard s, fixed2 uv, fixed3 viewDir){
			float4 final;
			float3 V = normalize(viewDir);
			float NoV = saturate( dot(s.Normal, V) );
			float3 R = normalize(reflect( -V, s.Normal ));
			float3 RimColor = _RimColor.rgb;
			float3 IridescentColor = _IridescentColor.rgb;
			final.a = Opacity(NoV);
			final.rgb = Emission(NoV,s.Normal,IridescentColor,RimColor);
			return final;
		}


		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = fixed4(.5, .5, .5, .5);// tex2D (_MainTex, IN.uv) * _Color;
			o.Albedo = c.rgb;
			o.Normal = IN.normal;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
