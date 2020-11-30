shader_type spatial;

render_mode unshaded;

uniform sampler2D tex : hint_albedo;

void fragment() {
  ALBEDO = texture(tex, UV).xyz;
}