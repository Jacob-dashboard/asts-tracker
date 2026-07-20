#!/usr/bin/env bash
# Refresh AST SpaceMobile TLEs from CelesTrak into tles.js
# Run any time, then reload index.html in the browser.
set -e
cd "$(dirname "$0")"

TMP=$(mktemp)
{
  curl -sf --max-time 30 "https://celestrak.org/NORAD/elements/gp.php?NAME=SPACEMOBILE&FORMAT=tle"
  curl -sf --max-time 30 "https://celestrak.org/NORAD/elements/gp.php?NAME=BLUEWALKER&FORMAT=tle"
} > "$TMP"

python3 - "$TMP" <<'EOF'
import sys, json, datetime
lines = [l.rstrip() for l in open(sys.argv[1]) if l.strip()]
sats = {}
i = 0
while i + 2 < len(lines) + 1:
    if i + 2 <= len(lines) - 1 and lines[i+1].startswith('1 ') and lines[i+2].startswith('2 '):
        sats[lines[i].strip()] = [lines[i+1], lines[i+2]]
        i += 3
    else:
        i += 1
if not sats:
    sys.exit('No TLEs parsed — CelesTrak may be unreachable. tles.js left unchanged.')
out = {'fetched': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'), 'tles': sats}
open('tles.js', 'w').write('// AST SpaceMobile TLE data — regenerate with ./update-tles.sh\nconst TLE_DATA = ' + json.dumps(out, indent=1) + ';\n')
print(f'Updated tles.js with {len(sats)} satellites at {out["fetched"]}')
EOF
rm -f "$TMP"
