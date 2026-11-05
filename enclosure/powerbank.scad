// =============================================================================
//  Thin desk power bank: printable enclosure
//  Cell 635085 LiPo, Seeed XIAO ESP32-S3 Sense, Adafruit bq25185 (#6091),
//  Adafruit MAX17048 (#5580), OV5640 AF camera head, SS-12D00-G3, 6x6 tact switch
//  Printed by JLC3DP in 9000HE SLA resin.
// -----------------------------------------------------------------------------
//  Plain OpenSCAD, no libraries. Tested with OpenSCAD 2021.01 (Ubuntu 24.04 package).
//  Every dimension is a named parameter below. Its source is in the comment and in
//  enclosure/README.md (checked-dimension table).
//
//  ENCLOSURE FRAME (mm)
//    X = length.    X = 0 is the outer face of the ELECTRONICS END. In edge mode the
//                   charging USB-C exits through this face.
//    Y = width.     Y = 0 is the outer face of the long side next to the bq25185/MAX17048.
//    Z = thickness. Z = 0 is the BACK face (flush bottom plug, the face on the desk).
//                   Z = T is the FRONT face (lens, power switch, button).
//
//  PARTS (one module each):  body()  plug()  usb_cover(fit)  button_cap()  fit_coupon()
//  VIEWS:  assembled, exploded, section, layout (zones + keep-out), debug (pairwise intersections; each must be empty)
//  SWITCHES worth knowing: cell_connector ("PH" | "RCY" splice), antenna_place, plug_mode, board_connectors, cell_vents
// =============================================================================

/* [What to render] */
// assembled | exploded | section | layout | body | plug | usb_cover_A | usb_cover_B | usb_cover_C | button_cap | coupon | debug
part = "assembled";
// "sharp" = version 1 (square edges), "rounded" = version 2
style = "rounded";
// "edge" = charging USB-C on the short end face (default), "front" = on the front face (board stands on edge)
charge_port = "edge";
// "permanent" = epoxy-bonded flush plug (default), "removable" = crush-rib friction plug for development
plug_mode = "permanent";
// tactile button on the front face
has_button = true;
// "bay" = antenna in its own bay between electronics and cell, >= ant_keep from all metal (default)
// "none" = no antenna (3 mm air gap only)
antenna_place = "bay";
// "kept" = Adafruit JST-PH / STEMMA QT connectors stay on the boards (default)
// "removed" = connectors desoldered, wires soldered to the pads (smaller)
board_connectors = "kept";
// convection slots in the long side walls next to the charger and the XIAO
vents = true;
// pressure-relief slots in both long walls beside the cell: a sealed rigid case has no relief for a swelling pouch
cell_vents = true;
// draw the reserved wire lanes in assembled/section views
show_lanes = false;
// cell connector: "PH" = JST-PH plug on the cell (mates the MAX17048 JST-PH header directly)
//                 "RCY" = red JST-RCY plug on the cell: a mated RCY pair (splice) is reserved in the lead zone
cell_connector = "PH";
// RCY splice orientation: "edge" = stands on edge (6.7 tall x 4.0 thick), "flat" = lies flat (4.0 tall x 6.7)
rcy_orient = "edge";
// debug: -1 = union of all pair intersections; n = only pair n (see debug_pairs)
debug_pair = -1;
// exploded-view spacing
explode = 16;
$fn = 40;
eps = 0.01;

// =============================================================================
//  PRINTER (JLC3DP 9000HE: https://jlc3dp.com/help/article/9000he-resin)
// =============================================================================
tol_small = 0.20;   // ± on any dimension < 100 mm
tol_pct   = 0.003;  // ± 0.3 % on dimensions > 100 mm
tol_hole  = 0.30;   // ± on holes
drift     = 0.20;   // drift over 3-7 days after printing (reported in worst cases, not added to fits)
min_wall  = 0.80;   // JLC recommended minimum wall
function tol(L) = L < 100 ? tol_small : tol_pct * L;

wall   = 1.00;      // every outer wall. Worst case 1.00 - 0.20 = 0.80 = min_wall
plug_t = 1.00;      // bottom plug thickness, same reasoning

// =============================================================================
//  FITS (per side). Derived from the ±0.2 / ±0.3 tolerances, see README "Fits"
// =============================================================================
fit_slide_bought = 0.10; // printed pocket around a bought part. Pocket can print 0.2 small -> line contact at worst
fit_glue_bought  = 0.15; // same + 0.05 mm epoxy film
fit_pp_slide     = 0.20; // printed part in printed recess: (0.2 + 0.2) / 2
fit_pp_glue      = 0.25; // same + 0.05 mm epoxy film
fit_pp_hole      = 0.25; // printed pin in printed round hole: (0.3 + 0.2) / 2
fit_pin_pcb      = 0.15; // printed pin (±0.2 on Ø) in a drilled PCB hole (±0.08)
clr_z            = 0.20; // free space above the tallest part of a stack (worst case: just touching)
pad_float        = 0.20; // hold-down pads on the plug stop this far short of the part (worst case: touching)
glue_film        = 0.05;

// =============================================================================
//  CELL  635085 LiPo (single source: temperosystems.com.au/?p=35057, 6.3 x 50 x 85, ±5 %)
// =============================================================================
cell_t = 6.3;
cell_w = 50.0;
cell_l = 85.0;
cell_margin_l = 1.0;     // >= 1.0 extra on length (requested), worst case held after print tolerance
cell_margin_w = 1.0;     // >= 1.0 extra on width
cell_swell    = 0.8;     // >= 0.8 free above the cell for swelling
cell_corner_r = 0.5;     // pouch corner radius, ASSUMED (measure)
cell_head_zone = 5.0;    // lead end: protection board, lead bends, plug. ASSUMED (measure your cell)
cell_rail_h   = 1.5;     // rails under the cell: air gap + NTC-wire channel (0.5 wire + 1.0 spare)
cell_rail_w   = 3.0;
cell_rail_dy  = 30.0;    // spacing between the two rails

// 10 k NTC, flat/film type ASSUMED. Held flat against the cell between the rails.
ntc_l = 4.0;  ntc_w = 2.5;  ntc_t = 1.0;
ntc_from_lead_end = 20;  // distance from the cell's lead end
ntc_wire_d = 0.5;

// =============================================================================
//  XIAO ESP32-S3 Sense + expansion board. Measured from the Seeed STEP file
//  (reference/XIAO_ESP32S3_Sense.step, see tools/ and README).
//  Local frame (u,v,w): u along the board from the USB-C end edge of the XIAO PCB,
//  v across, w up from the BACK of the XIAO PCB. Mapping from STEP coordinates:
//      u = 12.282 - x_step ,  v = z_step + 15.001 ,  w = y_step + 0.250
//  The enclosure FLIPS the stack (rotate 180 about X) so the camera-FPC latch faces the back opening:
//      X = Xx0 + u ,  Y = Yx0 + xiao_pcb_w - v ,  Z = Zxb - w   (proper rotation, det +1)
// =============================================================================
xiao_pcb_l    = 21.14;   // Seeed dimension DXF 21.135 (STEP 20.955, wiki 21). Larger value used
xiao_pcb_w    = 17.78;   // STEP 17.780, DXF 17.780, wiki 17.8
xiao_pcb_t    = 1.25;    // STEP
xiao_usb_over = 1.527;   // USB-C shell sticks out past the PCB end (STEP 13.809 - 12.282)
xiao_exp_over = 0.60;    // expansion board past the far PCB end (STEP 0.30, DXFs 0.58). Larger used
xiao_stack_h  = 8.03;    // back of XIAO PCB -> top of microSD socket (STEP 7.780 + 0.250)
sd_card_fitted = false;  // you answered: no card. With card the STEP stack is 8.50
xiao_solder_gap = 0.6;   // under the XIAO: flat solder joints on the BAT pads. ASSUMED, keep joints flat
ribbon_t = 0.15;         // camera FPC crossing over the socket (Seeed spec 0.12 ± 0.03)
xiao_ribbon_v = 8.92;    // centre of the camera FPC connector across the board (STEP)

// =============================================================================
//  Adafruit bq25185 (#6091). Eagle board "rev B1" + Adafruit STEP (Adafruit_CAD_Parts)
//  Board frame (bx, by, bz): bx along the 31.75 edge, USB-C on the by = 25.4 edge.
// =============================================================================
bq_l = 31.75;  bq_d = 25.40;  bq_pcb_t = 1.57;  bq_corner_r = 2.54;
bq_usb   = [11.405, 20.345, 18.486, 26.386, 1.56, 4.77]; // x0,x1,y0,y1,z0,z1 (shell 8.94 x 3.21)
bq_jst   = [[7.48, 15.38], [16.37, 24.27]];               // the two JST-PH (BATT, LOAD) in bx
bq_jst_y = [0.48, 9.08];                                    // in by, mouths face by = 0
bq_jst_h = 5.6;          // above PCB top: product page 7.2 total - 1.57 (distributor S2B-PH-SM4-TB 5.5; Adafruit model 4.8)
bq_low   = [4.6, 25.2, 6.8, 23.5, 1.35];                  // envelope of the small parts (STEP: parts from bx 5.28; diodes 1.35 tallest)
bq_holes = [[2.54, 2.54], [29.21, 2.54], [2.54, 22.86], [29.21, 22.86]];
bq_hole_d = 2.5;
bq_gap   = 1.0;          // plug -> PCB bottom (centres the USB-C in the end face, keeps 0.8 web under the well)

// =============================================================================
//  Adafruit MAX17048 (#5580). Eagle board + Adafruit STEP. Board frame (bx, by)
// =============================================================================
mx_l = 25.40;  mx_d = 20.32;  mx_pcb_t = 1.57;  mx_corner_r = 2.54;
mx_jst   = [[4.43, 12.33], [13.07, 20.97]];   // JST-PH in bx
mx_jst_y = [11.46, 20.06];                    // in by, mouths face by = 20.32
mx_jst_h = 5.6;
mx_qt    = [[0.13, 5.08], [20.32, 25.27]];    // STEMMA QT (JST-SH 4) in bx, mouths face outward
mx_qt_y  = [5.89, 11.89];
mx_qt_h  = 2.96;         // Adafruit STEP
mx_low   = [6.9, 19.2, 5.2, 10.7, 0.8];
mx_holes = [[2.54, 2.54], [22.86, 2.54], [2.54, 17.78], [22.86, 17.78]]; // 4 holes (product page lists none)
mx_hole_d = 2.5;
mx_gap   = 1.0;

