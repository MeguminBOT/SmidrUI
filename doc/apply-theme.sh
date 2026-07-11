#!/usr/bin/env bash
# Applies the smidr "Dark" palette to a freshly generated dox site.
# Run after dox, from the repo root:  bash doc/apply-theme.sh
#
# 1. Appends the palette override to the generated dark-mode.css (so it loads last and wins).
# 2. Defaults the site to dark (the toggle still switches to light) by relaxing the
#    no-flash bootstrap condition in every page from "system-dark or stored-dark" to
#    "anything except explicitly stored light".
set -euo pipefail

site="doc/site"
here="$(dirname "$0")"

if [ ! -d "$site" ]; then
	echo "error: $site not found - run 'haxe doc.hxml' and dox first" >&2
	exit 1
fi

cat "$here/theme/smidr-dark.css" >> "$site/dark-mode.css"

# default to dark unless the user explicitly picked light, and match the anti-flash colour
find "$site" -name '*.html' -exec sed -i \
	-e 's/(!localStorage.theme \&\& systemDarkMode) || localStorage.theme == "dark"/localStorage.theme != "light"/g' \
	-e 's/backgroundColor = "#111"/backgroundColor = "#121214"/g' {} +

# Inject a floating "Examples" link into every page (a fixed-position anchor, so it does not
# depend on the dox template markup and works at any page depth). Uses a site-absolute path;
# change EXAMPLES_URL if the repo name or hosting domain changes.
# @ is the sed delimiter because the inlined CSS contains '#' hex colours.
EXAMPLES_URL="/SmidrUI/examples/"
STYLE='<style>.smidr-examples-link{position:fixed;bottom:16px;right:16px;z-index:9999;background:#8a5ee0;color:#fff;padding:9px 15px;border-radius:8px;font:600 13px/1 sans-serif;text-decoration:none;box-shadow:0 3px 12px rgba(0,0,0,.45)}.smidr-examples-link:hover{background:#9a72ea}</style>'
LINK="<a class=\"smidr-examples-link\" href=\"${EXAMPLES_URL}\">Examples ↗</a>"
find "$site" -name '*.html' -exec sed -i "s@</body>@${STYLE}${LINK}</body>@" {} +

echo "Applied smidr Dark theme to $site"
