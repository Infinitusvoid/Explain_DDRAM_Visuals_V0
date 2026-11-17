#include "lib/kit.as"
#include "lib/config.as"

// ---------------------------------------------------------------------------
//  Episode 01 -- The Leaky Bucket
//  A DRAM bit is one transistor, one capacitor and a very slow escape.
// ---------------------------------------------------------------------------

float g_len = 46.0;

// camera keyframes (seconds, azimuth, elevation, distance, target, fov)
float[] CK_T   = {  0.0,  6.0, 12.5, 19.5, 26.5, 33.5, 40.5, 46.0 };
float[] CK_AZ  = { 95.0, 80.0, 100.0, 62.0, 100.0, 70.0, 90.0, 85.0 };
float[] CK_EL  = { 24.0, 22.0,  14.0, 16.0,  22.0, 40.0, 52.0, 48.0 };
float[] CK_D   = { 10.6,  7.0,  6.2,  6.6,  7.2, 15.5, 14.5, 16.0 };
float[] CK_FOV = { 38.0, 34.0,  40.0, 34.0,  35.0, 40.0, 38.0, 40.0 };
Vec3[]  CK_TG  = {
    Vec3(0.0, 0.62, 0.0),
    Vec3(0.0, 0.58, 0.0),
    Vec3(-0.45, 0.40, 0.0),
    Vec3(0.0, 0.72, 0.0),
    Vec3(0.0, 0.60, 0.0),
    Vec3(0.0, 0.0, 0.0),
    Vec3(0.0, 0.0, 0.0),
    Vec3(0.0, 0.2, 0.0)
};

void build_scene(Scene@ scene)
{
    kit_build(scene, "project/textures/cards.png", 7,
              300, 100, 60,
              110000, 6 * 14,
              420, 140,
              CFG_W, CFG_H, CFG_FPS, g_len,
              "renders/ep01_the_leaky_bucket.mp4");
}

// ---------------------------------------------------------------------------
float charge_at(float t)
{
    float q = 0.30;
    q = mixf(q, 1.0, sstep(7.6, 9.4, t));      // first write
    q = mixf(q, 0.10, sstep(21.0, 25.6, t));   // the leak
    q = mixf(q, 1.0, sstep(28.0, 29.4, t));    // refresh
    return q;
}

float bank_at(float t)
{
    return sstep(35.0, 35.9, t);
}

float hero_at(float t)
{
    return 1.0 - sstep(34.6, 35.5, t);
}

