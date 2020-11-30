shader_type spatial;

render_mode unshaded;

uniform sampler2D tex : hint_albedo;


void fragment() {
	float x; 
	x = mod(UV.x, 0.5) + 0.5;
	vec2 UV_right = vec2(x, UV.y);
		
 	ALBEDO = texture(tex, UV_right).xyz;
}