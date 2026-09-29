#!/bin/bash
# Full-page, full-width, real high-DPI screenshot of the page already open in an
# agent-browser session. Navigate, sign in, click tabs and close popups first;
# this script only prepares and captures what is on screen.
#
# Usage: capture.sh SESSION OUTPUT.png [CSS_WIDTH=1920] [SCALE=2]
# Env:   UNCLIP=0 to leave inner scroll panels alone (default 1).
set -uo pipefail

session=${1:?Usage: capture.sh SESSION OUTPUT.png [CSS_WIDTH] [SCALE]}
output=${2:?Usage: capture.sh SESSION OUTPUT.png [CSS_WIDTH] [SCALE]}
width=${3:-1920}
scale=${4:-2}
unclip=${UNCLIP:-1}

ab() { agent-browser --session "$session" "$@"; }
mkdir -p "$(dirname -- "$output")"

# Density comes from viewport emulation. Never use the Chrome launch flag
# --force-device-scale-factor: it paints the page small inside a large blank canvas.
ab set viewport "$width" 1080 "$scale" >/dev/null || exit 1
ab wait --load networkidle >/dev/null 2>&1 || true

prep=$(ab eval "(async () => {
  const delay = ms => new Promise(r => setTimeout(r, ms));
  await document.fonts.ready;
  window.dispatchEvent(new Event('resize'));
  const scrollers = () => [...document.querySelectorAll('body *')].filter(el => {
    const cs = getComputedStyle(el);
    return /(auto|scroll)/.test(cs.overflowY) && el.clientHeight > 150 && el.scrollHeight > el.clientHeight + 20;
  });
  // Load lazy content: walk the window and every inner scroll panel, then return to the top.
  for (let y = 0; y < document.documentElement.scrollHeight; y += 700) { window.scrollTo(0, y); await delay(250); }
  for (const s of scrollers()) { for (let y = 0; y < s.scrollHeight; y += 700) { s.scrollTop = y; await delay(200); } s.scrollTop = 0; }
  await Promise.all([...document.images].map(img => img.complete ? 1 : new Promise(r => { img.onload = img.onerror = r; setTimeout(r, 5000); })));
  const unclipped = [];
  if ($unclip) {
    const force = (el, props) => { for (const [k, v] of Object.entries(props)) el.style.setProperty(k, v, 'important'); };
    for (let pass = 0; pass < 6; pass++) {
      const list = scrollers();
      if (!list.length) break;
      for (const s of list) {
        unclipped.push((s.id ? '#' + s.id : s.tagName.toLowerCase()) + '.' + String(s.className).trim().split(/\s+/).slice(0, 2).join('.'));
        force(s, {height: 'auto', 'max-height': 'none', 'overflow-y': 'visible'});
        for (let a = s.parentElement; a && a !== document.documentElement; a = a.parentElement) {
          const cs = getComputedStyle(a);
          if (a.scrollHeight > a.clientHeight + 2 || cs.overflowY !== 'visible') force(a, {height: 'auto', 'max-height': 'none', 'min-height': '0', 'overflow-y': 'visible'});
        }
      }
      window.dispatchEvent(new Event('resize'));
      await delay(600);
    }
  }
  window.scrollTo(0, 0);
  await delay(1500);
  return JSON.stringify({dpr: devicePixelRatio, width: innerWidth, docHeight: document.documentElement.scrollHeight, unclipped: [...new Set(unclipped)]});
})()" 2>&1)
prep=$(printf '%s' "$prep" | tail -1 | sed -e 's/^"//' -e 's/"$//' -e 's/\\"/"/g')
echo "prepared: $prep"

rm -f "$output"
ab screenshot --full "$output" >/dev/null || { echo "FAIL: screenshot command failed" >&2; exit 1; }
px_w=$(sips -g pixelWidth "$output" | awk '/pixelWidth:/ {print $2}')
px_h=$(sips -g pixelHeight "$output" | awk '/pixelHeight:/ {print $2}')
doc_h=$(printf '%s' "$prep" | sed -n 's/.*"docHeight":\([0-9]*\).*/\1/p')
expected_w=$((width * scale))
echo "saved: $output  ${px_w}x${px_h}"
if (( px_w < expected_w )); then
  echo "FAIL: width $px_w, expected at least $expected_w. Density or viewport did not apply." >&2
  exit 1
fi
if (( px_w > expected_w )); then
  echo "NOTE: page is wider than the viewport (${px_w}px); content overflows sideways."
fi
if [[ -n "$doc_h" && $((doc_h * scale - px_h)) -gt 4 ]]; then
  echo "WARN: image is ${px_h}px tall but the page is $((doc_h * scale))px. The capture is cut off." >&2
  exit 3
fi
echo "OK. Look at the image before accepting it: header, body and footer in place, no blank bands, no popup."
