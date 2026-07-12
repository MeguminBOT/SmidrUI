# Getting started with SmiðrUI

This guide takes you from an empty project to a running SmiðrUI app, and explains the handful of
classes you actually touch day to day. If you just want the one-screen version, the
[README quick start](../README.md#quick-start) has it; this page is the slower, "explain everything"
walkthrough.

SmiðrUI is a **retained-mode** UI toolkit for [OpenFL](https://www.openfl.org/): every widget is a
plain `openfl.display.Sprite` that repaints **only when something changes**. There is no per-frame
layout pass and no framework lock-in — it runs standalone on OpenFL, or above a game (there is an
optional Flixel bridge).

## Contents

1. [Prerequisites & install](#1-prerequisites--install)
2. [Set up the project](#2-set-up-the-project)
3. [The app skeleton](#3-the-app-skeleton)
4. [The classes you'll use](#4-the-classes-youll-use)
5. [Adding a widget](#5-adding-a-widget)
6. [Positioning & responsive layout](#6-positioning--responsive-layout)
7. [Theming](#7-theming)
8. [Keyboard focus & input](#8-keyboard-focus--input)
9. [Popups, menus, tooltips & toasts](#9-popups-menus-tooltips--toasts)
10. [Fonts & localization](#10-fonts--localization)
11. [Writing your own widget](#11-writing-your-own-widget)
12. [Desktop & mobile](#12-desktop--mobile)
13. [Building & running](#13-building--running)
14. [Tearing down](#14-tearing-down)
15. [Where to go next](#15-where-to-go-next)

---

## 1. Prerequisites & install

You need **Haxe 4.3+**, **Lime** and **OpenFL**. If you don't have them:

```bash
haxelib install lime
haxelib install openfl
haxelib run openfl setup
```

Then add SmiðrUI (haxelib id `smidr`):

```bash
haxelib install smidr
# or track the latest from git:
haxelib git smidr https://github.com/MeguminBOT/SmidrUI.git
```

## 2. Set up the project

A SmiðrUI app is a normal OpenFL app. Create a `project.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<project>
	<meta title="My App" package="com.example.myapp" version="0.1.0" company="Me" />
	<app main="Main" file="MyApp" path="bin" />
	<window width="900" height="600" fps="60" background="#121214" vsync="true" resizable="true" />

	<source path="src" />

	<haxelib name="openfl" />
	<haxelib name="smidr" />
</project>
```

Put your code under `src/`. The two `<haxelib>` lines are all SmiðrUI needs — OpenFL pulls in Lime.

## 3. The app skeleton

Your entry point is a `Sprite`. Inside it you create **one `UIRoot`**, attach it to the display, and
add widgets to its `content` layer:

```haxe
package;

import openfl.display.Sprite;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.widgets.UIButton;
import smidr.widgets.UIPanel;

class Main extends Sprite {
	var ui:UIRoot;

	public function new() {
		super();

		// 1. pick a palette (optional; defaults to the built-in dark theme)
		UITheme.apply(UITheme.PRESETS[0].palette); // "Dark"

		// 2. create the root and attach it above your content
		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1); // offsetX, offsetY, scaleX, scaleY

		// 3. add a background panel
		var panel = new UIPanel(240, 120);
		panel.x = 40;
		panel.y = 40;
		ui.content.addChild(panel);

		// 4. add a button
		var button = new UIButton("Click me", 160, 34, () -> trace("clicked!"), true);
		button.x = 80;
		button.y = 90;
		ui.content.addChild(button);
	}
}
```

That's a complete, runnable app. Set `<app main="Main" />` to match the class name.

`setViewport(offsetX, offsetY, scaleX, scaleY)` positions and scales the whole UI over your content.
For a plain UI app leave it at `(0, 0, 1, 1)`. It matters when you letterbox or render UI over a game
that scales differently — pass the same offset/scale your game uses so UI coordinates line up.

## 4. The classes you'll use

You interact with a small set of classes. Everything else is a widget under `smidr.widgets`.

| Class | What it is |
| --- | --- |
| **`smidr.UIRoot`** | The stage-attached root. Owns three layers — `content` (your widgets) < `popupLayer` (menus/modals) < `tooltipLayer` — plus the repaint scheduler and the pointer/keyboard plumbing. One per screen. |
| **`smidr.UIComponent`** | The base class of every widget: a retained `Sprite` with `w`/`h`, hover/press/click, drag capture, tooltips, and `dispose()`. You subclass it to make your own widgets. |
| **`smidr.UITheme`** | The active palette (plain `0xAARRGGBB` ints) and metric scale. Swap presets, recolor the accent, or set a density scale — the whole live tree re-skins. |
| **`smidr.UIFonts`** | Font/`TextFormat` cache. `register()` points every widget at an embedded font. |
| **`smidr.UILocale`** | Localization hook. Assign `translate`; widgets with a `localize(key, fallback)` method resolve through it. |
| **`smidr.UIColor`** | Colour maths: `rgb`, `mix`, `lighten`/`darken`, `opaque`, `fromRGB`, HSV/HSL, `contrastText`. |
| **`smidr.UITween`** | A tiny pooled tween driver (`UITween.to(...)`), stepped by `UIRoot`. |
| **`smidr.input`** | `UIFocus` (keyboard focus routing), `UIPointer` (press/capture arbiter), `IUIFocusable`. |

The mental model: **`UIRoot` drives one `ENTER_FRAME` that repaints only the widgets that called
`invalidate()`**. An idle screen does no work.

## 5. Adding a widget

Every built-in widget lives in `smidr.widgets`. Adding one is always the same three steps:
**construct → position → `addChild` to a layer** (usually `ui.content`). Wire behaviour with the
callback fields.

```haxe
import smidr.widgets.UITextInput;
import smidr.widgets.UISlider;
import smidr.widgets.UICheckbox;

// a labelled text field; onChange fires on every edit
var name = new UITextInput("Name", 260, "", (value) -> trace('name = $value'));
name.x = 40;
name.y = 200;
ui.content.addChild(name);

// a slider 0..100
var volume = new UISlider("Volume", 260, 0, 100, 50, (value) -> trace('volume = $value'));
volume.x = 40;
volume.y = 240;
ui.content.addChild(volume);

// a checkbox; onToggle fires with the new boolean
var mute = new UICheckbox("Mute", 120, false, (on) -> trace('mute = $on'));
mute.x = 40;
mute.y = 280;
ui.content.addChild(mute);
```

Common `UIComponent` fields you'll set on any widget:

- `x`, `y` — position (in UI units).
- `onClick`, `onRightClick`, `onHover` — pointer callbacks (interactive widgets only).
- `tooltip` — hover-tooltip text (needs `UITooltip.install()`, see below).
- `enabled` — `false` dims the widget and ignores the pointer.
- `hoverCursor` — the native cursor while hovering.

> **Constructing widgets that take a colour or an id**: some constructors take an *enum-abstract* value
> like `UIFill` (`BG`/`PANEL`/`CARD`), `UITone` (`PRIMARY`/`SECONDARY`/`TERTIARY`) or `UIGlyph`. You can
> write the bare name — `new UIPanel(240, 120, CARD)` — because it resolves against the expected type.
> No import of the value is needed.

To discover the full widget set, see the **[widget guide](https://meguminbot.github.io/SmidrUI/widgets.html)**
(every widget with its description) or browse [`src/smidr/widgets/`](../src/smidr/widgets/).

## 6. Positioning & responsive layout

SmiðrUI does not impose a layout engine — you set `x`/`y` and a size. Widgets carry a **layout size**
(`w`, `h`) separate from the DisplayObject's content-derived `width`/`height`; change it with
`resize(width, height)`.

For a resizable window, do your own layout in one function and call it whenever the stage resizes:

```haxe
import openfl.events.Event;

function onAddedToStage(_:Event):Void {
	stage.addEventListener(Event.RESIZE, (_) -> layout());
	layout();
}

function layout():Void {
	var w:Float = stage.stageWidth;
	var h:Float = stage.stageHeight;
	backdrop.resize(w, h);            // a full-window UIPanel
	toolbar.resize(w, 40);
	editor.x = 0;
	editor.y = 40;
	editor.resize(w, h - 40);
}
```

For flow layouts there are helpers — `UIStack` (row/column with gap & padding), `UISplitter`
(resizable panes), `UIScrollPane`, `UIList`/`UITreeView`/`UIDataGrid` (virtualized). The
[`examples/`](../examples/) apps show real responsive layouts (the gallery reflows a card masonry to
the window; the notepad is a full multi-pane editor).

## 7. Theming

All colours are plain ints on `UITheme`. Change them and re-skin the whole live tree:

```haxe
import smidr.UITheme;

UITheme.apply(UITheme.PRESETS[2].palette); // one of 4 built-in presets (Dark/Light/Midnight/Slate)
UITheme.applyAccent(0xFF3AA0FF);           // recolour the accent family from a single hue
UITheme.setScale(1.25);                     // global density multiplier (HiDPI / accessibility)
```

Any of these re-render every widget through `UIRoot.invalidateAll`. For touch screens,
`UITheme.applyMobilePreset()` bumps the density so controls are finger-sized (pair with
`clearMobilePreset()`).

Widgets read theme colours **at paint time**, so a theme swap is instant and automatic — you don't
re-create anything.

## 8. Keyboard focus & input

Exactly one widget holds keyboard focus at a time, managed by `smidr.input.UIFocus`. Text inputs and
other typing widgets implement `IUIFocusable`; `UIRoot` routes key events to the focused one and
consumes the keys it handles.

The one thing a host app checks is **`UIFocus.typing`** — it's `true` while a focused widget is
capturing raw typing. Gate your own keybinds on it so they don't fire while the user is typing:

```haxe
import smidr.input.UIFocus;

if (!UIFocus.typing) {
	// safe to handle app shortcuts here
}
```

On mobile, focusing a typing widget raises the soft keyboard automatically (the IME is bridged into
the same key path). Long-press acts as right-click on touch.

## 9. Popups, menus, tooltips & toasts

Transient UI lives on `UIRoot.popupLayer` / `tooltipLayer`, above your content, and closes on Escape
or an outside click. These are in `smidr.overlays`:

```haxe
import smidr.overlays.UITooltip;
import smidr.overlays.UIContextMenu;
import smidr.overlays.UIToast;
import smidr.types.UIMenuItem;

// call once at startup; afterwards any widget tooltip string shows on hover
UITooltip.install();

// a right-click context menu at a point, wired to your own handlers
var items:Array<UIMenuItem> = [
	{ label: "Rename", onSelect: renameSelected },
	{ separator: true },
	{ label: "Delete", onSelect: deleteSelected }
];
UIContextMenu.open(stage.mouseX, stage.mouseY, items);

// a transient toast
UIToast.show("Saved");
```

Modal dialogs are `smidr.widgets.UIModal` (add content to its `body`, call `open()`). Movable windows
are `UIWindow`; a slide-out drawer for mobile is `UIDrawer`.

## 10. Fonts & localization

By default widgets use the system sans font. To ship your own, embed it and register it once at
startup:

```haxe
import smidr.UIFonts;
UIFonts.register("assets/fonts/Inter.ttf"); // every widget now uses it
```

For translations, point `UILocale.translate` at your lookup and call `refresh()` after a language
switch. Widgets with a `localize(key, fallback)` method (e.g. `UIButton`, `UILabel`, `UITextInput`)
resolve through it:

```haxe
import smidr.UILocale;

UILocale.translate = (key, fallback) -> myI18n.get(key, fallback);
// later, after switching language:
UILocale.refresh();
```

## 11. Writing your own widget

When a built-in doesn't fit, subclass `UIComponent`, override `render()`, and call `invalidate()`
whenever your state changes. The constructor flavour picks the pointer behaviour:

- `super(true, true)` — interactive: hover/press/click (leaf widgets).
- `super(false, true)` — a passive surface that still swallows pointer hits (panels, backdrops);
  children stay interactive.
- `super(false, false)` — a pure layout group, pointer-transparent.

Here is a complete custom widget — a square that toggles colour when clicked:

```haxe
package;

import smidr.UIColor;
import smidr.UIComponent;
import smidr.UITheme;

class Swatch extends UIComponent {
	public var on(default, set):Bool = false;

	public function new(size:Float) {
		super(true, true); // interactive
		resize(size, size);
		render();
	}

	// UIComponent fires click() on a completed press+release; override to add behaviour
	override function click():Void {
		on = !on;
		super.click(); // still fire onClick if the caller set one
	}

	override public function render():Void {
		graphics.clear();
		var fill:Int = on ? UITheme.accentDark : UITheme.panel2;
		if (hovered)
			fill = UIColor.lighten(fill, 0.10);
		var radius:Float = UITheme.px(UITheme.radius) * 2;
		graphics.beginFill(UIColor.rgb(fill)); // UIColor.rgb strips the alpha byte for beginFill
		graphics.drawRoundRect(0, 0, w, h, radius, radius);
		graphics.endFill();
	}

	function set_on(value:Bool):Bool {
		on = value;
		invalidate(); // schedule a repaint on the next frame
		return value;
	}
}
```

Notes:

- **`render()` draws your full visual state** from `UITheme` colours, so theme swaps re-skin it for
  free. Read `hovered` / `pressed` there for interaction states.
- Hover and press already schedule a repaint (via `onStateChanged`), so a widget that reads `hovered`
  updates automatically.
- Call **`invalidate()`** (never `render()` directly) when your own data changes — it dedupes and
  repaints on the next frame.
- Use `UITheme.px(n)` for pixel metrics and `UITheme.fs(n)` for font sizes so your widget honours the
  global density scale.

Use it like any widget:

```haxe
var swatch = new Swatch(48);
swatch.x = 40;
swatch.y = 40;
swatch.onClick = () -> trace('now ${swatch.on}');
ui.content.addChild(swatch);
```

For a text-bearing widget, build a `TextField` with `UIFonts.make(size, color)` and add it as a child
(see `UILabel` for the minimal pattern). For a keyboard widget, implement `IUIFocusable`.

## 12. Desktop & mobile

The same widget code runs on both, but a few behaviours differ by form factor, and a couple of
helpers make a screen feel native on each. Gate the differences with Lime's `desktop` / `mobile`
defines (and per-OS `#if android` / `#if ios` / `#if windows` / `#if mac` / `#if linux` when needed):

```haxe
#if mobile
UITheme.applyMobilePreset(); // finger-sized controls
#end
```

### Mobile (Android / iOS)

- **Density** — call `UITheme.applyMobilePreset()` when a touch-first screen opens (and
  `clearMobilePreset()` when it closes). It bumps `UITheme.scale` so controls are finger-sized; because
  widgets use `UITheme.px()` / `fs()`, everything scales together.
- **Touch scrolling** — `UIList`, `UITreeView`, `UIDataGrid` and `UIScrollPane` scroll by dragging
  anywhere, with fling momentum (`touchScroll`, on by default on mobile). A drag past the threshold
  steals the press so a row does not also click.
- **Soft keyboard** — focusing a typing widget raises the platform IME automatically; committed text
  and Backspace/Enter/Escape are bridged into the normal key path, so `UITextInput` / `UITextArea` work
  with no extra code.
- **Long-press = right-click** — a held press fires the widget's right-click path (`onRightClick` / a
  context menu), or peeks its tooltip. Tune `UIRoot.longPressMs`; hook `UIRoot.onLongPress` for haptics.
- **Slide-out panels** — `UIDrawer` is an edge-docked drawer for side content that does not fit on a
  phone. Swipe in from the edge (`attachEdge()`) or call `open()`; put content in its `content`:

```haxe
import smidr.widgets.UIDrawer;

var drawer = new UIDrawer(LEFT, 300); // dock to the left, 300 units wide
drawer.attachEdge();                  // enable the edge-swipe strip
menuButton.onClick = drawer.open;
// add navigation widgets into drawer.content ...
```

- **project.xml** — a phone build usually wants portrait, fullscreen and high-DPI:

```xml
<window if="mobile" orientation="portrait" fullscreen="true" allow-high-dpi="true" />
<window unless="mobile" width="400" height="740" resizable="true" />
```

There is **no native file dialog on mobile** — persist to app storage instead (a `SharedObject`, or
`sys.io.File` under the app directory). The [`examples/notepad-mobile/`](../examples/notepad-mobile/)
app shows the whole picture: a `UIDrawer` note list, the mobile density preset, and the soft-keyboard
editor.

### Desktop (Windows / macOS / Linux)

- **Right-click menus** — `onRightClick` fires on a real right press; open a `UIContextMenu` at the
  pointer (see [section 9](#9-popups-menus-tooltips--toasts)).
- **Mouse wheel & scrollbars** — the scrolling widgets take wheel input and show a draggable thumb.
- **Cursors** — set `hoverCursor` per widget (e.g. an I-beam on a text field), or drive a global
  cursor with `UICursors.set(...)` / `reset()` (e.g. a wait cursor during a load).
- **Native file dialogs** — use `lime.ui.FileDialog` for Open / Save, and `sys.io.File` to read/write:

```haxe
#if desktop
import lime.ui.FileDialog;
import lime.ui.FileDialogType;

var dialog = new FileDialog();
dialog.onSelect.add(onFilePicked); // receives a String path
dialog.browse(FileDialogType.OPEN, "txt,md", null, "Open a file");
#end
```

- **Resizable window** — handle the stage `RESIZE` event and re-run your `layout()` (see
  [section 6](#6-positioning--responsive-layout)).

The [`examples/notepad/`](../examples/notepad/) app is the desktop counterpart to the mobile one:
native file dialogs, right-click context menus, wheel scrolling and a resizable multi-pane layout.

## 13. Building & running

From your project folder:

```bash
lime test project.xml windows   # or mac / linux / html5 / hl / android / ios
lime build project.xml html5    # a static web build -> bin/html5/bin
```

To typecheck without opening a window (handy for CI), point Haxe at your sources against Lime/OpenFL
on the hxcpp target, e.g.:

```bash
haxe -cp src -lib lime -lib openfl -lib hxcpp Main -cpp bin/check --no-output
```

Supported targets: Windows, macOS, Linux, HTML5, HashLink, and Android (iOS compiles at the source
level). Use `#if desktop` / `#if mobile` and per-OS gates (`#if android`, etc.) where a screen differs
by form factor.

## 14. Tearing down

When you leave a screen, dispose the root. It removes listeners, frees the widget tree, cancels
tweens, and clears the statics:

```haxe
public function destroy():Void {
	if (ui != null) {
		ui.dispose();
		ui = null;
	}
}
```

Individual widgets have `dispose()` too, but `UIRoot.dispose()` walks and frees the whole tree for you.

## 15. Where to go next

- **[Widget guide](https://meguminbot.github.io/SmidrUI/widgets.html)** — every widget with its
  description.
- **[Live examples](https://meguminbot.github.io/SmidrUI/examples/)** — run them in the browser; read
  the source under [`examples/`](../examples/) (calculator, widget gallery, notepad, snipping tool,
  Flixel bridge).
- **[API reference](https://meguminbot.github.io/SmidrUI/api/)** — the full member reference.
- **Game integration** — if you use HaxeFlixel, `smidr.flixel.FlxSmidr` handles viewport matching,
  cursor and input arbitration (compiled only when the `flixel` haxelib is present).
