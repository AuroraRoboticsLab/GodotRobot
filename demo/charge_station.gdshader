shader_type spatial;

// Uniform to control the "battery charge" level
uniform float charge_percentage = 0.5;  // You can adjust this from the Godot editor

void vertex() {
	// Vertex shader is not needed for this effect
}

void fragment() {
	// Calculate whether the current fragment's height is below the charge level
	if (UV.y < (1.0-charge_percentage)/2.0 || (UV.y > 0.5)) {
		ALBEDO = vec3(0.2, 0.2, 0.2); // Dark grey for uncharged area
	} else {
		ALBEDO = vec3(0.0, 1.0, 0.0); // Green for charged area
	}
}

// The light function is not needed for this shader unless you want specific lighting effects