void hero_cell(float t, float alpha, float charge, float leak)
{
    if (alpha <= 0.003) return;

    // drafting floor
    grid_xz(-1.5, 5.4, 0.6, 0.010, steel(), 0.05 * alpha);

    // ---- the bucket: floor, four walls, open top
    Vec3 wall = mix3(cyan(), white(), 0.10);
    box(Vec3(0, 0.56, 0), 0.98, 0.025, 0.98, cyan(), 0.42 * alpha);
    box(Vec3(-0.955, 1.16, 0), 0.025, 0.60, 0.98, wall, 0.34 * alpha);
    box(Vec3( 0.955, 1.16, 0), 0.025, 0.60, 0.98, wall, 0.34 * alpha);
    box(Vec3(0, 1.16, -0.955), 0.98, 0.60, 0.025, wall, 0.34 * alpha);
    box(Vec3(0, 1.16,  0.955), 0.98, 0.60, 0.025, wall, 0.34 * alpha);

    // bright rim and floor outline
    rect_xz(1.762, -0.98, -0.98, 0.98, 0.98, 0.018, white(), 0.48 * alpha);
    rect_xz(0.535, -0.98, -0.98, 0.98, 0.98, 0.012, cyan(), 0.22 * alpha);

    // ---- transistor at the base of the bucket
    box(Vec3(0, 0.32, 0), 0.30, 0.090, 0.22, steel(), 0.85 * alpha);
    box(Vec3(0, 0.32, 0), 0.37, 0.105, 0.27, amber(), 0.34 * alpha);
    line3(Vec3(0, 0.41, 0), Vec3(0, 0.535, 0), 0.045, steel(), 0.60 * alpha);
    line3(Vec3(0, 0.23, 0), Vec3(0, 0.10, 0), 0.050, steel(), 0.60 * alpha);

    // wordline (control) from the left, into the gate
    line3(Vec3(-3.4, 0.32, 0), Vec3(-0.26, 0.32, 0), 0.050, amber(), 0.80 * alpha);

    // bitline (data) downwards, then away to the left
    line3(Vec3(0, 0.10, 0), Vec3(0, -1.05, 0), 0.045, cyan(), 0.42 * alpha);
    line3(Vec3(0, -1.05, 0), Vec3(-3.4, -1.05, 0), 0.042, cyan(), 0.30 * alpha);

    // glows
    glow(Vec3(0, 1.00, 0), 1.9, cyan(), (0.04 + 0.16 * charge) * alpha);
    glow(Vec3(0, 1.62, 0), 0.9, cyan(), (0.01 + 0.08 * charge) * alpha);
    glow(Vec3(0, 0.32, 0), 0.95, amber(), 0.16 * alpha);

    // stored charge as a glowing liquid: volume up to the waterline
    float surf = 0.60 + charge * 1.10;
    if (charge > 0.01)
    {
        glow(Vec3(0, (0.60 + surf) * 0.5, 0), 1.15, cyan(), 0.26 * charge * alpha);
        box(Vec3(0, surf, 0), 0.90, 0.004, 0.90, cyan(), (0.17 + 0.15 * charge) * alpha);
        for (int b = 1; b <= 3; ++b)
        {
            float yy = 0.60 + (surf - 0.60) * (1.0 - float(b) * 0.25);
            box(Vec3(0, yy, 0), 0.88, 0.003, 0.88, cyan(), 0.05 * alpha);
        }
        rect_xz(surf + 0.002, -0.90, -0.90, 0.90, 0.90, 0.012, white(), (0.50 + 0.25 * charge) * alpha);
    }

    // charge particles inside the bucket
    g_spark_a.set_vec3("u_region_center", 0, 1.15, 0);
    g_spark_a.set_vec3("u_region_size", 1.80, 1.10, 1.80);
    g_spark_a.set_vec3("u_color", 0.35, 0.95, 1.0);
    g_spark_a.set_float("u_fill", charge);
    g_spark_a.set_float("u_size", 1.6);
    g_spark_a.set_float("u_alpha", 0.28 * alpha);

    // escaping particles
    g_spark_b.set_vec3("u_region_center", 0, 1.15, 0);
    g_spark_b.set_vec3("u_region_size", 1.80, 1.10, 1.80);
    g_spark_b.set_vec3("u_color", 1.0, 0.45, 0.30);
    g_spark_b.set_float("u_invert", 1.0);
    g_spark_b.set_float("u_escape", leak);
    g_spark_b.set_float("u_rise", 1.5);
    g_spark_b.set_float("u_alpha", 0.65 * alpha * leak);
    g_spark_b.set_float("u_size", 2.4);

    // rounding ring under the cell
    ring_xz(Vec3(0, -1.49, 0), 2.35, 64, 0.012, cyan(), 0.14 * alpha, t * 0.10);
}
void pulses(float t, float alpha)
{
    // write pulse travelling up the bitline as the first bit is stored
    if (t > 7.0 && t < 10.6)
    {
        g_flow_a.set_vec3("u_a", 0, -1.05, 0);
        g_flow_a.set_vec3("u_b", 0, 0.56, 0);
        g_flow_a.set_float("u_progress", sstep(7.0, 9.2, t));
        g_flow_a.set_vec3("u_color", 0.55, 0.95, 1.0);
        g_flow_a.set_float("u_alpha", 0.75 * alpha * (1.0 - sstep(9.6, 10.6, t)));
        g_flow_a.set_float("u_speed", 0.35);
        g_flow_a.set_float("u_spread", 0.03);
    }
    else g_flow_a.set_float("u_alpha", 0.0);

    // wordline activation pulse on the parts beat
    if (t > 14.2 && t < 16.9)
    {
        g_flow_b.set_vec3("u_a", -3.40, 0.32, 0);
        g_flow_b.set_vec3("u_b", -0.26, 0.32, 0);
        g_flow_b.set_float("u_progress", 1.0);
        g_flow_b.set_vec3("u_color", 1.0, 0.74, 0.32);
        g_flow_b.set_float("u_alpha", alpha * sstep(14.2, 14.9, t) * (1.0 - sstep(16.1, 16.9, t)));
        g_flow_b.set_float("u_speed", 0.45);
        g_flow_b.set_float("u_spread", 0.02);
    }
    // second pulse for the refresh write-back
    else if (t > 27.8 && t < 31.4)
    {
        g_flow_b.set_vec3("u_a", 0, -1.05, 0);
        g_flow_b.set_vec3("u_b", 0, 0.56, 0);
        g_flow_b.set_float("u_progress", sstep(27.8, 29.9, t));
        g_flow_b.set_vec3("u_color", 0.80, 0.55, 1.0);
        g_flow_b.set_float("u_alpha", alpha * (1.0 - sstep(30.3, 31.4, t)));
        g_flow_b.set_float("u_speed", 0.30);
        g_flow_b.set_float("u_spread", 0.06);
    }
    else g_flow_b.set_float("u_alpha", 0.0);

    // rings: one when the cell first charges, one on refresh
    float r1 = sstep(8.6, 10.8, t);
    if (r1 > 0.001 && r1 < 0.999)
    {
        float rad = 0.6 + r1 * 2.6;
        ring_xz(Vec3(0, 1.76, 0), rad, 72, 0.018, cyan(), alpha * (1.0 - r1) * 0.85, 0.0);
    }
    float r2 = sstep(28.8, 31.0, t);
    if (r2 > 0.001 && r2 < 0.999)
    {
        float rad = 0.6 + r2 * 2.6;
        ring_xz(Vec3(0, 1.76, 0), rad, 72, 0.018, violet(), alpha * (1.0 - r2) * 0.85, 0.0);
    }
}