// --- REAL JST-PH sizes (JST PH catalogue, ePH.pdf; see README section 2) ---
ph_hsg_w   = 5.8;   // PHR-2 housing width across the contacts (B = 5.8)
ph_hsg_t   = 4.5;   // PHR-2 housing thickness
ph_hsg_len = 6.35;  // PHR-2 housing length along the mating axis
ph_hdr_len = 6.0;   // S2B-PH-SM4-TB side-entry header body depth (+2.6 solder tab behind it)
ph_hdr_w   = 7.9;   // header width, 2 circuits
ph_hdr_h   = 5.5;   // header height above the PCB
ph_out     = 2.0;   // housing protrusion when mated: JST gives 8.0 mm mated height on a 6.0 mm header
ph_wire_od = 1.2;   // SPH-002T-P0.5S takes AWG 24-30, O.D. 0.8-1.5 mm: 1.2 assumed (26 AWG)
ph_bend_r  = 4 * ph_wire_od;   // minimum wire bend radius, ASSUMED 4 x O.D.
ph_straight = 2.0;  // straight wire run out of the housing before any bend (strain relief)
ph_mouth_bq = 0.48; // header mouth inset from the board edge on the bq25185 (Adafruit STEP)
ph_mouth_mx = 0.26; // same on the MAX17048
jst_plug_zone = ph_hsg_len + ph_straight;   // legacy name: used by front-port mode and layout_studies.scad
qt_plug_zone  = 6.0;     // STEMMA QT (JST-SH) plug + cable, unchanged, ASSUMED

// --- JST-RCY splice (only when cell_connector = "RCY"): JST RCY sheet: mated 23.3 long x 4.0 thick, housing 6.7 wide
rcy_l = 23.3;  rcy_w = 6.7;  rcy_t = 4.0;

// =============================================================================
//  CAMERA HEAD. Defaults = Seeed OV5640 AF spec (MJY5OAF-F3M-V1):
//  8.5 x 8.5 ±0.2, total height 5.5 ±0.2, FPC 6 wide, 70.5 long.
//  YOUR AFTERMARKET WIDE-ANGLE AF MODULE IS UNMEASURED. MEASURE AND SET THESE.
// =============================================================================
cam_w = 8.5;  cam_d = 8.5;  cam_tol = 0.2;
cam_block_h  = 5.0;      // back of head (incl. foam/stiffener) -> flat top of the VCM block
cam_barrel_d = 6.7;      // lens barrel Ø above the block (Seeed: Ø6.7 opening in top foam)
cam_barrel_h = 0.5;      // barrel height above the block (5.5 total - 5.0)
cam_aperture_d = 3.0;    // clear front glass of the lens, ASSUMED
cam_fov = 120;           // diagonal FOV of your wide-angle lens, ASSUMED (Seeed standard is 69)
cam_ribbon_w = 6.0;
cam_plate_t  = 0.8;      // printed stop plate between the VCM top and the window disc
cam_cradle_depth = 3.0;  // side walls that locate the head
cam_cradle_wall  = 0.8;

// Clear window disc (buy: acrylic or glass, Ø12 x 1.0)
win_d = 12.0;  win_t = 1.0;  win_tol = 0.1;
win_lip = 0.8;           // front-wall rim the disc is glued against (retaining lip)
win_recess_extra = 0.3;  // recess depth = disc + this (absorbs ±0.2 print and ±0.1 disc)
win_ring_wall = 0.8;

// =============================================================================
//  SLIDE SWITCH  SS-12D00-G3. Sofng SS-12D00 drawing (LCSC PDF): body 8.8 x 3.9 x 3.5,
//  handle 1.5 x 1.5, travel 2, pitch 2.5. G3 = 3.0 handle above the body (retailer listing).
// =============================================================================
sw_l = 8.8;  sw_w = 3.9;  sw_h = 3.5;  sw_tol = 0.2;   // tolerance ASSUMED
sw_handle = 1.5;  sw_handle_h = 3.0;  sw_travel = 2.0;
sw_pin_l  = 3.5;        // pin length below the body, ASSUMED (not dimensioned). Trim if needed
sw_tip_proud = 0.5;     // handle tip above the front surface
sw_scoop_d   = 0.8;     // fingernail scoop around the slot
sw_cradle_wall = 0.8;

// =============================================================================
//  TACTILE SWITCH 6 x 6, 4 pin (Omron B3F-style). Height = base to plunger top.
// =============================================================================
tact_w = 6.0;  tact_tol = 0.2;  tact_body_h = 3.5;
tact_h = 5.0;            // 4.3 | 5 | 6 | 7 | 8. Body grows with it if needed
tact_act_d = 3.5;  tact_travel = 0.25;
tact_leg_clear = 2.0;    // room for the legs below the body. TRIM the legs to <= 1.8 mm
btn_d = 5.0;  btn_flange_d = 7.0;  btn_flange_t = 0.8;  btn_stem_d = 3.0;
btn_gap   = 0.20;        // cap never touches the plunger by itself
btn_proud = 0.40;        // cap above the front face
btn_free  = 0.45;        // extra counterbore depth: btn_gap + tact_travel
tact_cradle_wall = 0.8;

// =============================================================================
//  ANTENNA  Seeed 2.4 GHz FPC for XIAO ESP32-S3. 39 x 19 from ONE forum report. MEASURE
// =============================================================================
ant_l = 39;  ant_w = 19;  ant_t = 0.2;  ant_clr = 0.5;  ant_frame_h = 0.4;  ant_frame_w = 0.6;
ant_keep = 5.0;      // RULE: antenna >= 5 mm from cell foil and any other metal (plastic is allowed inside)
fence_t  = 0.8;      // plastic fences at both ends of the antenna bay; they carry the antenna frame
ant_wall_gap = 3.0;  // Seeed staff: do not stick the FPC antenna flat on the case, leave 3-5 mm to the plastic
ant_rim  = 1.5;      // adhesive rim of the carrier frame (the radiating area is over an open window)
carrier_t = 0.8;     // carrier frame thickness
finger_clr = 3.0;    // RULE: finger/tweezer room each side of every mated plug, open to the back

// =============================================================================
//  WIRES AND LANES (wire sizes ASSUMED, see README)
// =============================================================================
wire_pwr_d = 1.2;   // cell leads, LOAD, switch: 24-26 AWG silicone
wire_sig_d = 0.8;   // button, I2C, NTC extension: 28-30 AWG
lane_spare = 1.0;   // >= 1 mm spare clearance on every bundle
laneA_w = 0.5 + wire_sig_d + lane_spare + 0.4;   // XIAO castellation side: joint 0.5 + wire + spare (+0.4 bend) = 2.7
laneB_w = qt_plug_zone;                          // between MAX and XIAO: QT plug + battery jumper + NTC
laneC_w = wire_sig_d + lane_spare + 0.2;         // button wires along the +Y wall = 2.0
ribbon_bay = 6.0;   // minimum X gap row1/row2, S-folds the spare ribbon
heat_gap   = 3.0;   // air gap between electronics and the cell lead zone when there is no antenna bay
lead_lane_w = wire_pwr_d + 2*ntc_wire_d + lane_spare;  // cell-lead + NTC bundle, leads stacked vertically: 1.2 + 2 x 0.5 (side by side) + 1 spare

// =============================================================================
//  USB-C PORT WELL AND COVER
// =============================================================================
usbc_shell_w = bq_usb[1] - bq_usb[0];   // 8.94
usbc_shell_h = bq_usb[5] - bq_usb[4];   // 3.21
usb_well_w = 12.4;   // USB-C plug overmold envelope. ASSUMED 12.35 x 6.5 (not confirmed): MEASURE YOUR CABLE
usb_well_h = 6.6;
usb_well_d = 1.5;    // depth of the flush-cover well
usb_inner_wall = 1.0;
usb_open_w = usbc_shell_w + 2*tol_hole;   // opening around the receptacle shell
usb_open_h = usbc_shell_h + 2*tol_hole;
usbc_shell_r = 1.25;                      // shell corner radius (Adafruit STEP)
usb_open_r = usbc_shell_r + tol_hole;
clr_board = 0.20;    // board edge to wall / post
cover_core_fit = fit_pp_slide;            // cover body clearance per side
cover_rib_interf = [0.05, 0.10, 0.15];    // A, B, C: nominal crush-rib interference per side
cover_rib_r = 0.30;
pry_w = 2.0;         // fingernail scoop next to the well

// =============================================================================
//  STYLE
// =============================================================================
corner_r = 4.0;      // version 2 plan-corner radius (outer)
edge_r_front = 1.0;  // version 2 front-face edge radius
edge_r_back  = 0.5;  // version 2 back-face edge radius (keeps a 0.5 rim around the plug)
ledge_h = 0.6;  ledge_d = 1.0;  ledge_len = 4.0;
vent_w = 1.2;  vent_h = 5.0;  vent_pitch = 3.0;
plug_rib_interf = 0.08;  plug_rib_r = 0.35;  plug_rib_pitch = 25;

coupon_fits = [0.10, 0.15, 0.20, 0.25];

// =============================================================================
//  DERIVED: Z (thickness) budget
// =============================================================================
xiao_h = sd_card_fitted ? 8.50 : xiao_stack_h;
kept = board_connectors == "kept";
bq_top_h = kept ? bq_jst_h : (bq_usb[5] - bq_pcb_t);     // tallest part above the bq PCB
mx_top_h = kept ? mx_jst_h : bq_low[4];
Ri   = style == "rounded" ? max(0, corner_r - wall) : 0;  // inner plan-corner radius
corner_keep = Ri * (1 - 1/sqrt(2));                     // keep square items this far from both walls at a corner

