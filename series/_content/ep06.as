#include "lib/kit.as"
#include "lib/config.as"

// ---------------------------------------------------------------------------
//  Episode 06 -- Inside a DIMM
//  Module -> rank -> bank -> controller. The system view of DRAM.
// ---------------------------------------------------------------------------

float g_len = 44.0;

float[] CK_T   = {  0.0,  6.0, 14.0, 22.0, 30.0, 38.0, 44.0 };
float[] CK_AZ  = { 90.0, 88.0, 92.0, 100.0, 96.0, 90.0, 84.0 };
float[] CK_EL  = { 42.0, 38.0, 34.0, 48.0, 40.0, 30.0, 26.0 };
float[] CK_D   = { 19.0, 16.0, 13.5, 6.2, 12.0, 17.0, 19.0 };
float[] CK_FOV = { 42.0, 42.0, 40.0, 42.0, 42.0, 40.0, 40.0 };
Vec3[]  CK_TG  = {
    Vec3(0.0, 0.02, 0.0),
    Vec3(0.0, 0.02, 0.0),
    Vec3(0.0, 0.02, 0.0),
    Vec3(2.10, 0.30, 0.0),
    Vec3(-2.0, 0.30, 0.0),
    Vec3(0.0, 0.30, 0.0),
    Vec3(0.0, 0.30, 0.0)
};

const int CHIPS = 8;
float chipX(int i) { return -4.9 + float(i) * 1.4; }

void build_scene(Scene@ scene)
{
    kit_build(scene, "project/textures/cards.png", 6,
              220, 120, 60,
              80000, 0,
              0, 0,
              CFG_W, CFG_H, CFG_FPS, g_len,
              "renders/ep06_inside_a_dimm.mp4");
}

void module(float t, float alpha, float rankPulse, float bankZoom)
{
    // PCB
    box(Vec3(0, 0, 0), 6.2, 0.07, 1.5, steel(), 0.28 * alpha);
    rect_xz(0.072, -6.2, -1.5, 6.2, 1.5, 0.020, steel(), 0.55 * alpha);
    // edge connector teeth
    for (int i = 0; i < 26; ++i)
    {
        float x = -6.0 + float(i) * 0.48;
        line3(Vec3(x, -0.02, 1.56), Vec3(x, 0.06, 1.56), 0.022, amber(), 0.20 * alpha);
    }

    // memory controller
    box(Vec3(-8.4, 0.10, 0), 0.75, 0.30, 1.05, amber(), 0.42 * alpha);
    rect_xz(0.42, -9.15, -1.05, -7.65, 1.05, 0.016, amber(), 0.55 * alpha);
    glow(Vec3(-8.4, 0.22, 0), 1.2, amber(), 0.12 * alpha);
    line3(Vec3(-7.65, 0.10, 0), Vec3(-6.25, 0.10, 0), 0.045, amber(), 0.45 * alpha);

    // chips
    for (int i = 0; i < CHIPS; ++i)
    {
        float x = chipX(i);
        float pulse = rankPulse * (0.5 + 0.5 * sin(t * 6.0 - float(i) * 0.5));
        Vec3 col = (i % 2 == 0) ? cyan() : mix3(cyan(), violet(), 0.55);
        box(Vec3(x, 0.19, 0), 0.55, 0.09, 0.95, col, (0.45 + 0.45 * pulse) * alpha);
        rect_xz(0.285, x - 0.55, -0.95, x + 0.55, 0.95, 0.012, white(), (0.28 + 0.45 * pulse) * alpha);
        // address trace to the controller
        line3(Vec3(-6.25, 0.10, 0), Vec3(x, 0.10, -1.5), 0.010, steel(), 0.22 * alpha);
        line3(Vec3(x, 0.10, -1.5), Vec3(x, 0.10, -0.95), 0.010, steel(), 0.22 * alpha);
    }

    // bank array inside one chip (zoom beat)
    if (bankZoom > 0.01)
    {
        float cx = chipX(3);
        for (int b = 0; b < 16; ++b)
        {
            int bx = b % 4;
            int by = b / 4;
            float x = cx + (float(bx) - 1.5) * 0.24;
            float z = (float(by) - 1.5) * 0.42;
            float sweep = 0.5 + 0.5 * sin(t * 3.0 - float(b) * 0.6);
            box(Vec3(x, 0.32, z), 0.085, 0.020, 0.13, mix3(cyan(), white(), 0.2 + 0.5 * sweep), (0.45 + 0.45 * sweep) * bankZoom);
        }
        rect_xz(0.30, cx - 0.55, -0.95, cx + 0.55, 0.95, 0.010, white(), 0.35 * bankZoom);
    }
}

