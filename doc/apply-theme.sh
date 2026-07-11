#!/usr/bin/env bash
# Applies the smidr "Dark" palette to a freshly generated dox site and adds a nav cluster that
# links the dox API pages back to the hand-authored pages (home / widgets / examples).
# Run after dox, from the repo root:  bash doc/apply-theme.sh
#
# The dox output lives under doc/site/api (the site root is the hand-authored home page).
# 1. Appends the palette override to the generated dark-mode.css (so it loads last and wins).
# 2. Defaults the site to dark (the toggle still switches to light) by relaxing the
#    no-flash bootstrap condition in every page from "system-dark or stored-dark" to
#    "anything except explicitly stored light".
# 3. Injects a floating nav cluster into every API page.
set -euo pipefail

site="doc/site/api"
here="$(dirname "$0")"

if [ ! -d "$site" ]; then
	echo "error: $site not found - run 'haxe doc.hxml' and dox (-o doc/site/api) first" >&2
	exit 1
fi

cat "$here/theme/smidr-dark.css" >> "$site/dark-mode.css"

# default to dark unless the user explicitly picked light, and match the anti-flash colour
find "$site" -name '*.html' -exec sed -i \
	-e 's/(!localStorage.theme \&\& systemDarkMode) || localStorage.theme == "dark"/localStorage.theme != "light"/g' \
	-e 's/backgroundColor = "#111"/backgroundColor = "#121214"/g' {} +

# Inject a floating nav cluster into every API page so visitors can get back to the home,
# widgets and examples pages. It is a fixed-position element (independent of the dox template)
# with site-absolute links; change SITE_BASE if the repo name or hosting domain changes.
#
# Every link carries its colours INLINE (not via a class): dox/Bootstrap style links with
# `a:link`/`a:visited` (specificity 0,1,1), which would beat a class (0,1,0) in the same origin
# and override the text colour, making the links invisible. Inline styles win over any selector.
# @ is the sed delimiter because the inline styles contain '#' hex colours and '/' (font shorthand).
SITE_BASE="/SmidrUI"
L="text-decoration:none;font:600 13px/1 sans-serif;padding:7px 11px;border-radius:7px"
NAV="<div style=\"position:fixed;bottom:16px;right:16px;z-index:9999;display:flex;gap:4px;background:#17171a;border:1px solid #33333c;border-radius:10px;padding:6px;box-shadow:0 4px 16px rgba(0,0,0,.5)\"><a href=\"${SITE_BASE}/\" style=\"color:#e6e6ea;${L}\">Home</a><a href=\"${SITE_BASE}/widgets.html\" style=\"color:#e6e6ea;${L}\">Widgets</a><a href=\"${SITE_BASE}/examples/\" style=\"color:#ffffff;background:#8a5ee0;${L}\">Examples</a></div>"
find "$site" -name '*.html' -exec sed -i "s@</body>@${NAV}</body>@" {} +

echo "Applied smidr Dark theme + nav to $site"