H_xiao = xiao_solder_gap + xiao_h + ribbon_t + clr_z;
H_cell = cell_rail_h + cell_t + cell_swell + tol_small;
H_bq   = bq_gap + bq_pcb_t + bq_top_h + clr_z;
H_mx   = mx_gap + mx_pcb_t + mx_top_h + clr_z;
H_cam  = (0.8 + pad_float) + cam_block_h + cam_plate_t + win_recess_extra + win_t;
H_tact = has_button ? tact_leg_clear + tact_h + btn_gap + btn_flange_t + btn_free : 0;
H_sw   = 0.3 + sw_pin_l + sw_h + sw_handle_h - sw_tip_proud - wall;
usb_boss_t = usb_well_d + usb_inner_wall;               // wall thickness at the port
H_front = (kept ? jst_plug_zone : clr_board) + bq_d + clr_board + (usb_boss_t - wall);
Hi = max(H_xiao, H_cell, H_mx, H_cam, H_tact, H_sw,
         charge_port == "front" ? H_front : H_bq);
T  = plug_t + Hi + wall;
Zi0 = plug_t;          // interior floor = inner face of the plug
Zw  = T - wall;        // inner face of the front wall
Zxb = Zw - xiao_solder_gap;     // XIAO flipped: back of the XIAO PCB faces the front wall (FPC latch faces the back)
Zxs = Zxb - xiao_h;               // stack bottom (microSD socket face), ribbon + clr_z below it
Zbq = Zi0 + bq_gap;
Zmx = Zi0 + mx_gap;
Zc  = Zi0 + cell_rail_h;

// camera chain (front wall -> disc -> stop plate -> head)
Zplate_top = Zw - win_t - win_recess_extra;
Zplate_bot = Zplate_top - cam_plate_t;
Zlens      = Zplate_bot + cam_barrel_h;                 // top of lens barrel
Zcam0      = Zplate_bot - cam_block_h;                  // back of camera head
cam_gap_disc = (Zw - win_t) - Zlens;                    // lens -> disc air gap (nominal)
// switch chain
Zsw_top = T + sw_tip_proud - sw_handle_h;
Zsw_bot = Zsw_top - sw_h;
sw_boss_t = T - Zsw_top;
// tact chain
Ztb = Zi0 + tact_leg_clear;
Ztt = Ztb + tact_h;

// =============================================================================
//  DERIVED: Y (width)
// =============================================================================
y0 = wall;
sw_cradle  = [sw_l + sw_tol + 2*fit_slide_bought + 2*sw_cradle_wall,      // along X
              sw_w + sw_tol + 2*fit_slide_bought + 2*sw_cradle_wall];     // along Y
tact_pocket = tact_w + tact_tol + 2*fit_glue_bought;
btn_cbore_d = btn_flange_d + 2*fit_pp_slide;
tact_cradle = max(tact_pocket, btn_cbore_d) + 2*tact_cradle_wall;
win_pocket_d = win_d + win_tol + 2*fit_glue_bought;
cam_ring_od  = win_pocket_d + 2*win_ring_wall;
cam_pocket   = cam_w + cam_tol + 2*fit_slide_bought;
cam_cradle_o = cam_pocket + 2*cam_cradle_wall;

cell_m0 = (cell_margin_w + tol_small) / 2;
function corner_need(ri, m, rc) = max(0, (ri - rc) * (1 - 1/sqrt(2)) - m);
cell_g  = corner_need(Ri, cell_m0, cell_corner_r);      // growth so the cell clears a rounded corner
cell_pocket_w = cell_w + cell_margin_w + tol_small + 2*cell_g;
cell_pocket_l = cell_l + cell_margin_l + tol_small + cell_g;

y_bq0 = y0 + clr_board + (charge_port == "front" ? corner_keep : 0);   // standing board has a square corner in plan
y_mx0 = y0 + clr_board;
Yx0   = y_mx0 + mx_l + laneB_w;
y_sp0 = y_bq0 + bq_l + 0.6;                             // small-parts column (switch, button, camera)
sp_w_need = sw_cradle[1] + 0.6 + (has_button ? tact_cradle : 0) + laneC_w;
Wi = max(cell_pocket_w,
         Yx0 + xiao_pcb_w + laneA_w - y0,
         y_sp0 + max(sp_w_need, cam_ring_od + laneC_w + 0.3) - y0);
W  = Wi + 2*wall;
y_hi = y0 + Wi;        // inner face of the +Y wall
// antenna: pushed to the -Y wall so the +Y side stays free for the cell-lead lane
y_ant0  = y0 + ant_wall_gap;
y_lane0 = y_ant0 + ant_l + ant_keep;      // start of the +Y wire lane (outside the 5 mm keep-out)

// =============================================================================
//  DERIVED: X (length)
// =============================================================================
x_row1 = charge_port == "edge" ? usb_boss_t + clr_board : wall + 1.0 + clr_board;   // front: outer guide plate between wall and board
bq_edge_th = bq_pcb_t + bq_top_h + clr_board;           // bq standing on edge (front mode)
sp_margin = max(0.5, corner_keep);
sp_x0 = wall + sp_margin;
sp_len = max(sw_cradle[0], has_button ? tact_cradle : 0) + 0.6 + cam_ring_od + 0.3;
row1_end = max(charge_port == "edge" ? x_row1 + bq_d : x_row1 + bq_edge_th, sp_x0 + sp_len);
// row gap: set by the real JST-PH housings of the bq25185 and MAX17048, which face each other
function s_bend(d, r) = d >= 2*r ? 2*r : 2*sqrt(r*d - d*d/4);   // axial length of an S-bend of radius r that shifts a wire sideways by d
bq_jst_c = [for (j = bq_jst) (j[0] + j[1])/2];
mx_jst_c = [for (j = mx_jst) (j[0] + j[1])/2];
jump_d = abs(bq_jst_c[0] - mx_jst_c[0]);                          // BATT <-> MAX JST #1 are this far out of line across Y
ph_gap_mouth = max(2*ph_hsg_len,                                  // both housings fully withdrawn, no overlap
                   2*ph_out + 2*ph_straight + s_bend(jump_d, ph_bend_r),   // jumper S-bend with both mated
                   ph_hsg_len + ph_straight + ph_bend_r + ph_out);         // cell lead leaves its withdrawn housing and bends 90 deg
x_bq_mouth = x_row1 + bq_d - ph_mouth_bq;                         // bq JST mouth plane (edge mode)
gap12 = kept ? (charge_port == "edge" ? max(ph_gap_mouth + (x_bq_mouth - row1_end) - clr_board - ph_mouth_mx, ribbon_bay)
                                       : jst_plug_zone)
             : max(ribbon_bay, 3.0);
x_row2 = row1_end + gap12;
x_mx0 = x_row2 + clr_board;                             // MAX JST edge, mouths face -X into the gap
Xx0 = x_row2 + xiao_usb_over + clr_board;               // XIAO PCB USB-end edge
xiao_far = Xx0 + xiao_pcb_l + xiao_exp_over;            // far end of the stack envelope
xpost = 1.3;                                            // XIAO end-post thickness
row2_metal = max(xiao_far, x_mx0 + mx_d);               // last metal of row 2
row2_end = row2_metal;
x_bay = row2_metal;                                     // antenna keep-out starts here
bay_len = antenna_place == "bay" ? 2*ant_keep + ant_w : heat_gap;
x_ant0 = x_bay + ant_keep;                              // antenna sticker edge
x_head = x_bay + bay_len;                               // lead zone: metal allowed again from here
rcy_foot_x = rcy_orient == "edge" ? rcy_t : rcy_w;       // splice footprint across the lead zone (X)
rcy_h      = rcy_orient == "edge" ? rcy_w : rcy_t;       // splice height (Z)
lead_zone  = cell_connector == "RCY" ? max(cell_head_zone, rcy_foot_x + 2*finger_clr) : cell_head_zone;
x_cell = x_head + lead_zone;
L  = x_cell + cell_pocket_l + wall;
Li = L - 2*wall;

// positions of the small parts
sw_x = sp_x0 + sw_cradle[0]/2;
sw_y = y_sp0 + sw_cradle[1]/2;
tact_x = sp_x0 + tact_cradle/2;
tact_y = y_hi - laneC_w - tact_cradle/2;
cam_x = row1_end - 0.3 - cam_ring_od/2;
cam_y = min(max(Yx0 + xiao_pcb_w - xiao_ribbon_v, y_sp0 + cam_ring_od/2 + 0.2), y_hi - laneC_w - cam_ring_od/2);
// cell
x_cellb = x_cell + cell_margin_l/2 + tol_small/2;      // cell lead-end face
y_cellb = y0 + (Wi - cell_w)/2;
cell_cy = y_cellb + cell_w/2;
// USB-C centre
usb_y = y_bq0 + (bq_usb[0] + bq_usb[1])/2;
usb_z = Zbq + (bq_usb[4] + bq_usb[5])/2;
usb_x_front = x_row1 + (bq_usb[4] + bq_usb[5])/2;      // front mode: centre in X
Zab = (Zi0 + Zw)/2 - ant_t/2;                           // antenna bottom: centred between the plug and the front wall
// cell-lead route: lead zone -> +Y lane across the bay -> lane A beside the XIAO -> row gap -> MAX JST #2 (Y = y_mx0 + mx_jst_c[1])
lane_y = y_hi - 1.5;
cell_lead_need = abs(x_cellb - (x_row2 + ph_mouth_mx)) + abs(lane_y - cell_cy) + abs(lane_y - (y_mx0 + mx_jst_c[1]))
                 + 2*(ph_out + ph_straight) + 10;
// RCY splice position (lead zone, along Y, starting just beside the cell's lead exit)
y_s0 = cell_cy - 3.7;
x_s  = x_head + lead_zone/2;
// bq standing on edge (front mode): bottom edge height
Zbq_edge0 = Zi0 + (kept ? jst_plug_zone : clr_board);

// lens opening (front wall), cone sized from the FOV
fov_t = tan(cam_fov/2);
lens_r_in  = win_pocket_d/2 - fit_glue_bought - win_tol/2 - win_lip;   // = disc radius - lip
lens_r_req_in  = cam_aperture_d/2 + (cam_gap_disc + win_t) * fov_t;
lens_r_out = lens_r_in + wall * fov_t;
lens_r_req_out = cam_aperture_d/2 + (cam_gap_disc + win_t + wall) * fov_t;
fov_max = 2 * atan((lens_r_in - cam_aperture_d/2) / (cam_gap_disc + win_t));

// plug fit (per side). Long dimension > 100 mm uses ±0.3 %
plug_fx = tol(Li) + (plug_mode == "permanent" ? glue_film : 0);
plug_fy = tol(Wi) + (plug_mode == "permanent" ? glue_film : 0);