void bank(float t, float alpha)
{
    if (alpha <= 0.003)
    {
        g_cell_layer.set_float("u_alpha", 0.0);
        return;
    }

    g_cell_layer.set_uint("u_rows", 6);
    g_cell_layer.set_uint("u_cols", 14);
    g_cell_layer.set_vec2("u_spacing", 1.10, 1.10);
    g_cell_layer.set_vec3("u_origin", 0, -1.45, 0);
    g_cell_layer.set_float("u_sweep_period", 6.0);
    g_cell_layer.set_float("u_decay", 0.22);
    g_cell_layer.set_float("u_charge", 1.0);
    g_cell_layer.set_vec3("u_charge_color", 0.25, 0.95, 1.0);
    g_cell_layer.set_vec3("u_empty_color", 0.10, 0.20, 0.30);
    g_cell_layer.set_float("u_point_size", 15.0);
    g_cell_layer.set_float("u_alpha", alpha);

    // one row is highlighted while it refreshes
    float phase = (t / 6.0);
    float rowF = (phase - ffloor(phase)) * 6.0;
    g_cell_layer.set_float("u_highlight_row", ffloor(rowF));
    g_cell_layer.set_float("u_highlight_boost", 0.9);

    // row guides so the array reads as rows
    for (int r = 0; r < 8; ++r)
    {
        float z = (float(r) - 2.5) * 1.10;
        float a = alpha * (0.06 + 0.10 * (1.0 - fabs(float(r) - 2.5) / 5.0));
        line3(Vec3(-9.0, -1.47, z), Vec3(9.0, -1.47, z), 0.008, steel(), a);
    }

    // array border
    rect_xz(-1.50, -7.45, -3.05, 7.45, 3.05, 0.012, steel(), 0.30 * alpha);
    rect_xz(-1.49, -7.45, -3.05, 7.45, 3.05, 0.006, cyan(), 0.12 * alpha);

    // refresh sweep: a bright bar crossing the row being refreshed
    float zr = (ffloor(rowF) - 2.5) * 1.10;
    float sweep = 0.55 + 0.45 * sin(t * 9.0);
    line3(Vec3(-9.2, -1.44, zr), Vec3(9.2, -1.44, zr), 0.030, white(), alpha * 0.55 * sweep);
    line3(Vec3(-9.2, -1.40, zr), Vec3(9.2, -1.40, zr), 0.075, amber(), alpha * 0.20 * sweep);
}

void update_scene(Scene@ scene, float time, float dt)
{
    begin_frame();

    float hero = hero_at(time);
    float bankA = bank_at(time);
    float charge = charge_at(time);
    float leak = window(time, 20.2, 21.2, 25.4, 26.3);

    float dim = mixf(0.34, 1.0, sstep(4.9, 6.1, time));
    hero_cell(time, hero * dim, charge, leak);
    pulses(time, hero * dim);
    bank(time, bankA);
    g_dust_layer.set_float("u_alpha", 0.5 * (1.0 - 0.55 * bankA));

    cam_track(time, CK_T, CK_AZ, CK_EL, CK_D, CK_TG, CK_FOV);

    end_frame();

    // ---- typography
    float a0 = card_alpha(time, 0.9, 5.4, 0.7, 0.5);
    float a1 = card_alpha(time, 6.4, 12.0, 0.5, 0.5);
    float a2 = card_alpha(time, 13.0, 19.0, 0.5, 0.5);
    float a3 = card_alpha(time, 20.0, 26.0, 0.5, 0.5);
    float a4 = card_alpha(time, 27.0, 33.0, 0.5, 0.5);
    float a5 = card_alpha(time, 34.0, 40.0, 0.5, 0.5);
    float a6 = card_alpha(time, 41.0, 45.6, 0.6, 0.6);

    if (a0 > 0.001) show_card(0, a0, (1.0 - a0) * 0.012);
    else if (a1 > 0.001) show_card(1, a1, (1.0 - a1) * 0.012);
    else if (a2 > 0.001) show_card(2, a2, (1.0 - a2) * 0.012);
    else if (a3 > 0.001) show_card(3, a3, (1.0 - a3) * 0.012);
    else if (a4 > 0.001) show_card(4, a4, (1.0 - a4) * 0.012);
    else if (a5 > 0.001) show_card(5, a5, (1.0 - a5) * 0.012);
    else show_card(6, a6, (1.0 - a6) * 0.012);

    // ---- exposure: fade in, tiny cut dips on beat changes, fade out
    float exp = sstep(0.0, 0.9, time) * (1.0 - 0.6 * sstep(45.0, 46.0, time));
    exp *= 1.0 - 0.15 * pulse(time, 12.5, 0.10);
    exp *= 1.0 - 0.15 * pulse(time, 19.5, 0.10);
    exp *= 1.0 - 0.15 * pulse(time, 26.5, 0.10);
    exp *= 1.0 - 0.15 * pulse(time, 33.5, 0.12);
    exp *= 1.0 - 0.15 * pulse(time, 40.5, 0.12);
    g_final_pass.set_float("u_exposure", exp * 1.05);
}












