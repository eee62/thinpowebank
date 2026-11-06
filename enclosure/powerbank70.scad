// =============================================================================
//  Thin desk power bank, COMPACT version
//  HARD LIMITS: 70 x 100 mm footprint (outer, including walls), 12.0 mm thick at most.
//  Cell: one small LiPo pouch (603450 class) with built-in protection circuit and a JST-PH 2.0 plug.
//  Antenna: 2.4 GHz with U.FL / IPEX cable (small ceramic type, or flat stick-on type if it fits).
//  Boards: Adafruit bq25185 (#6091) + MAX17048 (#5580) + XIAO ESP32-S3 Sense. JST-PH on every board connection.
//
//  Plain OpenSCAD, no libraries (tested with OpenSCAD 2021.01). Outer coordinates throughout:
//  X = length, Y = width, Z = thickness (Z = 0 is the back plug, Z = T the front face).
//
//  ===== WHICH PARAMETERS TO CHANGE WHEN YOU HAVE REAL SHOPEE PARTS =====
//   section "PARTS YOU SWAP":  CELL      cell_t  cell_w  cell_l  cell_lead_len
//                              ANTENNA   ant_type  ant_l  ant_w  ant_t  ant_cable_len
//                              (UNUSED, kept for reference: ant_place "tab_x"/"tab_y", ant_rot, ant_tab_pos, tab_budget. The outer shape must stay a clean rectangle.)
//                              PLAN B:   to grow the whole body instead, raise max_L / max_W (README, "Plan B"). part = "wifi_test" / "wifi_test_plug" = the Wi-Fi test piece.
//                              SWITCH    sw_l  sw_w  sw_h  sw_handle  sw_handle_h  sw_travel  sw_pin_l
//                              BUTTON    tact_w  tact_h (<= 6.0)  tact_body_h  tact_act_d
//   Then run:  openscad -o out.echo powerbank70.scad   (asserts say which dimension does not fit)
//   The layout re-computes itself from these numbers. Nothing else needs to be moved by hand.
//  READ BEFORE TRUSTING A PASS: wire lanes are reserved boxes and the antenna cable is a straight-line check, not simulated cables;
//  the camera ribbon jog is not simulated; the USB-C port is on a LONG (100 mm) edge in this layout (see README).
//  =======================================================================
// =============================================================================

/* [What to render] */
// assembled | exploded | section | layout | body | plug | usb_cover_A | usb_cover_B | usb_cover_C | button_cap | coupon | wifi_test | wifi_test_plug | wifi_test_view | debug
part = "assembled";
// "sharp" = version 1 (square edges), "rounded" = version 2
style = "rounded";
// "removable" = crush-rib friction plug (default here), "permanent" = epoxy-bonded
plug_mode = "removable";
// tactile button on the front face
has_button = true;
// slots in the walls beside the charger and the XIAO
vents = true;
// pressure-relief slots in the walls beside the cell
cell_vents = true;
// draw the reserved wire lanes / plug zones / finger columns / antenna keep-out in assembled views
show_lanes = false;
// fail (assert) when the outer size exceeds the hard limits below
enforce_limits = true;
// true = the limits are checked at the WORST-CASE PRINTED size (nominal + JLC tolerance, +-0.2 mm below 100 mm). false = nominal size only
limits_at_worst_case = true;
// debug: -1 = union of all pair intersections; n = only pair n (see debug_pairs)
debug_pair = -1;
explode = 14;
$fn = 40;
eps = 0.01;

// ---------------- HARD LIMITS (yours) ----------------
max_L = 100;  max_W = 70;  max_T = 12.0;

// =============================================================================
//  PARTS YOU SWAP. Every number here is a LISTING value: mark it "verified" only after you measure the real part.
//  Defaults are representative standard sizes, NOT a Shopee listing (none was readable).
// =============================================================================
// ---- CELL: LiPo pouch with built-in protection circuit and JST-PH 2.0 plug (code = TT WW LL in 0.1 mm / mm / mm) ----
cell_code = "603450";    // label only
cell_t = 6.0;            // thickness [mm]. If the listing gives a maximum or a tolerance, enter the MAX
cell_w = 34.0;           // width [mm] (listing max)
cell_l = 50.0;           // length [mm] (listing max). Several 503450 / 603450 listings say 52-53 mm
cell_tol_pct = 0.05;     // pouch size tolerance (+-5 %). The swelling rule is checked at thickness x (1 + this)
cell_lead_len = 100;     // wire length from the pouch to the JST-PH plug, from the listing [mm] (UNVERIFIED default)
// ---- ANTENNA: 2.4 GHz, U.FL / IPEX cable ----
ant_type = "ceramic";    // "ceramic" (small PCB / chip type) or "stick" (flat adhesive FPC). Only the label and the holder use it
ant_l = 13;              // length [mm]. DEFAULT 13 x 5 ceramic: outer 98.60 x 68.96 x 11.78. 15.0 is the longest that still fits in 100 x 70
ant_w = 5;               // width [mm]
ant_t = 1.0;             // thickness [mm]  (flat FPC types are about 0.1-0.2)
ant_cable_len = 100;     // U.FL cable length from the listing [mm] (must be >= the straight line from the XIAO's U.FL socket)
// ---- ANTENNA PLACEMENT: THE TAB OPTIONS BELOW ARE UNUSED (the outer shape must stay a clean rectangle). Keep ant_place = "inside". ----
ant_place = "inside";    // UNUSED OPTION. "inside" = in the main body (the only one used) | "tab_x" = in a separate tab on the +X (100 mm) end | "tab_y" = tab on the +Y (70 mm) side
ant_rot = 0;             // 0 = long side along X, 90 = long side along Y
ant_tab_pos = -1;        // where the antenna sits along the tab edge (Y of its low edge for tab_x, X for tab_y). -1 = automatic best (smallest tab)
smalls_place = "auto";   // switch + button: "auto" (corner beside the cell if it is free within max_L, else the band above the cell) | "corner" | "band"
tab_budget = 10;         // most the tab may add beyond max_L / max_W [mm] (checked at the worst-case printed size)
// ---- SLIDE SWITCH (default = SS-12D00-G3 from the Sofng drawing; replace with the Shopee switch) ----
sw_l = 8.8;  sw_w = 3.9;  sw_h = 3.5;     // body: length (along the slide), width, height above the seat
sw_handle = 1.5;                           // handle width
sw_handle_h = 3.0;                         // handle height above the body
sw_travel = 2.0;                           // handle travel
sw_pin_l = 3.5;                            // pin length below the body
// ---- BUTTON: 6 x 6 tactile switch ----
tact_w = 6.0;                              // body width (square)
tact_body_h = 3.5;                         // body height
tact_h = 5.0;                              // total height to the top of the plunger. YOUR RULE: <= 6.0
tact_act_d = 3.5;                          // plunger diameter

// =============================================================================
//  PRINTER (JLC3DP 9000HE) AND FITS: unchanged from the first model (see README section 4)
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
//  CELL, remaining parameters
// =============================================================================
cell_margin_l = 1.0;     // >= 1.0 extra on length
cell_margin_w = 1.0;     // >= 1.0 extra on width
cell_swell    = 0.8;     // >= 0.8 free above the cell at +5 % thickness (your rule)
cell_corner_r = 0.5;     // pouch corner radius, ASSUMED
cell_head_zone = 5.0;    // lead end: protection board, lead bends. ASSUMED (measure your cell)
cell_rail_h   = 1.5;     // rails under the cell: air gap + NTC-wire channel
cell_rail_w   = 3.0;
cell_rail_dy  = max(8, cell_w - 10);     // rail spacing
ntc_l = 4.0;  ntc_w = 2.5;  ntc_t = 1.0;  // 10 k NTC, flat/film type ASSUMED
ntc_from_lead_end = 15;
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
ribbon_t = 0.15;         // camera FPC crossing over the socket (Seeed spec 0.12 ± 0.03)
xiao_ribbon_v = 8.92;    // centre of the camera FPC connector across the board (STEP)

xiao_wall_gap = 1.4;     // gap between the XIAO back (hot face, BAT-pad joints) and the front wall. 1.4 keeps T = 11.78, so T + 0.2 print tolerance <= 12.0 (was 1.6 -> T = 11.98, which could print at 12.18)

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
//  SWITCH / BUTTON, remaining parameters
// =============================================================================
sw_tol = 0.2;            // body tolerance ASSUMED
sw_tip_proud = 0.5;      // handle tip above the front surface
sw_scoop_d   = 0.8;      // fingernail scoop around the slot
sw_cradle_wall = 0.8;
tact_tol = 0.2;  tact_travel = 0.25;
tact_leg_clear = 2.0;    // room for the legs below the body. TRIM the legs to <= 1.8 mm
btn_d = 5.0;  btn_flange_d = 7.0;  btn_flange_t = 0.8;  btn_stem_d = 3.0;
btn_gap   = 0.20;        // cap never touches the plunger by itself
btn_proud = 0.40;        // cap above the front face
btn_free  = 0.45;        // extra counterbore depth: btn_gap + tact_travel
tact_cradle_wall = 0.8;

