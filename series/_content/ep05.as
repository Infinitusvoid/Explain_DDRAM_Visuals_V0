#include "lib/kit.as"
#include "lib/config.as"

// ---------------------------------------------------------------------------
//  Episode 05 -- Double Data Rate
//  Two transfers per clock, eight beats per access, sixty-four pins wide.
// ---------------------------------------------------------------------------

float g_len = 42.0;

float[] CK_T   = {  0.0,  6.0, 13.0, 20.0, 28.0, 35.0, 42.0 };
float[] CK_AZ  = { 84.0, 88.0, 86.0, 84.0, 80.0, 86.0, 90.0 };
float[] CK_EL  = { 14.0, 10.0,  8.0, 14.0, 18.0, 12.0, 10.0 };
float[] CK_D   = { 12.0, 10.0,  9.5, 10.0, 12.0, 12.0, 13.0 };
float[] CK_FOV = { 46.0, 46.0, 46.0, 48.0, 50.0, 46.0, 46.0 };
Vec3[]  CK_TG  = {
    Vec3(0.0, 2.20, 0.0),
    Vec3(0.0, 2.20, 0.0),
    Vec3(0.0, 2.20, 0.0),
    Vec3(0.0, 1.80, 0.0),
    Vec3(0.0, 0.80, 0.0),
    Vec3(0.0, 1.60, 0.0),
    Vec3(0.0, 1.80, 0.0)
};

float Y_CLK = 3.4;
float Y_DQ = 2.25;
float X0 = -9.0;
float X1 = 9.6;

void build_scene(Scene@ scene)
{
    kit_build(scene, "project/textures/cards.png", 6,
              620, 80, 80,
              90000, 0,
              500, 420,
              CFG_W, CFG_H, CFG_FPS, g_len,
              "renders/ep05_double_data_rate.mp4");
}

void clock_wave(float a, float reach)
{
    float period = 1.2;
    float amp = 0.55;
    float prevX = X0;
    float prevY = Y_CLK - amp;
    for (float x = X0; x < X1; x += period)
    {
        if (x > reach) break;
        float hiY = Y_CLK + amp;
        float loY = Y_CLK - amp;
        bool high = fmod_p((x - X0) / period, 2.0) < 1.0;
        line3(Vec3(prevX, prevY, 0), Vec3(x, prevY, 0), 0.028, cyan(), 0.7 * a * (x < reach ? 1.0 : 0.20));
        float y2 = high ? hiY : loY;
        line3(Vec3(x, prevY, 0), Vec3(x, y2, 0), 0.028, cyan(), 0.7 * a * (x < reach ? 1.0 : 0.20));
        prevX = x;
        prevY = y2;
        float xe = x + period * 0.5;
        if (xe > reach) xe = reach;
        line3(Vec3(x, y2, 0), Vec3(xe, y2, 0), 0.028, cyan(), 0.7 * a * (x < reach ? 1.0 : 0.20));
        prevX = xe;
        prevY = y2;
    }
}

// a data beat drawn as a raised block on the DQ lane
void beat(float x, float w, Vec3 col, float a)
{
    float y = Y_DQ;
    float h = 0.75;
    line3(Vec3(x, y, 0), Vec3(x, y + h, 0), 0.026, col, a);
    line3(Vec3(x, y + h, 0), Vec3(x + w, y + h, 0), 0.040, col, a);
    line3(Vec3(x + w, y + h, 0), Vec3(x + w, y, 0), 0.026, col, a);
}

