/*
 Calculates color of lunar surface in a fragment shader.
 You need to implement vec3 lunar_surface_normal(vec2 uv).
*/

uniform sampler2D normals_detail : repeat_enable, filter_linear_mipmap_anisotropic; // tiling detail texture

// Convert packed 0..1 image to -1 .. +1 vector
vec3 unpack_normalmap(vec3 src)
{
	return (src - vec3(0.5))*2.0;
}
// Re-pack into 0..1
vec3 repack_normalmap(vec3 N)
{
	return vec3(0.5) + 0.5*normalize(N);
}

// Set ALBEDO, ROUGHNESS, NORMAL_MAP, etc for this lunar surface location.
void fragment() {
	ALBEDO = vec3(0.3); // lunar dirt has low albedo
	ROUGHNESS = 0.98f; // it's very rough
	CLEARCOAT = 0.0f; // no surface coat, all dust
	SPECULAR = 0.1f; // specular only at low angles
	
	// Start with map normals
	// You need to implement this function to look up your packed normal map color here.
	//    Return vec3(0.5,0.5,1.0) if Y-up is fine.
	vec3 Nmap = lunar_surface_normal(UV);
	vec3 N = unpack_normalmap(Nmap);
	
	// Add detail texture from global coordinates (so separate shaders will line up)
	float global_scale1=1.0f/4.0f; // makes 4 meter repeat pattern
	float global_scale2=1.0f/64.0f; // makes 64 meter repeat pattern
	vec4 world = INV_VIEW_MATRIX * vec4(VERTEX, 1.0f);
	world.xyz = world.xyz / world.w; // undo perspective divide
	vec2 xy1 = world.xz * global_scale1; // <- spatial repeat inverval
	vec2 xy2 = world.xz * global_scale2;
	float out_scale1 = 2.0f; // amplitude of small normal deviations
	float out_scale2 = 0.5f; // amplitude of large normal deviations
	vec3 upvector = vec3(0,0,1);
	N += out_scale1*(unpack_normalmap(texture(normals_detail, xy1).rgb) - upvector);
	N += out_scale2*(unpack_normalmap(texture(normals_detail, xy2).rgb) - upvector);
	
	N.y = -N.y; // DEM normals have a Y flip
	vec3 Npack = repack_normalmap(N); // unit length
	NORMAL_MAP = Npack; // wants an "OpenGL style" normal map, including 0.5 bias
	
	/*
	if (true) { // make glowing grid lines every 10 meters
		vec3 glow = vec3(0.0,0.6,0.0);
		vec2 gridlines = fract(world.xz/10.0);
		if (min(gridlines.x,gridlines.y)<0.001) ALBEDO = EMISSION = glow;
	}
	*/
	
//	ALBEDO=vec3(0); // debug
//  EMISSION = texture(heights,UV).rrr; // draw raw heights as brightness
//	EMISSION = vec3(UV.x,UV.y,0.0f); // debug UV texture coords
//	EMISSION = vec3(xy.x,xy.y,0.0f); // debug xy world pos
//	EMISSION = Nmap;
}
