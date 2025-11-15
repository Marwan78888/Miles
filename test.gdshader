shader_type canvas_item;

// ====== SETTINGS ======
uniform float time_speed : hint_range(0.1, 5.0) = 1.0;
uniform float density : hint_range(0.0, 1.0) = 0.4;
uniform float size : hint_range(0.001, 0.02) = 0.005;
uniform float wind_speed : hint_range(0.0, 1.0) = 0.2;
uniform float wind_strength : hint_range(0.0, 50.0) = 20.0;
uniform vec4 ash_color : source_color = vec4(0.7, 0.7, 0.7, 0.8);
uniform vec2 direction = vec2(0.5, -1.0);
uniform vec2 viewport_size = vec2(1280.0, 720.0); // ← حدد مقاس الشاشة هنا أو خليه من الكود

// ====== RANDOM FUNCTION ======
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / viewport_size;
    float t = TIME * time_speed;

    // تحريك الرماد بالرياح
    vec2 wind = vec2(sin(t * wind_speed) * wind_strength, 0.0);
    vec2 move = uv * 10.0 + t * direction + wind * 0.001;

    // توليد عشوائي لنقط الرماد
    float n = rand(floor(move / size));

    // كثافة الرماد
    float alpha = smoothstep(1.0 - density, 1.0, n);

    // لون وشفافية الرماد
    COLOR = ash_color * alpha;

    // نعومة الحواف
    COLOR.a *= 0.3 + 0.7 * n;
}
