#!/usr/bin/env python3
"""Generate the SmidrUI widget guide (widgets.html) from the widgets' class docstrings.

Scans src/smidr/widgets/*.hx and src/smidr/overlays/*.hx, pulls the leading `/** ... **/`
doc comment of each module's main class, and emits one themed page grouping them. Because it
reads the source docstrings, the guide stays in sync with the library.

Usage:  python3 doc/build-widget-guide.py [output.html]   (default: doc/site/widgets.html)
"""
import html
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (source dir, API reference package path, section title)
SECTIONS = [
    ("src/smidr/widgets", "smidr/widgets", "Widgets"),
    ("src/smidr/overlays", "smidr/overlays", "Overlays &amp; services"),
]

# leading /** ... **/ doc comment immediately before a (final) class declaration
CLASS_DOC = re.compile(
    r"/\*\*(?P<doc>.*?)\*\*/\s*(?:@:[^\n]*\n\s*)*(?:final\s+|private\s+)*class\s+(?P<name>\w+)",
    re.DOTALL,
)

STYLE = """
:root{--bg:#121214;--panel:#1c1c20;--panel2:#232329;--border:#33333c;--text:#e6e6ea;--text2:#a0a0a8;--text3:#6e6e78;--accent:#8a5ee0;--accent2:#9a72ea}
*{box-sizing:border-box}html,body{margin:0;padding:0}
body{background:var(--bg);color:var(--text);font:15px/1.6 -apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased}
.nav{position:sticky;top:0;z-index:50;display:flex;align-items:center;justify-content:space-between;gap:16px;padding:0 22px;height:54px;background:#17171a;border-bottom:1px solid var(--border)}
.nav .brand{color:var(--text);font-weight:700;font-size:17px;text-decoration:none;letter-spacing:.2px}
.nav .links{display:flex;gap:6px;flex-wrap:wrap}
.nav .links a{color:var(--text2);text-decoration:none;font-size:14px;padding:6px 12px;border-radius:7px}
.nav .links a:hover{color:var(--text);background:var(--panel2)}
.nav .links a.active{color:#fff;background:var(--accent)}
.wrap{max-width:860px;margin:0 auto;padding:36px 20px 80px}
h1{font-size:30px;margin:0 0 8px}
.lead{color:var(--text2);margin:0 0 26px;font-size:16px}
.toc{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 34px;padding:16px;background:var(--panel);border:1px solid var(--border);border-radius:12px}
.toc a{color:var(--text2);text-decoration:none;font-size:13px;padding:4px 9px;border-radius:6px;background:var(--panel2)}
.toc a:hover{color:var(--text);background:var(--border)}
.section-title{font-size:22px;margin:40px 0 4px;padding-top:10px;border-top:1px solid var(--border)}
.widget{padding:22px 0;border-bottom:1px solid var(--border)}
.widget h3{font-size:19px;margin:0 0 8px;display:flex;align-items:baseline;gap:12px;scroll-margin-top:70px}
.widget h3 code{font-size:19px;color:var(--text);background:none;padding:0}
.widget h3 .ref{font-size:12px;font-weight:400}
.widget h3 .ref a{color:var(--accent);text-decoration:none}
.widget h3 .ref a:hover{color:var(--accent2)}
.widget p{margin:0 0 10px;color:var(--text2)}
.widget p:last-child{margin-bottom:0}
code{background:var(--panel2);padding:2px 6px;border-radius:5px;font:13px/1.4 "SF Mono",Consolas,monospace;color:#d6cffa}
footer{margin-top:40px;color:var(--text3);font-size:13px}
footer a{color:var(--text2)}
"""

NAV = """<nav class="nav">
	<a class="brand" href="/SmidrUI/">Smi&eth;rUI</a>
	<div class="links">
		<a href="/SmidrUI/">Home</a>
		<a class="active" href="/SmidrUI/widgets.html">Widgets</a>
		<a href="/SmidrUI/examples/">Examples</a>
		<a href="/SmidrUI/api/">API</a>
	</div>
</nav>"""


def clean_doc(raw: str) -> str:
    """Turn a raw Haxe doc comment body into paragraph HTML."""
    lines = []
    for line in raw.splitlines():
        line = line.strip()
        if line.startswith("*"):
            line = line[1:]
        lines.append(line.strip())
    text = "\n".join(lines).strip()
    text = html.escape(text)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    paragraphs = re.split(r"\n\s*\n", text)
    out = []
    for para in paragraphs:
        para = para.strip().replace("\n", " ")
        if para:
            out.append(f"<p>{para}</p>")
    return "\n\t\t\t".join(out)


def collect(rel_dir: str):
    abs_dir = os.path.join(ROOT, rel_dir)
    items = []
    for fname in sorted(os.listdir(abs_dir)):
        if not fname.endswith(".hx"):
            continue
        with open(os.path.join(abs_dir, fname), "r", encoding="utf-8") as fh:
            source = fh.read()
        match = CLASS_DOC.search(source)
        if not match:
            continue
        name = match.group("name")
        # skip private helper classes that happen to be first (shouldn't be, but be safe)
        items.append((name, clean_doc(match.group("doc"))))
    return items


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "doc/site/widgets.html")

    sections = []
    toc = []
    for rel_dir, ref_pkg, title in SECTIONS:
        items = collect(rel_dir)
        rows = []
        for name, body in items:
            ref = f"/SmidrUI/api/{ref_pkg}/{name}.html"
            toc.append(f'<a href="#{name}">{name}</a>')
            rows.append(
                f'\t\t<div class="widget" id="{name}">\n'
                f'\t\t\t<h3><code>{name}</code><span class="ref"><a href="{ref}">API &#8599;</a></span></h3>\n'
                f'\t\t\t{body}\n'
                f'\t\t</div>'
            )
        sections.append(
            f'\t\t<h2 class="section-title">{title}</h2>\n' + "\n".join(rows)
        )

    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>SmiðrUI · Widgets</title>
	<style>{STYLE}</style>
</head>
<body>
	{NAV}
	<div class="wrap">
		<h1>Widget guide</h1>
		<p class="lead">Every widget in the library, with the description straight from its source. Follow <b>API &#8599;</b> for the full member reference.</p>
		<div class="toc">
			{''.join(toc)}
		</div>
{chr(10).join(sections)}
		<footer>
			Generated from the widget docstrings in <a href="https://github.com/MeguminBOT/SmidrUI">MeguminBOT/SmidrUI</a>.
		</footer>
	</div>
</body>
</html>
"""

    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fh:
        fh.write(doc)
    total = sum(len(collect(d)) for d, _, _ in SECTIONS)
    print(f"Wrote {out_path} ({total} entries)")


if __name__ == "__main__":
    main()