// =============================================================================
//  ANTENNA RULES
// =============================================================================
ant_keep = 5.0;          // RULE: antenna >= 5 mm from any other metal
ant_cell_clear = 10.0;   // RULE: antenna >= 10 mm from the cell foil
ant_wall_gap = 3.0;      // Seeed staff: leave 3-5 mm between the antenna and the plastic
ant_rim  = 1.5;          // adhesive rim of the carrier frame (the radiating area is over an open window)
carrier_t = 0.8;         // carrier frame thickness
finger_clr = 3.0;        // RULE: finger room each side of every mated plug, open to the back

// =============================================================================
//  WIRES, LANES AND LAYOUT CLEARANCES
// =============================================================================
wire_pwr_d = 1.2;  wire_sig_d = 0.8;  lane_spare = 1.0;
laneA_w = 0.5 + wire_sig_d + lane_spare + 0.4;   // XIAO castellation side
ribbon_bay = 6.0;
ribbon_run = 9.0;        // XIAO block -> camera block: room for the 45-degree jog of the 6 mm ribbon
lane_g  = 2.0;           // clearance / wire lane between blocks
therm_g = 4.0;           // air gap from the cell to the hot boards (bq25185, XIAO)
lane_t  = 3.5;           // wire lane between the cell and the band above it (switch, button, LOAD wires)
lane_cell_g = 4.0;       // gap between the power block and the cell block (cell-lead column)
strain_post_d = 2.0;     // strain-relief tie posts
strain_post_z = 3.0;     // posts end this far above the plug

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
//  DERIVED: Z (thickness) budget. HARD LIMIT: T <= max_T
// =============================================================================
kept = true;                                             // JST-PH connectors kept on both boards
xiao_h = xiao_stack_h;                                   // no microSD card (your answer)
Ri   = style == "rounded" ? max(0, corner_r - wall) : 0;
corner_keep = Ri * (1 - 1/sqrt(2));
cell_t_hi = cell_t * (1 + cell_tol_pct);                 // thickness at +5 %
H_xiao = xiao_wall_gap + xiao_h + ribbon_t + clr_z;
H_cell = cell_rail_h + cell_t_hi + cell_swell + tol_small;
H_bq   = bq_gap + bq_pcb_t + bq_jst_h + clr_z;
H_mx   = mx_gap + mx_pcb_t + mx_jst_h + clr_z;
H_cam  = (0.8 + pad_float) + cam_block_h + cam_plate_t + win_recess_extra + win_t;
H_tact = has_button ? tact_leg_clear + tact_h + btn_gap + btn_flange_t + btn_free : 0;
H_sw   = 0.3 + sw_pin_l + sw_h + sw_handle_h - sw_tip_proud - wall;
usb_boss_t = usb_well_d + usb_inner_wall;
Hi = max(H_xiao, H_cell, H_bq, H_mx, H_cam, H_tact, H_sw);
T  = plug_t + Hi + wall;
Zi0 = plug_t;
Zw  = T - wall;
Zxb = Zw - xiao_wall_gap;       // XIAO flipped: back of the XIAO PCB faces the front wall
Zxs = Zxb - xiao_h;
Zbq = Zi0 + bq_gap;
Zmx = Zi0 + mx_gap;
Zc  = Zi0 + cell_rail_h;
Zab = (Zi0 + Zw)/2 - ant_t/2;   // antenna bottom: centred between the plug and the front wall

// camera chain (front wall -> disc -> stop plate -> head)
Zplate_top = Zw - win_t - win_recess_extra;
Zplate_bot = Zplate_top - cam_plate_t;
Zlens      = Zplate_bot + cam_barrel_h;
Zcam0      = Zplate_bot - cam_block_h;
cam_gap_disc = (Zw - win_t) - Zlens;
// switch chain
Zsw_top = T + sw_tip_proud - sw_handle_h;
Zsw_bot = Zsw_top - sw_h;
sw_boss_t = T - Zsw_top;
// tact chain
Ztb = Zi0 + tact_leg_clear;
Ztt = Ztb + tact_h;

// derived part sizes
sw_cradle  = [sw_l + sw_tol + 2*fit_slide_bought + 2*sw_cradle_wall,
              sw_w + sw_tol + 2*fit_slide_bought + 2*sw_cradle_wall];
tact_pocket = tact_w + tact_tol + 2*fit_glue_bought;
btn_cbore_d = btn_flange_d + 2*fit_pp_slide;
tact_cradle = max(tact_pocket, btn_cbore_d) + 2*tact_cradle_wall;
win_pocket_d = win_d + win_tol + 2*fit_glue_bought;
cam_ring_od  = win_pocket_d + 2*win_ring_wall;
cam_pocket   = cam_w + cam_tol + 2*fit_slide_bought;
cam_cradle_o = cam_pocket + 2*cam_cradle_wall;
cam_blk      = cam_ring_od + 0.6;
fov_t = tan(cam_fov/2);
lens_r_in  = win_pocket_d/2 - fit_glue_bought - win_tol/2 - win_lip;
lens_r_req_in  = cam_aperture_d/2 + (cam_gap_disc + win_t) * fov_t;
lens_r_out = lens_r_in + wall * fov_t;
fov_max = 2 * atan((lens_r_in - cam_aperture_d/2) / (cam_gap_disc + win_t));

// =============================================================================
//  DERIVED: plan layout (outer coordinates). Everything follows from the sizes above.
//    left column  : power block P = bq25185 (USB-C on the Y = 0 wall) + 14 mm JST-PH gap + MAX17048
//    bottom band  : cell (lead end towards P), 4 mm from P
//    band above   : XIAO, camera (ribbon straight to it), button, antenna, switch
// =============================================================================
xpost = 1.3;
bq_jst_c = [for (j = bq_jst) (j[0] + j[1])/2];
mx_jst_c = [for (j = mx_jst) (j[0] + j[1])/2];
function s_bend(d, r) = d >= 2*r ? 2*r : 2*sqrt(r*d - d*d/4);

// ---- power block P, local frame (x_p along the stack, y_p across). P_T() maps it to outer X, Y
P_w = bq_l + 2*clr_board;
p_y_bq0 = clr_board;
p_y_mx0 = P_w - clr_board - mx_l;                 // MAX against the left side; its QT strip (6.35) faces the XIAO
p_x_row1 = usb_boss_t + clr_board;
p_row1_end = p_x_row1 + bq_d;
jump_d = abs((p_y_bq0 + bq_jst_c[0]) - (p_y_mx0 + mx_jst_c[0]));
ph_gap_mouth = max(2*ph_hsg_len,
                   2*ph_out + 2*ph_straight + s_bend(jump_d, ph_bend_r),
                   ph_hsg_len + ph_straight + ph_bend_r + ph_out);
x_bq_mouth = p_row1_end - ph_mouth_bq;
gap12 = max(ph_gap_mouth + (x_bq_mouth - p_row1_end) - clr_board - ph_mouth_mx, ribbon_bay);
p_x_row2 = p_row1_end + gap12;
p_x_mx0 = p_x_row2 + clr_board;
P_len = p_x_mx0 + mx_d + clr_board;
x_p0 = wall + corner_keep;
x_pr = x_p0 + P_w;                                // right edge of P (outer X)
usb_y = p_y_bq0 + (bq_usb[0] + bq_usb[1])/2;
usb_z = Zbq + (bq_usb[4] + bq_usb[5])/2;

// ---- cell block (bottom band)
cell_pocket_l = cell_l + cell_margin_l + tol_small;
cell_pocket_w = cell_w + cell_margin_w + tol_small;
x_cb = x_pr + lane_cell_g;
x_cell = x_cb + cell_head_zone;
x_cbr = x_cell + cell_pocket_l;
y_cell0 = wall;
y_th = y_cell0 + cell_pocket_w;
x_cellb = x_cell + cell_margin_l/2 + tol_small/2;
y_cellb = y_cell0 + (cell_pocket_w - cell_w)/2;
cell_cy = y_cellb + cell_w/2;

// ---- XIAO block (band above the cell)
XB_w = 0.2 + xpost + 0.1 + xiao_usb_over + xiao_pcb_l + xiao_exp_over + 0.1 + xpost + 0.2;
XB_h = laneA_w + xiao_pcb_w + 3.0;
x_x = x_pr + lane_g;
x_xr = x_x + XB_w;
y_tb = y_th + therm_g;
Xx0 = x_x + 0.2 + xpost + 0.1 + xiao_usb_over;
Yx0 = y_tb + laneA_w;
xiao_far = Xx0 + xiao_pcb_l + xiao_exp_over;
function xy_v(v) = Yx0 + xiao_pcb_w - v;
rib_y = xy_v(xiao_ribbon_v);
rib_half = cam_ribbon_w/2 + 0.2;                  // ribbon lane half-width

