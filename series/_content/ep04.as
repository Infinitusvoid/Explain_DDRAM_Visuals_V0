#include "lib/kit.as"
#include "lib/config.as"

// ---------------------------------------------------------------------------
//  Episode 04 -- The Read Transaction
//  ACT -> tRCD -> RD -> CL -> data. A read is a timed sequence of commands.
// ---------------------------------------------------------------------------

float g_len = 44.0;

float[] CK_T   = {  0.0,  6.0, 14.0, 22.0, 30.0, 37.0, 44.0 };
float[] CK_AZ  = { 78.0, 84.0, 82.0, 80.0, 84.0, 84.0, 88.0 };
float[] CK_EL  = { 16.0, 12.0, 10.0, 12.0, 10.0, 14.0, 12.0 };
float[] CK_D   = { 16.0, 14.0, 10.0, 10.0, 10.0, 15.0, 17.0 };
float[] CK_FOV = { 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0 };
Vec3[]  CK_TG  = {
    Vec3(0.0, 1.80, 0.0),
    Vec3(0.0, 1.80, 0.0),
    Vec3(-4.4, 1.90, 0.0),
    Vec3(0.0, 1.50, 0.0),
    Vec3(5.0, 1.60, 0.0),
    Vec3(0.0, 1.70, 0.0),
    Vec3(0.0, 1.60, 0.0)
};

float Y_CLK = 3.15;
float Y_CMD = 1.95;
float Y_DQ = 0.65;
float X0 = -9.0;
float X1 = 9.6;

void build_scene(Scene@ scene)
{
    kit_build(scene, "project/textures/cards.png", 6,
              520, 60, 60,
              90000, 0,
              400, 260,
              CFG_W, CFG_H, CFG_FPS, g_len,
              "renders/ep04_the_read_transaction.mp4");
}

float playX(float t) { return -7.0 + seq(t, 12.0, 34.0) * 11.0; }

void lane(float y, Vec3 col, float a)
{
    line3(Vec3(X0, y, 0), Vec3(X1, y, 0), 0.020, col, a);
    line3(Vec3(X0, y, 0), Vec3(X0, y + 0.28, 0), 0.020, col, a * 0.6);
}

// raised command pulse between x0 and x1
void pulse_rect(float y, float x0, float x1, Vec3 col, float a)
{
    float h = 0.55;
    line3(Vec3(x0, y, 0), Vec3(x0, y + h, 0), 0.030, col, a);
    line3(Vec3(x0, y + h, 0), Vec3(x1, y + h, 0), 0.034, col, a);
    line3(Vec3(x1, y + h, 0), Vec3(x1, y, 0), 0.030, col, a);
}

void bracket(float y, float x0, float x1, Vec3 col, float a)
{
    line3(Vec3(x0, y, 0), Vec3(x1, y, 0), 0.018, col, a * 0.55);
    line3(Vec3(x0, y, 0), Vec3(x0, y - 0.26, 0), 0.020, col, a);
    line3(Vec3(x1, y, 0), Vec3(x1, y - 0.26, 0), 0.020, col, a);
}

void clock_wave(float a, float reach)
{
    float period = 1.0;
    float amp = 0.32;
    float prevX = X0;
    float prevY = Y_CLK - amp;
    for (float x = X0; x < X1; x += period)
    {
        if (x > reach) break;
        float hiY = Y_CLK + amp;
        float loY = Y_CLK - amp;
        bool high = fmod_p((x - X0) / period, 2.0) < 1.0;
        // transition
        line3(Vec3(prevX, prevY, 0), Vec3(x, prevY, 0), 0.020, cyan(), 0.65 * a);
        // vertical edge
        float y2 = high ? hiY : loY;
        line3(Vec3(x, prevY, 0), Vec3(x, y2, 0), 0.020, cyan(), 0.65 * a);
        prevX = x;
        prevY = y2;
        // half period at level
        float xe = x + period * 0.5;
        if (xe > reach) xe = reach;
        line3(Vec3(x, y2, 0), Vec3(xe, y2, 0), 0.020, cyan(), 0.65 * a);

        prevX = xe;
        prevY = y2;
    }
}

