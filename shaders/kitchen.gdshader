shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	ALBEDO = original;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
