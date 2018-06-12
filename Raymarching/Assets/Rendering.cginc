uniform float4 _Color1;
uniform float4 _Color2;
uniform float4 _Color3;
uniform float4 _Color4;
uniform float4 _Color5;

uniform float3 _LightPos;
uniform float _LightStrength;

struct RenderInfo
{
    float3 worldPos;
    float3 normal;
    float4 reflection;
    float shadow;
    float light;
    float ao;
};

//X - dist
//Y - color index
//Z - reflection
float3 map(float3 p) 
{
    float sphere = sdSphere(p, 1.3);
    float torus = sdTorus(p, float2(5, 1));
    float plane = p.y + 1;

    float sphereTorus = min(sphere, torus);
    float currentColor = sphere < torus ? 0 : 1;
    return float3(min(sphereTorus, plane), sphereTorus < plane ? currentColor : 2, sphereTorus < plane ? 0 : 1);
}

float4 renderBuffer(RenderInfo buffer, float4 color)
{
    return pow(buffer.light * 1 * buffer.ao * pow(color, 2.2), 1.0/2.2);
}

float3 calcNormal(in float3 pos)
{
    const float2 eps = float2(0.001, 0.0);
    // The idea here is to find the "gradient" of the distance field at pos
    // Remember, the distance field is not boolean - even if you are inside an object
    // the number is negative, so this calculation still works.
	// Essentially you are approximating the derivative of the distance field at this point.
	float3 nor = float3(
		map(pos + eps.xyy).x - map(pos - eps.xyy).x,
		map(pos + eps.yxy).x - map(pos - eps.yxy).x,
		map(pos + eps.yyx).x - map(pos - eps.yyx).x);
	return normalize(nor);
}

float hardshadow(float3 origin, float3 direction)
{
    for(float t = 1; t < 64;)
    {
        float dist = map(origin + direction * t);

        if(dist < 0.001)
            return 0;

        t += dist;
    }
    return 1;
}

float softshadow (float3 origin, float3 direction)
{
    if(abs(_LightPos.x) + abs(_LightPos.y) + abs(_LightPos.z) < 0.1)
        return 0;
    direction = normalize(_LightPos);
    float res = 1;
    const int k = _LightStrength;
    float mindist = .3;
    float ph = 1e20;

    for(float t = 1; t < 64;)
    {
        float dist = map(origin + direction*t);
        mindist = min(mindist, dist);
        if(dist < 0.001)
        {
            return 0;
        }
        float y = dist*dist/(2.0*ph);
        float d = sqrt(dist*dist-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = dist;
        t += dist;
    }

    return res;
}

float3 calcLight (float3 worldPos, float3 normal)
{
	return dot(normal, normalize(_LightPos - worldPos));
}

float calcAO(float3 pos, float3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        float3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

float4 renderRefl (float3 worldPos, float3 direction, float4 color)
{
    RenderInfo i;
    i.worldPos = worldPos;
    i.normal = calcNormal(worldPos);
    i.shadow = softshadow(worldPos, direction);
    i.light = calcLight(worldPos, i.normal);
    i.ao = calcAO(worldPos, i.normal);
    i.reflection = 1;

    return renderBuffer(i, color);
}

RenderInfo render(float3 worldPos, float3 direction);

fixed4 calcRefl(float3 origin, float3 direction, float3 origin2, float3 dir2)
{
	const int maxstep = 50;
	float traveledDist = 0;

	[loop]
	for (int i = 0; i < maxstep; ++i) 
	{					
		if (traveledDist > 100)
		{
			break;
		}

		float3 worldPos = origin + direction * traveledDist;
		float2 dist = map(worldPos);

		if (dist.x < 0.0001) 
		{
            float4 colors[5] =
			{
				_Color1, 
				_Color2,
				_Color3,
				_Color4,
				_Color5
			};

			return renderRefl(origin2, dir2, colors[dist.y]);
		}
		
		traveledDist += dist;
	}
	return 1;
}

RenderInfo render (float3 worldPos, float3 direction)
{
    RenderInfo i;
    i.worldPos = worldPos;
    i.normal = calcNormal(worldPos);
    i.shadow = softshadow(worldPos, direction);
    i.light = calcLight(worldPos, i.normal);
    i.ao = calcAO(worldPos, i.normal);

    float3 reflectionDir = reflect(direction, normalize(i.normal));
    i.reflection = calcRefl(worldPos + reflectionDir * 0.5, reflectionDir, worldPos, reflectionDir);

    return i;
}