// ---- camera (straight run from the XIAO connector, then a short jog), button, antenna, switch
y_cam_b = y_th + lane_t;
cam_x = x_xr + ribbon_run + cam_blk/2;
cam_y = y_cam_b + cam_blk/2;
cam_jog = abs(cam_y - rib_y);
tab_on = ant_place != "inside";
a_ax = ant_rot == 0 ? ant_l : ant_w;              // antenna box size along X / Y after rotation
a_ay = ant_rot == 0 ? ant_w : ant_l;
v_ax = tab_on ? 0 : a_ax;                         // what the MAIN body has to hold (nothing, when the antenna is in a tab)
v_ay = tab_on ? 0 : a_ay;
x_a_in = x_xr + ant_keep;                         // inside the body: 5 mm from the XIAO block
y_a_in = max(y_cam_b + cam_blk + ant_keep, rib_y + rib_half + ant_keep);   // 5 mm above the camera block AND the ribbon
free_br = (max_L - wall) - 0.5 - x_cbr - lane_g;  // free width right of the cell block
smalls_bottom = smalls_place == "corner" ? true : smalls_place == "band" ? false : free_br >= max(sw_cradle[0], tact_cradle);
tact_x = smalls_bottom ? x_cbr + lane_g + tact_cradle/2 : cam_x + cam_blk/2 + lane_g + tact_cradle/2;
tact_y = smalls_bottom ? y_cell0 + 1.0 + tact_cradle/2 : y_cam_b + tact_cradle/2;
sw_x = smalls_bottom ? x_cbr + lane_g + sw_cradle[0]/2 : tab_on ? cam_x : x_a_in + v_ax + ant_keep + sw_cradle[0]/2;   // antenna in a tab: switch goes above the camera
sw_y = smalls_bottom ? tact_y + tact_cradle/2 + lane_g + sw_cradle[1]/2 : tab_on ? y_cam_b + cam_blk + lane_g + sw_cradle[1]/2 : y_a_in + sw_cradle[1]/2;

right_extent = max(x_cbr + 0.5, x_a_in + v_ax + ant_wall_gap, cam_x + cam_blk/2 + 0.5,
                   tact_x + tact_cradle/2 + 0.5, sw_x + sw_cradle[0]/2 + 0.5);
top_extent   = max(P_len + 0.5, y_tb + XB_h, y_a_in + v_ay + ant_wall_gap, sw_y + sw_cradle[1]/2 + 0.5);
L  = right_extent + wall;
W  = top_extent + wall;
Li = L - 2*wall;
Wi = W - 2*wall;
y0 = wall;
y_hi = y0 + Wi;

y_gate = p_row1_end + gap12/2;                    // Y where the cell leads cross into P's gap
// ---- antenna placement: inside the body, or in a tab on the +X / +Y end.
// Metal the antenna must stay clear of (XY boxes: x0, y0, x1, y1, clearance, name). The check is the same box-against-box test as the
// antenna_keepout / antenna_cellzone pairs below, so the automatic position is verified again by CGAL.
ant_metals = concat(
    [[x_cellb, y_cellb, x_cellb + cell_l, y_cellb + cell_w, ant_cell_clear, "cell foil"]],
    [[x_pr - (p_y_bq0 + bq_l), p_x_row1, x_pr - p_y_bq0, p_row1_end, ant_keep, "bq25185"]],
    [[x_pr - (p_y_mx0 + mx_l), p_x_mx0, x_pr - p_y_mx0, p_x_mx0 + mx_d, ant_keep, "MAX17048"]],
    [for (z = P_zone_list()) let(b = pm3(z[0], z[1])) [b[0], b[1], b[3], b[4], ant_keep, "JST plug zone"]],
    [[Xx0 - xiao_usb_over, Yx0, xiao_far, Yx0 + xiao_pcb_w, ant_keep, "XIAO"]],
    [[cam_x - cam_blk/2, cam_y - cam_blk/2, cam_x + cam_blk/2, cam_y + cam_blk/2, ant_keep, "camera"]],
    [[sw_x - sw_l/2, sw_y - sw_w/2, sw_x + sw_l/2, sw_y + sw_w/2, ant_keep, "slide switch"]],
    has_button ? [[tact_x - tact_w/2, tact_y - tact_w/2, tact_x + tact_w/2, tact_y + tact_w/2, ant_keep, "button"]] : [],
    [for (b = lane_boxes()) [b[0], b[1], b[3], b[4], ant_keep, "wire lane"]]);
function cands(lo, hi) = hi >= lo ? [for (p = [lo : 0.5 : hi]) p] : [];
function hit_x(m, ya) = ya - m[4] < m[3] - eps && ya + a_ay + m[4] > m[1] + eps;     // keep-out box overlaps the metal in Y
function hit_y(m, xa) = xa - m[4] < m[2] - eps && xa + a_ax + m[4] > m[0] + eps;     // ... in X
function need_x(ya) = max(concat([wall + ant_wall_gap], [for (m = ant_metals) if (hit_x(m, ya)) m[2] + m[4]]));   // smallest x_a at this Y
function need_y(xa) = max(concat([wall + ant_wall_gap], [for (m = ant_metals) if (hit_y(m, xa)) m[3] + m[4]]));   // smallest y_a at this X
function who_x(ya) = let(v = [for (m = ant_metals) hit_x(m, ya) ? m[2] + m[4] : -1e9])
                     max(v) < wall + ant_wall_gap ? "plastic wall" : ant_metals[search(max(v), v)[0]][5];
function who_y(xa) = let(v = [for (m = ant_metals) hit_y(m, xa) ? m[3] + m[4] : -1e9])
                     max(v) < wall + ant_wall_gap ? "plastic wall" : ant_metals[search(max(v), v)[0]][5];
tab_yc = cands(wall + ant_wall_gap, W - wall - ant_wall_gap - a_ay);       // positions along the +X end
tab_xc = cands(wall + ant_wall_gap, L - wall - ant_wall_gap - a_ax);       // positions along the +Y side
tab_nx = [for (y = tab_yc) need_x(y)];
tab_ny = [for (x = tab_xc) need_y(x)];
tab_ya = ant_tab_pos >= 0 ? ant_tab_pos : (len(tab_yc) > 0 ? tab_yc[search(min(tab_nx), tab_nx)[0]] : 0);
tab_xa = ant_tab_pos >= 0 ? ant_tab_pos : (len(tab_xc) > 0 ? tab_xc[search(min(tab_ny), tab_ny)[0]] : 0);
x_a = !tab_on ? x_a_in : ant_place == "tab_x" ? need_x(tab_ya) : tab_xa;
y_a = !tab_on ? y_a_in : ant_place == "tab_x" ? tab_ya : need_y(tab_xa);
tab_xe = x_a + a_ax + ant_wall_gap + wall;        // outer end of a +X tab
tab_ye = y_a + a_ay + ant_wall_gap + wall;        // outer end of a +Y tab
tab_x_on = ant_place == "tab_x" && tab_xe > L + eps;
tab_y_on = ant_place == "tab_y" && tab_ye > W + eps;
Lt = tab_x_on ? tab_xe : L;                       // total outer size including the tab
Wt = tab_y_on ? tab_ye : W;
// tab rectangles: outer (overlapping the body end so the union is one solid) and cavity
tab_o = tab_x_on ? [L - 3*corner_r, y_a - ant_wall_gap - wall, tab_xe, y_a + a_ay + ant_wall_gap + wall]
      : tab_y_on ? [x_a - ant_wall_gap - wall, W - 3*corner_r, x_a + a_ax + ant_wall_gap + wall, tab_ye] : [0, 0, 0, 0];
tab_c = tab_x_on ? [L - wall - 1, y_a - ant_wall_gap, tab_xe - wall, y_a + a_ay + ant_wall_gap]
      : tab_y_on ? [x_a - ant_wall_gap, W - wall - 1, x_a + a_ax + ant_wall_gap, tab_ye - wall] : [0, 0, 0, 0];

// plug fit (per side), long dimension rule
plug_fx = tol(Lt - 2*wall) + (plug_mode == "permanent" ? glue_film : 0);
plug_fy = tol(Wt - 2*wall) + (plug_mode == "permanent" ? glue_film : 0);

// cell-lead route length (lead zone -> column -> across P's gap -> MAX JST #2)
cell_lead_need = (x_cb - x_pr) + abs(y_gate - cell_cy) + (x_pr - (x_pr - (p_y_mx0 + mx_jst_c[1])))
                 + 2*(ph_out + ph_straight) + 10;
