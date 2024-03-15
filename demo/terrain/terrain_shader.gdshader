/*
GLSL Godot 4 Shader for drawing a height map.

To land a vertex in the center of each NxN height map pixel, you need
either a custom mesh, or a PlaneMesh with 2*N-1 x 2*N-1 subdivide slots.

https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#doc-spatial-shader


*/
shader_type spatial;
render_mode cull_disabled; // draw both faces, for better shadows

uniform sampler2D heights : repeat_disable;

void vertex() {
	// Loft the geometry to match the texture image
	VERTEX.y += texture(heights,UV).r;
	
	// Adjust the surface normal to match neighboring pixels
	vec2 pixel = 1.0 / vec2(textureSize(heights, 0));
	float spacing = 0.1f * 2.0f; // space between two pixels
	vec3 normal = vec3(
		(texture(heights,UV-vec2(pixel.x,0)).r - texture(heights,UV+vec2(pixel.x,0)).r)/spacing,
		(texture(heights,UV-vec2(0,pixel.x)).r - texture(heights,UV+vec2(0,pixel.x)).r)/spacing,
		1.0f);
	NORMAL = normalize(normal.xzy);
}

void fragment() {
	ALBEDO = vec3(0.3); 
	ROUGHNESS = 0.98f;
	CLEARCOAT = 0.0f;
	SPECULAR = 0.1f;
	
	// ALBEDO = texture(heights,UV).rrr; // draw raw heights as brightness
	
	if (false) { // make glowing grid lines
		vec3 glow = vec3(0.0,1.0,0.0);
		vec2 gridlines = fract(UV*8.0);
		if (min(gridlines.x,gridlines.y)<0.05) ALBEDO = EMISSION = glow;
	}
	//ALBEDO = vec3(UV.x,UV.y,0.0f); // debug check uv
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
