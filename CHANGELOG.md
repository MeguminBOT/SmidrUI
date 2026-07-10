# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] — 2026-07-07

### Added
- `UIDropdown.searchable` -- combo-box type-ahead: while the popup is open, a search header shows
  the query and typing filters the entries (case-insensitive substring on the shown labels),
  Backspace edits, Escape clears then closes, and Enter picks the first match. Off by default, so
  existing dropdowns are unchanged.
- `UITreeView` -- a hierarchical, expandable tree built on `UIList` virtualization: a mutable
  `UITreeNode` model is flattened to its visible nodes and fed to the list, so a huge tree still
  only instantiates on-screen rows. Rows indent by depth and draw an expand/collapse chevron
  (chevron toggles the branch, elsewhere selects); `expandAll`/`collapseAll`, `onSelect`/
  `onActivate`/`onToggle`.
- `UIDataGrid` -- a virtualized data table: a fixed header of `UIDataColumn`s over a `UIList` of
  multi-cell rows. Provider-driven (`setData(rowCount, cell)`, never copies the source); clicking a
  sortable header sorts a display-order permutation in place (text or `numeric`), selection is kept
  in SOURCE row indices across sorts.
- `UITileGrid` -- a virtualized icon/tile grid: fixed-size tiles reflow into as many columns as the
  width allows and scroll vertically, recycling on-screen tiles like `UIList` (wheel + thumb + touch
  fling, arrow-key navigation). The default `UITile` draws an optional glyph over a centered label;
  custom tiles subclass `UITile` via `tileFactory`.
- `UIDockHost` -- editor-style panel docking: a tree of resizable splits with tabbed
  `UIDockGroup`s at the leaves. `UIDockPanel`s dock via `addPanel` / `dock(panel, target, zone)`
  or by dragging a tab (a drop-zone overlay shows where it lands: `CENTER` tabs into a group, the
  edges split it), emptied groups collapse, and split dividers drag to reproportion. Adds
  `smidr.types.UIDockZone`.
- `UIStack` -- a flow-layout container (row/column, `gap`/`padding`, `stretch` or `align`).
- `UISplitter` -- two resizable panes with a draggable divider (side-by-side or stacked).
- `UIRadioGroup` -- an exclusive vertical radio list (the counterpart to `UISegmentedControl`).
- `UIStatusBar` -- a themed bottom bar of left/right-aligned text cells with separators.
- `UIBalloon` -- a callout/popover with a directional tail that points at an anchor, shown on the
  popup layer with outside-click dismissal.
- `UIPieMenu` -- a radial menu of `UIMenuItem` sectors opened at a point.
- Color helpers on `UIColor`: `opaque(rgb)` (force a plain 6-digit `0xRRGGBB` opaque — bare hex
  literals are alpha 0, i.e. transparent), `fromRGB(r, g, b, ?a)`, `withAlpha(c, a)`, and HSV/HSL
  round-trips (`hsv`/`toHSV`, `hsl`/`toHSL`).
- The full easing set on `UIEase` -- the Penner families (SINE / CUBIC / QUART / QUINT / EXPO /
  CIRC / BACK / ELASTIC / BOUNCE) in `IN_*` / `OUT_*` / `IN_OUT_*` variants. The four originals
  keep their ids, so nothing breaks.
- `UIGradient` -- a linear/radial gradient fill (`linear`/`radial`/`vertical`/`horizontal`),
  opt-in on `UIPanel.gradient` and `UIButton.gradient` (overrides the flat `UIFill`; fixed colours,
  so it does not follow theme swaps).
- `UICursor` (named cursor shapes) + `UICursors` (global cursor override: `set`/`reset`/`busy`/
  `hide`/`show`). Custom bitmap cursors are not offered -- OpenFL 9.5.2 compiles out
  `Mouse.registerCursor`.
- `UIAnimation` -- preset transform animations on any `DisplayObject` over the pooled `UITween`,
  centre-pivoted: `FLY_IN`/`FLY_OUT`, `ZOOM_IN`/`ZOOM_OUT`, `FADE_IN`/`FADE_OUT`, `POP`, `FLIP`
  (2D scale fake), `REVOLVE`, `SHAKE`, `PULSE`. Plus `UIEdge` (`LEFT`/`TOP`/`RIGHT`/`BOTTOM`).
- `UIWindow` -- a draggable, titled window panel: widgets parented into its `content` move
  with the window automatically (display-list children), the title bar drags with viewport
  clamping, and the body follows the theme via a `UIFill`. The title bar is an interactive child
  (so widgets inside `content` stay clickable -- the window no longer disables `mouseChildren`),
  and it supports `closable` / `collapsible` / `resizable` chrome plus raise-to-front with
  active-window styling.
- `UIStepper` hold-to-repeat tuning: `repeatDelayMs` / `repeatStartMs` / `repeatMinMs` /
  `repeatAccel` (defaults softened from 500/140/28/0.92 to 400/180/60/0.95).