void update_scene(Scene@ scene, float time, float dt)
{
    begin_frame();

    float px = -8.6 + seq(time, 6.0, 34.0) * 18.0;

    // grid paper
    for (int i = -9; i <= 9; ++i)
        line3(Vec3(float(i), 0.9, 0), Vec3(float(i), 4.2, 0), 0.005, steel(), 0.04);

    // lanes
    line3(Vec3(X0, Y_CLK, 0), Vec3(X1, Y_CLK, 0), 0.012, steel(), 0.25);
    line3(Vec3(X0, Y_DQ, 0), Vec3(X1, Y_DQ, 0), 0.012, steel(), 0.25);
    clock_wave(1.0, px);

    // SDR: one beat per rising edge
    float sdrA = sstep(6.4, 8.0, time) * (1.0 - sstep(12.2, 13.4, time));
    if (sdrA > 0.01)
    {
        for (float x = -8.0; x < 6.0; x += 1.2)
        {
            bool past = x < px;
            beat(x + 0.14, 0.42, white(), 0.85 * sdrA * (past ? 1.0 : 0.22));
        }
    }

    // DDR: also on the falling edge -> double density
    float ddrA = sstep(13.4, 15.0, time) * (1.0 - sstep(19.4, 20.6, time));
    if (ddrA > 0.01)
    {
        for (float x = -8.0; x < 6.0; x += 0.6)
        {
            bool past2 = x < px;
            bool rise = fmod_p((x + 8.0) / 1.2, 1.0) < 0.25;
            Vec3 col = rise ? white() : amber();
            beat(x + 0.07, 0.38, col, 0.9 * ddrA * (past2 ? 1.0 : 0.22));
        }
    }

    // prefetch: eight beats per access, on a wide bus
    float pfA = sstep(20.4, 22.0, time) * (1.0 - sstep(27.2, 28.4, time));
    if (pfA > 0.01)
    {
        for (int lane2 = 0; lane2 < 8; ++lane2)
        {
            float y = 0.9 - float(lane2) * 0.30;
            line3(Vec3(-8.2, y, 0), Vec3(8.4, y, 0), 0.010, steel(), 0.22 * pfA);
            for (float x = -8.0; x < 8.0; x += 1.0)
            {
                float sp = 0.10 + 0.02 * float(lane2);
                float xx = -8.0 + fmod_p(x + time * 2.2 + float(lane2) * 0.17, 16.0);
                line3(Vec3(xx, y, 0), Vec3(xx + 0.44, y, 0), 0.030, mix3(cyan(), violet(), float(lane2) / 7.0), 0.55 * pfA);
            }
        }
    }

    // bandwidth: everything streaming at once
    float bwA = sstep(28.4, 30.0, time) * (1.0 - sstep(34.6, 35.6, time));
    if (bwA > 0.01)
    {
        for (int lane3 = 0; lane3 < 10; ++lane3)
        {
            float y = 1.4 - float(lane3) * 0.26;
            line3(Vec3(-8.6, y, 0), Vec3(8.8, y, 0), 0.012, steel(), 0.20 * bwA);
            for (float x = -8.4; x < 8.6; x += 1.6)
            {
                float xx = -8.4 + fmod_p(x + time * 4.0 + float(lane3) * 0.31, 17.0);
                line3(Vec3(xx, y, 0), Vec3(xx + 0.7, y, 0), 0.026, mix3(cyan(), white(), 0.25 + 0.05 * float(lane3)), 0.65 * bwA);
            }
        }
        glow(Vec3(0, 0.2, 0), 6.0, cyan(), 0.10 * bwA);
    }

    // playhead
    float playA = sstep(5.6, 6.6, time) * (1.0 - sstep(19.6, 20.6, time));
    if (playA > 0.01)
        line3(Vec3(px, 1.1, 0), Vec3(px, 4.1, 0), 0.014, white(), 0.45 * playA);

    cam_track(time, CK_T, CK_AZ, CK_EL, CK_D, CK_TG, CK_FOV);
    end_frame();

    float a0 = card_alpha(time, 0.9, 5.4, 0.7, 0.5);
    float a1 = card_alpha(time, 6.4, 12.4, 0.5, 0.5);
    float a2 = card_alpha(time, 13.6, 19.6, 0.5, 0.5);
    float a3 = card_alpha(time, 20.6, 27.4, 0.5, 0.5);
    float a4 = card_alpha(time, 28.6, 34.6, 0.5, 0.5);
    float a5 = card_alpha(time, 35.4, 41.6, 0.6, 0.6);

    if (a0 > 0.001) show_card(0, a0, (1.0 - a0) * 0.012);
    else if (a1 > 0.001) show_card(1, a1, (1.0 - a1) * 0.012);
    else if (a2 > 0.001) show_card(2, a2, (1.0 - a2) * 0.012);
    else if (a3 > 0.001) show_card(3, a3, (1.0 - a3) * 0.012);
    else if (a4 > 0.001) show_card(4, a4, (1.0 - a4) * 0.012);
    else show_card(5, a5, (1.0 - a5) * 0.012);

    float exp = sstep(0.0, 0.9, time) * (1.0 - 0.6 * sstep(41.0, 42.0, time));
    exp *= 1.0 - 0.13 * pulse(time, 13.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 20.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 28.0, 0.12);
    exp *= 1.0 - 0.13 * pulse(time, 35.0, 0.12);
    g_final_pass.set_float("u_exposure", exp * 0.95);
}