// =============================================================================
//  ASSERTS (clearances computed from the parameters)
// =============================================================================
assert(wall - tol_small >= min_wall, "outer wall below the 0.8 mm minimum after tolerance");
assert(plug_t - tol_small >= min_wall, "plug below the 0.8 mm minimum after tolerance");
assert(Zxs - ribbon_t - Zi0 - tol_small >= -eps, "XIAO stack + ribbon do not fit in the worst case");
assert(Zw - (Zc + cell_t) - tol_small >= cell_swell - eps, "less than the swell margin above the cell in the worst case");
assert(cell_pocket_w - tol_small - cell_w >= cell_margin_w - eps, "cell width margin below spec in the worst case");
assert(cell_pocket_l - tol(cell_pocket_l) - cell_l >= cell_margin_l - eps, "cell length margin below spec in the worst case");
assert(cell_rail_h - ntc_wire_d >= lane_spare, "NTC wire channel under the cell has < 1 mm spare");
assert(Zw - (Zbq + bq_pcb_t + bq_top_h) - tol_small >= -eps || charge_port == "front", "bq25185 does not fit in the worst case");
assert(Zw - (Zmx + mx_pcb_t + mx_top_h) - tol_small >= -eps, "MAX17048 does not fit in the worst case");
assert(cam_gap_disc - tol_small >= 0.2, "camera barrel can come within 0.2 mm of the window");
assert(Zcam0 - Zi0 >= 0.8 + pad_float, "no room for the camera backstop");
assert(lens_r_in >= lens_r_req_in, str("lens opening clips the FOV: need r ", lens_r_req_in, " have ", lens_r_in, ". Max FOV here = ", fov_max));
assert(cam_plate_t - tol_small >= 0.6, "camera stop plate too thin");
assert(cam_plate_t >= cam_barrel_h + 0.3 - eps, "barrel would reach the disc: plate must be >= barrel + 0.3");
assert(sw_boss_t >= wall, "switch handle too short for this wall: lower sw_tip_proud");
assert(sw_boss_t - sw_scoop_d - tol_small >= min_wall - eps, "wall under the switch scoop too thin");
assert(Zsw_bot - sw_pin_l - Zi0 >= 0.3 - eps, "switch pins hit the plug: trim pins / lower sw_pin_l");
assert(!has_button || (Zw - btn_flange_t - btn_free) - (Ztt + btn_gap) >= -eps, "tact switch too tall for this thickness");
assert((sw_handle + 2*tol_hole) - 2*tol_hole >= sw_handle - eps, "switch slot worst case narrower than the handle");
assert(usb_z - usb_well_h/2 - Zi0 >= 0.8 || charge_port == "front", "web under the USB well < 0.8");
assert(gap12 >= ribbon_bay, "row gap too small for the ribbon S-fold");
assert(antenna_place != "bay" || Zab - Zi0 >= ant_wall_gap - eps, "antenna closer than ant_wall_gap to the plug");
assert(antenna_place != "bay" || Zw - (Zab + ant_t) >= ant_wall_gap - eps, "antenna closer than ant_wall_gap to the front wall");
assert(antenna_place != "bay" || y_hi - y_lane0 - ledge_d >= lead_lane_w - eps, "+Y lane across the antenna bay too narrow for the cell leads + NTC");
assert(laneA_w >= wire_pwr_d + lane_spare - eps, "lane A too narrow for the stacked cell leads");
assert(ph_gap_mouth >= 2*ph_hsg_len - eps, "row gap shorter than both JST-PH housings fully withdrawn");
assert(antenna_place != "bay" || ant_l + 2*ant_clr + 2*ant_frame_w <= Wi, "antenna longer than the body is wide");
assert(Wi >= cell_pocket_w, "interior narrower than the cell pocket");
assert(cam_y - cam_ring_od/2 >= y_sp0 - eps && cam_y + cam_ring_od/2 <= y_hi - laneC_w + eps, "camera bezel does not fit in the small-parts column");
assert(cam_x - cam_ring_od/2 >= sp_x0 + max(sw_cradle[0], has_button ? tact_cradle : 0) + 0.3, "camera bezel overlaps the switch/button");

// =============================================================================
//  REPORT (shown in the console on every run)
// =============================================================================
echo(str("OUTER SIZE (", style, ", port ", charge_port, ", connectors ", board_connectors, ", antenna ", antenna_place,
         "): L x W x T = ", L, " x ", W, " x ", T, " mm"));
echo(str("Thickness drivers (interior heights): XIAO ", H_xiao, " cell ", H_cell, " bq ", H_bq, " MAX ", H_mx,
         " camera ", H_cam, " tact ", H_tact, " switch ", H_sw, " front-port ", H_front, " -> Hi = ", Hi));
echo(str("Layout X: row1 ", x_row1, "..", row1_end, "  gap ", gap12, "  row2 ", x_row2, "..", row2_end,
         "  antenna bay ", x_bay, "..", x_head, "  lead zone ..", x_cell, "  cell pocket ", x_cell, "..", x_cell + cell_pocket_l));
echo(str("Antenna: X ", x_ant0, "..", x_ant0 + ant_w, " Y ", y_ant0, "..", y_ant0 + ant_l, " Z ", Zab, "; keep-out ", ant_keep, " mm; gap to cell foil ",
         x_cellb - (x_ant0 + ant_w), " mm; to plug ", Zab - Zi0, " mm; to front wall ", Zw - (Zab + ant_t), " mm"));
echo(str("JST-PH row gap: mouth-to-mouth ", ph_gap_mouth, " (jumper offset ", jump_d, ", S-bend ", s_bend(jump_d, ph_bend_r), ") -> gap12 ", gap12));
echo(str("Cell leads must reach about ", cell_lead_need, " mm along the lane route (else a JST-PH extension). Lead zone ", lead_zone,
         " mm (", cell_connector, cell_connector == "RCY" ? str(", splice ", rcy_orient, " ", rcy_foot_x, " x ", rcy_l, " x ", rcy_h) : "", ")"));
echo(str("Rounded-corner growth at cell corners: ", cell_g, " mm per side; corner keep-out ", corner_keep));
echo(str("Lens: opening r_in ", lens_r_in, " (needs ", lens_r_req_in, "), r_out ", lens_r_out, ", lens-disc gap ", cam_gap_disc, ", max FOV ", fov_max));
echo(str("Plug fit per side: X ", plug_fx, "  Y ", plug_fy));

// =============================================================================
//  2D / 3D HELPERS
// =============================================================================
module rrect(s, r) {                     // rounded rectangle, corner at origin
    if (r <= eps) square(s);
    else translate([r, r]) offset(r = r) square([s[0] - 2*r, s[1] - 2*r]);
}
module rbox(s, r) linear_extrude(s[2]) rrect([s[0], s[1]], r);
module cbox(c, s) translate([c[0] - s[0]/2, c[1] - s[1]/2, c[2]]) cube(s);   // centred in XY
module rrect_c(w, h, r) translate([-w/2, -h/2]) rrect([w, h], r);   // centred rounded rectangle
module stadium(w, h) {                   // centred 2D stadium, long axis along X
    hull() { translate([-(w - h)/2, 0]) circle(d = h); translate([(w - h)/2, 0]) circle(d = h); }
}
module bx(p0, p1) translate(p0) cube([p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]]);   // box from corners

module corner_profile(R, H, ef, eb) {    // (r, z) profile of one rounded corner column
    hull() {
        square([eps, H]);
        if (eb > eps) translate([R - eb, eb]) circle(r = eb); else translate([R - eps, 0]) square([eps, eps]);
        if (ef > eps) translate([R - ef, H - ef]) circle(r = ef); else translate([R - eps, H - eps]) square([eps, eps]);
    }
}

// =============================================================================
//  OUTER SHELL AND CAVITY
// =============================================================================
module outer_solid() {
    if (style == "rounded")
        hull() for (x = [corner_r, L - corner_r], y = [corner_r, W - corner_r])
            translate([x, y, 0]) rotate_extrude($fn = max($fn, 48)) corner_profile(corner_r, T, edge_r_front, edge_r_back);
    else cube([L, W, T]);
}
module cavity_2d() translate([wall, wall]) rrect([Li, Wi], Ri);
module cavity_solid(z0 = -1, z1 = Zw) translate([0, 0, z0]) linear_extrude(z1 - z0) cavity_2d();

// =============================================================================
//  BODY (tray: front wall + side walls, open back closed by the plug)
// =============================================================================
module body() {
    difference() {
        union() {
            difference() { outer_solid(); cavity_solid(); }
            intersection() { cavity_solid(Zi0, Zw + eps); internal_features(); }
        }
        body_cuts();
    }
}

module internal_features() {
    if (antenna_place == "bay") bay_carrier();
    if (charge_port == "edge") usb_boss_edge(); else { usb_boss_front(); bq_edge_guides(); }
    if (charge_port == "edge") board_posts("bq", 3.6, Zbq + bq_pcb_t, Zbq);
    board_posts("mx", 3.4, Zmx + mx_pcb_t, Zmx);
    xiao_posts();
    camera_bezel();
    switch_boss();
    if (has_button) tact_cradle_solid();
    cell_stops();
    ledges();
}

// --- antenna bay: two full-height plastic fences carry a plastic FRAME at mid-height. The antenna's
//     adhesive back sticks to the 1.5 mm rim, so the radiating area hangs over an open window, >= ant_wall_gap
//     from the front wall and from the plug (Seeed staff advice). Everything here is plastic.
//     The wire lane is on the +Y side, outside the 5 mm keep-out, so no wire crosses the antenna.
module bay_carrier() {
    for (x = [x_bay + 0.2, x_head - fence_t])
        bx([x, y0 - eps, Zi0], [x + fence_t, y_lane0, Zw + eps]);
    translate([0, 0, Zab - carrier_t]) linear_extrude(carrier_t) difference() {
        translate([x_bay + 0.2, y0 - eps]) square([x_head - x_bay - 0.2, y_lane0 - y0 + eps]);
        translate([x_ant0 + ant_rim, y_ant0 + ant_rim]) square([ant_w - 2*ant_rim, ant_l - 2*ant_rim]);
    }
}