cell_dist_ant = sqrt(pow(max(0, x_cellb - (x_a + a_ax), x_a - (x_cellb + cell_l)), 2)
                   + pow(max(0, y_cellb - (y_a + a_ay), y_a - (y_cellb + cell_w)), 2));

// =============================================================================
//  ASSERTS (computed from the parameters; each message names the dimension that fails)
// =============================================================================
function lim_tol(x) = limits_at_worst_case ? tol(x) : 0;   // printing tolerance added before comparing with the hard limits
// XIAO U.FL socket centre (STEP: u 17.734-20.734, v 2.613-5.713, w 1.25-2.5) and the straight line from it to the antenna box.
// This is a LOWER bound on the cable length: the real route goes around the XIAO / camera ribbon and is longer. Slack is not modelled.
ufl_pt = [Xx0 + 19.234, xy_v(4.163), Zxb - 1.875];
ant_cable_min = norm([max(x_a - ufl_pt[0], 0, ufl_pt[0] - (x_a + a_ax)),
                      max(y_a - ufl_pt[1], 0, ufl_pt[1] - (y_a + a_ay)),
                      max(Zab - ufl_pt[2], 0, ufl_pt[2] - (Zab + ant_t))]);
assert(ant_cable_len >= ant_cable_min, str("ANTENNA CABLE: the straight line from the XIAO U.FL socket to the antenna is ", ant_cable_min, " mm, the listing cable is only ", ant_cable_len, " mm"));
assert(wall - tol_small >= min_wall, "outer wall below the 0.8 mm minimum after tolerance");
assert(plug_t - tol_small >= min_wall, "plug below the 0.8 mm minimum after tolerance");
assert(tact_h <= 6.0, "BUTTON RULE: tact_h must be <= 6.0 mm");
assert(!enforce_limits || T + lim_tol(T) <= max_T + 1e-6, str("THICKNESS: T = ", T, " (worst case printed ", T + lim_tol(T), ") > ", max_T, ". Thickest item: see the Thickness drivers line"));
assert(!enforce_limits || L + lim_tol(L) <= max_L + 1e-6, str("LENGTH: outer L = ", L, " (worst case printed ", L + lim_tol(L), ") > ", max_L, ". Something in the layout is too long: cell block ", x_cbr, ", antenna row ", x_a_in + v_ax + ant_wall_gap, ", camera/button ", cam_x + cam_blk/2, ", switch ", sw_x + sw_cradle[0]/2));
assert(!enforce_limits || W + lim_tol(W) <= max_W + 1e-6, str("WIDTH: outer W = ", W, " (worst case printed ", W + lim_tol(W), ") > ", max_W));
assert(!enforce_limits || Lt + lim_tol(Lt) <= max_L + tab_budget + 1e-6, str("TAB LENGTH: total L = ", Lt, " (worst case printed ", Lt + lim_tol(Lt), ") > ", max_L, " + tab_budget ", tab_budget));
assert(!enforce_limits || Wt + lim_tol(Wt) <= max_W + tab_budget + 1e-6, str("TAB WIDTH: total W = ", Wt, " (worst case printed ", Wt + lim_tol(Wt), ") > ", max_W, " + tab_budget ", tab_budget));
assert(!tab_on || (ant_place == "tab_x" ? len(tab_yc) > 0 : len(tab_xc) > 0), "TAB: the antenna is longer than the edge it should sit on");
assert(!tab_on || ant_tab_pos < 0 || (ant_place == "tab_x" ? (ant_tab_pos >= wall + ant_wall_gap - eps && ant_tab_pos <= W - wall - ant_wall_gap - a_ay + eps)
                                                         : (ant_tab_pos >= wall + ant_wall_gap - eps && ant_tab_pos <= L - wall - ant_wall_gap - a_ax + eps)), "TAB: ant_tab_pos is outside the body edge");
assert(!tab_on || ant_tab_pos < 0 || (ant_place == "tab_x" ? ant_tab_pos >= 0 : true), "TAB: bad ant_tab_pos");
assert(Zw - (Zc + cell_t_hi) - tol_small >= cell_swell - eps, "SWELL RULE: less than 0.8 mm above the cell at +5 % thickness");
assert(H_cell <= Hi + eps, "cell too thick for the thickness budget");
assert(cell_dist_ant >= ant_cell_clear - eps, str("ANTENNA RULE: antenna is only ", cell_dist_ant, " mm from the cell foil (need ", ant_cell_clear, ")"));
assert(Zab - Zi0 >= ant_wall_gap - eps, "antenna closer than ant_wall_gap to the plug");
assert(Zw - (Zab + ant_t) >= ant_wall_gap - eps, "antenna closer than ant_wall_gap to the front wall (antenna too thick)");
assert(cam_jog <= 8.0 + eps, str("RIBBON: camera sideways jog ", cam_jog, " > 8 mm"));
assert(cam_jog <= 2.0 + eps || ribbon_run >= 9.0 - eps, "RIBBON: a jog needs ribbon_run >= 9 mm");
assert(lens_r_in >= lens_r_req_in, str("lens opening clips the FOV: need r ", lens_r_req_in, " have ", lens_r_in, ". Max FOV here = ", fov_max));
assert(cam_gap_disc - tol_small >= 0.2, "camera barrel can come within 0.2 mm of the window");
assert(cam_plate_t >= cam_barrel_h + 0.3 - eps, "barrel would reach the disc");
assert(sw_boss_t >= wall, "switch handle too short for this wall: lower sw_tip_proud");
assert(sw_boss_t - sw_scoop_d - tol_small >= min_wall - eps, "wall under the switch scoop too thin");
assert(Zsw_bot - sw_pin_l - Zi0 >= 0.3 - eps, "switch pins hit the plug: trim pins / lower sw_pin_l");
assert(!has_button || (Zw - btn_flange_t - btn_free) - (Ztt + btn_gap) >= -eps, "tact switch too tall for this thickness");
assert(usb_z - usb_well_h/2 - Zi0 >= 0.8, "web under the USB well < 0.8");
assert(gap12 >= ribbon_bay, "row gap too small for the ribbon fold");
assert(ph_gap_mouth >= 2*ph_hsg_len - eps, "gap shorter than both JST-PH housings fully withdrawn");
assert(laneA_w >= wire_pwr_d + lane_spare - eps, "wire lane too narrow for the stacked cell leads");

// =============================================================================
//  REPORT
// =============================================================================
echo(str("OUTER SIZE (", style, ", cell ", cell_code, " ", cell_t, "x", cell_w, "x", cell_l, ", antenna ", ant_type, " ", ant_l, "x", ant_w,
         "): L x W x T = ", L, " x ", W, " x ", T, " mm   (limits ", max_L, " x ", max_W, " x ", max_T, ")"));
echo(str("WORST-CASE PRINTED SIZE (nominal + tolerance): ", L + tol(L), " x ", W + tol(W), " x ", T + tol(T), " mm   limits are checked ", limits_at_worst_case ? "at this size" : "at the nominal size"));
echo(str("Thickness drivers: XIAO ", H_xiao, " cell ", H_cell, " bq ", H_bq, " MAX ", H_mx, " camera ", H_cam, " button ", H_tact, " switch ", H_sw, " -> interior ", Hi));
echo(str("Swell room above the cell at +5 %: ", Zw - (Zc + cell_t_hi), " mm (rule 0.8 + 0.2 print tolerance); XIAO back to front wall ", xiao_wall_gap, " mm"));
echo(str("Layout X: P ", x_p0, "..", x_pr, "  cell block ", x_cb, "..", x_cbr, "  XIAO ", x_x, "..", x_xr, "  camera ", cam_x - cam_blk/2, "..", cam_x + cam_blk/2,
         "  antenna ", x_a, "..", x_a + a_ax, "  buttons/switch: ", smalls_bottom ? "bottom right" : "band above the cell"));
echo(str("Layout Y: P 0..", P_len, "  cell ", y_cell0, "..", y_th, "  XIAO ", y_tb, "..", y_tb + XB_h, "  antenna ", y_a, "..", y_a + a_ay));
echo(str("ANTENNA PLACEMENT: ", ant_place, ", rotation ", ant_rot, ", box x ", x_a, "..", x_a + a_ax, " y ", y_a, "..", y_a + a_ay,
         tab_on ? str(", binding metal: ", ant_place == "tab_x" ? who_x(y_a) : who_y(x_a)) : ""));
echo(str("TOTAL OUTER SIZE incl. tab: ", Lt, " x ", Wt, " x ", T, " mm   main body ", L, " x ", W, "   extra over ", max_L, " x ", max_W, ": length ", max(0, Lt - max_L), ", width ", max(0, Wt - max_W),
         "   tab ", tab_x_on ? "on the +X end" : tab_y_on ? "on the +Y side" : "not needed (antenna fits inside the main footprint)"));
