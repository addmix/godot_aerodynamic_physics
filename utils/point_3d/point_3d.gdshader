shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform float _width = 1.0;
uniform vec3 _color : source_color = vec3(0, 0, 0);
uniform bool checker_pattern = false;

void vertex() {
	VERTEX = VERTEX * _width;
	COLOR = vec4(VERTEX, 0);
}

void fragment() {
	vec3 output_color = _color;
	if (checker_pattern) {
		ALBEDO = _color * sign(COLOR.r) * sign(COLOR.g) * sign(COLOR.b);
	} else {
		ALBEDO = _color;
	}
}