// --- thick end wall around the charging port (edge mode) ---
module usb_boss_edge() {        // end wall thickened to usb_boss_t around the well (+ room for the pry scoop on +Y)
    bx([wall - eps, usb_y - usb_well_w/2 - 0.8, Zi0],
       [usb_boss_t, usb_y + usb_well_w/2 + 0.8 + pry_w, usb_z + usb_well_h/2 + 0.8]);
}
module usb_boss_front() {
    translate([usb_x_front, usb_y, Zw - (usb_boss_t - wall)])
        linear_extrude(usb_boss_t - wall + eps)
            offset(r = 0.8) rotate(90) stadium(usb_well_w + pry_w*2, usb_well_h);
}
// front mode: two vertical channels hold the bq25185 standing on edge
module bq_edge_guides() {
    slot = bq_pcb_t + 0.15 + 2*fit_slide_bought;   // PCB 1.57 ±0.15 assumed
    for (yy = [y_bq0 - 0.8, y_bq0 + bq_l - 1.2])
        difference() {
            bx([x_row1 - 1.0, yy, Zbq_edge0 + 3], [x_row1 + slot + 1.0, yy + 2.0, Zw + eps]);   // hangs from the front wall
            bx([x_row1 - eps, yy - 1, Zbq_edge0], [x_row1 + slot, yy + 3, Zw]);
        }
}

// --- posts with locating pins into PCB holes ---
function bq_place_xy(p) = [x_row1 + bq_d - p[1], y_bq0 + p[0]];
function mx_place_xy(p) = [x_mx0 + mx_d - p[1], y_mx0 + p[0]];   // MAX rotated +90: JST mouths face -X
function place_xy(kind, p) = kind == "bq" ? bq_place_xy(p) : mx_place_xy(p);
module board_posts(kind, shoulder_d, z_top, z_bot) {
    pin_d = bq_hole_d - 2*fit_pin_pcb;
    for (h = (kind == "bq" ? bq_holes : mx_holes)) {
        q = place_xy(kind, h);
        translate([q[0], q[1], z_top]) cylinder(d = shoulder_d, h = Zw - z_top + eps);
        translate([q[0], q[1], z_bot - 0.4]) {
            cylinder(d = pin_d, h = z_top - z_bot + 0.4 + eps);
        }
    }
}

// --- XIAO: two posts straddle the USB-C shell at the USB end, two posts at the far end ---
// XIAO is flipped (rotate 180 about X): local v maps to Y = Yx0 + xiao_pcb_w - v, w maps to Z = Zxb - w
function xy_v(v) = Yx0 + xiao_pcb_w - v;
module xiao_posts() {
    zb = Zxb - xiao_pcb_t - 0.3;               // posts reach just past the XIAO PCB (which is at the top)
    // USB end: posts beside the shell, touching neither the castellations nor the BOOT/RESET buttons
    for (vv = [[4.412 - fit_slide_bought - 1.6, 4.412 - fit_slide_bought],
               [13.352 + fit_slide_bought, 13.352 + fit_slide_bought + 1.6]])
        bx([Xx0 - 0.1 - xpost, xy_v(vv[1]), zb], [Xx0 - 0.1, xy_v(vv[0]), Zw + eps]);
    // far end: past the expansion board envelope
    for (vv = [[3.2, 4.8], [14.18, 15.78]])     // first post kept >= 0.6 mm from the +Y lane (Y >= y_lane0)
        bx([xiao_far + 0.1, xy_v(vv[1]), zb], [xiao_far + 0.1 + xpost, xy_v(vv[0]), Zw + eps]);
}

// --- camera bezel: window ring + stop plate + cradle (hangs from the front wall) ---
module camera_bezel() {
    translate([cam_x, cam_y, 0]) {
        // ring that locates the disc (disc glued to the front-wall lip)
        translate([0, 0, Zplate_bot]) cylinder(d = cam_ring_od, h = Zw - Zplate_bot + eps);
        // cradle around the head
        translate([-cam_cradle_o/2, -cam_cradle_o/2, Zplate_bot - cam_cradle_depth])
            cube([cam_cradle_o, cam_cradle_o, cam_cradle_depth + eps]);
    }
}

// --- switch boss (local thick front wall) + cradle ---
module switch_boss() {
    cbox([sw_x, sw_y, Zsw_top], [sw_cradle[0], sw_cradle[1], Zw - Zsw_top + eps]);
    cbox([sw_x, sw_y, Zsw_bot + 1.0], [sw_cradle[0], sw_cradle[1], Zsw_top - Zsw_bot - 1.0 + eps]);
}

// --- tact switch cradle ---
module tact_cradle_solid() {
    cbox([tact_x, tact_y, Ztb + 1.0], [tact_cradle, tact_cradle, Zw - Ztb - 1.0 + eps]);
}

// --- cell stops at the lead end: round posts (no sharp edge toward the pouch), touch only the sealed side edges ---
module cell_stops() {
    for (yy = [y_cellb + 1.75, y_cellb + cell_w - 1.75])
        translate([x_cell - 1.25, yy, Zc + 1.5]) cylinder(d = 2.5, h = Zw - Zc - 1.5 + eps);
}

// --- ledges the plug rests on (low enough to pass under the cell and boards) ---
module ledges() {
    xs_cell = [x_cell + 10, x_cell + cell_pocket_l/2, x_cell + cell_pocket_l - 8];
    for (x = xs_cell) {
        bx([x - ledge_len/2, y0 - eps, Zi0], [x + ledge_len/2, y0 + ledge_d, Zi0 + ledge_h]);
        bx([x - ledge_len/2, y_hi - ledge_d, Zi0], [x + ledge_len/2, y_hi + eps, Zi0 + ledge_h]);
    }
    for (y = [y0 + 8, y0 + Wi/2, y_hi - 8])
        bx([L - wall - ledge_d, y - ledge_len/2, Zi0], [L - wall + eps, y + ledge_len/2, Zi0 + ledge_h]);
    // electronics end: beside the bq along the -Y wall, and in the bay
    for (x = [x_row1 + 6, x_row1 + 19])
        bx([x - ledge_len/2, y0 - eps, Zi0], [x + ledge_len/2, y0 + ledge_d, Zi0 + ledge_h]);
    if (bay_len >= ledge_len + 2) for (yy = [y0 - eps, y_hi - ledge_d])
        bx([x_bay + bay_len/2 - ledge_len/2, yy, Zi0], [x_bay + bay_len/2 + ledge_len/2, yy + ledge_d + eps, Zi0 + ledge_h]);
}


// --- everything cut out of the body ---
module body_cuts() {
    // charging port: flush-cover well + receptacle opening
    if (charge_port == "edge") {
        translate([-1, usb_y, usb_z]) rotate([0, 90, 0]) rotate(90)
            linear_extrude(1 + usb_well_d) stadium(usb_well_w, usb_well_h);
        translate([usb_well_d - eps, usb_y, usb_z]) rotate([0, 90, 0]) rotate(90)
            linear_extrude(usb_inner_wall + 1) rrect_c(usb_open_w, usb_open_h, usb_open_r);
        // fingernail scoop at the +Y end of the well
        translate([-1, usb_y + usb_well_w/2 - 0.6, usb_z - 1.2]) cube([1 + 0.8, pry_w + 0.6, 2.4]);
    } else {
        translate([usb_x_front, usb_y, T - usb_well_d]) linear_extrude(usb_well_d + 1)
            rotate(90) stadium(usb_well_w, usb_well_h);
        translate([usb_x_front, usb_y, Zw - (usb_boss_t - wall) - 1]) linear_extrude(usb_inner_wall + 1 + eps)
            rotate(90) rrect_c(usb_open_w, usb_open_h, usb_open_r);
        translate([usb_x_front - 1.2, usb_y + usb_well_w/2 - 0.6, T - 0.8]) cube([2.4, pry_w + 0.6, 1]);
    }
    // lens: cone through the front wall (sized from the FOV), disc recess, barrel hole
    translate([cam_x, cam_y, 0]) {
        translate([0, 0, Zw - eps]) cylinder(r1 = lens_r_in, r2 = lens_r_out, h = wall + 2*eps);
        translate([0, 0, Zplate_top]) cylinder(d = win_pocket_d, h = Zw - Zplate_top + eps);
        translate([0, 0, Zplate_bot - eps]) cylinder(d = cam_barrel_d + cam_tol + 2*fit_slide_bought, h = cam_plate_t + 2*eps);
        // head pocket
        translate([-cam_pocket/2, -cam_pocket/2, Zplate_bot - cam_cradle_depth - 1]) cube([cam_pocket, cam_pocket, cam_cradle_depth + 1 + eps]);
        // ribbon port (+X side, toward the XIAO)
        translate([cam_pocket/2 - eps, -(cam_ribbon_w + lane_spare)/2, Zplate_bot - cam_cradle_depth - 1])
            cube([cam_cradle_wall + 1, cam_ribbon_w + lane_spare, cam_cradle_depth + 1]);
    }
    // switch: handle slot, fingernail scoop, body pocket
    slot = [sw_travel + sw_handle + 2*tol_hole, sw_handle + 2*tol_hole];
    translate([sw_x - slot[0]/2, sw_y - slot[1]/2, Zsw_top - eps]) cube([slot[0], slot[1], T]);
    translate([sw_x, sw_y, T - sw_scoop_d]) linear_extrude(1)
        offset(r = 1.2) square([slot[0] + 2*2.0 - 2.4, slot[1] + 2*1.4 - 2.4], center = true);
    cbox([sw_x, sw_y, Zsw_bot - 1], [sw_l + sw_tol + 2*fit_slide_bought, sw_w + sw_tol + 2*fit_slide_bought, Zsw_top - Zsw_bot + 1]);
    // button: bore, flange counterbore, tact pocket
    if (has_button) {
        translate([tact_x, tact_y, Zw - eps]) cylinder(d = btn_d + 2*fit_pp_hole, h = wall + 1);
        translate([tact_x, tact_y, Zw - btn_flange_t - btn_free]) cylinder(d = btn_cbore_d, h = btn_flange_t + btn_free + eps);
        cbox([tact_x, tact_y, Ztb], [tact_pocket, tact_pocket, Zw - btn_flange_t - btn_free - Ztb + eps]);
    }
    // vents
    if (vents) {
        vz = T/2 - vent_h/2;
        for (x = [x_row1 + 4 : vent_pitch : x_row1 + bq_d - 4])
            translate([x, -1, vz]) cube([vent_w, wall + 2, vent_h]);
        for (x = [x_row2 + 4 : vent_pitch : row2_end - 4])
            translate([x, W - wall - 1, vz]) cube([vent_w, wall + 2, vent_h]);
    }
    // relief slots beside the cell (gas and swelling pressure path; they do not give the cell more thickness)
    if (cell_vents) {
        vz = T/2 - vent_h/2;
        for (x = [x_cell + 12 : 18 : x_cell + cell_pocket_l - 12]) {
            translate([x, -1, vz]) cube([vent_w, wall + 2, vent_h]);
            translate([x, W - wall - 1, vz]) cube([vent_w, wall + 2, vent_h]);
        }
    }
    // removable plug: pry notch in the wall rim is NOT used (wall is min thickness); the notch is in the plug
}