echo(str("Antenna cable: straight line from the XIAO U.FL socket to the antenna box = ", ant_cable_min, " mm (lower bound, the real route is longer); listing cable ", ant_cable_len, " mm"));
echo(str("Antenna: ", cell_dist_ant, " mm from the cell foil (rule 10); ", ant_keep, " mm keep-out from other metal; ", Zab - Zi0, " mm to the plug, ", Zw - Zab - ant_t, " mm to the front wall"));
echo(str("JST-PH gap in P: mouth-to-mouth ", ph_gap_mouth, " (jumper offset ", jump_d, ") -> gap ", gap12, ". Cell leads needed about ", cell_lead_need, " mm; listing says ", cell_lead_len, " mm: ",
         cell_lead_len >= cell_lead_need ? "OK" : "TOO SHORT, add a JST-PH pigtail"));
echo(str("Ribbon: camera jog ", cam_jog, " mm over a run of ", ribbon_run, " mm (not simulated)"));
echo(str("Plug fit per side: X ", plug_fx, "  Y ", plug_fy));

// =============================================================================
//  2D / 3D HELPERS (copied from powerbank.scad)
// =============================================================================
function tol(L) = L < 100 ? tol_small : tol_pct * L;
module rrect(s, r) {                     // rounded rectangle, corner at origin
    if (r <= eps) square(s);
    else translate([r, r]) offset(r = r) square([s[0] - 2*r, s[1] - 2*r]);
}
module rbox(s, r) linear_extrude(s[2]) rrect([s[0], s[1]], r);
module cbox(c, s) translate([c[0] - s[0]/2, c[1] - s[1]/2, c[2]]) cube(s);
module rrect_c(w, h, r) translate([-w/2, -h/2]) rrect([w, h], r);
module stadium(w, h) {                   // centred 2D stadium, long axis along X
    hull() { translate([-(w - h)/2, 0]) circle(d = h); translate([(w - h)/2, 0]) circle(d = h); }
}
module bx(p0, p1) translate(p0) cube([p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]]);
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
module rect_solid(x0, y0, x1, y1) {
    if (style == "rounded")
        hull() for (x = [x0 + corner_r, x1 - corner_r], y = [y0 + corner_r, y1 - corner_r])
            translate([x, y, 0]) rotate_extrude($fn = max($fn, 48)) corner_profile(corner_r, T, edge_r_front, edge_r_back);
    else translate([x0, y0, 0]) cube([x1 - x0, y1 - y0, T]);
}
module outer_solid() {
    rect_solid(0, 0, L, W);
    if (tab_x_on || tab_y_on) rect_solid(tab_o[0], tab_o[1], tab_o[2], tab_o[3]);
}
module tab_shape(x0, y0, x1, y1, r) {      // rounded at the free end only; the end next to the body is square
    translate([x0, y0]) rrect([x1 - x0, y1 - y0], r);
    if (tab_x_on) translate([x0, y0]) square([min(2*r, x1 - x0), y1 - y0]);
    if (tab_y_on) translate([x0, y0]) square([x1 - x0, min(2*r, y1 - y0)]);
}
module cavity_2d() {
    translate([wall, wall]) rrect([Li, Wi], Ri);
    if (tab_x_on || tab_y_on) tab_shape(tab_c[0], tab_c[1], tab_c[2], tab_c[3], Ri);
}
module cavity_solid(z0 = -1, z1 = Zw) translate([0, 0, z0]) linear_extrude(z1 - z0) cavity_2d();

// =============================================================================
//  POWER BLOCK P: local frame (x_p, y_p) -> outer (X, Y) = (x_pr - y_p, x_p).  USB-C end on the Y = 0 wall.
// =============================================================================
module P_T() translate([x_pr, 0, 0]) rotate(90) children();
function bq_place_xy(p) = [p_row1_end - p[1], p_y_bq0 + p[0]];
function mx_place_xy(p) = [p_x_mx0 + mx_d - p[1], p_y_mx0 + p[0]];
function place_xy(kind, p) = kind == "bq" ? bq_place_xy(p) : mx_place_xy(p);
module board_posts(kind, shoulder_d, z_top, z_bot) {
    pin_d = bq_hole_d - 2*fit_pin_pcb;
    for (h = (kind == "bq" ? bq_holes : mx_holes)) {
        q = place_xy(kind, h);
        translate([q[0], q[1], z_top]) cylinder(d = shoulder_d, h = Zw - z_top + eps);
        translate([q[0], q[1], z_bot - 0.4]) cylinder(d = pin_d, h = z_top - z_bot + 0.4 + eps);
    }
}
module usb_boss_p() bx([wall - eps, usb_y - usb_well_w/2 - 0.8, Zi0],
                       [usb_boss_t, usb_y + usb_well_w/2 + 0.8 + pry_w, usb_z + usb_well_h/2 + 0.8]);
// strain relief, site B: two tie posts flank the jumper / LOAD cables in P's gap (outside the finger columns)
module anchors_P() for (yp = [1.0, P_w - 1.0])
    translate([p_row1_end + gap12/2, yp, Zi0 + strain_post_z]) cylinder(d = strain_post_d, h = Zw - (Zi0 + strain_post_z) + eps);
module P_body() {
    usb_boss_p();
    board_posts("bq", 3.6, Zbq + bq_pcb_t, Zbq);
    board_posts("mx", 3.4, Zmx + mx_pcb_t, Zmx);
    anchors_P();
}
module P_cuts() {
    translate([-1, usb_y, usb_z]) rotate([0, 90, 0]) rotate(90) linear_extrude(1 + usb_well_d) stadium(usb_well_w, usb_well_h);
    translate([usb_well_d - eps, usb_y, usb_z]) rotate([0, 90, 0]) rotate(90)
        linear_extrude(usb_inner_wall + 1) rrect_c(usb_open_w, usb_open_h, usb_open_r);
    translate([-1, usb_y + usb_well_w/2 - 0.6, usb_z - 1.2]) cube([1 + 0.8, pry_w + 0.6, 2.4]);   // fingernail scoop
}

// =============================================================================
//  OTHER BODY FEATURES (global frame)
// =============================================================================
module xiao_posts() {
    zb = Zxb - xiao_pcb_t - 0.3;
    for (vv = [[4.412 - fit_slide_bought - 1.6, 4.412 - fit_slide_bought],
               [13.352 + fit_slide_bought, 13.352 + fit_slide_bought + 1.6]])
        bx([Xx0 - 0.1 - xpost, xy_v(vv[1]), zb], [Xx0 - 0.1, xy_v(vv[0]), Zw + eps]);
    for (vv = [[2.0, 3.6], [14.18, 15.78]])
        bx([xiao_far + 0.1, xy_v(vv[1]), zb], [xiao_far + 0.1 + xpost, xy_v(vv[0]), Zw + eps]);
}
module camera_bezel() {
    translate([cam_x, cam_y, 0]) {
        // ring that locates the disc (disc glued to the front-wall lip)
        translate([0, 0, Zplate_bot]) cylinder(d = cam_ring_od, h = Zw - Zplate_bot + eps);
        // cradle around the head
        translate([-cam_cradle_o/2, -cam_cradle_o/2, Zplate_bot - cam_cradle_depth])
            cube([cam_cradle_o, cam_cradle_o, cam_cradle_depth + eps]);
    }
}
module switch_boss() {
    cbox([sw_x, sw_y, Zsw_top], [sw_cradle[0], sw_cradle[1], Zw - Zsw_top + eps]);
    cbox([sw_x, sw_y, Zsw_bot + 1.0], [sw_cradle[0], sw_cradle[1], Zsw_top - Zsw_bot - 1.0 + eps]);
}
module tact_cradle_solid() {
    cbox([tact_x, tact_y, Ztb + 1.0], [tact_cradle, tact_cradle, Zw - Ztb - 1.0 + eps]);
}
module cell_stops() {
    for (yy = [y_cellb + 1.75, y_cellb + cell_w - 1.75])
        translate([x_cell - 1.25, yy, Zc + 1.5]) cylinder(d = 2.5, h = Zw - Zc - 1.5 + eps);
}

// antenna holder: a plastic frame at mid-height hangs from the front wall on two posts. The antenna's adhesive back sticks to
// the rim, so its radiating area is over an open window and it is >= ant_wall_gap from the walls (Seeed staff advice).
module ant_holder(xa = x_a, ya = y_a) {
    px = ant_wall_gap - 0.5; py = 1.0;                                   // plate overhang beyond the antenna: ends / sides
    win = [max(0, a_ax - 2*ant_rim), max(0, a_ay - 2*ant_rim)];
    translate([0, 0, Zab - carrier_t]) linear_extrude(carrier_t) difference() {
        translate([xa - px, ya - py]) square([a_ax + 2*px, a_ay + 2*py]);
        if (win[0] > 0 && win[1] > 0) translate([xa + ant_rim, ya + ant_rim]) square(win);
    }
    for (xx = [xa - px + 1.0, xa + a_ax + px - 1.0])
        translate([xx, ya + a_ay/2, Zab - carrier_t]) cylinder(d = strain_post_d, h = Zw - (Zab - carrier_t) + eps);
}
// strain relief, site A: two tie posts flank the cell leads at the lead zone
module anchors_cell() for (dy = [-4.5, 4.5])
    translate([x_cb + cell_head_zone/2, cell_cy + dy, Zi0 + strain_post_z]) cylinder(d = strain_post_d, h = Zw - (Zi0 + strain_post_z) + eps);
