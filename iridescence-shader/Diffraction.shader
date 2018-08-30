
Shader "Custom/Diffraction" {
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_DetailTex ("Smoothness (R) Metallic (G) AO (B)", 2D) = "white" {}
		_TextureRatio ("Texture Color Ratio", range(0,1)) = 0.5
		_DiffIntensity("Diffraction Intensity", range(0,1)) = 0.4

		_BumpAmt ("Distortion", range (0,1)) = 0.12
		_Alpha("Alpha", range(0,1)) = 0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Distance ("Grating distance", Range(0,10000)) = 1600 // nm
	}

Category{
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }

	SubShader {

	// extra pass that renders to depth buffer only
	// solves depth problem regarding to rendering opaque objects in alpha-blend mode

		 Pass {
			ZWrite On
			ColorMask 0
    	}

		CGPROGRAM

		#pragma surface surf Diffraction alpha:blend
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"


		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _DetailTex;
		float _BumpAmt;
		float _Distance;
		float _Alpha;
		float _TextureRatio;
		float _DiffIntensity;
		float3 worldTangent;
		half2 BumpNormal;

		// Based on GPU Gems and the following blog
		// reference: https://www.alanzucconi.com/tag/cd-rom/
		inline fixed3 bump3y (fixed3 x, fixed3 yoffset)
		{
			float3 y = 1 - x * x;
			y = saturate(y-yoffset);
			return y;
		}

		fixed3 CalculateSpectrum (float w)
		{
			// w: [400, 700]
			// x: [0,   1]
			fixed x = saturate((w - 400.0)/ 300.0);

			const float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
			const float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
			const float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);

			const float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
			const float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
			const float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);

			return
			bump3y(c1 * (x - x1), y1) + bump3y(c2 * (x - x2), y2) ;
		}


		inline fixed4 LightingDiffraction(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
		{
			// Original colour
			float ratio = _TextureRatio;
			fixed4 pbr = fixed4(s.Albedo,1) * ratio + LightingStandard(s, viewDir, gi) * (1-ratio);
			pbr.a = s.Alpha;

			//--- Diffraction grating effect ---
			float3 L = gi.light.dir;
			L.x = L.x + BumpNormal.x;
			L.y = L.y + BumpNormal.y;
			float3 V = viewDir;
			float3 T = worldTangent;

			float d = _Distance;
			float cos_ThetaL = dot(L, T);
			float cos_ThetaV = dot(V, T);
			float u = abs(cos_ThetaL - cos_ThetaV);

			if (u == 0)
				return pbr;

			// Reflection color
			fixed3 color = 0;
			for (int n = 1; n <= 3; n++)
			{
				float wavelength = u * d / n;
				color += CalculateSpectrum(wavelength);
			}
			float intensity = _DiffIntensity;
			color = intensity * saturate(color);

			// Adds the refelection to the material color and use lerp to achieve a more harmonic color blend

			pbr.rgb += lerp(color, 0.4, 0.2);
			return pbr;
		}

		void LightingDiffraction_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			LightingStandard_GI(s, data, gi);
		}


		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			fixed3 Tangent;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		UNITY_INSTANCING_CBUFFER_START(Props)
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {

			// Obtain the offset from BumpMap to add to the light source
			BumpNormal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)).xy * _BumpAmt;
			fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex) * _Color * 0.7;
			fixed3 detail = tex2D(_DetailTex, IN.uv_MainTex).rgb;
			o.Albedo = albedo.rgb;
			o.Alpha = albedo.a + _Alpha * (1 - albedo.a);
			o.Metallic = detail.g * _Metallic;
			o.Smoothness = detail.r * _Glossiness;
			o.Occlusion = detail.b;

			// Emission makes the material brighter
			//  o.Emission = albedo;

			// change the uv coordinates from [0,1] to [-1, 1] in the unit circle
			// the surface of mesh has to be correctly UV-mapped.
			// fixed2 uv = IN.uv_MainTex * 2 -1;
			// fixed2 uv_orthogonal = normalize(uv);

			// Obtain the tangent vector from vertex information

			// The following tangent calculation relies on correctly UV-mapped mesh
			// fixed3 uv_tangent = IN.Tangent;
			// fixed3 uv_tangent = fixed3(-uv_orthogonal.y, 0, uv_orthogonal.x);
			// worldTangent = normalize(mul(unity_ObjectToWorld, float4(uv_tangent, 0)));

			// Fixed tangent shows better iridescent effect
			worldTangent = float3(1, 0, 0);

		}

		ENDCG


		// The following Pass uses Unity built-in GrabTexture to achieve screen distortion, which is
		// optimized by directly adding the noise offset to light source, shown above

		// Blend SrcAlpha OneMinusSrcAlpha

		// GrabPass{
		// 	Name "BASE"
		// 	Tags { "LightMode" = "Always" }
		// }

		// Pass{
		// 	Name "BASE"
        //     Tags { "LightMode" = "Always" }

        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     // #pragma target 3.0
        //     #pragma multi_compile_fog
        //     // #define UNITY_PASS_FORWARDBASE
        //     #include "UnityCG.cginc"

        //     struct appdata_t {
		// 		float4 vertex : POSITION;
		// 		float2 texcoord: TEXCOORD0;
        // 	};

        //     struct v2f {
        //         float4 vertex : SV_POSITION;

		// 		float4 uvgrab: TEXCOORD0;
		// 		float2 uvbump: TEXCOORD1;
		// 		float2 uv : TEXCOORD2; // _MainTex
		// 		//UNITY_FOG_COORDS(3)

        //     };

        //     float4 _MainTex_ST;
		// 	float _BumpAmt;
		// 	float4 _BumpMap_ST;


        //     // vertex shader
        //     v2f vert (appdata_t v) {
        //         v2f o;
        //          o.vertex = UnityObjectToClipPos(v.vertex);

		// 		o.uvgrab = ComputeGrabScreenPos(o.vertex);
		// 		o.uvbump = TRANSFORM_TEX(v.texcoord, _BumpMap);
		// 		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		// 		//UNITY_TRANSFER_FOG(o,o.vertex);
        //         return o;
        //     }

		// 	sampler2D _GrabTexture;
		// 	float4 _Color;
		// 	sampler2D _MainTex;
		// 	sampler2D _BumpMap;


        //     // fragment shader
        //     fixed4 frag (v2f i) : SV_Target {

		// 		half2 bump = UnpackNormal(tex2D(_BumpMap, i.uvbump)).rg;
		// 		float2 offset = bump * _BumpAmt * 5;
		// 		i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
		// 		half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(i.uvgrab));
        //         half4 albedo = tex2D(_MainTex, i.uv) * _Color *2;
		// 		col *= albedo;
		// 		//UNITY_APPLY_FOG(i.fogCoord, col);
        //         return col;
        //     }
        //     ENDCG
		// }

	}
	FallBack "Diffuse"
}
}
