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
			
			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;

			uniform float _DrawDistance;

			uniform float4 _Color1;
			uniform float4 _Color2;
			uniform float4 _Color3;
			uniform float4 _Color4;
			uniform float4 _Color5;

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

			
			
			fixed4 raymarch(float3 origin, float3 direction, float depth, out bool hit, out float shadows, out float ao, out float3 normal, out float light) 
			{
				hit = true;				
				const int maxstep = 500;
				float traveledDist = 0;

				[loop]
				for (int i = 0; i < maxstep; ++i) 
				{					
					if (traveledDist > _DrawDistance || traveledDist > depth)
					{
						break;
					}

					float3 worldPos = origin + direction * traveledDist;
					float2 dist = map(worldPos);

					if (dist.x < 0.0001) 
					{
						normal = calcNormal(worldPos);
						shadows = softshadow(worldPos, normalize(_LightPos - worldPos));
						ao = calcAO(worldPos, normal);
						light = dot(normal, normalize(_LightPos - worldPos));
						
						float4 colors[5] =
						{
							_Color1, 
							_Color2,
							_Color3,
							_Color4,
							_Color5
						};

						return colors[dist.y];
					}
					
					traveledDist += dist;
				}
				hit = false;
				return 0;
			}


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

				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
		
				//Out paramters
				float steps = 0;	
				bool hit;				
				float shadows;
				float light;
				float ao;
				float3 normal;
				fixed4 color = raymarch(origin, direction, depth, hit, shadows, ao, normal, light);

				return pow(light * shadows * ao * pow(color, 2.2), 1.0/2.2);//ao * color;
				//return light * ao * shadows * color;
			}
			ENDCG
		}
	}
}