module ledges() {
    for (x = [x_cell + 10, x_cell + cell_pocket_l/2, x_cbr - 8])
        bx([x - ledge_len/2, wall - eps, Zi0], [x + ledge_len/2, wall + ledge_d, Zi0 + ledge_h]);
    for (y = [12, 32, 52])
        bx([wall - eps, y - ledge_len/2, Zi0], [wall + ledge_d, y + ledge_len/2, Zi0 + ledge_h]);
    for (y = [y_cell0 + 8, y_th - 8]) if (!(tab_x_on && y + ledge_len/2 > tab_c[1] - 1 && y - ledge_len/2 < tab_c[3] + 1))   // none where the tab opens the wall
        bx([L - wall - ledge_d, y - ledge_len/2, Zi0], [L - wall + eps, y + ledge_len/2, Zi0 + ledge_h]);
    for (x = [x_x + 6, x_xr - 6]) if (!(tab_y_on && x + ledge_len/2 > tab_c[0] - 1 && x - ledge_len/2 < tab_c[2] + 1))
        bx([x - ledge_len/2, W - wall - ledge_d, Zi0], [x + ledge_len/2, W - wall + eps, Zi0 + ledge_h]);
}
module internal_features() {
    P_T() P_body();
    xiao_posts();
    camera_bezel();
    switch_boss();
    if (has_button) tact_cradle_solid();
    cell_stops();
    anchors_cell();
    ant_holder();
    ledges();
}

// =============================================================================
//  CUTS
// =============================================================================
module lens_cuts() translate([cam_x, cam_y, 0]) {
    translate([0, 0, Zw - eps]) cylinder(r1 = lens_r_in, r2 = lens_r_out, h = wall + 2*eps);
    translate([0, 0, Zplate_top]) cylinder(d = win_pocket_d, h = Zw - Zplate_top + eps);
    translate([0, 0, Zplate_bot - eps]) cylinder(d = cam_barrel_d + cam_tol + 2*fit_slide_bought, h = cam_plate_t + 2*eps);
    translate([-cam_pocket/2, -cam_pocket/2, Zplate_bot - cam_cradle_depth - 1]) cube([cam_pocket, cam_pocket, cam_cradle_depth + 1 + eps]);
    // ribbon port on the -X side, towards the XIAO
    translate([-cam_pocket/2 - cam_cradle_wall - 1 + eps, -(cam_ribbon_w + lane_spare)/2, Zplate_bot - cam_cradle_depth - 1])
        cube([cam_cradle_wall + 1, cam_ribbon_w + lane_spare, cam_cradle_depth + 1]);
}
module switch_cuts() {
    slot = [sw_travel + sw_handle + 2*tol_hole, sw_handle + 2*tol_hole];
    translate([sw_x - slot[0]/2, sw_y - slot[1]/2, Zsw_top - eps]) cube([slot[0], slot[1], T]);
    translate([sw_x, sw_y, T - sw_scoop_d]) linear_extrude(1)
        offset(r = 1.2) square([slot[0] + 2*2.0 - 2.4, slot[1] + 2*1.4 - 2.4], center = true);
    cbox([sw_x, sw_y, Zsw_bot - 1], [sw_l + sw_tol + 2*fit_slide_bought, sw_w + sw_tol + 2*fit_slide_bought, Zsw_top - Zsw_bot + 1]);
}
module button_cuts() if (has_button) {
    translate([tact_x, tact_y, Zw - eps]) cylinder(d = btn_d + 2*fit_pp_hole, h = wall + 1);
    translate([tact_x, tact_y, Zw - btn_flange_t - btn_free]) cylinder(d = btn_cbore_d, h = btn_flange_t + btn_free + eps);
    cbox([tact_x, tact_y, Ztb], [tact_pocket, tact_pocket, Zw - btn_flange_t - btn_free - Ztb + eps]);
}
module vent_cuts() {
    vz = T/2 - vent_h/2;
    if (vents) {
        for (y = [p_x_row1 + 4 : vent_pitch : p_row1_end - 4])            // left wall beside the charger
            translate([-1, y, vz]) cube([wall + 2, vent_w, vent_h]);
        for (x = [x_x + 6 : vent_pitch : x_xr - 6])                        // top wall beside the XIAO
            translate([x, W - wall - 1, vz]) cube([vent_w, wall + 2, vent_h]);
    }
    if (cell_vents) {                                                      // relief slots beside the cell
        for (x = [x_cell + 10 : 14 : x_cbr - 10]) translate([x, -1, vz]) cube([vent_w, wall + 2, vent_h]);
        for (y = [y_cell0 + 8, y_th - 8]) translate([L - wall - 1, y, vz]) cube([wall + 2, vent_w, vent_h]);
    }
}
module body_cuts() { P_T() P_cuts(); lens_cuts(); switch_cuts(); button_cuts(); vent_cuts(); }

module body() {
    difference() {
        union() {
            difference() { outer_solid(); cavity_solid(); }
            intersection() { cavity_solid(Zi0, Zw + eps); internal_features(); }
        }
        body_cuts();
    }
}

// =============================================================================
//  BOTTOM PLUG
// =============================================================================
module plug_2d() {
    translate([wall + plug_fx, wall + plug_fy]) rrect([Li - 2*plug_fx, Wi - 2*plug_fy], max(0, Ri - min(plug_fx, plug_fy)));
    if (tab_x_on || tab_y_on)
        tab_shape(tab_x_on ? tab_c[0] : tab_c[0] + plug_fx, tab_x_on ? tab_c[1] + plug_fy : tab_c[1],     // starts where the cavity opens: it still overlaps the body plug by 1 - fit
                  tab_c[2] - plug_fx, tab_c[3] - plug_fy, max(0, Ri - max(plug_fx, plug_fy)));
}
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
    P_T() {
        for (p = [[6, 12.7], [25.75, 12.7]]) cbox(concat(bq_place_xy(p), Zi0 - eps), [3, 3, bq_gap - pad_float + eps]);
        for (p = [[12.7, 2.5], [12.7, 15.5]]) cbox(concat(mx_place_xy(p), Zi0 - eps), [3, 3, mx_gap - pad_float + eps]);
    }
    for (vv = [2.0, 15.78]) cbox([Xx0 + 13.65, xy_v(vv), Zi0 - eps], [2.2, 2.0, (Zxb - 5.43) - pad_float - Zi0 + eps]);
    cbox([cam_x + 1.5, cam_y, Zi0 - eps], [4, 4, Zcam0 - pad_float - Zi0 + eps]);       // camera backstop (away from the ribbon side)
    for (s = [-1, 1]) cbox([sw_x + s*(sw_l/2 - 0.6), sw_y, Zi0 - eps], [1.0, 2.5, Zsw_bot - pad_float - Zi0 + eps]);
    if (has_button) cbox([tact_x, tact_y, Zi0 - eps], [2.5, 2.5, Ztb - pad_float - Zi0 + eps]);
}

// =============================================================================
//  USB-C COVER and BUTTON CAP (copied)
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
module usb_cover_placed() P_T() translate([0, usb_y, usb_z]) rotate([0, 90, 0]) rotate(90) usb_cover_core();
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
//  COMPONENT DUMMIES
// =============================================================================
module cell_dummy() translate([x_cellb, y_cellb, Zc]) rbox([cell_l, cell_w, cell_t], cell_corner_r);
module cell_swollen() translate([x_cellb, y_cellb, Zc]) rbox([cell_l, cell_w, cell_t_hi + cell_swell], cell_corner_r);   // +5 % and 0.8 swell
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
module bq_dummy() P_T() translate([p_row1_end, p_y_bq0, Zbq]) rotate(90) bq_local();
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
module mx_dummy() P_T() translate([p_x_mx0 + mx_d, p_y_mx0, Zmx]) rotate(90) mx_local();
module camera_dummy() translate([cam_x, cam_y, 0]) {
    cbox([0, 0, Zcam0], [cam_w, cam_d, cam_block_h]);
    translate([0, 0, Zcam0 + cam_block_h - eps]) cylinder(d = cam_barrel_d, h = cam_barrel_h + eps);
    translate([-cam_w/2 - 3 + eps, -cam_ribbon_w/2, Zcam0]) cube([3, cam_ribbon_w, ribbon_t]);   // ribbon stub, -X side
}
module window_dummy() translate([cam_x, cam_y, Zw - win_t]) cylinder(d = win_d, h = win_t);
module switch_dummy() {
    cbox([sw_x, sw_y, Zsw_bot], [sw_l, sw_w, sw_h]);
    cbox([sw_x, sw_y, Zsw_top - eps], [sw_travel + sw_handle, sw_handle, sw_handle_h + eps]);
    for (dx = [-2.5, 0, 2.5]) cbox([sw_x + dx, sw_y, Zsw_bot - sw_pin_l], [0.5, 0.3, sw_pin_l + eps]);
}
module tact_dummy() if (has_button) {
    cbox([tact_x, tact_y, Ztb], [tact_w, tact_w, tact_body_h]);
    translate([tact_x, tact_y, Ztb + tact_body_h - eps]) cylinder(d = tact_act_d, h = tact_h - tact_body_h + eps);
    for (sx = [-1, 1], sy = [-1, 1]) cbox([tact_x + sx*3.25, tact_y + sy*2.25, Ztb - (tact_leg_clear - 0.2)], [0.7, 0.3, tact_leg_clear - 0.2 + eps]);
}
module antenna_dummy() translate([x_a, y_a, Zab]) cube([a_ax, a_ay, ant_t]);

