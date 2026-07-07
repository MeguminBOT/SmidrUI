# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `examples/` -- runnable `SmallExample`, `FullExample` and `FlixelExample` with a `project.xml`
  and typecheck `hxml`s.
- `UIFonts.libraryLoaded(id)` -- a silent guard for probing `openfl.utils.Assets`.
- `UIGlyph` -- an `enum abstract Int` of the named glyph ids, so callers can write
  `UIGlyphs.draw(g, CHEVRON_LEFT, ...)` (unqualified) or `UIGlyph.STAR`. Zero runtime cost and
  interchangeable with plain ints.

### Changed
- The glyph id constants moved from `UIGlyphs` to `UIGlyph` (`UIGlyphs.PLAY` -> `UIGlyph.PLAY`,
  `UIGlyphs.COUNT` -> `UIGlyph.COUNT`). `UIGlyphs.draw` now takes a `UIGlyph`; raw-int calls
  still compile.

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
