#include "lib/kit.as"
#include "lib/config.as"

// ---------------------------------------------------------------------------
//  Episode 02 -- The Refresh Cycle
//  Charge is always leaking; the system reads and rewrites every row in time.
// ---------------------------------------------------------------------------

float g_len = 44.0;

float[] CK_T   = {  0.0,  6.0, 13.0, 21.0, 30.0, 37.0, 44.0 };
float[] CK_AZ  = { 90.0, 95.0, 85.0, 74.0, 90.0, 85.0, 90.0 };
float[] CK_EL  = { 24.0, 18.0, 16.0, 30.0, 52.0, 46.0, 48.0 };
float[] CK_D   = { 11.0,  8.2,  6.6,  8.6, 17.0, 17.0, 19.0 };
float[] CK_FOV = { 38.0, 34.0, 36.0, 38.0, 40.0, 38.0, 40.0 };
Vec3[]  CK_TG  = {
    Vec3(0.0, 0.90, 0.0),
    Vec3(0.0, 0.66, 0.0),
    Vec3(0.0, 0.55, 0.0),
    Vec3(0.0, 0.10, 0.0),
    Vec3(0.0, -1.40, 0.0),
    Vec3(0.0, -1.30, 0.0),
    Vec3(0.0, -1.10, 0.0)
};

void build_scene(Scene@ scene)
{
    kit_build(scene, "project/textures/cards.png", 6,
              300, 110, 60,
              100000, 6 * 14,
              400, 140,
              CFG_W, CFG_H, CFG_FPS, g_len,
              "renders/ep02_the_refresh_cycle.mp4");
}

// ---------------------------------------------------------------------------
float charge_at(float t)
{
    float q = 1.0;
    q = mixf(q, 0.20, sstep(7.0, 12.6, t));
    q = mixf(q, 1.0, sstep(18.6, 20.4, t));
    return q;
}

float hero_at(float t) { return 1.0 - sstep(21.2, 22.6, t); }
float bank_at(float t) { return sstep(21.8, 23.4, t); }

void cell_and_amp(float t, float alpha, float charge)
{
    if (alpha <= 0.003) return;

    // bucket
    Vec3 wall = mix3(cyan(), white(), 0.10);
    box(Vec3(0, 0.56, 0), 0.98, 0.025, 0.98, cyan(), 0.40 * alpha);
    box(Vec3(-0.955, 1.16, 0), 0.025, 0.60, 0.98, wall, 0.18 * alpha);
    box(Vec3( 0.955, 1.16, 0), 0.025, 0.60, 0.98, wall, 0.18 * alpha);
    box(Vec3(0, 1.16, -0.955), 0.98, 0.60, 0.025, wall, 0.18 * alpha);
    box(Vec3(0, 1.16,  0.955), 0.98, 0.60, 0.025, wall, 0.18 * alpha);
    rect_xz(1.762, -0.98, -0.98, 0.98, 0.98, 0.018, white(), 0.45 * alpha);

    // charge level
    float surf = 0.60 + charge * 1.10;
    if (charge > 0.01)
    {
        glow(Vec3(0, (0.60 + surf) * 0.5, 0), 1.15, cyan(), 0.22 * charge * alpha);
        box(Vec3(0, surf, 0), 0.90, 0.004, 0.90, cyan(), (0.16 + 0.14 * charge) * alpha);
        rect_xz(surf + 0.002, -0.90, -0.90, 0.90, 0.90, 0.012, white(), (0.42 + 0.22 * charge) * alpha);
    }
    g_spark_a.set_vec3("u_region_center", 0, 1.15, 0);
    g_spark_a.set_vec3("u_region_size", 1.80, 1.10, 1.80);
    g_spark_a.set_vec3("u_color", 0.35, 0.95, 1.0);
    g_spark_a.set_float("u_fill", charge);
    g_spark_a.set_float("u_size", 1.6);
    g_spark_a.set_float("u_alpha", 0.22 * alpha);

    // bitline down to the sense amplifier
    line3(Vec3(0, 0.10, 0), Vec3(0, -0.62, 0), 0.040, cyan(), 0.40 * alpha);

    // sense amplifier: a small slab on the bitline
    float ampPulse = pulse(t, 16.2, 0.55) + 0.7 * pulse(t, 17.4, 0.5);
    box(Vec3(0, -0.75, 0), 0.34, 0.085, 0.22, amber(), (0.35 + 0.45 * ampPulse) * alpha);
    box(Vec3(0, -0.75, 0), 0.40, 0.016, 0.28, amber(), (0.25 + 0.4 * ampPulse) * alpha);
    glow(Vec3(0, -0.75, 0), 0.70, amber(), (0.06 + 0.40 * ampPulse) * alpha);

    // output of the amplifier reads as a clean bit
    float outPulse = sstep(16.4, 17.2, t) * (1.0 - sstep(20.0, 21.0, t));
    if (outPulse > 0.01)
    {
        line3(Vec3(0.40, -0.75, 0), Vec3(2.30, -0.75, 0), 0.032, white(), 0.42 * outPulse * alpha);
        box(Vec3(2.38, -0.75, 0), 0.10, 0.10, 0.10, white(), 0.65 * outPulse * alpha);
        glow(Vec3(2.38, -0.75, 0), 0.20, white(), 0.85 * outPulse * alpha);
    }

}

