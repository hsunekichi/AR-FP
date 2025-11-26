// HSV to RBG from https://www.rapidtables.com/convert/color/hsv-to-rgb.html
// Rotation matrix from https://en.wikipedia.org/wiki/Rotation_matrix

shader_type canvas_item;

uniform float strength: hint_range(0., 1.) = 0.5;
uniform float speed: hint_range(0., 10.) = 0.5;
uniform float angle: hint_range(0., 360.) = 0.;
uniform float alpha: hint_range(0., 1.) = 1.;
uniform float inner_radius: hint_range(0., 1.) = 0.2;  // Inner circle radius where alpha is 0

void fragment() 
{
	float d = distance(UV, vec2(0.5));
	
	// Calculate alpha based on distance from center
	// Inner circle (d < inner_radius) has alpha 0
	// Gradually increases from inner_radius to corners
	float distance_alpha = smoothstep(inner_radius, 0.707, d);  // 0.707 is distance to corner
	
	// Remap distance for hue calculation to start at inner_radius
	float hue = (d - inner_radius) / (0.707 - inner_radius);
	hue = clamp(hue, 0., 1.);
	hue = fract(hue - fract(TIME  * speed));

	float x = 1. - abs(mod(hue / (1./ 6.), 2.) - 1.);
	vec3 rainbow;

	if(hue < 1./6.){
		rainbow = vec3(1., x, 0.);
	} else if (hue < 1./3.) {
		rainbow = vec3(x, 1., 0);
	} else if (hue < 0.5) {
		rainbow = vec3(0, 1., x);
	} else if (hue < 2./3.) {
		rainbow = vec3(0., x, 1.);
	} else if (hue < 5./6.) {
		rainbow = vec3(x, 0., 1.);
	} else {
		rainbow = vec3(1., 0., x);
	}
	
	vec4 color = vec4(1.);
	color = mix(color, vec4(rainbow, color.a), strength);
	color.a = alpha * distance_alpha;  // Combine uniform alpha with distance-based alpha
	COLOR = color;
}