// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Gem2" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_ReflectTex ("Reflection Texture", Cube) = "" { }
		_RefractTex ("Refraction Texture", Cube) = "" { }
		_EnvLightTex ("Environment Light Map", Cube) = ""{ }
		_DispersionTex("Dispersion Tex", Cube) = "" {}

		_FresnelBias("Bias", float) = .5
		_FresnelScale("Scale", float) = .5
	 	_FresnelPower("Power", float) = .5 
	}	
	Subshader{
		Pass{

			Cull Front 
			ZWrite Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc" 

			fixed4 _Color;  
			samplerCUBE _RefractTex;    
        	samplerCUBE _ReflectTex;  
			float _FresnelBias;
			float _FresnelScale;
			float _FresnelPower;

			struct appdata {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
         };

         struct v2f {
            float4 pos : SV_POSITION;
            float3 normalDir : TEXCOORD0;
            float3 viewDir : TEXCOORD1;
         };

		 // Fresnel
		 float CaculateFresnelApproximation(float3 I, float3 N)
		 {
			float fresnel = max(0, min(1, _FresnelBias + _FresnelScale * pow(min(0.0, 1.0 - dot(I, N)), _FresnelPower)));
			return fresnel;
		 }

  
         v2f vert(appdata v) 
         {
            v2f o;
 
            float4x4 modelMatrixInverse = unity_WorldToObject; 
 
            o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;

            o.normalDir = normalize (mul ((float3x3)unity_ObjectToWorld, v.normal));

            o.pos = UnityObjectToClipPos(v.vertex);

            return o;
         }
 
         fixed4 frag(v2f IN) : SV_Target
         {
            float3 reflectedDir = reflect(IN.viewDir, IN.normalDir);
	        fixed4 reflectCol = texCUBE(_RefractTex, reflectedDir *_Color);

            float3 refractedDir = refract(IN.viewDir, IN.normalDir, 1/2.4);
	        fixed4 refractCol = texCUBE(_ReflectTex, refractedDir);
			refractCol = pow(refractCol, 2.2); //Gamma correction

	        float fresnel = CaculateFresnelApproximation(IN.viewDir, IN.normalDir);

            fixed4 col = lerp(refractCol, reflectCol, fresnel);
            return col;
         }
 
         ENDCG
			

		// Second pass - here we render the front faces of the diamonds.
		// Pass {
		// 	ZWrite On
		// 	Blend One One
			
		// 	CGPROGRAM
		// 	#pragma vertex vert
		// 	#pragma fragment frag
		// 	#include "UnityCG.cginc"
        
		// 	struct v2f {
		// 		float4 pos : SV_POSITION;
		// 		float3 uv : TEXCOORD0;
		// 		half fresnel : TEXCOORD1;
		// 	};

		// 	v2f vert (float4 v : POSITION, float3 n : NORMAL)
		// 	{
		// 		v2f o;
		// 		o.pos = UnityObjectToClipPos(v);

		// 		// TexGen CubeReflect:
		// 		// reflect view direction along the normal, in view space.
		// 		float3 viewDir = normalize(ObjSpaceViewDir(v));
		// 		o.uv = -reflect(viewDir, n);
		// 		o.uv = mul(unity_ObjectToWorld, float4(o.uv,0));
		// 		o.fresnel = 1.0 - saturate(dot(n,viewDir));
		// 		return o;
		// 	}

		// 	fixed4 _Color;
		// 	samplerCUBE _RefractTex;
		// 	half _ReflectionStrength;
		// 	half _EnvironmentLight;
		// 	half _Emission;
		// 	half4 frag (v2f i) : SV_Target
		// 	{
		// 		half3 refraction = texCUBE(_RefractTex, i.uv).rgb * _Color.rgb;
		// 		half4 reflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.uv);
		// 		reflection.rgb = DecodeHDR (reflection, unity_SpecCube0_HDR);
		// 		half3 reflection2 = reflection * _ReflectionStrength * i.fresnel;
		// 		half3 multiplier = reflection.rgb * _EnvironmentLight + _Emission;
		// 		return fixed4(reflection2 + refraction.rgb * multiplier, 1.0f);
		// 	}
		// 	ENDCG
		}
	}

}  