- `UIScrollPane` touch scrolling (`touchScroll`, default on for mobile): drag anywhere with
  fling momentum, mirroring `UIList` — a drag past the threshold steals the press so child
  widgets don't click, and yields to a deeper capture (e.g. a `UIList` inside the pane).
- Long-press-as-right-click on touch (`UIRoot.longPressMs` / `longPressEnabled`, default on
  for mobile): a held, unmoved press fires the pressed widget's `onRightPress`/`onRightClick`
  path — or peeks its tooltip when it has no right-click consumer — and steals the press so
  releasing never also clicks. `UIComponent.longPressable` opts in `onRightPress`-only
  subclasses; `UIRoot.onLongPress` is a feedback hook (haptics).
- `UIDrawer` — a persistent edge-docked slide-out for mobile layouts: swipe in from the
  viewport edge (`attachEdge()`), horizontally-dominant drags slide it while vertical drags
  pass through to inner scroll panes, and velocity/position settle it open or closed; scrim
  tap, Escape and `pushOverlayCloser` hosts close it.
- Mobile IME support in `UIFocus`: focusing a typing component raises the platform soft
  keyboard; committed text feeds the normal `onKeyDown(0, charCode)` path and
  Backspace/Enter/Escape are bridged from lime's window (deduplicated against the stage
  keyboard chain).

### Fixed
- Above-game roots stay above the camera layers: Flixel inserts every new camera's flash
  sprite at the input container's index, which landed on top of a root added earlier, so any
  state that reset or added cameras after `init()` rendered its whole UI invisible. The root
  now re-raises itself on `FlxG.cameras.cameraAdded`.
- Shared frame systems (dirty flush, tweens, tickers, tooltips) are now stepped only by the
  CURRENT root: overlapping or leaked roots each stepped them per frame, so caret blinks and
  stepper hold-repeats ran at a multiple of real time.
- `FlxSmidr` above-game roots were never scaled: Flixel's scale modes only offset `FlxG.game`
  and scale each camera internally, so `init()` UI rendered at 1:1 pixels and ignored window
  resizes/fullscreen. `syncViewport` now applies the scale mode's scale in both attach modes
  (offset too when stage-attached) and runs on `init` and every `gameResized`.

### Added
- `smidr.types.UIFill` -- what fills a themed rectangle: a theme slot
  (`BG`/`PANEL`/`PANEL2`/`PANEL3`/`CARD`/`INPUT`, re-read from the live palette every render)
  or a fixed ARGB colour, one `Int` at runtime. Slot names resolve unqualified and colour
  literals are accepted directly (`from Int`); `resolve()` returns the colour to paint.
- `UIColor.luminance(c)` and `UIColor.contrastText(bg)` helpers.
- A scrollable widget `Gallery` example (`-Dex_gallery`) with a responsive layout, a themed
  backdrop/status bar and a continuously animating progress bar.

### Fixed
- Accent/danger `UIButton` text (and its icon) now take their colour by contrast against the
  fill, so the label stays legible on light themes instead of going dark-on-dark.

### Changed
- **Breaking:** the non-widget files moved out of `smidr.widgets`. The static popup services
  `UIToast` / `UITooltip` / `UIContextMenu` are now in `smidr.overlays`, and the `UIMenuItem` /
  `UIRailTabDef` typedefs are now in `smidr.types`. Update imports accordingly; `smidr.widgets`
  now holds only `UIComponent` widgets.
- `UIPanel` is now theme-following by default: `fill` is a `UIFill`, and the constructor's
  colour argument became optional -- `new UIPanel(w, h)` paints the live `PANEL` slot and
  follows theme swaps like every other widget, `new UIPanel(w, h, CARD)` picks another slot,
  and existing `new UIPanel(w, h, 0xAARRGGBB)` calls keep compiling with the same fixed-colour
  behaviour as 0.2.x.
- A naming pass across the library for consistency and readability. **Breaking:**
  - `UILoadingBar` is renamed `UIProgressBar` and `UISegmented` is renamed `UISegmentedControl`
    (the docs already described them that way).
  - `UIIconRail`'s tab typedef `UIRailTab` is renamed `UIRailTabDef` (matching `UITabDef`/
    `UIMenuDef`), and its `caption` field is renamed `label`.
  - Callback names are normalized by payload: boolean toggles fire `onToggle(Bool)`
    (`UICheckbox`/`UISwitch` moved off `onChange`), index selectors fire `onSelect(Int)`
    (`UISegmentedControl` moved off `onChange`), and value editors keep `onChange(value)`.
  - The labelled-row widgets' right-hand column width is unified to `controlWidth`
    (was `boxWidth` on `UIStepper`/`UIDropdown`/`UITextInput`/`UIKeybind`/`UISegmentedControl`,
    `trackWidth` on `UISlider`, `barWidth` on `UIProgressBar`).
  - `UITheme.changed()` is renamed `UITheme.refresh()` to mirror `UILocale.refresh()`.

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
