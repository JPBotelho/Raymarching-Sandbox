uniform float _DrawDistance;
fixed4 raymarch(float3 origin, float3 direction, float depth, out bool hit, out RenderInfo buffers)
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
		float3 dist = map(worldPos);

		if (dist.x < 0.0001) 
		{
			buffers = render(worldPos, direction);
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