# Contributing to SmiðrUI

Thanks for helping out. SmiðrUI is a **retained-mode UI toolkit for OpenFL** — widgets are plain
`openfl.display.Sprite`s that repaint only when invalidated, with no dependency on any game framework.
The conventions below exist to keep it that way: fast, typed, framework-free and consistent. Please
read them before opening a pull request — they are enforced in review.

If you are new to the library itself, start with the
[Getting started guide](doc/getting-started.md).

## Getting set up

You need **Haxe 4.3+** with **Lime**, **OpenFL** and **hxcpp** (plus **flixel** + **hscript** if you
touch the Flixel bridge or its example):

```bash
haxelib install lime
haxelib install openfl
haxelib install hxcpp
haxelib install flixel   # only for the smidr.flixel bridge
```

The layout:

```
src/smidr/        the library
  widgets/        UIComponent widgets
  overlays/       popup services (tooltip, toast, context menu)
  types/          enum-abstract value types and typedefs
  input/          focus + pointer plumbing
  text/           rich-text modules (styler, markdown, style vocabulary)
  flixel/         the optional HaxeFlixel bridge
examples/         self-contained example apps (each with its own project.xml)
doc/              docs site sources + the getting-started guide
```

## Before you open a PR

Run the typecheck suite from the repo root — this is what CI runs, and it must pass:

```bash
haxe check.hxml                 # the whole library, on the hxcpp (native) target
haxe examples/check.hxml        # the OpenFL examples
haxe examples/check-flixel.hxml # the Flixel bridge example (needs -lib flixel)
```

Then, if your change has any runtime behaviour (almost anything that is not a docs/typing-only
tweak): **build and run at least one example natively and confirm the behaviour** — do not rely on a
green typecheck alone. A widget can compile and still mis-render or mishandle input.

```bash
lime test examples/gallery/project.xml windows   # or another example / target
```

Finally, format your changes with the Haxe formatter so diffs stay clean:

```bash
haxelib run formatter -s src
```

## Code style (enforced)

### Strict typing

- **Explicit types on the whole public surface**: every field, function parameter and return type is
  annotated. Type locals too; the only inference we lean on is obvious one-liners like
  `var root = UIRoot.current;`.
- **Avoid `Dynamic`.** If you reach for it, there is almost always a typedef, enum abstract or type
  parameter that expresses the intent. Avoid reflection entirely in hot paths.
- Prefer **`final`** for fields that never reassign and **`inline`** for tiny hot helpers. These lower
  to tighter native code under hxcpp.

### Naming

- **Full-word identifiers.** No single-letter names (`c`, `n`, `r`, `v`, `g`, …) — write `count`,
  `radius`, `value`, `component`, and draw with the `graphics` property directly (not a `var g =
  graphics` alias). The only allowed single letters are the conventional ones: `i`/`j`/`k` for loop
  indices and `x`/`y`/`w`/`h` for position and size.
- Widget classes are **`UI`-prefixed** (`UIButton`, `UIPanel`). Named ids / value types are
  `enum abstract`s in `smidr.types` (e.g. `UIGlyph`, `UITone`, `UIFill`) so callers write
  `CHEVRON_LEFT` / `SECONDARY` and they compile to plain ints.
- Respect the package split: `smidr.widgets` (UIComponents), `smidr.overlays` (popup services),
  `smidr.types` (enum abstracts + typedefs), `smidr.input`, `smidr.text`, `smidr.flixel`.

### Comments & docstrings

- **Public classes and members get a Haxe docstring** (`/** … **/`). The widget guide on the docs site
  is generated from each widget's **leading class docstring**, so a new widget without one will not
  appear there. Write full sentences; reference other types with markdown backticks.
- **No inline `//` noise.** A comment should explain *why*, not restate the code.
- **No decorative separators** in code — not box-drawing rules and not `// --- section ---` dashes.
  Let the structure and docstrings do the work.

### The "smidr" name

- The package id, haxelib id and every code identifier use plain **`smidr`**. The stylized **`SmiðrUI`**
  is only for prose (README, docstring descriptions, UI text) — never in tags, ids or type names.

### Formatting

- **Tabs** for indentation. Run `haxelib run formatter` before committing.

## Architecture rules

These keep the core model intact. A change that breaks one of them will be asked to rework, even if it
compiles.

### Retained-mode & invalidation

- Widgets repaint **only** when `invalidate()` is called — never call `render()` directly to force a
  repaint after a state change. (Calling `render()` once at the end of a constructor for the initial
  paint, as the built-in widgets do, is the one accepted direct call.)
- Read `UITheme` colours and `UILocale` strings **inside `render()`**, so a theme or locale swap
  re-skins the live tree for free.
- **An idle UI must do zero per-frame work.** Do not add `ENTER_FRAME` handlers or standing tickers
  that run when nothing is changing. Use `UIRoot.addTicker` only while something animates (a caret
  blink, a hold-repeat) and `removeTicker` the moment it stops.
- Use `UITheme.px(n)` for pixel metrics and `UITheme.fs(n)` for font sizes so the global density scale
  is honoured.

### Keep generic widgets generic

- A general-purpose widget must **not** carry app- or domain-specific logic. Put policy in an
  *installable module behind an interface*, exposed as a property — e.g. `UITextArea` is style-agnostic
  and defers to an installed `smidr.text.UITextStyler` (`UIRichStyler` is the concrete WYSIWYG module).
  The dependency points widgets → a small interface, never the reverse.

### No framework lock-in

- The core depends on **OpenFL only**. The Flixel bridge in `smidr.flixel` compiles only when the
  `flixel` haxelib is present — keep it gated and never pull flixel (or any game framework) into the
  core widgets.

