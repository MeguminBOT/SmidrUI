# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] — 2026-07-07

### Added
- `smidr.types.UISurface` -- a theme surface role (`BG`/`PANEL`/`PANEL2`/`PANEL3`/`CARD`/`INPUT`).
- `UIPanel.solid(w, h, argb)` -- a fixed-colour panel for the rare static case (backdrops, brand).
- A scrollable widget `Gallery` example (`-Dex_gallery`) with a responsive layout, a themed
  backdrop/status bar and a continuously animating progress bar.

### Changed
- `UIPanel` is now theme-following by default: the constructor takes a `UISurface` role
  (`new UIPanel(w, h, PANEL)`) and re-reads the palette every render, so panels follow theme
  swaps like every other widget. **Breaking:** the old `new UIPanel(w, h, fill:Int)` and the
  `UIPanel.themed(...)` factory are removed -- use the role constructor, or `UIPanel.solid` for a
  fixed colour.
- `UISurface` is `to Int` only (no `from Int`), so a theme colour int can't be mistaken for a role.

## [0.2.1] — 2026-07-07

### Added
- `examples/` -- runnable `SmallExample`, `FullExample` and `FlixelExample` with a `project.xml`
  and typecheck `hxml`s.
- `UIFonts.libraryLoaded(id)` -- a silent guard for probing `openfl.utils.Assets`.
- `smidr.types` package of `enum abstract Int` value types -- `UIGlyph` (named glyph ids),
  `UITone` (`PRIMARY`/`SECONDARY`/`TERTIARY`), `UIEase` (`LINEAR`/`OUT_QUAD`/`OUT_BACK`/`IN_QUAD`)
  and `UICursorMode`. Each is just an `Int` at runtime, usable by name (unqualified where the type
  is expected, e.g. `new UILabel("x", 13, SECONDARY)`), and interchangeable with plain ints.
- `UIButton` now hosts a `UIIcon` -- `UIButton.icon(icon, size, ?onClick)` for an icon-only
  button, or `setIcon(icon)` for icon + label. The icon may be glyph- or asset-backed and follows
  the button's foreground tone unless it pins its own colour.
- `UIIcon.fromGlyph(glyph, size, tone)` and a `glyph` property draw a built-in vector glyph with
  no asset.

### Changed
- Glyph ids moved to `smidr.types.UIGlyph` (from `UIGlyphs`); `UIGlyphs.draw` takes a `UIGlyph`.
- `UITween` easings moved to `UIEase` (from `UITween.OUT_QUAD` etc.); `UILabel`/`UIIcon` `tone`
  now `UITone`; `FlxSmidr.cursorMode` now `UICursorMode` (the `CURSOR_*` consts moved onto it).
  All still accept raw ints (`from Int`).
- `UIIconButton` was removed and folded into `UIButton`: use `UIButton.icon(UIIcon.fromGlyph(...),
  size)` and toggle `accent` at runtime in place of the old `active`.

### Fixed
- `UIFonts.register` and `UIIcon` no longer emit `ERROR: There is no asset library named
  "default"` when the target asset (or a `default` asset library) is absent -- a missing asset
  now fails quietly, so a project that embeds no assets stays silent.

## [0.1.0] — 2026-07-05

### Added
- Initial release, extracted from an in-game UI layer into a standalone OpenFL library.
- Core: `UIRoot`, `UIComponent`, `UITheme`, `UIFonts`, `UILocale`, `UITween`, `UIColor`.
- Input: `UIFocus`, `UIPointer`, `IUIFocusable`.
- Widgets: buttons, icon buttons/rails, labels, panels, separators, chips, checkboxes,
  sliders, steppers, text inputs, dropdowns, context menus, menu bars, accordions,
  scroll panes, modals, tooltips, and toasts.
