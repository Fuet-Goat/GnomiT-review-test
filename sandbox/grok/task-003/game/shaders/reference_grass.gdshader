shader_type spatial;
render_mode cull_disabled;

// Linear vertex colours come from the authored grass geometry in the GLB.
// This preserves the small coloured fill used in the displayed Blender trial.
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.84;
	SPECULAR = 0.25;
	EMISSION = COLOR.rgb * 0.075;
}
