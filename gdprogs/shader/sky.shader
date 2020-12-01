shader_type spatial;
render_mode unshaded;

const vec3 TRANSPARENT = vec3(0.0, 0.0, 0.0);	// Black color is transparent

uniform sampler2D tex : hint_albedo;



void fragment() {
	vec2 dir_UV = UV;
	
	// lower clouds
	float lc_t = mod(TIME/16.0, 1.0);
	float lc_x = mod(dir_UV.x + lc_t, 0.5);
	vec2 lc_UV = vec2(lc_x, dir_UV.y);
	vec3 lc_ALBEDO = texture(tex, lc_UV).xyz;

	// If lower clouds == TRANSPARENT(black) then
	// render higher clouds
	if (lc_ALBEDO == TRANSPARENT) {
		// higher clouds
		float hc_t = mod(TIME/32.0, 1.0);
		float hc_x = mod(dir_UV.x + hc_t, 0.5) + 0.5;
		vec2 hc_UV = vec2(hc_x, dir_UV.y);
		vec3 hc_ALBEDO = texture(tex, hc_UV).xyz;
		ALBEDO = hc_ALBEDO;
	}
	else {
 		ALBEDO = lc_ALBEDO;
	}
}