// =============================================================================
//  BOTTOM PLUG (flush back panel; permanent = epoxy, removable = crush ribs)
// =============================================================================
module plug_2d() translate([wall + plug_fx, wall + plug_fy]) rrect([Li - 2*plug_fx, Wi - 2*plug_fy], max(0, Ri - min(plug_fx, plug_fy)));
module plug(ribs = true) {
    difference() {
        union() {
            linear_extrude(plug_t) plug_2d();
            plug_features();
            if (plug_mode == "removable" && ribs) plug_ribs();
        }
        if (plug_mode == "removable")      // pry notch at the far end (fingernail / flat screwdriver)
            translate([L - wall - plug_fx - 1.0, W/2 - 3, -eps]) cube([1.0 + eps, 6, 0.6]);
    }
}
module plug_ribs() {
    p = plug_fy + plug_rib_interf;                       // protrusion beyond the plug edge
    for (x = [wall + 12 : plug_rib_pitch : L - wall - 12]) {
        translate([x, wall + plug_fy - p + plug_rib_r, 0]) cylinder(r = plug_rib_r, h = plug_t);
        translate([x, W - wall - plug_fy + p - plug_rib_r, 0]) cylinder(r = plug_rib_r, h = plug_t);
    }
}
module plug_features() {
    // cell rails (rounded tops, no sharp edge against the pouch)
    for (dy = [-cell_rail_dy/2, cell_rail_dy/2])
        translate([x_cell + 2, cell_cy + dy - cell_rail_w/2, Zi0 - eps])
            hull() {
                cube([cell_pocket_l - 4, cell_rail_w, eps]);
                translate([0, 0.5, cell_rail_h - eps]) cube([cell_pocket_l - 4, cell_rail_w - 1.0, eps]);
            }
    // NTC seat (top flush with the rail tops) + guides
    nx = x_cellb + ntc_from_lead_end;
    cbox([nx, cell_cy, Zi0 - eps], [ntc_l, ntc_w, cell_rail_h - ntc_t + eps]);
    for (s = [-1, 1]) cbox([nx, cell_cy + s*(ntc_w/2 + 0.4 + 0.3), Zi0 - eps], [ntc_l + 1, 0.8, cell_rail_h - 0.5]);
    cbox([nx + ntc_l/2 + 0.4 + 0.3, cell_cy, Zi0 - eps], [0.8, ntc_w + 2.2, cell_rail_h - 0.5]);
    // hold-down pads (stop pad_float short of the part)
    for (p = [[6, 12.7], [25.75, 12.7]]) if (charge_port == "edge")
        cbox(concat(bq_place_xy(p), Zi0 - eps), [3, 3, bq_gap - pad_float + eps]);
    for (p = [[12.7, 2.5], [12.7, 15.5]])
        cbox(concat(mx_place_xy(p), Zi0 - eps), [3, 3, mx_gap - pad_float + eps]);
    // XIAO (flipped): pads under the expansion PCB, between the microSD socket and the camera connector
    for (vv = [2.0, 15.78])
        cbox([Xx0 + 13.65, xy_v(vv), Zi0 - eps], [2.2, 2.0, (Zxb - 5.43) - pad_float - Zi0 + eps]);
    // camera backstop (away from the ribbon side)
    cbox([cam_x - 1.5, cam_y, Zi0 - eps], [4, 4, Zcam0 - pad_float - Zi0 + eps]);
    // switch backstops at the ends of the switch base (pins are in the middle)
    for (s = [-1, 1]) cbox([sw_x + s*(sw_l/2 - 0.6), sw_y, Zi0 - eps], [1.0, 2.5, Zsw_bot - pad_float - Zi0 + eps]);
    // tact backstop between the legs
    if (has_button) cbox([tact_x, tact_y, Zi0 - eps], [2.5, 2.5, Ztb - pad_float - Zi0 + eps]);
    // front-mode: pads under the standing bq board corners
    if (charge_port == "front") for (yy = [y_bq0 + 1, y_bq0 + bq_l - 1])
        cbox([x_row1 + bq_pcb_t/2, yy, Zi0 - eps], [bq_pcb_t, 1.5, Zbq_edge0 - pad_float - Zi0 + eps]);
}

// =============================================================================
//  USB-C COVER (flush, removable, crush ribs; fit A/B/C). Print outer face down.
//  Local frame: outer face at z = 0, stadium long axis along x.
// =============================================================================
module usb_cover_core() {
    linear_extrude(usb_well_d) stadium(usb_well_w - 2*cover_core_fit, usb_well_h - 2*cover_core_fit);
}
module usb_cover(k) {
    i = cover_rib_interf[k];
    p = cover_core_fit + i;                       // rib protrusion beyond the core
    hc = (usb_well_h - 2*cover_core_fit)/2;
    difference() {
        union() {
            usb_cover_core();
            for (xx = [-3.5, 0, 3.5], s = [-1, 1])
                hull() {
                    translate([xx, s*(hc + p - cover_rib_r), 0]) cylinder(r = cover_rib_r, h = usb_well_d - 0.5, $fn = 16);
                    translate([xx, s*(hc - cover_rib_r), 0]) cylinder(r = cover_rib_r, h = usb_well_d, $fn = 16);
                }
        }
        // fit letter engraved on the inner face
        translate([-3, -1.2, usb_well_d - 0.3]) linear_extrude(1) text(chr(65 + k), size = 2.4);
    }
}
module usb_cover_placed() {     // cover core in its assembled position (ribs omitted: they interfere by design)
    if (charge_port == "edge")
        translate([0, usb_y, usb_z]) rotate([0, 90, 0]) rotate(90) usb_cover_core();
    else
        translate([usb_x_front, usb_y, T]) rotate([180, 0, 0]) rotate(90) usb_cover_core();
}

// =============================================================================
//  BUTTON CAP (printed). Built upright: stem end at z = 0, head top at z = cap_len.
//  The export (part = "button_cap") flips it so it prints head down.
// =============================================================================
cap_stem_l = (Zw - btn_flange_t) - (Ztt + btn_gap);
cap_len = cap_stem_l + btn_flange_t + wall + btn_proud;
module button_cap() {
    cylinder(d = btn_stem_d, h = cap_stem_l + eps);
    translate([0, 0, cap_stem_l]) cylinder(d = btn_flange_d, h = btn_flange_t + eps);
    translate([0, 0, cap_stem_l + btn_flange_t]) hull() {
        cylinder(d = btn_d, h = wall + btn_proud - 0.3);
        cylinder(d = btn_d - 0.6, h = wall + btn_proud);
    }
}
module button_cap_placed() translate([tact_x, tact_y, Ztt + btn_gap]) button_cap();

// =============================================================================
//  COMPONENT DUMMIES (for views and clearance checks)
// =============================================================================
module cell_dummy() translate([x_cellb, y_cellb, Zc]) rbox([cell_l, cell_w, cell_t], cell_corner_r);
module cell_swollen() translate([x_cellb, y_cellb, Zc]) rbox([cell_l, cell_w, cell_t + cell_swell], cell_corner_r);
// NTC wire (Ø ntc_wire_d) + 1 mm spare in the channel between the rails, from the NTC to the cell lead end
module ntc_wire_room() bx([x_cell + eps, cell_cy - 0.75, Zi0 + eps], [x_cellb + ntc_from_lead_end - ntc_l/2 - eps, cell_cy + 0.75, Zi0 + ntc_wire_d + lane_spare]);
module ntc_dummy() cbox([x_cellb + ntc_from_lead_end, cell_cy, Zc - ntc_t], [ntc_l, ntc_w, ntc_t]);

module xiao_local() {   // (u, v, w) boxes measured from the STEP file
    bx([0, 0, 0], [xiao_pcb_l, xiao_pcb_w, xiao_pcb_t]);                 // XIAO PCB
    bx([-xiao_usb_over, 4.412, 0.26], [6.373, 13.352, 4.46]);           // USB-C shell
    bx([6.71, 2.59, 0.55], [17.31, 15.19, 3.25]);                       // RF shield
    bx([0.028, 2.156, 1.25], [3.118, 3.756, 1.98]);                     // BOOT button
    bx([0.046, 14.014, 1.25], [3.136, 15.614, 1.98]);                   // RESET button
    bx([17.734, 2.613, 1.25], [20.734, 5.713, 2.5]);                    // U.FL
    bx([17.314, 6.738, 1.25], [20.694, 15.338, 4.18]);                  // board-to-board connectors
    bx([6.579, 0, 4.18], [xiao_pcb_l + xiao_exp_over, xiao_pcb_w, 5.43]); // expansion PCB (envelope)
    bx([6.674, 2.916, 5.38], [12.174, 14.316, xiao_stack_h]);           // microSD socket
    bx([15.125, 0.821, 5.42], [21.125, 17.021, 7.43]);                  // camera FPC connector
    if (sd_card_fitted) bx([-3.108, 2.484, 6.85], [11.952, 13.664, 8.50]);
}
module xiao_dummy() translate([Xx0, Yx0 + xiao_pcb_w, Zxb]) rotate([180, 0, 0]) xiao_local();

