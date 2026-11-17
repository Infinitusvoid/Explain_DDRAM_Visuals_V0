#include "lib/kit.as"
#include "lib/config.as"

// ---------------------------------------------------------------------------
//  Episode 03 -- Rows, Columns, Banks
//  One address selects a row (wordline) and a column, then rows are closed.
// ---------------------------------------------------------------------------

float g_len = 40.0;

float[] CK_T   = {  0.0,  6.0, 13.0, 20.0, 27.0, 34.0, 40.0 };
float[] CK_AZ  = { 90.0, 96.0, 90.0, 82.0, 84.0, 90.0, 86.0 };
float[] CK_EL  = { 30.0, 34.0, 30.0, 24.0, 26.0, 32.0, 28.0 };
float[] CK_D   = { 16.0, 14.0, 15.0, 16.0, 17.0, 17.0, 18.0 };
float[] CK_FOV = { 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0 };
Vec3[]  CK_TG  = {
    Vec3(0.0, -1.20, 0.0),
    Vec3(0.0, -1.20, 0.0),
    Vec3(0.0, -1.20, 0.0),
    Vec3(0.0, -1.40, 0.6),
    Vec3(0.0, -1.45, 1.2),
    Vec3(0.0, -1.20, 0.0),
    Vec3(0.0, -1.10, 0.0)
};

const int ROWS = 8;
const int COLS = 16;
const int ACT_ROW = 3;
const int ACT_COL = 11;

void build_scene(Scene@ scene)
{
    kit_build(scene, "project/textures/cards.png", 6,
              400, 120, 60,
              100000, ROWS * COLS,
              500, 220,
              CFG_W, CFG_H, CFG_FPS, g_len,
              "renders/ep03_rows_columns_banks.mp4");
}

float rowZ(int r) { return (float(r) - 3.5) * 1.0; }
float colX(int c) { return (float(c) - 7.5) * 1.0; }

void draw_array(float t, float alpha)
{
    if (alpha <= 0.003) { g_cell_layer.set_float("u_alpha", 0.0); return; }

    g_cell_layer.set_uint("u_rows", uint(ROWS));
    g_cell_layer.set_uint("u_cols", uint(COLS));
    g_cell_layer.set_vec2("u_spacing", 1.0, 1.0);
    g_cell_layer.set_vec3("u_origin", 0, -1.40, 0);
    g_cell_layer.set_float("u_sweep_period", 5.0);
    g_cell_layer.set_float("u_decay", 0.25);
    g_cell_layer.set_float("u_charge", 1.0);
    g_cell_layer.set_vec3("u_charge_color", 0.22, 0.85, 1.0);
    g_cell_layer.set_vec3("u_empty_color", 0.08, 0.16, 0.26);
    g_cell_layer.set_float("u_point_size", 11.0);
    g_cell_layer.set_float("u_alpha", alpha);
    g_cell_layer.set_float("u_highlight_row", float(ACT_ROW));
    g_cell_layer.set_float("u_highlight_boost", 0.35);
}

