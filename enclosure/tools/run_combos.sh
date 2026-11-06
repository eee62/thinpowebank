#!/usr/bin/env bash
# Evaluates powerbank70.scad for every cell x antenna combination below.
#   col 1  outer size with the hard limits NOT enforced (so a failing layout still shows how big it would be)
#   col 2  PASS or the first assert that fails with the limits enforced (message names the dimension)
# Add your real Shopee parts as new lines in CELLS / ANTENNAS (name  thickness width length  lead_len) and rerun.
# Pass "full" as the first argument to also run all collision pairs for every combination that passes the asserts.
set -u
cd "$(dirname "$0")/.."
SCAD=powerbank70.scad
OUT=${CHECK_OUT:-/tmp/powerbank70_combos}; mkdir -p "$OUT"
FULL=${1:-}

# name          cell_t cell_w cell_l  cell_lead_len   (sizes are STANDARD-CODE nominal values, NOT verified Shopee listings)
# "...max" rows = the largest size some listings / datasheets quote for that code (web search results, UNVERIFIED).
# Typical capacity per listings (UNVERIFIED): 603450 1000-1500 mAh | 503450 950-1200 | 603048 850-950 | 503040 520-620
CELLS=(
  "603450        6.0  34.0  50.0  100"
  "603450max     6.0  34.5  52.0  100"
  "503450        5.0  34.0  50.0  100"
  "503450max     5.3  34.8  53.0  100"
  "603048        6.0  30.0  48.0  100"
  "603048max     6.3  30.5  50.0  100"
  "503040        5.0  30.0  40.0  100"
  "503040max     5.5  30.5  42.0  100"
)
# name                 type     l    w    t     cable   (sizes are typical overseas listing values, NOT Shopee, all unverified)
ANTENNAS=(
  "ceramic13x5         ceramic  13   5    1.0   100"
  "ceramic15x5         ceramic  15   5    1.0   100"
  "ceramic10x4         ceramic  10   4    1.0   100"
  "molex15.4x6.4       stick    15.4 6.4  0.15  100"
  "stick25x6           stick    25   6    0.2   100"
  "stick42x12          stick    42   12   0.2   120"
  "stick45x7(Linx)     stick    45   7    0.1   100"
  "stick39x19(SeeedA02?) stick  39   19   0.2   100"
)

printf '%-10s | %-22s | %-30s | %s\n' "cell" "antenna" "outer size (limits off)" "result with limits"
printf -- '-----------+------------------------+--------------------------------+--------------------------------------------\n'
for c in "${CELLS[@]}"; do
  set -- $c; cn=$1; ct=$2; cw=$3; cl=$4; lead=$5
  for a in "${ANTENNAS[@]}"; do
    set -- $a; an=$1; aty=$2; al=$3; aw=$4; at=$5; cab=$6
    D=(-D "cell_code=\"$cn\"" -D "cell_t=$ct" -D "cell_w=$cw" -D "cell_l=$cl" -D "cell_lead_len=$lead"
       -D "ant_type=\"$aty\"" -D "ant_l=$al" -D "ant_w=$aw" -D "ant_t=$at" -D "ant_cable_len=$cab")
    openscad -o "$OUT/t.echo" -D enforce_limits=false "${D[@]}" "$SCAD" >/dev/null 2>&1
    size=$(grep -h -m1 -E "ERROR" "$OUT/t.echo")
    if [ -z "$size" ]; then size=$(grep -o 'L x W x T = [0-9.]* x [0-9.]* x [0-9.]*' "$OUT/t.echo" | sed 's/L x W x T = //'); size="$size mm"; else size="(layout assert: ${size:0:60})"; fi
    openscad -o "$OUT/t2.echo" "${D[@]}" "$SCAD" >/dev/null 2>&1
    msg=$(grep -h -m1 -E "ERROR: Assertion" "$OUT/t2.echo" | sed 's/.*failed: *//; s/ in file.*//')
    if [ -z "$msg" ]; then res=PASS; else res="FAIL: $msg"; fi
    printf '%-10s | %-22s | %-30s | %s\n' "$cn" "$an" "$size" "${res:0:150}"
    if [ "$FULL" = full ] && [ "$res" = PASS ]; then
      CHECK_OUT="$OUT/${cn}_${an}" JOBS=${JOBS:-4} SCAD=$SCAD tools/run_checks.sh "${D[@]}" > "$OUT/${cn}_${an}.log" 2>&1
      printf '           pairs: %s\n' "$(grep -E '^pairs:' "$OUT/${cn}_${an}.log")"
    fi
  done
done