void bank_view(float t, float alpha)
{
    if (alpha <= 0.003) { g_cell_layer.set_float("u_alpha", 0.0); return; }

    g_cell_layer.set_uint("u_rows", 6);
    g_cell_layer.set_uint("u_cols", 14);
    g_cell_layer.set_vec2("u_spacing", 1.10, 1.10);
    g_cell_layer.set_vec3("u_origin", 0, -1.45, 0);
    g_cell_layer.set_float("u_sweep_period", 6.5);
    g_cell_layer.set_float("u_decay", 0.28);
    g_cell_layer.set_float("u_charge", 1.0);
    g_cell_layer.set_vec3("u_charge_color", 0.25, 0.95, 1.0);
    g_cell_layer.set_vec3("u_empty_color", 0.10, 0.20, 0.30);
    g_cell_layer.set_float("u_point_size", 15.0);
    g_cell_layer.set_float("u_alpha", alpha);

    float phase = t / 6.5;
    float rowF = (phase - ffloor(phase)) * 6.0;
    g_cell_layer.set_float("u_highlight_row", ffloor(rowF));
    g_cell_layer.set_float("u_highlight_boost", 0.9);

    rect_xz(-1.50, -7.45, -3.05, 7.45, 3.05, 0.012, steel(), 0.30 * alpha);
    for (int r = 0; r < 6; ++r)
    {
        float z = (float(r) - 2.5) * 1.10;
        float a = alpha * (0.05 + 0.08 * (1.0 - fabs(float(r) - 2.5) / 5.0));
        line3(Vec3(-7.6, -1.48, z), Vec3(7.6, -1.48, z), 0.008, steel(), a);
    }

    float zr = (ffloor(rowF) - 2.5) * 1.10;
    float sweep = 0.55 + 0.45 * sin(t * 9.0);
    line3(Vec3(-7.6, -1.44, zr), Vec3(7.6, -1.44, zr), 0.030, white(), alpha * 0.5 * sweep);
    line3(Vec3(-7.6, -1.40, zr), Vec3(7.6, -1.40, zr), 0.080, amber(), alpha * 0.18 * sweep);

    // 64 ms refresh window as a timeline in front of the array
    float tlA = alpha * sstep(28.0, 30.0, t) * (1.0 - sstep(36.5, 37.5, t));
    if (tlA > 0.01)
    {
        float x0 = -6.6;
        float x1 = 6.6;
        float z = 4.2;
        line3(Vec3(x0, -1.40, z), Vec3(x1, -1.40, z), 0.018, steel(), 0.7 * tlA);
        for (int i = 0; i <= 6; ++i)
        {
            float x = mixf(x0, x1, float(i) / 6.0);
            line3(Vec3(x, -1.40, z), Vec3(x, -1.28, z), 0.012, steel(), 0.5 * tlA);
        }
        float ph = phase - ffloor(phase);
        float px = mixf(x0, x1, ph);
        line3(Vec3(px, -1.40, z), Vec3(px, -1.16, z), 0.030, white(), 0.8 * tlA);
        glow(Vec3(px, -1.30, z), 0.5, amber(), 0.5 * tlA);
    }

    g_dust_layer.set_float("u_alpha", 0.5 * (1.0 - 0.55 * alpha));
}

