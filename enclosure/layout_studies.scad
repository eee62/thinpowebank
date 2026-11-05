// =============================================================================
//  Layout studies 1 and 2: PLACEMENT MODELS, not printable parts.
//  Run with:  openscad -D 'part="none"' -D 'study=1' -o out.png layout_studies.scad
//  Each study places the measured parts (same dummies as powerbank.scad), the walls, the cell,
//  the antenna with its 5 mm keep-out, the mated-plug zones and the finger-access columns,
//  and computes the outer size. The size is a LOWER BOUND: detailing (posts, fences, guides)
//  can only add to it. tools/run_studies.sh runs the collision/rule checks for both.
// =============================================================================
include <powerbank.scad>

study = 1;            // 1 = boards under the cell (two decks), 2 = MAX17048 stacked on the bq25185
study_view = "assembled";   // assembled | debug
study_pair = -1;

// ---------- common front-wall chains (anchored to the front wall, so they move with T) ----------
function cam_z0(zw)   = zw - win_t - win_recess_extra - cam_plate_t - cam_block_h;
function sw_zbot(t)   = t + sw_tip_proud - sw_handle_h - sw_h;
function tact_zb(zw)  = zw - btn_flange_t - btn_free - btn_gap - tact_h;
module cam_env(x, y, zw) {   // camera head + stop plate + window ring envelope
    cbox([x, y, cam_z0(zw)], [cam_w, cam_d, cam_block_h + cam_barrel_h]);
}
module sw_env(x, y, t) {
    cbox([x, y, sw_zbot(t)], [sw_l, sw_w, sw_h]);
    for (dx = [-2.5, 0, 2.5]) cbox([x + dx, y, sw_zbot(t) - sw_pin_l], [0.5, 0.3, sw_pin_l + eps]);
}
module tact_env(x, y, zw) {
    cbox([x, y, tact_zb(zw)], [tact_w, tact_w, tact_h]);
    for (sx = [-1, 1], sy = [-1, 1]) cbox([x + sx*3.25, y + sy*2.25, tact_zb(zw) - 1.8], [0.7, 0.3, 1.8 + eps]);
}
module zone_box(z, acc) {   // plug zone, or its access column (finger_clr across the mating axis, down to the plug face)
    a = z[2];
    if (acc) bx([z[0][0] - (a == 1 ? finger_clr : 0), z[0][1] - (a == 0 ? finger_clr : 0), Zi0 + eps],
                [z[1][0] + (a == 1 ? finger_clr : 0), z[1][1] + (a == 0 ? finger_clr : 0), z[1][2]]);
    else bx(z[0], z[1]);
}
function keepout(xa, ya, zsh) = [[xa - ant_keep, ya - ant_keep, Zi0], [xa + ant_w + ant_keep, ya + ant_l + ant_keep, zsh]];

// =============================================================================
//  STUDY 1: boards in a lower deck under the cell; cell deck against the front wall on a shelf;
//  antenna in an END BAY at X = 0 with switch, button and camera hung from the front wall above it.
//  The charging USB-C exits the far end (bq25185 at the far end of the lower deck).
// =============================================================================
s1_Hd  = max(H_xiao, H_bq, H_mx);                 // lower (board) deck height
s1_Zs  = Zi0 + s1_Hd;                             // shelf underside
s1_sh  = 0.8;                                     // shelf thickness
s1_Zc  = s1_Zs + s1_sh + cell_rail_h;             // cell bottom
s1_T   = s1_Zs + s1_sh + H_cell + wall;
s1_Zw  = s1_T - wall;
s1_bay = ant_clr + ant_w + ant_keep;              // end bay: plastic end wall on the outside
s1_xl  = wall + s1_bay;                           // keep-out ends: lead zone (upper) and board deck (lower) start
s1_xc  = s1_xl + cell_head_zone;
s1_L   = s1_xc + cell_pocket_l + wall;
s1_Wi  = max(cell_pocket_w, 2*clr_board + mx_l + laneB_w + xiao_pcb_w + laneA_w);
s1_W   = s1_Wi + 2*wall;
s1_ya  = wall + (s1_Wi - ant_l)/2;
s1_Zsh = Zi0 + ant_t + ant_keep;
// lower deck: MAX (JST +X) and flipped XIAO side by side next to the bay; bq at the far end (JST -X, USB in the far wall)
s1_xmx = s1_xl + clr_board;
s1_ymx = wall + clr_board;
s1_Yx  = s1_ymx + mx_l + laneB_w;
s1_Xx  = s1_xl + xiao_usb_over + clr_board;
s1_Zxb = s1_Zs - xiao_solder_gap;
s1_xbq = s1_L - usb_boss_t - clr_board - bq_d;   // bq low-X edge (JST side)
s1_ybq = wall + clr_board;
s1_Zbq = Zi0 + bq_gap;
s1_zones = concat(
    [for (j = mx_jst) [[s1_xmx + mx_d + eps, s1_ymx + mx_l - j[1] - 0.5, Zi0 + mx_gap + mx_pcb_t],
                       [s1_xmx + mx_d + jst_plug_zone, s1_ymx + mx_l - j[0] + 0.5, Zi0 + mx_gap + mx_pcb_t + mx_jst_h + 0.3], 0]],
    [[[s1_xmx + mx_qt_y[0] - 0.5, s1_ymx + mx_l + eps, Zi0 + mx_gap + mx_pcb_t],
      [s1_xmx + mx_qt_y[1] + 0.5, s1_ymx + mx_l + qt_plug_zone - 0.2, Zi0 + mx_gap + mx_pcb_t + mx_qt_h + 0.5], 1]],
    [for (j = bq_jst) [[s1_xbq - jst_plug_zone, s1_ybq + bq_l - j[1] - 0.5, s1_Zbq + bq_pcb_t],
                       [s1_xbq - eps, s1_ybq + bq_l - j[0] + 0.5, s1_Zbq + bq_pcb_t + bq_jst_h + 0.3], 0]]);
