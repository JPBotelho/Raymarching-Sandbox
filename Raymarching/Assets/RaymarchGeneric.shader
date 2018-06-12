Shader "Hidden/RaymarchGeneric"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.0

			#include "UnityCG.cginc"
			#include "DistanceFunc.cginc"
			#include "Rendering.cginc"
			#include "Raymarcher.cginc"

			
			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			float3 _CameraWP;

			float3 _CamForward;
			float3 _CamRight;
			float3 _CamUp;
			float _FovX;
			float _AspectRatio;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			

			v2f vert (appdata v)
			{
				v2f o;				
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
				
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
				#endif
			
				return o;
			}

	
			fixed4 frag (v2f i) : SV_Target
			{
				float3 origin = _CameraWP;
				float xUV = 2.0 * i.uv.x - 1.0;
				float yUV = 2.0 * i.uv.y - 1.0;
				float3 direction = normalize(_CamForward + tan(_FovX/2.0)*_AspectRatio*xUV*_CamRight + tan(_FovX/2.0)*yUV*_CamUp);

				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					i.uv.y = 1 - i.uv.y;
				#endif

				bool hit;	
				RenderInfo buffers;			

				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
				fixed4 color = raymarch(origin, direction, depth, hit, buffers);

				return renderBuffer(buffers, color);//pow(buffers.light * buffers.shadow * buffers.ao * pow(color, 2.2), 1.0/2.2);
			}
			ENDCG
		}
	}
}