// RULE: no other metal within ant_keep of the antenna (full cavity height); the cell foil needs ant_cell_clear
module antenna_keepout() bx([x_a - ant_keep, y_a - ant_keep, Zi0], [x_a + a_ax + ant_keep, y_a + a_ay + ant_keep, Zw]);
module antenna_cellzone() bx([x_a - ant_cell_clear, y_a - ant_cell_clear, Zi0], [x_a + a_ax + ant_cell_clear, y_a + a_ay + ant_cell_clear, Zw]);
// the antenna tab's inside space beyond the body wall (empty when there is no tab): nothing else may be in it
module tab_cavity() {
    if (tab_x_on) bx([L - wall, tab_c[1], Zi0], [tab_c[2], tab_c[3], Zw]);
    if (tab_y_on) bx([tab_c[0], W - wall, Zi0], [tab_c[2], tab_c[3], Zw]);
}
// hot boards: the cell must stay therm_g away
module hot_zones() {
    P_T() bx([p_x_row1 - therm_g, p_y_bq0 - therm_g, Zi0], [p_row1_end + therm_g, p_y_bq0 + bq_l + therm_g, Zw]);
    bx([Xx0 - xiao_usb_over - therm_g, Yx0 - therm_g, Zi0], [xiao_far + therm_g, Yx0 + xiao_pcb_w + therm_g, Zw]);
}

// ---- JST-PH plug zones (housing swept from mated to fully withdrawn) in P-local coordinates
function P_zone_list() = concat(
    [for (c = bq_jst_c) [[x_bq_mouth + eps, p_y_bq0 + c - ph_hsg_w/2, Zbq + bq_pcb_t],
                         [x_bq_mouth + ph_hsg_len, p_y_bq0 + c + ph_hsg_w/2, Zbq + bq_pcb_t + bq_jst_h + 0.3], 0, "bq"]],
    [for (c = mx_jst_c) [[p_x_mx0 + ph_mouth_mx - ph_hsg_len, p_y_mx0 + c - ph_hsg_w/2, Zmx + mx_pcb_t],
                         [p_x_mx0 + ph_mouth_mx - eps, p_y_mx0 + c + ph_hsg_w/2, Zmx + mx_pcb_t + mx_jst_h + 0.3], 0, "mx"]],
    [[[p_x_mx0 + mx_d - mx_qt_y[1] - 0.5, p_y_mx0 - qt_plug_zone + 0.2, Zmx + mx_pcb_t],      // STEMMA QT on the strip side
      [p_x_mx0 + mx_d - mx_qt_y[0] + 0.5, p_y_mx0 - eps, Zmx + mx_pcb_t + mx_qt_h + 0.5], 1, "qt"]]);
module plug_zones() P_T() for (z = P_zone_list()) bx(z[0], z[1]);
// finger columns: from the back opening up to each plug, finger_clr wider across the mating axis;
// they stop at the board edge, because fingers cannot pass through a PCB
module access_zones() {
    P_T() for (z = P_zone_list()) {
        a = z[2];
        x0 = z[3] == "bq" ? max(z[0][0], p_row1_end + eps) : z[0][0];
        x1 = z[3] == "mx" ? min(z[1][0], p_x_mx0 - eps) : z[1][0];
        bx([x0 - (a == 1 ? finger_clr : 0), z[0][1] - (a == 0 ? finger_clr : 0), Zi0 + eps],
           [x1 + (a == 1 ? finger_clr : 0), z[1][1] + (a == 0 ? finger_clr : 0), z[1][2]]);
    }
    bx([Xx0 + 15.125, xy_v(17.021), Zi0 + eps], [Xx0 + 21.125, xy_v(0.821), Zxb - 7.43 - eps]);   // XIAO camera-FPC latch faces the back
}

// reserved wire lanes: free of printed material AND of boards/parts; none may enter the antenna keep-out.
// They are reserved volumes along the routes below, NOT a simulation of flexible cables.
function pm3(a, b) = [x_pr - b[1], a[0], a[2], x_pr - a[1], b[0], b[2]];   // P-local box -> outer box (x0, y0, z0, x1, y1, z1)
function lane_boxes() = let(zt = Zw - eps, zl = Zi0 + eps) [
    // cell leads + NTC: lead zone -> column between P and the cell -> into P's gap
    [x_cb + eps, cell_cy - 2.5, zl, x_cell - eps, cell_cy + 2.5, zt],
    [x_pr + eps, min(cell_cy, y_gate) - 2.5, zl, x_cb - eps, max(cell_cy, y_gate) + 2.5, zt],
    // P's gap (jumper, LOAD, cell-lead bend): between the posts, clear of the finger columns' ends
    pm3([p_row1_end + eps, 2.5, zl], [p_x_row2 + clr_board - eps, P_w - 2.5, zt]),
    // QT strip beside the MAX17048 (QT cable, switch / button / XIAO wires) and the lane between P and the XIAO
    pm3([p_x_row2 + eps, 0.3, zl], [P_len - 0.3, p_y_mx0 - eps, zt]),
    [x_pr + eps, y_tb, zl, x_x - eps, P_len, zt],
    // thermal lane under the band: switch, button and LOAD wires between the cell and the XIAO / camera / button
    [x_pr + eps, y_th + eps, zl, right_extent - 0.5, y_cam_b - eps, zt],
    // camera ribbon: under the flipped XIAO stack, then the run and the jog to the camera port
    [Xx0 + 15.1, rib_y - rib_half, zl, x_xr - eps, rib_y + rib_half, Zxs - eps],
    [x_xr, min(rib_y, cam_y) - rib_half, zl, cam_x - cam_w/2 - 3.0 - eps, max(rib_y, cam_y) + rib_half, zt],   // ends where the ribbon stub (in the camera model) begins
    // NTC channel under the cell, between the rails
    [x_cell + eps, cell_cy - 1.0, zl, x_cellb + ntc_from_lead_end - ntc_l/2 - 0.8, cell_cy + 1.0, Zc - eps]
];
module lanes() for (b = lane_boxes()) bx([b[0], b[1], b[2]], [b[3], b[4], b[5]]);

