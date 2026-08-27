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
import sys, json, datetime, urllib.request

def fetch_json(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'asts-tracker'}), timeout=30) as r:
            return json.load(r)
    except Exception:
        return None

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

# Satellites with extended (6-digit) NORAD ids are missing from the TLE-format
# feed — find them in the SATCAT and synthesize TLE lines from the JSON GP data.
def synth(gp, norad):
    ep = datetime.datetime.fromisoformat(gp['EPOCH'])
    doy = (ep - datetime.datetime(ep.year, 1, 1)).total_seconds() / 86400 + 1
    ndot = float(gp.get('MEAN_MOTION_DOT') or 0)
    l1 = ('1 00000U ' + f"{gp.get('OBJECT_ID','')[2:].replace('-',''):<8}" + ' '
          + f'{ep.year % 100:02d}{doy:012.8f} '
          + ('-' if ndot < 0 else ' ') + f'.{abs(ndot)*1e8:08.0f}'
          + '  00000+0  00000+0 0  0000')
    l2 = ('2 00000 ' + f"{float(gp['INCLINATION']):8.4f} " + f"{float(gp['RA_OF_ASC_NODE']):8.4f} "
          + f"{float(gp['ECCENTRICITY']):.7f}"[2:9] + ' ' + f"{float(gp['ARG_OF_PERICENTER']):8.4f} "
          + f"{float(gp['MEAN_ANOMALY']):8.4f} " + f"{float(gp['MEAN_MOTION']):11.8f}00000")
    return [l1, l2, norad]

satcat = fetch_json('https://celestrak.org/satcat/records.php?NAME=SPACEMOBILE&FORMAT=JSON') or []
for rec in satcat:
    name = rec.get('OBJECT_NAME', '')
    if rec.get('OBJECT_TYPE') != 'PAY' or rec.get('OPS_STATUS_CODE') != '+' or name in sats:
        continue
    gp = fetch_json(f"https://celestrak.org/NORAD/elements/gp.php?CATNR={rec['NORAD_CAT_ID']}&FORMAT=json")
    if gp:
        sats[name] = synth(gp[0], rec['NORAD_CAT_ID'])

out = {'fetched': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'), 'tles': sats}
open('tles.js', 'w').write('// AST SpaceMobile TLE data — regenerate with ./update-tles.sh\nconst TLE_DATA = ' + json.dumps(out, indent=1) + ';\n')
print(f'Updated tles.js with {len(sats)} satellites at {out["fetched"]}')
EOF
rm -f "$TMP"
