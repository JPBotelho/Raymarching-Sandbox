float map(float3 p) 
{
    float sphere = sdSphere(p, 1);
    float box = p.y + 1;
    return min(sphere, box);
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

float softshadow( in float3 ro, in float3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t < maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}