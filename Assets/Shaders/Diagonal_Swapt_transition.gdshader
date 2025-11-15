shader_type canvas_item;

uniform float progress : hint_range(0.0, 100.0) = 0.0; // ممكن يكمل لحد أي رقم
uniform int direction = 1; // 1 = من اليمين, -1 = من الشمال
uniform vec4 mask_color : source_color = vec4(0.0,0.0,0.0,1.0);

uniform int steps = 10; // عدد السلالم في الشاشة

void fragment() {
    vec2 uv = UV;

    // أي درجة واقعة فيها
    float stair = floor(uv.y * float(steps));

    // cutoff = progress بيتقسم على عدد السلالم
    float cutoff = progress / float(steps);

    // لو يمين أو شمال
    float x = (direction == 1) ? uv.x : (1.0 - uv.x);

    // نحرك كل درجة حسب ترتيبها
    float shifted = x + stair / float(steps);

    if (shifted < cutoff) {
        COLOR = mask_color; // متغطي
    } else {
        COLOR = vec4(0.0,0.0,0.0,0.0); // شفاف
    }
}
