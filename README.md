# SmiðrUI

[![Haxelib](https://img.shields.io/haxelib/v/smidr.svg?logo=haxe&label=haxelib)](https://lib.haxe.org/p/smidr)
[![API docs](https://img.shields.io/badge/docs-API-8A5EE0.svg)](https://meguminbot.github.io/SmidrUI/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Haxe 4.3+](https://img.shields.io/badge/Haxe-4.3%2B-orange.svg)
![OpenFL](https://img.shields.io/badge/OpenFL-required-1a6fc4.svg)

A lightweight **retained-mode UI toolkit for [OpenFL](https://www.openfl.org/)**. Widgets are
plain `openfl.display.Sprite`s that repaint **only when invalidated** — an idle UI does zero
per-frame work. Theming is plain ints, fonts and localization are pluggable hooks, and there is
no dependency on any game framework (flixel, HaxeFlixel, etc.) — just OpenFL.

> The name is Old Norse *smiðr* ("smith / craftsman"); the package id is `smidr`.

SmiðrUI is distributed as a **[haxelib](https://lib.haxe.org/)** named `smidr` — install it with
`haxelib` and add `<haxelib name="smidr" />` to your `project.xml` (see [Install](#install)).

## Why Smidr was made

I got frustrated with how Flixel UI was extremely draw-heavy on more elaborate UIs, then I tried
HaxeUI and immediately wanted to get rid of it as it's slightly too burdensome to use. So I opted
to make my own instead, meant to be used either standalone or above other frameworks without any
weird initialisation — no weird hitbox or hover logic, it's all handled by the UIComponents
themselves.

SmiðrUI also ships an optional Flixel bridge (compiled only when the `flixel` haxelib is present).

## Features

- **Retained + invalidation-driven** — `render()` runs on a widget only after `invalidate()`
  marks it dirty; `UIRoot` flushes the dirty set once per frame.
- **Built-in pointer correctness** — press/click only fire when press and release land on the
  same widget; drags use exclusive capture.
- **Themable at runtime** — swap `UITheme` palettes (4 presets built in) or a custom accent and
  the whole live tree re-skins.
- **Density scaling** — one global `UITheme.scale` multiplier for HiDPI / accessibility.
- **Built-in vector icons** — a 59-glyph set (`UIGlyphs`) drawn crisp at any size with no assets,
  tinted by the theme; use them anywhere or drop svg/png assets into `UIIcon`.
- **Named, type-safe ids** — `smidr.types` enum abstracts (`UIGlyph`, `UITone`, `UIEase`,
  `UICursorMode`) let you write `CHEVRON_LEFT` / `SECONDARY` / `OUT_QUAD`; they compile to plain
  ints, so there's zero runtime cost.
- **Pluggable fonts & i18n** — point `UIFonts` at any embedded font asset; wire `UILocale` to
  your own translation lookup. The library ships dependency-free defaults.
- **Optional Flixel bridge** — `smidr.flixel.FlxSmidr` handles viewport matching, cursor and
  input arbitration when the `flixel` haxelib is present.

### Widgets

Buttons (with optional glyph/asset icons), labels, icons, panels and separators, icon rails and
tabs, checkboxes, switches, chips, sliders, steppers, segmented controls, text inputs, keybind
capture, dropdowns, context menus, menu bars, accordions, scroll panes, data-bound lists, loading
bars, modals, tooltips and toasts.

## Install

```bash
haxelib install smidr

# or track the latest from git
haxelib git smidr https://github.com/MeguminBOT/SmidrUI.git
```

Then in your `project.xml`:

```xml
<haxelib name="openfl" />
<haxelib name="smidr" />
```

Requires **OpenFL** (which pulls in Lime). Tested with Haxe 4.3.

## Quick start

```haxe
import openfl.display.Sprite;
import smidr.UIRoot;
import smidr.UIFonts;
import smidr.widgets.UIButton;
import smidr.widgets.UIPanel;

class Main extends Sprite {
	var ui:UIRoot;

	public function new() {
		super();

		// optional: use an embedded font for every widget
		UIFonts.register("assets/fonts/Inter.ttf");

		// create the root and attach it above your content
		ui = new UIRoot();
		ui.attach(this);
		// match your content viewport if you letterbox/scale (offsetX, offsetY, scaleX, scaleY)
		ui.setViewport(0, 0, 1, 1);

		// a background panel
		var panel = new UIPanel(240, 120, 0xFF1E1E21);
		panel.x = 40;
		panel.y = 40;
		ui.content.addChild(panel);

		// a primary-action button
		var btn = new UIButton("Click me", 160, 34, () -> trace("clicked!"), true);
		btn.x = 80;
		btn.y = 90;
		ui.content.addChild(btn);
	}
}
```

When tearing a screen down, call `ui.dispose()` to remove listeners and free the tree.

## Examples

Runnable sources live in [`examples/`](examples/):

| File | What it shows |
| --- | --- |
| [`SmallExample.hx`](examples/SmallExample.hx) | The minimum: attach a root, a panel, a label and a button. |
| [`FullExample.hx`](examples/FullExample.hx) | Instantiates **every widget** — an icon rail switching three sections over a menu bar, with tabs, sliders, steppers, switches, checkboxes, segmented controls, icon buttons, a loading bar, a dropdown, text input, chip, keybind, icon, a data-bound list, collapsible accordions in a scroll pane, a modal, a context menu and toasts — plus font/theme/locale/tooltip setup. |
| [`FlixelExample.hx`](examples/FlixelExample.hx) | The `smidr.flixel.FlxSmidr` bridge on an `FlxState`: viewport matching, cursor handling, input arbitration, and a HUD label anchored to a world object. |

**Run** them as an OpenFL app (from the repo root):

```bash
lime test examples/project.xml windows              # FullExample (default)
lime test examples/project.xml windows -Dex_small   # SmallExample
lime test examples/project.xml windows -Dex_flixel  # FlixelExample (needs the flixel haxelib)
```

**Typecheck** them without a window (what CI runs):

```bash
haxe examples/check.hxml          # the two OpenFL examples
haxe examples/check-flixel.hxml   # the Flixel bridge example (needs -lib flixel)
```

## Documentation

**[Browse the API docs →](https://meguminbot.github.io/SmidrUI/)**

Full API docs are generated with [dox](https://github.com/HaxeFoundation/dox) (the same tool
behind the OpenFL and Flixel API sites) and published to GitHub Pages by
[`.github/workflows/docs.yml`](.github/workflows/docs.yml).

Build the site locally:

```bash
haxelib install dox
haxelib install flixel   # the smidr.flixel bridge is documented too, so flixel is required
haxe doc.hxml                                                      # -> doc/xml/smidr.xml
haxelib run dox -i doc/xml -o doc/site -in smidr --title "SmiðrUI API"
bash doc/apply-theme.sh                                            # recolor to the "Dark" palette
# open doc/site/index.html
```

## Architecture

- **`UIRoot`** — the stage-attached root. Three layers (`content` < `popupLayer` < `tooltipLayer`),
  the invalidation scheduler, the pointer arbiter, and the tween/tooltip driver. One
  `ENTER_FRAME` handler flushes dirty widgets and steps tweens.
- **`UIComponent`** — base widget: a retained `Sprite` with hover/press/click, drag capture,
  tooltips, and `dispose()`. Subclasses override `render()`.
- **`UITheme`** — the active palette + metric scale, all plain `0xAARRGGBB` ints. Mutate values
  or `apply()` a preset, then `changed()` to re-skin.
- **`UIFonts`** — `TextFormat`/`TextField` cache; `register()` swaps the library font.
- **`UILocale`** — assign `translate` to your lookup; call `refresh()` after a locale switch.
- **`UITween`** — tiny tween driver stepped by `UIRoot`.
- **`smidr.input`** — `UIFocus` (keyboard focus routing), `UIPointer` (press/capture arbiter),
  `IUIFocusable`.

## Theming

```haxe
import smidr.UITheme;

UITheme.apply(UITheme.PRESETS[2].palette); // "Midnight"
UITheme.applyAccent(0xFF3AA0FF);           // recolor the accent family from one hue
UITheme.setScale(1.25);                     // global density
```

Any of these re-render every live widget through `UIRoot.invalidateAll`.

## Localization

```haxe
import smidr.UILocale;

UILocale.translate = (key, fallback) -> myI18n.get(key, fallback);
// after switching language:
UILocale.refresh();
```

Widgets with a `localize(key, fallback)` method (e.g. `UIButton`) resolve through this hook.

## License

[MIT](LICENSE) © MeguminBOT