module bq_local() {
    difference() {
        rbox([bq_l, bq_d, bq_pcb_t], bq_corner_r);
        for (h = bq_holes) translate([h[0], h[1], -1]) cylinder(d = bq_hole_d, h = 5);
    }
    translate([(bq_usb[0] + bq_usb[1])/2, bq_usb[2], (bq_usb[4] + bq_usb[5])/2]) rotate([-90, 0, 0])   // USB-C shell
        linear_extrude(bq_usb[3] - bq_usb[2]) rrect_c(usbc_shell_w, usbc_shell_h, usbc_shell_r);
    bx([bq_low[0], bq_low[2], bq_pcb_t], [bq_low[1], bq_low[3], bq_pcb_t + bq_low[4]]);
    if (kept) for (j = bq_jst) bx([j[0], bq_jst_y[0], bq_pcb_t], [j[1], bq_jst_y[1], bq_pcb_t + bq_jst_h]);
}
module bq_place() {
    if (charge_port == "edge") translate([x_row1 + bq_d, y_bq0, Zbq]) rotate(90) children();
    else multmatrix([[0, 0, 1, x_row1], [1, 0, 0, y_bq0], [0, 1, 0, Zbq_edge0], [0, 0, 0, 1]]) children();
}
module bq_dummy() bq_place() bq_local();

module mx_local() {
    difference() {
        rbox([mx_l, mx_d, mx_pcb_t], mx_corner_r);
        for (h = mx_holes) translate([h[0], h[1], -1]) cylinder(d = mx_hole_d, h = 5);
    }
    bx([mx_low[0], mx_low[2], mx_pcb_t], [mx_low[1], mx_low[3], mx_pcb_t + mx_low[4]]);
    if (kept) {
        for (j = mx_jst) bx([j[0], mx_jst_y[0], mx_pcb_t], [j[1], mx_jst_y[1], mx_pcb_t + mx_jst_h]);
        for (q = mx_qt) bx([q[0], mx_qt_y[0], mx_pcb_t], [q[1], mx_qt_y[1], mx_pcb_t + mx_qt_h]);
    }
}
module mx_dummy() translate([x_mx0 + mx_d, y_mx0, Zmx]) rotate(90) mx_local();

module camera_dummy() translate([cam_x, cam_y, 0]) {
    cbox([0, 0, Zcam0], [cam_w, cam_d, cam_block_h]);
    translate([0, 0, Zcam0 + cam_block_h - eps]) cylinder(d = cam_barrel_d, h = cam_barrel_h + eps);
    translate([cam_w/2 - eps, -cam_ribbon_w/2, Zcam0]) cube([3, cam_ribbon_w, ribbon_t]);   // ribbon stub
}
module window_dummy() translate([cam_x, cam_y, Zw - win_t]) cylinder(d = win_d, h = win_t);

module switch_dummy() {
    cbox([sw_x, sw_y, Zsw_bot], [sw_l, sw_w, sw_h]);
    cbox([sw_x, sw_y, Zsw_top - eps], [sw_travel + sw_handle, sw_handle, sw_handle_h + eps]);   // swept handle
    for (dx = [-2.5, 0, 2.5]) cbox([sw_x + dx, sw_y, Zsw_bot - sw_pin_l], [0.5, 0.3, sw_pin_l + eps]);
}
module tact_dummy() if (has_button) {
    cbox([tact_x, tact_y, Ztb], [tact_w, tact_w, tact_body_h]);
    translate([tact_x, tact_y, Ztb + tact_body_h - eps]) cylinder(d = tact_act_d, h = tact_h - tact_body_h + eps);
    for (sx = [-1, 1], sy = [-1, 1]) cbox([tact_x + sx*3.25, tact_y + sy*2.25, Ztb - (tact_leg_clear - 0.2)], [0.7, 0.3, tact_leg_clear - 0.2 + eps]);
}
module antenna_dummy() if (antenna_place == "bay") translate([x_ant0, y_ant0, Zab]) cube([ant_w, ant_l, ant_t]);

// RULE 2: no metal within ant_keep of the antenna (box = conservative envelope; plastic is allowed)
module antenna_keepout() if (antenna_place == "bay")
    bx([x_ant0 - ant_keep, max(y0, y_ant0 - ant_keep), Zi0], [x_ant0 + ant_w + ant_keep, min(y_hi, y_lane0), Zw]);   // full height

// keep-out volumes for mated JST-PH / STEMMA QT plugs and their wire bends
// each entry: [box min, box max, mating axis 0 = X / 1 = Y]
function zone_list() = kept ? concat(
    charge_port == "edge"
      ? [for (c = bq_jst_c) [[x_bq_mouth + eps, y_bq0 + c - ph_hsg_w/2, Zbq + bq_pcb_t],       // housing swept from mated to fully withdrawn
                             [x_bq_mouth + ph_hsg_len, y_bq0 + c + ph_hsg_w/2, Zbq + bq_pcb_t + bq_jst_h + 0.3], 0, "bq"]]
      : [for (j = bq_jst) [[x_row1 + bq_pcb_t, y_bq0 + j[0] - 0.5, Zi0 + eps],
                           [x_row1 + bq_pcb_t + bq_jst_h + 0.3, y_bq0 + j[1] + 0.5, Zbq_edge0 - eps], 2, "bqf"]],
    [for (c = mx_jst_c) [[x_mx0 + ph_mouth_mx - ph_hsg_len, y_mx0 + c - ph_hsg_w/2, Zmx + mx_pcb_t],
                         [x_mx0 + ph_mouth_mx - eps, y_mx0 + c + ph_hsg_w/2, Zmx + mx_pcb_t + mx_jst_h + 0.3], 0, "mx"]],
    [[[x_mx0 + mx_d - mx_qt_y[1] - 0.5, y_mx0 + mx_l + eps, Zmx + mx_pcb_t],
      [x_mx0 + mx_d - mx_qt_y[0] + 0.5, y_mx0 + mx_l + qt_plug_zone - 0.2, Zmx + mx_pcb_t + mx_qt_h + 0.5], 1, "qt"]]) : [];
module plug_zones() for (z = zone_list()) bx(z[0], z[1]);

// RULE 1: every plug can be pulled from the back opening without moving anything else:
// a column from the plug face up to the plug zone, finger_clr wider each side across the mating axis.
// Plus the XIAO camera-FPC latch (faces the back because the stack is flipped).
module access_zones() {
    for (z = zone_list()) {
        a = z[2];
        // fingers come from below, so the column stops at the board edge: the 0.3-0.5 mm of housing zone above the PCB is reached from beside it
        x0 = z[3] == "bq" ? max(z[0][0], x_row1 + bq_d + eps) : z[0][0];
        x1 = z[3] == "mx" ? min(z[1][0], x_mx0 - eps) : z[1][0];
        bx([x0 - (a == 1 ? finger_clr : 0), z[0][1] - (a == 0 ? finger_clr : 0), Zi0 + eps],
           [x1 + (a == 1 ? finger_clr : 0), z[1][1] + (a == 0 ? finger_clr : 0), z[1][2]]);
    }
    bx([Xx0 + 15.125, xy_v(17.021), Zi0 + eps], [Xx0 + 21.125, xy_v(0.821), Zxb - 7.43 - eps]);
    if (cell_connector == "RCY") splice_zone(true);
}

// --- RCY splice (red JST-RCY pair, mated: 23.3 x 6.7 x 4.0), only for cell_connector = "RCY"
module splice_dummy() if (cell_connector == "RCY")
    translate([x_s - rcy_foot_x/2, y_s0, Zi0 + 0.2]) cube([rcy_foot_x, rcy_l, rcy_h]);
module splice_zone(access = true) if (cell_connector == "RCY")
    bx([x_s - rcy_foot_x/2 - (access ? finger_clr : 0), y_s0, Zi0 + eps],
       [x_s + rcy_foot_x/2 + (access ? finger_clr : 0), y_s0 + rcy_l, Zi0 + 0.2 + rcy_h]);

// reserved wire lanes (must stay free of printed material AND of boards/parts: pairs 67-73). Wires are metal:
// none may enter the antenna keep-out. Cell leads + NTC take this route to the MAX17048 (checked as free volumes,
// NOT simulated as flexible cables): lead zone -> +Y lane across the bay -> lane A beside the XIAO -> row gap.
module lanes() {
    zt = Zw - eps;  zl = Zi0 + ledge_h + eps;  yl = y_hi - ledge_d - eps;
    // lead zone: central part between the cell stops, then the +Y strip (clear of the +Y stop post)
    difference() {
        union() {
            bx([x_head + eps, y_cellb + 3.6, zl], [x_cell - 1.0 - eps, y_cellb + cell_w - 3.6, zt]);
            bx([x_head + eps, y_cellb + cell_w - 3.6, zl], [x_cell - 2.5 - 0.2, yl, zt]);
        }
        splice_zone(false);
    }
    // across the bay on the +Y side, outside the keep-out
    if (antenna_place == "bay") bx([x_bay + eps, y_lane0 + eps, zl], [x_head - eps, yl, zt]);
    else bx([x_bay + eps, y0 + ledge_d + eps, zl], [x_head - eps, yl, zt]);
    // lane A beside the XIAO (+Y wall): cell leads (stacked) + XIAO castellation wires
    bx([x_row2 + eps, Yx0 + xiao_pcb_w + eps, zl], [x_bay - eps, yl, zt]);
    // lane B (MAX <-> XIAO): QT cable, XIAO castellation wires, NTC
    bx([x_row2 + eps, y_mx0 + mx_l + eps, Zi0 + eps], [x_bay - eps, Yx0 - eps, zt]);
    // row gap (both plug zones, jumper S-bend, cell-lead bend, ribbon S-fold)
    bx([row1_end + eps, y0 + eps, Zi0 + eps], [Xx0 - xiao_usb_over - eps, y_hi - eps, zt]);
    // camera ribbon: under the flipped XIAO stack, and from the gap into the camera port (starts past the ribbon stub)
    bx([Xx0 - xiao_usb_over, xy_v(xiao_ribbon_v) - 3.5, Zi0 + eps], [Xx0 + 15.1, xy_v(xiao_ribbon_v) + 3.5, Zxs - eps]);
    bx([cam_x + cam_w/2 + 3.0 + eps, cam_y - 3.5, Zcam0 + eps], [row1_end + 1, cam_y + 3.5, Zplate_bot - cam_cradle_depth - eps]);
    // lane C (+Y wall of the small-parts column): button wires
    if (has_button) bx([tact_x + tact_cradle/2 + eps, y_hi - laneC_w + eps, Zi0 + eps], [row1_end + eps, y_hi - eps, zt]);
    // over the bq25185 (NTC to TH pad, switch to LOAD pads): past the USB-C shell, above the low parts
    if (charge_port == "edge")
        bx([x_row1 + bq_d - bq_usb[2] + 0.2, y_bq0 + 4.6, Zbq + bq_pcb_t + bq_low[4] + eps], [x_row1 + 15.5, y_bq0 + bq_l - 4.6, zt]);
    // NTC channel under the cell, between the rails
    bx([x_cell + eps, cell_cy - 1.0, Zi0 + eps], [x_cellb + ntc_from_lead_end - ntc_l/2 - 0.4 - 0.4, cell_cy + 1.0, Zc - eps]);
}