void update_scene(Scene@ scene, float time, float dt)
{
    begin_frame();

    float hero = hero_at(time);
    float bankA = bank_at(time);
    float charge = charge_at(time);

    cell_and_amp(time, hero, charge);
    bank_view(time, bankA);

    // sense pulse travelling down the bitline, then the restore write-back
    if (time > 14.6 && time < 17.0)
    {
        g_flow_a.set_vec3("u_a", 0, 0.10, 0);
        g_flow_a.set_vec3("u_b", 0, -0.62, 0);
        g_flow_a.set_float("u_progress", sstep(14.6, 16.2, time));
        g_flow_a.set_vec3("u_color", 1.0, 0.72, 0.30);
        g_flow_a.set_float("u_alpha", 0.8 * hero * (1.0 - sstep(16.0, 17.0, time)));
        g_flow_a.set_float("u_speed", 0.6);
        g_flow_a.set_float("u_spread", 0.02);
    }
    else g_flow_a.set_float("u_alpha", 0.0);

    if (time > 18.2 && time < 20.6)
    {
        g_flow_b.set_vec3("u_a", 0, -0.60, 0);
        g_flow_b.set_vec3("u_b", 0, 0.60, 0);
        g_flow_b.set_float("u_progress", sstep(18.2, 20.0, time));
        g_flow_b.set_vec3("u_color", 0.55, 0.95, 1.0);
        g_flow_b.set_float("u_alpha", 0.8 * hero * (1.0 - sstep(19.8, 20.6, time)));
        g_flow_b.set_float("u_speed", 0.5);
        g_flow_b.set_float("u_spread", 0.02);
    }
    else g_flow_b.set_float("u_alpha", 0.0);

    cam_track(time, CK_T, CK_AZ, CK_EL, CK_D, CK_TG, CK_FOV);
    end_frame();

    float a0 = card_alpha(time, 0.9, 5.5, 0.7, 0.5);
    float a1 = card_alpha(time, 6.4, 12.8, 0.5, 0.5);
    float a2 = card_alpha(time, 13.6, 20.6, 0.5, 0.5);
    float a3 = card_alpha(time, 22.8, 29.6, 0.5, 0.5);
    float a4 = card_alpha(time, 30.4, 36.6, 0.5, 0.5);
    float a5 = card_alpha(time, 37.6, 43.6, 0.6, 0.6);

    if (a0 > 0.001) show_card(0, a0, (1.0 - a0) * 0.012);
    else if (a1 > 0.001) show_card(1, a1, (1.0 - a1) * 0.012);
    else if (a2 > 0.001) show_card(2, a2, (1.0 - a2) * 0.012);
    else if (a3 > 0.001) show_card(3, a3, (1.0 - a3) * 0.012);
    else if (a4 > 0.001) show_card(4, a4, (1.0 - a4) * 0.012);
    else show_card(5, a5, (1.0 - a5) * 0.012);

    float exp = sstep(0.0, 0.9, time) * (1.0 - 0.6 * sstep(43.0, 44.0, time));
    exp *= 1.0 - 0.14 * pulse(time, 13.0, 0.10);
    exp *= 1.0 - 0.14 * pulse(time, 21.0, 0.10);
    exp *= 1.0 - 0.14 * pulse(time, 30.0, 0.10);
    exp *= 1.0 - 0.14 * pulse(time, 37.0, 0.12);
    g_final_pass.set_float("u_exposure", exp * 0.95);
}