module s1_obj(n) {
    if (n == "shell") difference() { cube([s1_L, s1_W, s1_T]); translate([wall, wall, Zi0]) cube([s1_L - 2*wall, s1_Wi, s1_Zw - Zi0]); }
    else if (n == "shelf") bx([s1_xl, wall, s1_Zs], [s1_L - wall, wall + s1_Wi, s1_Zs + s1_sh]);
    else if (n == "cell") translate([s1_xc + 0.6, wall + (s1_Wi - cell_w)/2, s1_Zc]) cube([cell_l, cell_w, cell_t + cell_swell]);
    else if (n == "xiao") translate([s1_Xx, s1_Yx + xiao_pcb_w, s1_Zxb]) rotate([180, 0, 0]) xiao_local();
    else if (n == "max") translate([s1_xmx, s1_ymx + mx_l, Zi0 + mx_gap]) rotate(-90) mx_local();
    else if (n == "bq") translate([s1_xbq, s1_ybq + bq_l, s1_Zbq]) rotate(-90) bq_local();
    else if (n == "camera") cam_env(wall + 9.5, s1_Yx + 8.86, s1_Zw);
    else if (n == "switch") sw_env(wall + 9.5, wall + 6, s1_T);
    else if (n == "tact") tact_env(wall + 9.5, wall + 17, s1_Zw);
    else if (n == "antenna") translate([wall + ant_clr, s1_ya, Zi0]) cube([ant_w, ant_l, ant_t]);
    else if (n == "keepout") bx(keepout(wall + ant_clr, s1_ya, s1_Zsh)[0], keepout(wall + ant_clr, s1_ya, s1_Zsh)[1]);
    else if (n == "zones") for (z = s1_zones) zone_box(z, false);
    else if (n == "access") for (z = s1_zones) zone_box(z, true);
}

// =============================================================================
//  STUDY 2: layout 3 rows, but the MAX17048 rides above the bq25185 (above its JST tops),
//  JSTs facing +X over the bq plug zone. Its QT zone must hang beyond the bq's +Y edge so the
//  QT can be reached from the back, so switch/button/camera move to row 2 beside the XIAO.
// =============================================================================
s2_Zmx = Zbq + bq_pcb_t + bq_jst_h + 0.3;
s2_Hi  = max(Hi, s2_Zmx + mx_pcb_t + mx_jst_h + max(clr_z, 0.3) - Zi0);   // 0.3 = plug-zone margin above a JST
s2_T   = plug_t + s2_Hi + wall;
s2_Zw  = s2_T - wall;
s2_xmx = row1_end + jst_plug_zone - mx_d;          // MAX JST mouths at row1_end + jst_plug_zone, facing +X
s2_ymx = y_bq0 + bq_l + clr_board - mx_l;          // MAX +Y edge just past the bq +Y edge (QT reachable)
s2_x2  = row1_end + 2*jst_plug_zone;               // row 2 starts after the MAX plug zone (its access column)
s2_Xx  = s2_x2 + xiao_usb_over + clr_board;
s2_Yx  = y0 + laneA_w;
s2_spx = s2_x2 + clr_board;                        // small parts beside the XIAO
s2_spy = s2_Yx + xiao_pcb_w + laneA_w;
s2_row2_end = max(s2_Xx + xiao_pcb_l + xiao_exp_over, s2_spx + max(sw_cradle[0], tact_cradle) + 0.6 + cam_ring_od);
s2_Wi  = max(cell_pocket_w, bq_l + 0.2 + qt_plug_zone, s2_spy - y0 + max(sw_cradle[1] + 0.6 + tact_cradle, cam_ring_od) + 0.5);
s2_W   = s2_Wi + 2*wall;
s2_xa  = s2_row2_end + ant_keep;
s2_ya  = y0 + (s2_Wi - ant_l)/2;
s2_xh  = s2_xa + ant_w + ant_keep;
s2_xc  = s2_xh + cell_head_zone;
s2_L   = s2_xc + cell_pocket_l + wall;
s2_zones = concat(
    [for (j = bq_jst) [[x_row1 + bq_d + eps, y_bq0 + j[0] - 0.5, Zbq + bq_pcb_t],
                       [x_row1 + bq_d + jst_plug_zone, y_bq0 + j[1] + 0.5, Zbq + bq_pcb_t + bq_jst_h + 0.3], 0]],
    [for (j = mx_jst) [[s2_xmx + mx_d + eps, s2_ymx + mx_l - j[1] - 0.5, s2_Zmx + mx_pcb_t],
                       [s2_xmx + mx_d + jst_plug_zone, s2_ymx + mx_l - j[0] + 0.5, s2_Zmx + mx_pcb_t + mx_jst_h + 0.3], 0]],
    [[[s2_xmx + mx_qt_y[0] - 0.5, s2_ymx + mx_l + eps, s2_Zmx + mx_pcb_t],
      [s2_xmx + mx_qt_y[1] + 0.5, s2_ymx + mx_l + qt_plug_zone - 0.2, s2_Zmx + mx_pcb_t + mx_qt_h + 0.5], 1]]);
