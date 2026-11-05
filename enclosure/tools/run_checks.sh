#!/usr/bin/env bash
# Runs every check on the model in $SCAD (default powerbank.scad; SCAD=powerbank70.scad for the compact model) and prints a summary.
#   1. assert()/echo pass for each configuration (any ERROR or WARNING fails)
#   2. every "must not touch" pair in debug_pairs: the intersection must be empty
#      (or have < 0.001 mm^3 volume = only a touching face)
#   3. every printable part renders with CGAL as a simple (manifold) solid
# Usage: tools/run_checks.sh [extra -D overrides...]   e.g.  tools/run_checks.sh -D 'style="sharp"'
set -u
cd "$(dirname "$0")/.."
SCAD=${SCAD:-powerbank.scad}
OUT=${CHECK_OUT:-/tmp/powerbank_checks}; mkdir -p "$OUT"
EXTRA=("$@")
JOBS=${JOBS:-4}
tag=$(printf '%s' "${EXTRA[*]:-default}" | tr -c 'A-Za-z0-9' '_')

echo "== 1. asserts / echo  (${EXTRA[*]:-defaults})"
openscad -o "$OUT/$tag.echo" "${EXTRA[@]}" "$SCAD" 2>"$OUT/$tag.err"
cat "$OUT/$tag.echo" | sed 's/^ECHO: //'
if grep -E "ERROR|WARNING" "$OUT/$tag.echo" "$OUT/$tag.err"; then echo "ASSERT/WARNING: FAIL"; else echo "asserts: PASS"; fi

echo "== 2. must-not-touch pairs"
npairs=$(grep -c '\["' <(sed -n '/^debug_pairs = \[/,/^\];/p' "$SCAD" | tr ']' '\n') )
run_pair() {
  i=$1; f="$OUT/${tag}_pair$i.stl"
  log=$(openscad -o "$f" -D 'part="debug"' -D "debug_pair=$i" "${EXTRA[@]}" "$SCAD" 2>&1)
  name=$(printf '%s\n' "$log" | grep -o 'DEBUG pair [0-9]*: [^"]*' | head -1)
  if printf '%s' "$log" | grep -q "Current top level object is empty"; then
    printf '%-45s EMPTY        PASS\n' "$name"
  elif [ -f "$f" ]; then
    read v n < <(python3 -I tools/stl_volume.py "$f")
    if python3 -c "import sys; sys.exit(0 if $v < 0.001 else 1)"; then
      printf '%-45s %8s mm3 (touch) PASS\n' "$name" "$v"
    else
      printf '%-45s %8s mm3      FAIL\n' "$name" "$v"
    fi
  else
    printf '%-45s render error FAIL\n%s\n' "$name" "$log"
  fi
}
export -f run_pair; export OUT tag SCAD
EXTRA_Q=""; [ ${#EXTRA[@]} -gt 0 ] && EXTRA_Q=$(printf '%q ' "${EXTRA[@]}")
seq 0 $((npairs-1)) | xargs -P "$JOBS" -I{} bash -c "EXTRA=($EXTRA_Q); run_pair {}" | sort -t' ' -k3 -n > "$OUT/${tag}_pairs.txt"
cat "$OUT/${tag}_pairs.txt"
echo "pairs: $(grep -c PASS "$OUT/${tag}_pairs.txt") pass, $(grep -c FAIL "$OUT/${tag}_pairs.txt") fail (of $npairs)"

echo "== 3. printable parts render as simple solids"
for p in body plug usb_cover_A usb_cover_B usb_cover_C button_cap coupon; do
  log=$(openscad -o "$OUT/${tag}_$p.stl" -D "part=\"$p\"" "${EXTRA[@]}" "$SCAD" 2>&1)
  simple=$(printf '%s' "$log" | grep -o 'Simple: *[a-z]*' | awk '{print $2}')
  vol=$(printf '%s' "$log" | grep -o 'Volumes: *[0-9]*' | awk '{print $2}')
  printf '%-12s simple=%s volumes=%s (2 = one solid) %s\n' "$p" "${simple:-?}" "${vol:-?}" "$( [ "$simple" = yes ] && echo PASS || echo FAIL)"
done