// =============================================================================
//  WI-FI TEST PIECE: the part of the real body around the XIAO and the antenna slot, cut out as a small closed box.
//  Same walls, plug, XIAO posts and hold-down pads, same antenna frame and distances as the full build, no cell, boards, camera or switch.
//  Print it once and swap the antenna in the one bay (ceramic, then stick-on) with the same XIAO, to compare RSSI. Export it with the
//  antenna you want the bay sized for:  -D ant_l=15.4 -D ant_w=6.4 -D ant_t=0.15  (Molex-class), which also takes the 13 x 5 ceramic.
// =============================================================================
wt_x0 = x_x - 3;  wt_y0 = y_th;                                   // lower left corner of the piece (outer)
wt_x1 = x_a_in + a_ax + ant_wall_gap + wall;  wt_y1 = y_a_in + a_ay + ant_wall_gap + wall;   // always the in-body slot (independent of the unused tab)
wt_fx = tol(wt_x1 - wt_x0 - 2*wall) + (plug_mode == "permanent" ? glue_film : 0);
wt_fy = tol(wt_y1 - wt_y0 - 2*wall) + (plug_mode == "permanent" ? glue_film : 0);
module wifi_cavity_2d() translate([wt_x0 + wall, wt_y0 + wall]) rrect([wt_x1 - wt_x0 - 2*wall, wt_y1 - wt_y0 - 2*wall], Ri);
module wifi_test() difference() {
    union() {
        difference() { rect_solid(wt_x0, wt_y0, wt_x1, wt_y1); translate([0, 0, -1]) linear_extrude(Zw + 1) wifi_cavity_2d(); }
        intersection() { translate([0, 0, Zi0]) linear_extrude(Zw - Zi0 + eps) wifi_cavity_2d(); union() { xiao_posts(); ant_holder(x_a_in, y_a_in); } }
    }
    // opening in the left wall for the XIAO's USB-C cable (power and flashing during the test)
    translate([wt_x0 - 1, xy_v(8.882), Zxb - 2.36]) rotate([90, 0, 90]) linear_extrude(wall + 2) stadium(usb_well_w, usb_well_h);
}
module wifi_test_plug(ribs = true) difference() {
    union() {
        linear_extrude(plug_t) translate([wt_x0 + wall + wt_fx, wt_y0 + wall + wt_fy])
            rrect([wt_x1 - wt_x0 - 2*wall - 2*wt_fx, wt_y1 - wt_y0 - 2*wall - 2*wt_fy], max(0, Ri - min(wt_fx, wt_fy)));
        for (vv = [2.0, 15.78]) cbox([Xx0 + 13.65, xy_v(vv), Zi0 - eps], [2.2, 2.0, (Zxb - 5.43) - pad_float - Zi0 + eps]);   // XIAO hold-down pads
        if (plug_mode == "removable" && ribs) {
            p = wt_fy + plug_rib_interf;
            for (x = [wt_x0 + wall + 8 : plug_rib_pitch : wt_x1 - wall - 8]) {
                translate([x, wt_y0 + wall + wt_fy - p + plug_rib_r, 0]) cylinder(r = plug_rib_r, h = plug_t);
                translate([x, wt_y1 - wall - wt_fy + p - plug_rib_r, 0]) cylinder(r = plug_rib_r, h = plug_t);
            }
        }
    }
    if (plug_mode == "removable") translate([wt_x1 - wall - wt_fx - 1.0, (wt_y0 + wt_y1)/2 - 3, -eps]) cube([1.0 + eps, 6, 0.6]);   // pry notch
}
module wifi_test_assembled(ex = 0) {
    color("white", 0.35) translate([0, 0, ex * 2.5]) wifi_test();
    color("ivory") translate([0, 0, -ex * 1.5]) wifi_test_plug();
    translate([0, 0, ex * 0.6]) { color("darkgreen") xiao_dummy(); color("gold") antenna_dummy(); }
}

// =============================================================================
//  VIEWS, CHECK PAIRS
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
}
module assembled(ex = 0) {
    color("white", 0.35) translate([0, 0, ex * 2.5]) body();
    color("ivory") translate([0, 0, -ex * 1.5]) plug();
    translate([0, 0, ex * 0.6]) components();
    color("ivory") translate([0, -ex, 0]) usb_cover_placed();
    if (has_button) color("ivory") translate([0, 0, ex * 3.2]) button_cap_placed();
    if (show_lanes) { color("red", 0.25) lanes(); color("orange", 0.25) plug_zones(); color("green", 0.2) access_zones(); color("cyan", 0.15) antenna_keepout(); }
}

debug_pairs = [
    ["body", "cell"], ["body", "cell_swollen"], ["body", "xiao"], ["body", "bq"], ["body", "max"], ["body", "camera"],
    ["body", "window"], ["body", "switch"], ["body", "tact"], ["body", "button_cap"], ["body", "ntc"],
    ["body", "antenna"], ["body", "plug"], ["body", "usb_cover"], ["body", "lanes"], ["body", "plug_zones"],
    ["plug", "cell"], ["plug", "xiao"], ["plug", "bq"], ["plug", "max"], ["plug", "camera"],
    ["plug", "switch"], ["plug", "tact"], ["plug", "lanes"], ["plug", "plug_zones"], ["plug", "antenna"], ["plug", "ntc_wire_room"],
    ["cell", "xiao"], ["cell", "bq"], ["cell", "max"], ["camera", "window"], ["tact", "button_cap"],
    ["xiao", "bq"], ["xiao", "max"], ["xiao", "camera"], ["xiao", "switch"], ["xiao", "tact"],
    ["bq", "max"], ["bq", "camera"], ["bq", "switch"], ["bq", "tact"], ["max", "camera"], ["max", "switch"], ["max", "tact"],
    ["camera", "switch"], ["camera", "tact"], ["switch", "tact"], ["usb_cover", "bq"],
    // antenna rules: 5 mm from metal (full height), 10 mm from the cell foil
    ["antenna_keepout", "cell_swollen"], ["antenna_keepout", "xiao"], ["antenna_keepout", "bq"], ["antenna_keepout", "max"],
    ["antenna_keepout", "camera"], ["antenna_keepout", "switch"], ["antenna_keepout", "tact"], ["antenna_keepout", "ntc"],
    ["antenna_keepout", "lanes"], ["antenna_keepout", "plug_zones"], ["antenna_cellzone", "cell_swollen"],
    // thermal: hot boards 4 mm from the cell
    ["hot_zones", "cell_swollen"],
    // unplug rule: finger columns clear
    ["access", "body"], ["access", "cell"], ["access", "xiao"], ["access", "bq"], ["access", "max"],
    ["access", "camera"], ["access", "switch"], ["access", "tact"], ["access", "antenna"], ["access", "button_cap"],
    // wire lanes against every component
    ["lanes", "cell"], ["lanes", "xiao"], ["lanes", "bq"], ["lanes", "max"], ["lanes", "camera"], ["lanes", "switch"], ["lanes", "tact"],
    // plug zones against the components
    ["plug_zones", "bq"], ["plug_zones", "max"], ["plug_zones", "xiao"], ["plug_zones", "camera"], ["plug_zones", "cell"],
    // antenna tab (empty module when the antenna is inside): its inside space must hold nothing else
    ["tab_cavity", "cell_swollen"], ["tab_cavity", "xiao"], ["tab_cavity", "bq"], ["tab_cavity", "max"], ["tab_cavity", "camera"],
    ["tab_cavity", "switch"], ["tab_cavity", "tact"], ["tab_cavity", "lanes"], ["tab_cavity", "plug_zones"], ["tab_cavity", "access"], ["tab_cavity", "ntc"],
    // Wi-Fi test piece: shell and lid against the XIAO and the antenna, and against each other
    ["wifi_shell", "xiao"], ["wifi_shell", "wifi_antenna"], ["wifi_plug", "xiao"], ["wifi_plug", "wifi_antenna"], ["wifi_shell", "wifi_plug"]
];
module obj(n) {
    if (n == "body") body();
    else if (n == "plug") plug(ribs = false);
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
    else if (n == "plug_zones") plug_zones();
    else if (n == "antenna_keepout") antenna_keepout();
    else if (n == "antenna_cellzone") antenna_cellzone();
    else if (n == "hot_zones") hot_zones();
    else if (n == "access") access_zones();
    else if (n == "tab_cavity") tab_cavity();
    else if (n == "wifi_shell") { if (!tab_on) wifi_test(); }                       // the test piece belongs to the in-body slot
    else if (n == "wifi_plug") { if (!tab_on) wifi_test_plug(ribs = false); }
    else if (n == "wifi_antenna") { if (!tab_on) translate([x_a_in, y_a_in, Zab]) cube([a_ax, a_ay, ant_t]); }
}
module debug_view() {
    if (debug_pair >= 0) {
        pr = debug_pairs[debug_pair];
        echo(str("DEBUG pair ", debug_pair, ": ", pr[0], " & ", pr[1]));
        intersection() { obj(pr[0]); obj(pr[1]); }
    } else
        for (pr = debug_pairs) intersection() { obj(pr[0]); obj(pr[1]); }
}
// =============================================================================
//  FIT COUPON (copied)
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

if (part == "assembled") assembled(0);
else if (part == "exploded") assembled(explode);
else if (part == "section") intersection() { assembled(0); translate([-1, -1, -1]) cube([Lt + 2, cam_y + 1, T + 2]); }
else if (part == "layout") { components(); color("ivory") plug(); color("orange", 0.5) plug_zones(); color("green", 0.25) access_zones(); color("cyan", 0.25) antenna_keepout(); color("red", 0.25) lanes(); }
else if (part == "body") body();
else if (part == "plug") plug();
else if (part == "usb_cover_A") usb_cover(0);
else if (part == "usb_cover_B") usb_cover(1);
else if (part == "usb_cover_C") usb_cover(2);
else if (part == "button_cap") rotate([180, 0, 0]) button_cap();
else if (part == "coupon") fit_coupon();
else if (part == "wifi_test") wifi_test();
else if (part == "wifi_test_plug") wifi_test_plug();
else if (part == "wifi_test_view") wifi_test_assembled(0);
else if (part == "wifi_test_exploded") wifi_test_assembled(explode);
else if (part == "debug") debug_view();