module s2_obj(n) {
    if (n == "shell") difference() { cube([s2_L, s2_W, s2_T]); translate([wall, wall, Zi0]) cube([s2_L - 2*wall, s2_Wi, s2_Zw - Zi0]); }
    else if (n == "shelf") { }
    else if (n == "cell") translate([s2_xc + 0.6, y0 + (s2_Wi - cell_w)/2, Zc]) cube([cell_l, cell_w, cell_t + cell_swell]);
    else if (n == "xiao") translate([s2_Xx, s2_Yx + xiao_pcb_w, s2_Zw - xiao_solder_gap]) rotate([180, 0, 0]) xiao_local();
    else if (n == "max") translate([s2_xmx, s2_ymx + mx_l, s2_Zmx]) rotate(-90) mx_local();
    else if (n == "bq") bq_dummy();
    else if (n == "camera") cam_env(s2_spx + max(sw_cradle[0], tact_cradle) + 0.6 + cam_ring_od/2, s2_spy + cam_ring_od/2, s2_Zw);
    else if (n == "switch") sw_env(s2_spx + sw_cradle[0]/2, s2_spy + sw_cradle[1]/2, s2_T);
    else if (n == "tact") tact_env(s2_spx + tact_cradle/2, s2_spy + sw_cradle[1] + 0.6 + tact_cradle/2, s2_Zw);
    else if (n == "antenna") translate([s2_xa, s2_ya, Zi0]) cube([ant_w, ant_l, ant_t]);
    else if (n == "keepout") bx(keepout(s2_xa, s2_ya, Zi0 + ant_t + ant_keep)[0], keepout(s2_xa, s2_ya, Zi0 + ant_t + ant_keep)[1]);
    else if (n == "zones") for (z = s2_zones) zone_box(z, false);
    else if (n == "access") for (z = s2_zones) zone_box(z, true);
}

module so(n) { if (study == 1) s1_obj(n); else s2_obj(n); }
study_pairs = [
    ["shell", "cell"], ["shell", "xiao"], ["shell", "max"], ["shell", "bq"], ["shell", "camera"], ["shell", "switch"], ["shell", "tact"],
    ["shelf", "cell"], ["shelf", "xiao"], ["shelf", "max"], ["shelf", "bq"],
    ["cell", "xiao"], ["cell", "max"], ["cell", "bq"], ["xiao", "max"], ["xiao", "bq"], ["max", "bq"],
    ["camera", "xiao"], ["camera", "max"], ["camera", "bq"], ["switch", "xiao"], ["tact", "xiao"], ["camera", "switch"], ["camera", "tact"], ["switch", "tact"],
    ["keepout", "cell"], ["keepout", "xiao"], ["keepout", "max"], ["keepout", "bq"], ["keepout", "camera"], ["keepout", "switch"], ["keepout", "tact"], ["keepout", "zones"],
    ["access", "shell"], ["access", "shelf"], ["access", "cell"], ["access", "xiao"], ["access", "max"], ["access", "bq"], ["access", "camera"], ["access", "switch"], ["access", "tact"]
];
sL = study == 1 ? s1_L : s2_L;  sW = study == 1 ? s1_W : s2_W;  sT = study == 1 ? s1_T : s2_T;
echo(str("STUDY ", study, " LOWER-BOUND SIZE: L x W x T = ", sL, " x ", sW, " x ", sT, " mm, volume ", sL*sW*sT/1000, " cm3"));

if (study_view == "assembled") {
    color("white", 0.3) so("shell");
    color("ivory") so("shelf");
    color("silver") so("cell");
    color("darkgreen") so("xiao");
    color("purple") so("max");
    color("royalblue") so("bq");
    color("dimgray") so("camera");
    color("black") so("switch");
    color("gray") so("tact");
    color("gold") so("antenna");
    color("cyan", 0.15) so("keepout");
    color("orange", 0.3) so("zones");
}
if (study_view == "debug") {
    if (study_pair >= 0) {
        pr = study_pairs[study_pair];
        echo(str("DEBUG pair ", study_pair, ": ", pr[0], " & ", pr[1]));
        intersection() { so(pr[0]); so(pr[1]); }
    } else for (pr = study_pairs) intersection() { so(pr[0]); so(pr[1]); }
}
