# ASTS Constellation Tracker

Live tracker for AST SpaceMobile's BlueBird constellation — every satellite launched to date, its unfold status, and the launch roadmap to the ~45 satellites needed for continuous commercial coverage.

**Features**
- 🗺️ Live orbit map — positions propagated in-browser (Kepler + J2) from CelesTrak orbital elements, with day/night terminator and per-satellite ground tracks
- 🛰️ Fleet status — Block 1 (BB1) vs Block 2 (BB2), fully unfolded vs deployed-pending, lost
- 📊 Launch roadmap — one bar per launch (color = provider, height = BB2 sats carried) with running totals to the 45-satellite commercial-coverage threshold
- 🚀 Provider status — SpaceX Falcon 9, Blue Origin New Glenn, ISRO LVM3

**Data**
- Orbital elements: [CelesTrak](https://celestrak.org) (`NAME=SPACEMOBILE`), auto-refreshed daily by GitHub Actions into `tles.js` — or run `./update-tles.sh` locally
- Fleet/launch data: hand-curated in `index.html` (`FLEET` / `LAUNCHES` arrays) from AST SpaceMobile press releases and filings

Launches marked "Projected" are a hypothetical model, not company guidance. Independent tracking tool — not affiliated with AST SpaceMobile, not investment advice.