void update_scene(Scene@ scene, float time, float dt)
{
    begin_frame();

    float alpha = 1.0;
    float rankPulse = sstep(14.6, 15.6, time) * (1.0 - sstep(21.0, 22.0, time));
    float bankZoom = sstep(22.0, 23.6, time) * (1.0 - sstep(29.6, 30.8, time));

    module(time, alpha, rankPulse + 0.35 * sstep(8.0, 9.0, time), bankZoom);

    // data packets running controller -> chips (interleaving)
    float runA = sstep(29.0, 31.0, time) * (1.0 - sstep(37.0, 38.0, time));
    if (runA > 0.01)
    {
        for (int i = 0; i < CHIPS; ++i)
        {
            float phase = fmod_p(time * 0.55 + float(i) * 0.125, 1.0);
            float x0 = -6.9;
            float x1 = chipX(i);
            float x = mixf(x0, x1, phase);
            float fade = sin(phase * PI);
            line3(Vec3(x - 0.55, 0.16, -0.2), Vec3(x, 0.16, -0.2), 0.050, (i % 2 == 0) ? cyan() : violet(), 0.9 * fade * runA);
            glow(Vec3(x, 0.16, -0.2), 0.30, white(), 0.55 * fade * runA);
            glow(Vec3(x, 0.16, -0.2), 0.22, white(), 0.5 * fade * runA);
        }
    }

    // controller heartbeat
    float beat = 0.5 + 0.5 * sin(time * 3.2);
    glow(Vec3(-8.4, 0.22, 0), 0.9, amber(), 0.10 + 0.10 * beat);

    cam_track(time, CK_T, CK_AZ, CK_EL, CK_D, CK_TG, CK_FOV);
    end_frame();

    float a0 = card_alpha(time, 0.9, 5.4, 0.7, 0.5);
    float a1 = card_alpha(time, 6.4, 13.4, 0.5, 0.5);
    float a2 = card_alpha(time, 14.6, 21.4, 0.5, 0.5);
    float a3 = card_alpha(time, 22.6, 29.4, 0.5, 0.5);
    float a4 = card_alpha(time, 30.6, 37.2, 0.5, 0.5);
    float a5 = card_alpha(time, 38.0, 43.6, 0.6, 0.6);

    if (a0 > 0.001) show_card(0, a0, (1.0 - a0) * 0.012);
    else if (a1 > 0.001) show_card(1, a1, (1.0 - a1) * 0.012);
    else if (a2 > 0.001) show_card(2, a2, (1.0 - a2) * 0.012);
    else if (a3 > 0.001) show_card(3, a3, (1.0 - a3) * 0.012);
    else if (a4 > 0.001) show_card(4, a4, (1.0 - a4) * 0.012);
    else show_card(5, a5, (1.0 - a5) * 0.012);

    float exp = sstep(0.0, 0.9, time) * (1.0 - 0.65 * sstep(43.0, 44.0, time));
    exp *= 1.0 - 0.13 * pulse(time, 14.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 22.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 30.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 38.0, 0.12);
    g_final_pass.set_float("u_exposure", exp * 0.95);
}


