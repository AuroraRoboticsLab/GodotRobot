/*
GLSL Godot 4 Shader for drawing a height map.

*/
shader_type spatial;

uniform sampler2D heights;

void vertex() {
	// Loft the geometry to match the texture image
	VERTEX.y += texture(heights,UV).r;
	
}

void fragment() {
	ALBEDO = texture(heights,UV).rrr;
	//ALBEDO = vec3(UV.x,UV.y,0.0f); // debug check uv
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
