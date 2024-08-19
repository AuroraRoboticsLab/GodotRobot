/*
GLSL Godot 4 Shader for drawing a height map.

To land a vertex in the center of each NxN height map pixel, you need
either a custom mesh, or a PlaneMesh with 2*N-1 x 2*N-1 subdivide slots.

https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html#doc-spatial-shader


*/
shader_type spatial;
render_mode cull_disabled; // draw both faces, for better shadows

uniform sampler2D heights : repeat_disable; // height of terrain in meters along Y axis

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


vec3 lunar_surface_normal(vec2 uv)
{
	return vec3(0.5,0.5,1.0); //<- Z up, uses vertex normals calculated above
}

#include "res://terrain/lunar_surface.gdshaderinc"