### Platforms

- Support **Windows, macOS, Linux, HTML5, HashLink and Android** (iOS must compile at the source
  level). Gate form-factor differences with `#if desktop` / `#if mobile`, and per-OS behaviour with
  `#if android` / `#if ios` / `#if windows` / `#if mac` / `#if linux`.

## Good and bad examples

Before/after snippets for the things that come up most in review. The left column is what gets a PR
sent back; the right column is what we merge.

### Strict typing

```haxe
// bad: untyped field, untyped setter, and Dynamic
public var value;
function set(v) {
	value = v;
}
var data:Dynamic = load();
```

```haxe
// good: explicit types everywhere, a real model type instead of Dynamic
public var value(default, set):Float = 0;

function set_value(next:Float):Float {
	value = next;
	invalidate();
	return next;
}

var data:NoteModel = load();
```

### Naming

```haxe
// bad: terse single-letter locals
for (i in 0...rows.length) {
	var r = rows[i];
	var n = r.parent.children.length;
}
```

```haxe
// good: full words (the loop index i is fine; r and n are not)
for (i in 0...rows.length) {
	var row = rows[i];
	var count = row.parent.children.length;
}
```

### Repaint through invalidation

```haxe
// bad: mutating and forcing a paint by hand
public var label:String;

public function setLabel(text:String):Void {
	label = text;
	render(); // never call render() directly
}
```

```haxe
// good: a set_* that schedules a repaint
public var label(default, set):String;

function set_label(next:String):String {
	label = next;
	invalidate(); // repaints on the next frame, deduplicated
	return next;
}
```

### Read the theme at paint time

```haxe
// bad: colour captured in the constructor; a theme swap will not re-skin it
public function new() {
	super(true, true);
	graphics.beginFill(UIColor.rgb(UITheme.panel2));
	graphics.drawRect(0, 0, w, h);
}
```

```haxe
// good: drawn in render() from the live palette, straight onto the graphics property
override public function render():Void {
	graphics.clear();
	graphics.beginFill(UIColor.rgb(UITheme.panel2));
	graphics.drawRect(0, 0, w, h);
	graphics.endFill();
}
```

### No standing per-frame work

```haxe
// bad: a ticker that runs every frame forever, even when nothing changes
public function new() {
	super();
	UIRoot.addTicker(step);
}

function step(dtMs:Float):Void {
	invalidate();
}
```

```haxe
// good: the ticker exists only while something animates
function startSpin():Void {
	spinning = true;
	UIRoot.addTicker(step);
}

function stopSpin():Void {
	spinning = false;
	UIRoot.removeTicker(step);
}
```

### Comments & docstrings

```haxe
// bad: a decorative divider, a missing class docstring (so it never reaches the widget guide),
// and comments that just restate the code
// ----- Rating widget -----
class UIRating extends UIComponent {
	// the value
	public var value:Int;
}
```

```haxe
// good: a class docstring feeds the generated guide; members are documented, not narrated
/**
	A star rating with a live hover preview. `onChange` fires with the newly picked value.
**/
final class UIRating extends UIComponent {
	/** The selected number of stars (0..`max`). **/
	public var value(default, set):Int = 0;
}
```

### Keep generic widgets generic

```haxe
// bad: a general text editor that reaches into the app note store
class UITextArea extends UIComponent {
	function onEdit():Void {
		NoteStore.current.body = text;
		NoteStore.save();
	}
}
```

```haxe
// good: the widget just reports edits; the app wires the policy
// in the widget:
public var onChange:String->Void = null;

// in the app:
editor.onChange = function(text:String):Void {
	note.body = text;
	store.save();
};
```

## Adding a widget

1. Create `src/smidr/widgets/UIXxx.hx` with `class UIXxx extends UIComponent` (`final class` unless it
   is meant to be subclassed).
2. Pick the constructor flavour via `super(interactive, blocking)`:
   - `super(true, true)` — interactive leaf (hover/press/click).
   - `super(false, true)` — passive surface that still swallows pointer hits (panels, backdrops).
   - `super(false, false)` — pure layout group, pointer-transparent.
3. Override `render()`; draw from theme colours (`UIColor.rgb(UITheme.panel2)`), size with
   `UITheme.px()`.
4. Expose state as `public var foo(default, set)` where `set_foo` calls `invalidate()` — never mutate
   and repaint by hand.
5. Add the **leading class docstring** (required for the generated widget guide).
6. Keyboard input → implement `smidr.input.IUIFocusable`. A popup/menu → live on `UIRoot.popupLayer`
   and register a closer with `UIRoot.pushOverlayCloser`.
7. Optionally add a demo to the widget gallery (`examples/gallery/`) so it shows up in the live
   examples.
8. Run the checks above and add a CHANGELOG entry.

## Examples

- Each example is a self-contained folder under `examples/` with its own `project.xml`. Add a new one
  to `examples/check.hxml` (its `-cp` and main class) so CI typechecks it.
- Because the checks compile several example mains together, keep example-only helper classes in a
  **named package** (e.g. `package notepad;`), not the empty package, so they cannot collide with
  another example's classes.

## Changelog & commits

- Add an entry under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md) (Keep a Changelog format).
  Prefix API breaks with **Breaking:**.
- Commit messages: imperative mood, a concise subject, **ASCII only — no em dashes** (use hyphens).

## What not to commit

Everything below is gitignored; keep it out of PRs: build output (`bin/`, `export/`, `.temp/`,
`dump/`), `.haxelib/`, generated docs (`doc/xml/`, `doc/site/`), and the packaging zip.

## License

SmiðrUI is [MIT](LICENSE) licensed. By contributing, you agree your contributions are licensed under
the same terms.