void update_scene(Scene@ scene, float time, float dt)
{
    begin_frame();

    float px = playX(time);

    // background grid paper
    for (int i = -9; i <= 9; ++i)
    {
        line3(Vec3(float(i), -0.4, 0), Vec3(float(i), 3.9, 0), 0.005, steel(), 0.045);
    }

    // lanes
    lane(Y_CLK, steel(), 0.30);
    lane(Y_CMD, steel(), 0.30);
    lane(Y_DQ, steel(), 0.30);

    // clock
    clock_wave(1.0, px);

    // ---- ACT -------------------------------------------------------------
    float actX = -4.75;
    float actOn = sstep(15.0, 15.4, time);
    if (actOn > 0.01)
    {
        pulse_rect(Y_CMD, actX, actX + 0.55, amber(), 0.35 + 0.65 * actOn);
    }

    // ---- tRCD bracket ----------------------------------------------------
    float rdX = 2.0;
    float trcdOn = sstep(15.6, 16.4, time);
    if (trcdOn > 0.01)
    {
        bracket(Y_CMD - 0.30, actX + 0.28, rdX + 0.28, white(), trcdOn);
    }

    // ---- RD --------------------------------------------------------------
    float rdOn = sstep(24.0, 24.4, time);
    if (rdOn > 0.01)
    {
        pulse_rect(Y_CMD, rdX, rdX + 0.55, cyan(), 0.35 + 0.65 * rdOn);
    }

    // ---- CL bracket ------------------------------------------------------
    float dataX = 4.35;
    float clOn = sstep(24.6, 25.4, time);
    if (clOn > 0.01)
    {
        bracket(Y_CMD - 0.30, rdX + 0.28, dataX, white(), clOn);
    }

    // ---- data burst ------------------------------------------------------
    float dataOn = sstep(26.6, 27.2, time);
    if (dataOn > 0.01)
    {
        for (int b = 0; b < 4; ++b)
        {
            float bx = dataX + float(b) * 0.62;
            float ba = dataOn * (1.0 - 0.25 * float(b));
            pulse_rect(Y_DQ, bx, bx + 0.45, violet(), 0.25 + 0.7 * ba);
        }
        glow(Vec3(dataX + 0.9, Y_DQ + 0.35, 0), 0.55, violet(), 0.16 * dataOn);
    }

    // ---- PRE + tRP -------------------------------------------------------
    float preX = 7.6;
    float preOn = sstep(31.6, 32.0, time);
    if (preOn > 0.01)
    {
        pulse_rect(Y_CMD, preX, preX + 0.55, rose(), 0.35 + 0.65 * preOn);
        float trpOn = sstep(32.4, 33.0, time);
        bracket(Y_CMD - 0.30, preX + 0.28, X1 - 0.2, white(), trpOn);
    }

    // playhead
    float playA = sstep(11.2, 12.2, time) * (1.0 - sstep(34.0, 35.0, time));
    if (playA > 0.01)
    {
        line3(Vec3(px, -0.35, 0), Vec3(px, 3.85, 0), 0.016, white(), 0.55 * playA);
        glow(Vec3(px, 3.85, 0), 0.18, white(), 0.22 * playA);
    }

    cam_track(time, CK_T, CK_AZ, CK_EL, CK_D, CK_TG, CK_FOV);
    end_frame();

    float a0 = card_alpha(time, 0.9, 5.4, 0.7, 0.5);
    float a1 = card_alpha(time, 6.4, 13.4, 0.5, 0.5);
    float a2 = card_alpha(time, 14.6, 21.4, 0.5, 0.5);
    float a3 = card_alpha(time, 22.6, 29.4, 0.5, 0.5);
    float a4 = card_alpha(time, 30.6, 36.8, 0.5, 0.5);
    float a5 = card_alpha(time, 37.6, 43.6, 0.6, 0.6);

    if (a0 > 0.001) show_card(0, a0, (1.0 - a0) * 0.012);
    else if (a1 > 0.001) show_card(1, a1, (1.0 - a1) * 0.012);
    else if (a2 > 0.001) show_card(2, a2, (1.0 - a2) * 0.012);
    else if (a3 > 0.001) show_card(3, a3, (1.0 - a3) * 0.012);
    else if (a4 > 0.001) show_card(4, a4, (1.0 - a4) * 0.012);
    else show_card(5, a5, (1.0 - a5) * 0.012);

    float exp = sstep(0.0, 0.9, time) * (1.0 - 0.6 * sstep(43.0, 44.0, time));
    exp *= 1.0 - 0.13 * pulse(time, 14.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 22.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 30.0, 0.10);
    exp *= 1.0 - 0.13 * pulse(time, 37.0, 0.12);
    g_final_pass.set_float("u_exposure", exp * 0.95);
}