// =============================================================================
//  FIT COUPON (same recess geometry as the real parts, ladder of per-side fits)
// =============================================================================
module fit_coupon() {
    pitch = 17;  rows = 7;  rowp = 12.5;
    pw = 4 * pitch + 14;  ph = rows * rowp + 8;  pt = 4.3;
    difference() {
        cube([pw, ph, pt]);
        for (i = [0 : 3]) {
            f = coupon_fits[i];
            cx = 14 + pitch/2 + i * pitch;
            // column label (fit in 1/100 mm)
            translate([cx - 2.4, ph - 5.2, pt - 0.4]) linear_extrude(1) text(str(round(f * 100)), size = 3);
            // row 1: camera head pocket
            translate([cx, 8, pt - 3]) cbox([0, 0, 0], [cam_w + cam_tol + 2*f, cam_d + cam_tol + 2*f, 4]);
            // row 2: slide switch pocket + handle slot
            translate([cx, 8 + rowp, 0]) {
                cbox([0, 0, pt - sw_h], [sw_l + sw_tol + 2*f, sw_w + sw_tol + 2*f, 4]);
                cbox([0, 0, -1], [sw_travel + sw_handle + 2*tol_hole, sw_handle + 2*tol_hole, pt]);
            }
            // row 3: tact pocket
            translate([cx, 8 + 2*rowp, pt - 3]) cbox([0, 0, 0], [tact_w + tact_tol + 2*f, tact_w + tact_tol + 2*f, 4]);
            // row 4: window disc recess (+ smaller through hole)
            translate([cx, 8 + 3*rowp, 0]) {
                translate([0, 0, pt - win_t - win_recess_extra]) cylinder(d = win_d + win_tol + 2*f, h = 4);
                translate([0, 0, -1]) cylinder(d = win_d - 2*win_lip, h = pt + 2);
            }
            // row 5: USB-C cover well (test with the plain core and with covers A/B/C)
            translate([cx, 8 + 4*rowp, pt - usb_well_d])
                linear_extrude(3) stadium(usb_well_w - 2*cover_core_fit + 2*f, usb_well_h - 2*cover_core_fit + 2*f);
            // row 7: button bore through a wall-thick web + counterbore
            translate([cx, 8 + 6*rowp, 0]) {
                translate([0, 0, -1]) cylinder(d = btn_d + 2*f, h = pt + 2);
                translate([0, 0, -1]) cylinder(d = btn_flange_d + 2*f, h = 1 + pt - wall);
            }
        }
        // row labels
        for (r = [0 : rows - 1]) translate([1.5, 6.5 + r*rowp, pt - 0.4])
            linear_extrude(1) text(["CAM", "SW", "TCT", "WIN", "USB", "PIN", "BTN"][r], size = 2.2);
    }
    // row 6: locating pins for the PCB holes (Ø2.5)
    for (i = [0 : 3]) translate([14 + pitch/2 + i*pitch, 8 + 5*rowp, pt - eps])
        cylinder(d = bq_hole_d - 2*coupon_fits[i], h = 3);
    // plain cover core to test the wells
    translate([pw + 9, 10, 0]) usb_cover_core();
}

// =============================================================================
//  ASSEMBLIES AND VIEWS
// =============================================================================
module components() {
    color("silver") cell_dummy();
    color("orange") ntc_dummy();
    color("darkgreen") xiao_dummy();
    color("royalblue") bq_dummy();
    color("purple") mx_dummy();
    color("dimgray") camera_dummy();
    color("lightcyan", 0.6) window_dummy();
    color("black") switch_dummy();
    color("gray") tact_dummy();
    color("gold") antenna_dummy();
    color("red") splice_dummy();
}
module assembled(ex = 0) {
    color("white", 0.35) translate([0, 0, ex * 2.5]) body();
    color("ivory") translate([0, 0, -ex * 1.5]) plug();
    translate([0, 0, ex * 0.6]) components();
    color("ivory") translate([charge_port == "edge" ? -ex : 0, 0, charge_port == "edge" ? 0 : ex * 3.5]) usb_cover_placed();
    if (has_button) color("ivory") translate([0, 0, ex * 3.2]) button_cap_placed();
    if (show_lanes) color("red", 0.25) lanes();
    if (show_lanes) color("orange", 0.25) plug_zones();
    if (show_lanes) color("green", 0.2) access_zones();
    if (show_lanes) color("cyan", 0.15) antenna_keepout();
}

// pairs that must not intersect (contacts are designed with a gap; see README)
debug_pairs = [
    ["body", "cell"], ["body", "xiao"], ["body", "bq"], ["body", "max"], ["body", "camera"],
    ["body", "window"], ["body", "switch"], ["body", "tact"], ["body", "button_cap"], ["body", "ntc"],
    ["body", "antenna"], ["body", "plug"], ["body", "usb_cover"], ["body", "lanes"], ["body", "plug_zones"],
    ["plug", "cell"], ["plug", "xiao"], ["plug", "bq"], ["plug", "max"], ["plug", "camera"],
    ["plug", "switch"], ["plug", "tact"], ["plug", "lanes"], ["plug", "plug_zones"], ["plug", "antenna"],
    ["cell", "xiao"], ["cell", "bq"], ["cell", "max"], ["camera", "window"], ["tact", "button_cap"],
    ["xiao", "bq"], ["xiao", "max"], ["xiao", "camera"], ["bq", "max"], ["bq", "camera"], ["bq", "switch"],
    ["bq", "tact"], ["camera", "switch"], ["camera", "tact"], ["switch", "tact"],
    ["xiao", "plug_zones"], ["max", "plug_zones"], ["camera", "plug_zones"],
    ["usb_cover", "bq"], ["body", "cell_swollen"], ["antenna", "cell_swollen"], ["plug", "ntc_wire_room"],
    // --- RULE 2: antenna keep-out (>= ant_keep) against every metal object (pairs 47-56)
    ["antenna_keepout", "cell_swollen"], ["antenna_keepout", "xiao"], ["antenna_keepout", "bq"], ["antenna_keepout", "max"],
    ["antenna_keepout", "camera"], ["antenna_keepout", "switch"], ["antenna_keepout", "tact"], ["antenna_keepout", "ntc"],
    ["antenna_keepout", "lanes"], ["antenna_keepout", "plug_zones"],
    // --- RULE 1: finger/cable access columns (plug removed) against everything else (pairs 57-66)
    ["access", "body"], ["access", "cell"], ["access", "xiao"], ["access", "bq"], ["access", "max"],
    ["access", "camera"], ["access", "switch"], ["access", "tact"], ["access", "antenna"], ["access", "button_cap"],
    // --- wire lanes against every component (pairs 67-73): a lane must be free of boards and parts, not only of printed walls
    ["lanes", "cell"], ["lanes", "xiao"], ["lanes", "bq"], ["lanes", "max"], ["lanes", "camera"], ["lanes", "switch"], ["lanes", "tact"],
    // --- real JST-PH zones and the RCY splice (pairs 74-80). The splice is empty unless cell_connector = "RCY"
    ["bq", "plug_zones"], ["splice", "cell_swollen"], ["splice", "body"], ["splice", "plug"], ["splice", "antenna_keepout"],
    ["splice", "lanes"], ["splice", "plug_zones"]
];
module obj(n) {
    if (n == "body") body();
    else if (n == "plug") plug(ribs = false);   // crush ribs interfere by design
    else if (n == "cell") cell_dummy();
    else if (n == "cell_swollen") cell_swollen();
    else if (n == "ntc_wire_room") ntc_wire_room();
    else if (n == "ntc") ntc_dummy();
    else if (n == "xiao") xiao_dummy();
    else if (n == "bq") bq_dummy();
    else if (n == "max") mx_dummy();
    else if (n == "camera") camera_dummy();
    else if (n == "window") window_dummy();
    else if (n == "switch") switch_dummy();
    else if (n == "tact") tact_dummy();
    else if (n == "button_cap") { if (has_button) button_cap_placed(); }
    else if (n == "antenna") antenna_dummy();
    else if (n == "usb_cover") usb_cover_placed();
    else if (n == "lanes") lanes();
    else if (n == "antenna_keepout") antenna_keepout();
    else if (n == "splice") splice_dummy();
    else if (n == "access") access_zones();
    else if (n == "plug_zones") plug_zones();
}
module debug_view() {
    if (debug_pair >= 0) {
        pr = debug_pairs[debug_pair];
        echo(str("DEBUG pair ", debug_pair, ": ", pr[0], " & ", pr[1]));
        intersection() { obj(pr[0]); obj(pr[1]); }
    } else
        for (pr = debug_pairs) intersection() { obj(pr[0]); obj(pr[1]); }
}

if (part == "assembled") assembled(0);
else if (part == "exploded") assembled(explode);
else if (part == "section") intersection() { assembled(0); translate([-1, -1, -1]) cube([L + 2, cam_y + 1, T + 2]); }
else if (part == "layout") {   // parts + plug zones (orange) + access columns (green) + antenna keep-out (cyan), no body
    components(); color("ivory") plug();
    color("orange", 0.5) plug_zones(); color("green", 0.25) access_zones(); color("cyan", 0.25) antenna_keepout();
}
else if (part == "body") body();
else if (part == "plug") plug();
else if (part == "usb_cover_A") usb_cover(0);
else if (part == "usb_cover_B") usb_cover(1);
else if (part == "usb_cover_C") usb_cover(2);
else if (part == "button_cap") rotate([180, 0, 0]) button_cap();
else if (part == "coupon") fit_coupon();
else if (part == "debug") debug_view();
