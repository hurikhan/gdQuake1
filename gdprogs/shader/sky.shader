shader_type spatial;

render_mode unshaded;

uniform sampler2D tex : hint_albedo;


void fragment() {
	// Lower Clouds
	float t1 = mod(TIME/16.0, 1.0);
	float x1 = mod(UV.x + t1, 0.5);
	vec2 UV_1 = vec2(x1, UV.y);
	vec3 ALBEDO_1 = texture(tex, UV_1).xyz;
	
	// If lower clouds == black then
	// render higher clouds
	if (ALBEDO_1 == vec3(0.0, 0.0, 0.0)) {
		// highe clouds
		float t2 = mod(TIME/32.0, 1.0);
		float x2 = mod(UV.x + t2, 0.5) + 0.5;
		vec2 UV_2 = vec2(x2, UV.y);
		vec3 ALBEDO_2 = texture(tex, UV_2).xyz;
		ALBEDO = ALBEDO_2;
	}
	else {
 		ALBEDO = ALBEDO_1;
	}
}