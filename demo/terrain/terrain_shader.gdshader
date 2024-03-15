/*
GLSL Godot 4 Shader for drawing a height map.

To land a vertex in the center of each NxN height map pixel, you need
either a custom mesh, or a PlaneMesh with 2*N-1 x 2*N-1 subdivide slots.

*/
shader_type spatial;

uniform sampler2D heights : repeat_disable;

void vertex() {
	// Loft the geometry to match the texture image
	VERTEX.y += texture(heights,UV).r;
	
}

void fragment() {
	ALBEDO = texture(heights,UV).rrr;
	
	vec3 glow = vec3(0.0,1.0,0.0);
	vec2 gridlines = fract(UV*8.0);
	if (min(gridlines.x,gridlines.y)<0.05) ALBEDO = EMISSION = glow;
	//ALBEDO = vec3(UV.x,UV.y,0.0f); // debug check uv
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
