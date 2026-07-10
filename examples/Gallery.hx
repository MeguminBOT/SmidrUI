package;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import smidr.UIAnimation;
import smidr.UIColor;
import smidr.UIGradient;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.types.UIAnimationPreset;
import smidr.types.UIGlyph;
import smidr.widgets.UIAccordion;
import smidr.widgets.UIBadge;
import smidr.widgets.UIBalloon;
import smidr.widgets.UIBreadcrumb;
import smidr.widgets.UIButton;
import smidr.widgets.UICheckbox;
import smidr.widgets.UIChip;
import smidr.widgets.UIColorPicker;
import smidr.overlays.UIContextMenu;
import smidr.widgets.UIDataGrid;
import smidr.widgets.UIDataGrid.UIDataColumn;
import smidr.widgets.UIDateTimePicker;
import smidr.widgets.UIDockHost;
import smidr.widgets.UIDockPanel;
import smidr.widgets.UIDropdown;
import smidr.widgets.UIExpander;
import smidr.widgets.UIIcon;
import smidr.widgets.UIIconRail;
import smidr.widgets.UIKeybind;
import smidr.widgets.UILabel;
import smidr.widgets.UIList;
import smidr.widgets.UIProgressBar;
import smidr.widgets.UIMenuBar;
import smidr.widgets.UIModal;
import smidr.widgets.UIPanel;
import smidr.widgets.UIPieMenu;
import smidr.widgets.UIRadioGroup;
import smidr.widgets.UIRating;
import smidr.widgets.UIScrollPane;
import smidr.widgets.UISpinner;
import smidr.widgets.UISegmentedControl;
import smidr.widgets.UIStatusBar;
import smidr.widgets.UISeparator;
import smidr.widgets.UISlider;
import smidr.widgets.UISplitter;
import smidr.widgets.UIStack;
import smidr.widgets.UIStepper;
import smidr.widgets.UISwitch;
import smidr.widgets.UITabs;
import smidr.widgets.UITextInput;
import smidr.widgets.UITileGrid;
import smidr.widgets.UIToolbar;
import smidr.widgets.UITreeView;
import smidr.widgets.UITreeView.UITreeNode;
import smidr.overlays.UIToast;
import smidr.overlays.UITooltip;
import smidr.widgets.UIWindow;

/**
	A scrollable gallery of every widget, each wired to a status line. Meant to be compiled to a
	small test executable so users can poke at the whole library in one window. The layout is
	responsive: a fixed-width column of widgets stays centred while the themed backdrop, menu bar
	and status bar span the window and the scroll viewport grows with the window height.

	Build it (from the repo root):
	```bash
	lime test examples/project.xml windows -Dex_gallery
	```
**/
class Gallery extends Sprite {
	static inline var MENU_H:Float = 28;
	static inline var STATUS_H:Float = 30;
	static inline var TOP:Float = MENU_H + 40; // where the scroll viewport starts
	static inline var PANE_W:Float = 540;       // fixed content column width (kept, so widgets don't reflow)
	static inline var INNER:Float = 14;         // left inset inside the scroll content
	static inline var GUTTER:Float = 14;         // right gutter for the scrollbar
	static inline var COL:Float = PANE_W - INNER - GUTTER;

	var ui:UIRoot;
	var backdrop:UIPanel;
	var menubar:UIMenuBar;
	var title:UILabel;
	var scroll:UIScrollPane;
	var statusBg:UIPanel;
	var statusTf:UILabel;
	var bar:UIProgressBar;
	var demoAnim:UIAnimation = null;

	var cy:Float = 0;        // build cursor inside the scroll content
	var contentH:Float = 0;  // total content height (for refreshContent on resize)
	var progT:Float = 0;     // continuous-progress accumulator

	public function new() {
		super();

		UILocale.translate = (key, fallback) -> fallback;
		UITheme.apply(UITheme.PRESETS[0].palette); // Dark

		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);
		UITooltip.install();

		// themed, full-window backdrop (follows theme swaps because it's bound to a theme slot)
		backdrop = new UIPanel(100, 100, BG, false);
		ui.content.addChild(backdrop);

		buildMenuBar();

		title = new UILabel("SmiðrUI — widget gallery", 15, PRIMARY);
		ui.content.addChild(title);

		scroll = new UIScrollPane(PANE_W, 100);
		ui.content.addChild(scroll);

		statusBg = new UIPanel(100, STATUS_H, PANEL2);
		statusBg.borderTop = true;
		ui.content.addChild(statusBg);
		statusTf = new UILabel("", 12, SECONDARY);
		ui.content.addChild(statusTf);

