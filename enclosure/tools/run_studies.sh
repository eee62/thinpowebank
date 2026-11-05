#!/usr/bin/env bash
# Collision + rule checks for the placement studies (layout_studies.scad), study 1 and 2.
# Every pair must intersect with < 0.001 mm^3 (empty or touching only).
set -u
cd "$(dirname "$0")/.."
OUT=${CHECK_OUT:-/tmp/powerbank_studies}; mkdir -p "$OUT"
JOBS=${JOBS:-4}
npairs=$(sed -n '/^study_pairs = \[/,/^\];/p' layout_studies.scad | tr ']' '\n' | grep -c '\["')
run_pair() {
  st=$1; i=$2; f="$OUT/study${st}_pair$i.stl"
  log=$(openscad -o "$f" -D 'part="none"' -D "study=$st" -D 'study_view="debug"' -D "study_pair=$i" layout_studies.scad 2>&1)
  name=$(printf '%s\n' "$log" | grep -o 'DEBUG pair [0-9]*: [^"]*' | head -1)
  if printf '%s' "$log" | grep -q "Current top level object is empty"; then printf 'study %s %-34s EMPTY PASS\n' "$st" "$name"
  elif [ -f "$f" ]; then
    read v n < <(python3 -I tools/stl_volume.py "$f")
    if python3 -c "import sys; sys.exit(0 if $v < 0.001 else 1)"; then printf 'study %s %-34s %s mm3 (touch) PASS\n' "$st" "$name" "$v"
    else printf 'study %s %-34s %s mm3 FAIL\n' "$st" "$name" "$v"; fi
  else printf 'study %s %-34s render error FAIL\n' "$st" "$name"; fi
}
export -f run_pair; export OUT
for st in 1 2; do
  openscad -o "$OUT/s$st.echo" -D 'part="none"' -D "study=$st" layout_studies.scad 2>/dev/null
  grep STUDY "$OUT/s$st.echo" | sed 's/ECHO: //'
  seq 0 $((npairs-1)) | xargs -P "$JOBS" -I{} bash -c "run_pair $st {}" | sort -t' ' -k5 -n > "$OUT/study$st.txt"
  cat "$OUT/study$st.txt"
  echo "study $st: $(grep -c PASS "$OUT/study$st.txt") pass, $(grep -c FAIL "$OUT/study$st.txt") fail (of $npairs)"
done