void update_scene(Scene@ scene, float time, float dt)
{
    begin_frame();
    g_dust_layer.set_float("u_alpha", 0.0); // dust probe

    float alpha = 1.0;

    // ---- array + outline ------------------------------------------------
    draw_array(time, alpha);
    rect_xz(-1.50, -8.1, -4.1, 8.1, 4.1, 0.012, steel(), 0.28);
    for (int c = 0; c <= COLS; ++c)
    {
        float x = -8.0 + float(c);
        line3(Vec3(x, -1.49, -4.0), Vec3(x, -1.49, 4.0), 0.006, steel(), 0.06);
    }

    // ---- address: row and column index lines ---------------------------
    float addrA = window(time, 5.8, 7.0, 12.4, 13.4);
    float cellX = colX(ACT_COL);
    float cellZ = rowZ(ACT_ROW);
    if (addrA > 0.01)
    {
        line3(Vec3(-8.4, -1.38, cellZ), Vec3(8.4, -1.38, cellZ), 0.030, amber(), 0.45 * addrA);
        line3(Vec3(cellX, -1.38, -4.2), Vec3(cellX, -1.38, 4.2), 0.030, cyan(), 0.45 * addrA);
        glow(Vec3(cellX, -1.30, cellZ), 0.30, white(), 0.7 * addrA);
    }

    // ---- row activation -------------------------------------------------
    float rowA = sstep(13.2, 14.6, time) * (1.0 - sstep(33.0, 34.2, time));
    float rowPulse = pulse(time, 14.2, 0.55);
    if (rowA > 0.01)
    {
        line3(Vec3(-8.4, -1.36, cellZ), Vec3(8.4, -1.36, cellZ), 0.055, amber(), (0.55 + 0.4 * rowPulse) * rowA);
        box(Vec3(-9.0, -1.15, cellZ), 0.28, 0.24, 0.30, amber(), (0.55 + 0.4 * rowPulse) * rowA);
        glow(Vec3(-9.0, -1.15, cellZ), 0.9, amber(), 0.35 * rowA);
    }
    g_cell_layer.set_float("u_highlight_boost", 0.35 + 0.9 * rowA);

    // ---- sense amplifier bank ------------------------------------------
    float ampA = sstep(19.6, 21.0, time) * (1.0 - sstep(33.2, 34.4, time));
    float active = sstep(20.4, 24.5, time);
    if (ampA > 0.01)
    {
        int lit = int(active * float(COLS));
        for (int c = 0; c < COLS; ++c)
        {
            float litA = (c < lit) ? 1.0 : 0.0;
            Vec3 col = mix3(steel(), amber(), litA);
    
            box(Vec3(colX(c), -1.55, 4.40), 0.10, 0.07, 0.12, col, (0.30 + 0.60 * litA) * ampA);
        }
        line3(Vec3(-8.2, -1.55, 4.40), Vec3(8.2, -1.55, 4.40), 0.020, amber(), 0.18 * ampA);
        glow(Vec3(0, -1.50, 4.40), 2.4, amber(), 0.07 * ampA);
    }

    // ---- column select + data burst -------------------------------------
    float colA = sstep(26.6, 28.0, time) * (1.0 - sstep(33.4, 34.6, time));
    if (colA > 0.01)
    {
        line3(Vec3(cellX, -1.36, -4.2), Vec3(cellX, -1.36, 4.2), 0.032, white(), 0.45 * colA);
        glow(Vec3(cellX, -1.32, cellZ), 0.32, white(), 0.5 * colA);
        // bus away from the array
        line3(Vec3(cellX, -1.10, 4.7), Vec3(9.4, -1.10, 4.7), 0.045, cyan(), 0.45 * colA);
        glow(Vec3(9.4, -1.10, 4.7), 0.5, cyan(), 0.5 * colA);
    }

    // data packets: cell -> amplifier bank -> bus
    if (time > 28.2 && time < 32.6)
    {
        float p = sstep(28.2, 30.4, time);
        g_flow_a.set_vec3("u_a", cellX, -1.34, cellZ);
        g_flow_a.set_vec3("u_b", cellX, -1.44, 4.2);
        g_flow_a.set_float("u_progress", p);
        g_flow_a.set_vec3("u_color", 0.55, 0.95, 1.0);
        g_flow_a.set_float("u_alpha", 0.9 * (1.0 - sstep(31.8, 32.6, time)));
        g_flow_a.set_float("u_speed", 0.5);
        g_flow_a.set_float("u_spread", 0.03);

        g_flow_b.set_vec3("u_a", cellX, -1.15, 4.7);
        g_flow_b.set_vec3("u_b", 9.4, -1.15, 4.7);
        g_flow_b.set_float("u_progress", sstep(29.4, 31.6, time));
        g_flow_b.set_vec3("u_color", 1.0, 0.75, 0.35);
        g_flow_b.set_float("u_alpha", 0.8 * (1.0 - sstep(31.8, 32.6, time)));
        g_flow_b.set_float("u_speed", 0.7);
        g_flow_b.set_float("u_spread", 0.03);
    }
    else { g_flow_a.set_float("u_alpha", 0.0); g_flow_b.set_float("u_alpha", 0.0); }

    cam_track(time, CK_T, CK_AZ, CK_EL, CK_D, CK_TG, CK_FOV);
    end_frame();

    float a0 = card_alpha(time, 0.9, 5.4, 0.7, 0.5);
    float a1 = card_alpha(time, 6.4, 12.6, 0.5, 0.5);
    float a2 = card_alpha(time, 13.6, 19.6, 0.5, 0.5);
    float a3 = card_alpha(time, 20.6, 26.6, 0.5, 0.5);
    float a4 = card_alpha(time, 27.6, 33.4, 0.5, 0.5);
    float a5 = card_alpha(time, 34.4, 39.6, 0.6, 0.6);

    if (a0 > 0.001) show_card(0, a0, (1.0 - a0) * 0.012);
    else if (a1 > 0.001) show_card(1, a1, (1.0 - a1) * 0.012);
    else if (a2 > 0.001) show_card(2, a2, (1.0 - a2) * 0.012);
    else if (a3 > 0.001) show_card(3, a3, (1.0 - a3) * 0.012);
    else if (a4 > 0.001) show_card(4, a4, (1.0 - a4) * 0.012);
    else show_card(5, a5, (1.0 - a5) * 0.012);

    float exp = sstep(0.0, 0.9, time) * (1.0 - 0.6 * sstep(39.0, 40.0, time));
    exp *= 1.0 - 0.14 * pulse(time, 13.0, 0.10);
    exp *= 1.0 - 0.14 * pulse(time, 20.0, 0.10);
    exp *= 1.0 - 0.14 * pulse(time, 27.0, 0.10);
    exp *= 1.0 - 0.14 * pulse(time, 34.0, 0.12);
    g_final_pass.set_float("u_exposure", exp * 0.95);
}