		buildRows();
		contentH = cy;
		scroll.refreshContent(contentH);

		UIRoot.addTicker(tick); // drive the continuous progress bar

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			layout();

		setStatus("Ready — scroll and try the widgets.");
	}

	// responsive layout
	function onAddedToStage(_:Event):Void {
		stage.addEventListener(Event.RESIZE, onResize);
		layout();
	}

	function onResize(_:Event):Void {
		layout();
	}

	function layout():Void {
		var sw:Float = (stage != null) ? stage.stageWidth : 600;
		var sh:Float = (stage != null) ? stage.stageHeight : 780;

		backdrop.resize(sw, sh);
		menubar.resize(sw, MENU_H);

		var sx:Float = Math.max(0, (sw - PANE_W) / 2); // centre the fixed column
		title.x = sx + INNER;
		title.y = MENU_H + 8;

		scroll.x = sx;
		scroll.y = TOP;
		scroll.resize(PANE_W, Math.max(80, sh - TOP - STATUS_H));
		scroll.refreshContent(contentH);

		statusBg.resize(sw, STATUS_H);
		statusBg.y = sh - STATUS_H;
		statusTf.x = sx + INNER;
		statusTf.y = sh - STATUS_H + (STATUS_H - 16) / 2;
	}

	// scaffolding
	function buildMenuBar():Void {
		menubar = new UIMenuBar(100, MENU_H);
		menubar.brand = "smidr";
		menubar.setMenus([
			{
				title: "File",
				items: () -> [
					{label: "Say hi", shortcut: "Ctrl+H", onSelect: () -> setStatus("Menu: Say hi")},
					{separator: true},
					{label: "Quit", onSelect: () -> setStatus("Menu: Quit (wire me up)")}
				]
			},
			{
				title: "Theme",
				items: () -> [for (i in 0...UITheme.PRESETS.length) {
					label: UITheme.PRESETS[i].name,
					onSelect: applyTheme.bind(i)
				}]
			}
		]);
		ui.content.addChild(menubar);
	}

	function applyTheme(i:Int):Void {
		UITheme.apply(UITheme.PRESETS[i].palette);
		setStatus('Theme: ${UITheme.PRESETS[i].name}');
	}

	function setStatus(msg:String):Void {
		statusTf.text = msg;
		UIToast.show(msg);
	}

	function head(name:String):Void {
		var l = new UILabel(name, 11, TERTIARY);
		l.x = INNER;
		l.y = cy;
		scroll.content.addChild(l);
		cy += 18;
	}

	function put(o:DisplayObject, height:Float):Void {
		o.x = INNER;
		o.y = cy;
		scroll.content.addChild(o);
		cy += height + 16;
	}

	function rule():Void {
		var s = new UISeparator(COL);
		s.x = INNER;
		s.y = cy;
		scroll.content.addChild(s);
		cy += 14;
	}

	// continuous progress: loop the bar 0 -> 1 forever
	function tick(dtMs:Float):Void {
		if (bar == null)
			return;
		progT += dtMs;
		var period:Float = 2600;
		bar.setProgress((progT % period) / period, false);
	}

	// the widgets
	function buildRows():Void {
		cy = 10;

		head("UILabel");
		put(new UILabel("Primary / secondary / tertiary tones", 13, PRIMARY), 20);

		head("UIButton — default / accent / danger");
		var bDefault = new UIButton("Default", 120, 32, () -> setStatus("Button: Default"));
		bDefault.tooltip = "A plain button";
		var bAccent = new UIButton("Accent", 120, 32, () -> setStatus("Button: Accent"), true);
		var bDanger = new UIButton("Danger", 120, 32, () -> setStatus("Button: Danger"));
		bDanger.danger = true;
		bAccent.x = 132;
		bDanger.x = 264;
		var buttonRow = new Sprite();
		buttonRow.addChild(bDefault);
		buttonRow.addChild(bAccent);
		buttonRow.addChild(bDanger);
		put(buttonRow, 32);

		head("UIButton.icon — icon-only");
		var iconRow = new Sprite();
		var glyphs:Array<UIGlyph> = [PLAY, PAUSE, GEAR, SEARCH, TRASH, HEART];
		for (i in 0...glyphs.length) {
			var g = glyphs[i];
			var ib = UIButton.icon(UIIcon.fromGlyph(g, 16), 32, () -> setStatus('Icon button ${(g : Int)}'));
			ib.x = i * 40;
			iconRow.addChild(ib);
		}
		put(iconRow, 32);

		head("UIIcon.fromGlyph — vector icons, no assets");
		var iconStrip = new Sprite();
		var strip:Array<UIGlyph> = [STAR, BELL, HOME, USER, LOCK, IMAGE, FOLDER, CLOCK];
		for (i in 0...strip.length) {
			var ic = UIIcon.fromGlyph(strip[i], 20, SECONDARY);
			ic.x = i * 30;
			iconStrip.addChild(ic);
		}
		put(iconStrip, 24);

		rule();

		head("UICheckbox");
		put(new UICheckbox("Enable feature", COL, true, (on) -> setStatus('Checkbox: $on')), 24);

		head("UISwitch");
		put(new UISwitch("Dark mode", COL, true, (on) -> setStatus('Switch: $on')), 26);

		head("UIChip");
		put(new UIChip("Beta", true, false, (on) -> setStatus('Chip: $on')), 26);

		rule();

		head("UISlider");
		var slider = new UISlider("Volume", COL, 0, 1, 0.7, (v) -> setStatus('Slider: ${Math.round(v * 100)}%'));
		slider.decimals = 2;
		put(slider, 40);

		head("UIStepper");
		var stepper = new UIStepper("Count", COL, 3, 1, (v) -> setStatus('Stepper: $v'));
		stepper.min = 0;
		stepper.max = 10;
		put(stepper, 34);

		head("UISegmentedControl");
		var seg = new UISegmentedControl("Quality", COL, ["Low", "Med", "High"], (i) -> setStatus('Segmented: $i'));
		seg.select(1);
		put(seg, 30);

		rule();

		head("UIDropdown");
		var dd = new UIDropdown("Resolution", COL, (i, value) -> setStatus('Dropdown: $value'));
		dd.setItems(["1280x720", "1920x1080", "2560x1440"]);
		dd.select(1);
		put(dd, 34);

		head("UIDropdown — searchable (type to filter)");
		var timezone = new UIDropdown("Timezone", COL, (i, value) -> setStatus('Timezone: $value'));
		timezone.searchable = true;
		timezone.setItems([
			"UTC", "London", "Paris", "Berlin", "Cairo", "Moscow", "Dubai", "Karachi", "Mumbai",
			"Bangkok", "Shanghai", "Tokyo", "Sydney", "Auckland", "Honolulu", "Los Angeles",
			"Denver", "Chicago", "New York", "Sao Paulo"
		]);
		put(timezone, 34);

		head("UIDateTimePicker — calendar popup");
		var datePick = new UIDateTimePicker("Release date", COL, null, (d) -> setStatus('Date: ${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}'));
		put(datePick, 34);

		head("UIDateTimePicker — with time");
		var dtPick = new UIDateTimePicker("Meeting", COL, null, (d) -> setStatus('When: ${d.toString()}'));
		dtPick.showTime = true;
		put(dtPick, 34);

		head("UITextInput");
		var input = new UITextInput("Name", COL, "Player", (t) -> setStatus('Input: $t'));
		input.onEnter = (t) -> setStatus('Entered: $t');
		put(input, 40);

		head("UIKeybind — click, then press a key");
		put(new UIKeybind("Jump", COL, 32, (code) -> setStatus('Keybind: $code')), 34);

		rule();

		head("UITabs");
		put(new UITabs(COL, [{label: "One"}, {label: "Two"}, {label: "Three"}], (i) -> setStatus('Tab: $i')), 34);

		head("UIIconRail");
		put(new UIIconRail(56, 132, [{label: "A"}, {label: "B"}, {label: "C"}], (i) -> setStatus('Rail: $i')), 132);

		rule();

		head("UIAccordion");
		var bodyA = new Sprite();
		var acc = new UIAccordion("Details", COL, true, (open) -> {
			bodyA.visible = open;
			setStatus('Accordion: $open');
		});
		put(acc, 22);
		var l1 = new UILabel("• a detail line", 12, SECONDARY);
		var l2 = new UILabel("• another detail", 12, SECONDARY);
		l2.y = 18;
		bodyA.addChild(l1);
		bodyA.addChild(l2);
		put(bodyA, 40);

		head("UIProgressBar — auto-animating");
		bar = new UIProgressBar("Downloading", COL, 0.0);
		bar.showPercent = true;
		put(bar, 30);

		head("UISpinner / UIRating / UIBadge");
		var indicators = new Sprite();
		var spin = new UISpinner(28);
		indicators.addChild(spin);
		var rating = new UIRating(5, 3, (n) -> setStatus('Rating: $n'));
		rating.x = 48;
		rating.y = 4;
		indicators.addChild(rating);
		var badgeBtn = new UIButton("Inbox", 90, 30, () -> setStatus("Inbox"));
		badgeBtn.x = 220;
		indicators.addChild(badgeBtn);
		var badge = new UIBadge(7);
		badge.x = 220 + 90 - 12;
		badge.y = -6;
		indicators.addChild(badge);
		put(indicators, 34);

		rule();

		head("UIList — data-bound rows");
		var items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Kiwi"];
		var list = new UIList(COL, 132);
		list.setProvider(items.length, (i) -> items[i]);
		list.onSelect = (i) -> setStatus('List select: ${items[i]}');
		list.onActivate = (i) -> setStatus('List activate: ${items[i]}');
		put(list, 132);

		rule();

		head("UIPanel — theme-following card");
		var panel = new UIPanel(COL, 56, CARD);
		panel.corner = 8;
		panel.outline = true;
		var pl = new UILabel("A card surface that follows the theme", 12, SECONDARY);
		pl.x = 12;
		pl.y = 18;
		panel.addChild(pl);
		put(panel, 56);

		rule();

		head("UIModal / UIContextMenu / UIToast");
		var openBtn = new UIButton("Open modal", 130, 30, () -> openModal(), true);
		var toastBtn = new UIButton("Show toast", 130, 30, () -> setStatus("Toast fired"));
		toastBtn.x = 142;
		var overlayRow = new Sprite();
		overlayRow.addChild(openBtn);
		overlayRow.addChild(toastBtn);
		put(overlayRow, 30);

		// onRightClick only fires on interactive widgets (UILabel is pointer-transparent), so the
		// context-menu target is a button; left-click opens it too, for discoverability.
		var ctxBtn = new UIButton("Right-click (or click) me", 220, 30, () -> openContextMenu());
		ctxBtn.onRightClick = openContextMenu;
		put(ctxBtn, 30);

		rule();

		head("UIGradient — linear panel + gradient button");
		var gpanel = new UIPanel(COL, 44);
		gpanel.corner = 8;
		gpanel.gradient = UIGradient.linear([UIColor.opaque(0x2A2440), UIColor.opaque(0x4A3A7E)], 90);
		put(gpanel, 44);
		var gbtn = new UIButton("Gradient button", 180, 34, () -> setStatus("Gradient button"));
		gbtn.gradient = UIGradient.horizontal(UITheme.accentDark, UITheme.accentAlt);
		put(gbtn, 34);

		head("UIAnimation — replay a preset on the box");
		var animTarget = new UIPanel(120, 40, PANEL2);
		animTarget.corner = 8;
		animTarget.outline = true;
		var atl = new UILabel("Animate me", 12, SECONDARY);
		atl.x = 12;
		atl.y = 12;
		animTarget.addChild(atl);
		put(animTarget, 40);
		var presets:Array<{n:String, p:UIAnimationPreset}> = [
			{n: "Pop", p: POP}, {n: "Fly", p: FLY_IN}, {n: "Zoom", p: ZOOM_IN}, {n: "Flip", p: FLIP},
			{n: "Revolve", p: REVOLVE}, {n: "Shake", p: SHAKE}, {n: "Pulse", p: PULSE}
		];
		var animRow = new Sprite();
		for (i in 0...presets.length) {
			var pr = presets[i];
			var ab = new UIButton(pr.n, 68, 28, () -> {
				playDemo(animTarget, pr.p);
				setStatus('Animate: ${pr.n}');
			});
			ab.x = i * 72;
			animRow.addChild(ab);
		}
		put(animRow, 28);

		rule();

		head("UIRadioGroup");
		var radio = new UIRadioGroup(["Low", "Medium", "High"], COL, 1, (i) -> setStatus('Radio: $i'));
		put(radio, radio.h);

		head("UIStatusBar");
		var sbar = new UIStatusBar(COL, 24);
		sbar.setCells([{text: "Ready"}, {text: "Ln 1, Col 1", rightAlign: true}, {text: "UTF-8", rightAlign: true}]);
		put(sbar, 24);

		head("UIBalloon / UIPieMenu — popups");
		var balloonBtn = new UIButton("Balloon", 120, 30);
		balloonBtn.onClick = () -> openBalloon(balloonBtn);
		var pieBtn = new UIButton("Pie menu", 120, 30, () -> openPie());
		pieBtn.x = 132;
		var popRow = new Sprite();
		popRow.addChild(balloonBtn);
		popRow.addChild(pieBtn);
		put(popRow, 30);

		rule();

		head("UIStack — flow layout");
		var stack = new UIStack(false, 40, 8);
		stack.add(new UIButton("One", 70, 30));
		stack.add(new UIButton("Two", 70, 30));
		stack.add(new UIButton("Three", 84, 30));
		put(stack, 40);

		head("UISplitter — draggable divider");
		var split = new UISplitter(false, COL, 90);
		var leftLabel = new UILabel("Left pane", 12, SECONDARY);
		leftLabel.x = 12;
		leftLabel.y = 12;
		split.first.addChild(leftLabel);
		var rightLabel = new UILabel("Right pane", 12, SECONDARY);
		rightLabel.x = 12;
		rightLabel.y = 12;
		split.second.addChild(rightLabel);
		put(split, 90);

		head("UIWindow — draggable / resizable / collapsible (content stays clickable)");
		var spawnBtn = new UIButton("Open window", 150, 30, () -> spawnWindow());
		put(spawnBtn, 30);

		rule();

		head("UIDockHost — drag tabs to re-dock, drag dividers to resize");
		var dock = new UIDockHost(COL, 220);
		var explorer = new UIDockPanel("Explorer");
		var exLabel = new UILabel("File tree", 12, SECONDARY);
		exLabel.x = 12;
		exLabel.y = 12;
		explorer.content.addChild(exLabel);
		var mainGroup = dock.addPanel(explorer);
		var editor = new UIDockPanel("Editor");
		var edLabel = new UILabel("Code here", 12, SECONDARY);
		edLabel.x = 12;
		edLabel.y = 12;
		editor.content.addChild(edLabel);
		var editorGroup = dock.dock(editor, mainGroup, RIGHT);
		var output = new UIDockPanel("Output");
		var outLabel = new UILabel("Build log", 12, SECONDARY);
		outLabel.x = 12;
		outLabel.y = 12;
		output.content.addChild(outLabel);
		dock.dock(output, editorGroup, BOTTOM);
		put(dock, 220);

		rule();

		head("UITreeView — expandable hierarchy (click a chevron)");
		var tree = new UITreeView(COL, 168);
		tree.setRoots([
			new UITreeNode("src", [
				new UITreeNode("smidr", [
					new UITreeNode("widgets", [new UITreeNode("UIButton.hx"), new UITreeNode("UIList.hx")], true),
					new UITreeNode("types", [new UITreeNode("UIGlyph.hx"), new UITreeNode("UIAlign.hx")])
				], true),
				new UITreeNode("Main.hx")
			], true)
		]);
		tree.onSelect = (node) -> setStatus('Tree: ${node.label}');
		tree.onToggle = (node, open) -> setStatus('Tree ${open ? "expand" : "collapse"}: ${node.label}');
		put(tree, 168);

		head("UIDataGrid — click a header to sort");
		var files:Array<Array<String>> = [
			["README.md", "4", "Markdown"],
			["UIList.hx", "18", "Haxe"],
			["project.xml", "2", "XML"],
			["logo.png", "56", "Image"],
			["CHANGELOG.md", "9", "Markdown"],
			["Gallery.hx", "21", "Haxe"],
			["haxelib.json", "1", "JSON"]
		];
		var grid = new UIDataGrid(COL, 168);
		grid.setColumns([
			new UIDataColumn("Name", 220),
			new UIDataColumn("Size (KB)", 100, END, true, true),
			new UIDataColumn("Kind", 180)
		]);
		grid.setData(files.length, (row, col) -> files[row][col]);
		grid.onSelect = (row) -> setStatus('Grid: ${files[row][0]}');
		put(grid, 168);

		head("UIColorPicker — drag the square / hue strip, or click a preset");
		var picker = new UIColorPicker(COL, UIColor.opaque(0x3DB7E2), (c) -> setStatus('Color: #${StringTools.hex(UIColor.rgb(c), 6)}'));
		put(picker, 198);

		head("UITileGrid — reflowing icon tiles");
		var tileNames:Array<String> = ["Docs", "Readme", "Photo", "Star", "Heart", "Bell", "Home", "User", "Lock", "Clock", "Config", "Search"];
		var tileGlyphs:Array<UIGlyph> = [FOLDER, FILE, IMAGE, STAR, HEART, BELL, HOME, USER, LOCK, CLOCK, GEAR, SEARCH];
		var tileGrid = new UITileGrid(COL, 208);
		tileGrid.setProvider(tileNames.length, (i) -> tileNames[i], (i) -> tileGlyphs[i]);
		tileGrid.onSelect = (i) -> setStatus('Tile: ${tileNames[i]}');
		put(tileGrid, 208);

		rule();

		head("UIToolbar — icon strip with a spacer");
		var toolbar = new UIToolbar(36);
		toolbar.addIconButton(UIIcon.fromGlyph(FILE, 16), () -> setStatus("New"));
		toolbar.addIconButton(UIIcon.fromGlyph(FOLDER_OPEN, 16), () -> setStatus("Open"));
		toolbar.addIconButton(UIIcon.fromGlyph(SAVE, 16), () -> setStatus("Save"));
		toolbar.addSeparator();
		toolbar.addButton("Build", 70, () -> setStatus("Build"));
		toolbar.addSpacer();
		toolbar.addIconButton(UIIcon.fromGlyph(GEAR, 16), () -> setStatus("Settings"));
		put(toolbar, 36);

		head("UIBreadcrumb — click a segment");
		var crumb = new UIBreadcrumb((i) -> setStatus('Breadcrumb: $i'));
		crumb.setPath(["Home", "Projects", "SmidrUI", "src"]);
		put(crumb, 24);

		head("UIExpander — self-collapsing section");
		var expander = new UIExpander("Advanced options", COL, false, (open) -> setStatus('Expander: $open'));
		var expanderBody = new UILabel("Body content, hidden until the section is expanded.", 12, SECONDARY);
		expanderBody.x = 12;
		expanderBody.y = 8;
		expander.content.addChild(expanderBody);
		expander.contentHeight = 36;
		put(expander, 30);
	}

	function spawnWindow():Void {
		var win = new UIWindow("Tool window", 250, 150);
		win.closable = true;
		win.collapsible = true;
		win.resizable = true;
		var inBtn = new UIButton("Inside button", 170, 30, () -> setStatus("Window button clicked"));
		inBtn.x = 16;
		inBtn.y = 16;
		win.content.addChild(inBtn);
		var inChk = new UICheckbox("A checkbox", 210, false, (on) -> setStatus('Window checkbox: $on'));
		inChk.x = 16;
		inChk.y = 56;
		win.content.addChild(inChk);
		win.x = 200;
		win.y = 130;
		ui.content.addChild(win);
	}

	function openBalloon(anchor:UIButton):Void {
		var balloon = new UIBalloon(220, 92, "Balloon");
		var msg = new UILabel("A callout with a tail that points at whatever opened it.", 12, SECONDARY);
		msg.wrapWidth = 196;
		msg.x = 12;
		balloon.body.addChild(msg);
		balloon.openAt(anchor);
	}

	function openPie():Void {
		UIPieMenu.open(ui.mouseX, ui.mouseY, [
			{label: "Cut", onSelect: () -> setStatus("Pie: Cut")},
			{label: "Copy", onSelect: () -> setStatus("Pie: Copy")},
			{label: "Paste", onSelect: () -> setStatus("Pie: Paste")},
			{label: "Delete", onSelect: () -> setStatus("Pie: Delete")}
		]);
	}

	function playDemo(target:DisplayObject, preset:UIAnimationPreset):Void {
		if (demoAnim != null)
			demoAnim.stop(true);
		demoAnim = UIAnimation.play(target, preset);
	}

	function openContextMenu():Void {
		UIContextMenu.open(ui.mouseX, ui.mouseY, [
			{label: "Cut", onSelect: () -> setStatus("Context: Cut")},
			{label: "Copy", onSelect: () -> setStatus("Context: Copy")},
			{separator: true},
			{label: "Delete", onSelect: () -> setStatus("Context: Delete")}
		]);
	}

	function openModal():Void {
		var modal = new UIModal("Modal dialog", 320, 150);
		var text = new UILabel("This is a modal on the popup layer.\nEscape or the backdrop closes it.", 12, SECONDARY);
		text.wrapWidth = 288;
		text.x = 16;
		text.y = 8;
		modal.body.addChild(text);
		var ok = new UIButton("Close", 100, 30, () -> modal.close(), true);
		ok.x = 16;
		ok.y = 62;
		modal.body.addChild(ok);
		modal.onClosed = () -> setStatus("Modal closed");
		modal.open();
		setStatus("Modal opened");
	}

	public function destroy():Void {
		UIRoot.removeTicker(tick);
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			stage.removeEventListener(Event.RESIZE, onResize);
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
