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

private typedef Section = {name:String, header:UILabel, cards:Array<UIPanel>};

/**
	A gallery of every widget, sorted into categories and laid out as a responsive masonry of
	cards that fills the whole browser window. Each demo lives in its own titled card of fixed
	width; the number of columns grows and shrinks with the window, and cards flow into the
	shortest column so the whole page reflows on resize with no fixed-width column.

	Build it (from the repo root):
	```bash
	lime build examples/gallery/project.xml html5
	```
**/
class Gallery extends Sprite {
	static inline var MENU_H:Float = 30;
	static inline var STATUS_H:Float = 28;
	static inline var MARGIN:Float = 24; // outer inset around the card grid
	static inline var TOP:Float = 16; // gap below the menu bar
	static inline var CARD_W:Float = 340; // fixed card width (only the column count is fluid)
	static inline var PAD:Float = 16; // inset inside a card
	static inline var INNER:Float = CARD_W - PAD * 2; // usable width inside a card
	static inline var TITLE_H:Float = 30; // card title strip
	static inline var CARD_BOTTOM:Float = 14; // card bottom padding
	static inline var GAP:Float = 18; // gap between cards
	static inline var HEADER_H:Float = 44; // category header strip
	static inline var SECTION_GAP:Float = 22; // gap after a category

	var ui:UIRoot;
	var backdrop:UIPanel;
	var menubar:UIMenuBar;
	var scroll:UIScrollPane;
	var statusBg:UIPanel;
	var statusTf:UILabel;

	var sections:Array<Section> = [];
	var current:Section;

	var bar:UIProgressBar;
	var demoAnim:UIAnimation = null;
	var contentHeight:Float = 0;
	var progT:Float = 0;

	public function new() {
		super();

		UILocale.translate = (key, fallback) -> fallback;
		UITheme.apply(UITheme.PRESETS[0].palette); // Dark

		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);
		UITooltip.install();

		backdrop = new UIPanel(100, 100, BG, false);
		ui.content.addChild(backdrop);

		buildMenuBar();

		scroll = new UIScrollPane(100, 100);
		ui.content.addChild(scroll);

		statusBg = new UIPanel(100, STATUS_H, PANEL2);
		statusBg.borderTop = true;
		ui.content.addChild(statusBg);
		statusTf = new UILabel("", 12, SECONDARY);
		ui.content.addChild(statusTf);

		buildContent();

		UIRoot.addTicker(tick);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			layout();

		setStatus("Ready — resize the window; the cards reflow.");
	}

	// responsive frame layout
	function onAddedToStage(_:Event):Void {
		stage.addEventListener(Event.RESIZE, onResize);
		layout();
	}

	function onResize(_:Event):Void {
		layout();
	}

	function layout():Void {
		var sw:Float = (stage != null) ? stage.stageWidth : 1100;
		var sh:Float = (stage != null) ? stage.stageHeight : 720;

		backdrop.resize(sw, sh);
		menubar.resize(sw, MENU_H);

		scroll.x = 0;
		scroll.y = MENU_H;
		scroll.resize(sw, Math.max(120, sh - MENU_H - STATUS_H));

		statusBg.resize(sw, STATUS_H);
		statusBg.y = sh - STATUS_H;
		statusTf.x = MARGIN;
		statusTf.y = sh - STATUS_H + (STATUS_H - 16) / 2;

		layoutCards(sw);
	}

	// masonry: flow the fixed-width cards into as many columns as the window allows
	function layoutCards(windowWidth:Float):Void {
		var avail:Float = windowWidth - MARGIN * 2;
		var columns:Int = Std.int((avail + GAP) / (CARD_W + GAP));
		if (columns < 1)
			columns = 1;
		var gridW:Float = columns * CARD_W + (columns - 1) * GAP;
		var originX:Float = MARGIN + Math.max(0, (avail - gridW)) / 2; // centre the grid

		var colH:Array<Float> = [for (i in 0...columns) 0.0];
		var y:Float = TOP;

		for (section in sections) {
			section.header.x = originX;
			section.header.y = y;
			y += HEADER_H;
			for (i in 0...columns)
				colH[i] = y;

			for (card in section.cards) {
				var shortest:Int = 0;
				for (i in 1...columns)
					if (colH[i] < colH[shortest])
						shortest = i;
				card.x = originX + shortest * (CARD_W + GAP);
				card.y = colH[shortest];
				colH[shortest] += card.h + GAP;
			}

			var maxH:Float = colH[0];
			for (i in 1...columns)
				if (colH[i] > maxH)
					maxH = colH[i];
			y = maxH + SECTION_GAP;
		}

		contentHeight = y + CARD_BOTTOM;
		scroll.refreshContent(contentHeight);
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
				items: () -> [for (i in 0...UITheme.PRESETS.length) {label: UITheme.PRESETS[i].name, onSelect: applyTheme.bind(i)}]
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

	// a new category
	function section(name:String):Void {
		var header = new UILabel(name, 17, PRIMARY);
		scroll.content.addChild(header);
		current = {name: name, header: header, cards: []};
		sections.push(current);
	}

	// a titled card; `build` fills the content sprite (origin at the card's inset) and returns
	// the height of what it added, so the card sizes itself to its demo.
	function add(title:String, build:Sprite->Float):Void {
		var panel = new UIPanel(CARD_W, TITLE_H + CARD_BOTTOM, CARD);
		panel.corner = 10;
		panel.outline = true;
		var label = new UILabel(title, 11, TERTIARY);
		label.x = PAD;
		label.y = 11;
		panel.addChild(label);
		var content = new Sprite();
		content.x = PAD;
		content.y = TITLE_H;
		panel.addChild(content);
		var demoH = build(content);
		panel.resize(CARD_W, TITLE_H + demoH + CARD_BOTTOM);
		current.cards.push(panel);
		scroll.content.addChild(panel);
	}

	function tick(dtMs:Float):Void {
		if (bar == null)
			return;
		progT += dtMs;
		var period:Float = 2600;
		bar.setProgress((progT % period) / period, false);
	}

	// the widgets, sorted into categories
	function buildContent():Void {
		section("Text & buttons");
		add("Label tones", (c) -> {
			var a = new UILabel("Primary label", 13, PRIMARY);
			var b = new UILabel("Secondary label", 13, SECONDARY);
			b.y = 20;
			var d = new UILabel("Tertiary label", 13, TERTIARY);
			d.y = 40;
			c.addChild(a);
			c.addChild(b);
			c.addChild(d);
			return 60;
		});
		add("Buttons — default / accent / danger", (c) -> {
			var w = (INNER - 16) / 3;
			var bDefault = new UIButton("Default", w, 32, () -> setStatus("Button: Default"));
			bDefault.tooltip = "A plain button";
			var bAccent = new UIButton("Accent", w, 32, () -> setStatus("Button: Accent"), true);
			bAccent.x = w + 8;
			var bDanger = new UIButton("Danger", w, 32, () -> setStatus("Button: Danger"));
			bDanger.danger = true;
			bDanger.x = (w + 8) * 2;
			c.addChild(bDefault);
			c.addChild(bAccent);
			c.addChild(bDanger);
			return 32;
		});
		add("Icon buttons", (c) -> {
			var glyphs:Array<UIGlyph> = [PLAY, PAUSE, GEAR, SEARCH, TRASH, HEART];
			for (i in 0...glyphs.length) {
				var g = glyphs[i];
				var ib = UIButton.icon(UIIcon.fromGlyph(g, 16), 32, () -> setStatus('Icon button ${(g : Int)}'));
				ib.x = i * 40;
				c.addChild(ib);
			}
			return 32;
		});
		add("Vector icons — no assets", (c) -> {
			var strip:Array<UIGlyph> = [STAR, BELL, HOME, USER, LOCK, IMAGE, FOLDER, CLOCK];
			for (i in 0...strip.length) {
				var ic = UIIcon.fromGlyph(strip[i], 20, SECONDARY);
				ic.x = i * 36;
				ic.y = 2;
				c.addChild(ic);
			}
			return 24;
		});

		section("Selection & toggles");
		add("Checkbox", (c) -> {
			c.addChild(new UICheckbox("Enable feature", INNER, true, (on) -> setStatus('Checkbox: $on')));
			return 24;
		});
		add("Switch", (c) -> {
			c.addChild(new UISwitch("Dark mode", INNER, true, (on) -> setStatus('Switch: $on')));
			return 26;
		});
		add("Chip", (c) -> {
			c.addChild(new UIChip("Beta", true, false, (on) -> setStatus('Chip: $on')));
			return 26;
		});
		add("Segmented control", (c) -> {
			var seg = new UISegmentedControl("Quality", INNER, ["Low", "Med", "High"], (i) -> setStatus('Segmented: $i'));
			seg.select(1);
			c.addChild(seg);
			return 30;
		});
		add("Radio group", (c) -> {
			var radio = new UIRadioGroup(["Low", "Medium", "High"], INNER, 1, (i) -> setStatus('Radio: $i'));
			c.addChild(radio);
			return radio.h;
		});

		section("Values & editing");
		add("Slider", (c) -> {
			var slider = new UISlider("Volume", INNER, 0, 1, 0.7, (v) -> setStatus('Slider: ${Math.round(v * 100)}%'));
			slider.decimals = 2;
			c.addChild(slider);
			return 40;
		});
		add("Stepper", (c) -> {
			var stepper = new UIStepper("Count", INNER, 3, 1, (v) -> setStatus('Stepper: $v'));
			stepper.min = 0;
			stepper.max = 10;
			c.addChild(stepper);
			return 34;
		});
		add("Dropdown", (c) -> {
			var dd = new UIDropdown("Resolution", INNER, (i, value) -> setStatus('Dropdown: $value'));
			dd.setItems(["1280x720", "1920x1080", "2560x1440"]);
			dd.select(1);
			c.addChild(dd);
			return 34;
		});
		add("Dropdown — searchable", (c) -> {
			var tz = new UIDropdown("Timezone", INNER, (i, value) -> setStatus('Timezone: $value'));
			tz.searchable = true;
			tz.setItems(["UTC", "London", "Paris", "Berlin", "Cairo", "Dubai", "Mumbai", "Tokyo", "Sydney", "New York", "Denver", "Chicago"]);
			c.addChild(tz);
			return 34;
		});
		add("Text input", (c) -> {
			var input = new UITextInput("Name", INNER, "Player", (t) -> setStatus('Input: $t'));
			input.onEnter = (t) -> setStatus('Entered: $t');
			c.addChild(input);
			return 40;
		});
		add("Keybind — click, then press a key", (c) -> {
			c.addChild(new UIKeybind("Jump", INNER, 32, (code) -> setStatus('Keybind: $code')));
			return 34;
		});
		add("Date picker", (c) -> {
			c.addChild(new UIDateTimePicker("Release date", INNER, null, (d) -> setStatus('Date: ${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}')));
			return 34;
		});
		add("Date & time", (c) -> {
			var dt = new UIDateTimePicker("Meeting", INNER, null, (d) -> setStatus('When: ${d.toString()}'));
			dt.showTime = true;
			c.addChild(dt);
			return 34;
		});
		add("Colour picker", (c) -> {
			c.addChild(new UIColorPicker(INNER, UIColor.opaque(0x3DB7E2), (col) -> setStatus('Colour: #${StringTools.hex(UIColor.rgb(col), 6)}')));
			return 198;
		});

		section("Indicators");
		add("Progress bar — auto-animating", (c) -> {
			bar = new UIProgressBar("Downloading", INNER, 0.0);
			bar.showPercent = true;
			c.addChild(bar);
			return 30;
		});
		add("Spinner", (c) -> {
			var spin = new UISpinner(30);
			spin.x = (INNER - 30) / 2;
			c.addChild(spin);
			return 40;
		});
		add("Rating", (c) -> {
			c.addChild(new UIRating(5, 3, (n) -> setStatus('Rating: $n')));
			return 24;
		});
		add("Badge", (c) -> {
			var btn = new UIButton("Inbox", 110, 32, () -> setStatus("Inbox"));
			btn.y = 4;
			c.addChild(btn);
			var badge = new UIBadge(7);
			badge.x = 100;
			c.addChild(badge);
			return 40;
		});

		section("Containers & layout");
		add("Panel — themed surface", (c) -> {
			var panel = new UIPanel(INNER, 50, PANEL2);
			panel.corner = 8;
			panel.outline = true;
			var pl = new UILabel("A surface that follows the theme", 12, SECONDARY);
			pl.x = 12;
			pl.y = 16;
			panel.addChild(pl);
			c.addChild(panel);
			return 50;
		});
		add("Stack — flow layout", (c) -> {
			var stack = new UIStack(false, 40, 8);
			stack.add(new UIButton("One", 70, 30));
			stack.add(new UIButton("Two", 70, 30));
			stack.add(new UIButton("Three", 84, 30));
			c.addChild(stack);
			return 40;
		});
		add("Splitter — draggable divider", (c) -> {
			var split = new UISplitter(false, INNER, 90);
			var l = new UILabel("Left pane", 12, SECONDARY);
			l.x = l.y = 12;
			split.first.addChild(l);
			var r = new UILabel("Right pane", 12, SECONDARY);
			r.x = r.y = 12;
			split.second.addChild(r);
			c.addChild(split);
			return 90;
		});
		add("Expander — collapsible section", (c) -> {
			var expander = new UIExpander("Advanced options", INNER, true, (open) -> setStatus('Expander: $open'));
			var body = new UILabel("Body content, shown while expanded.", 12, SECONDARY);
			body.x = 12;
			body.y = 8;
			expander.content.addChild(body);
			expander.contentHeight = 36;
			c.addChild(expander);
			return expander.h;
		});
		add("Accordion", (c) -> {
			var bodyA = new Sprite();
			var acc = new UIAccordion("Details", INNER, true, (open) -> {
				bodyA.visible = open;
				setStatus('Accordion: $open');
			});
			c.addChild(acc);
			bodyA.y = 26;
			var l1 = new UILabel("• a detail line", 12, SECONDARY);
			var l2 = new UILabel("• another detail", 12, SECONDARY);
			l2.y = 18;
			bodyA.addChild(l1);
			bodyA.addChild(l2);
			c.addChild(bodyA);
			return 64;
		});
		add("Window — floating, resizable", (c) -> {
			c.addChild(new UIButton("Open window", 150, 30, () -> spawnWindow()));
			return 30;
		});
		add("Dock host — drag tabs & dividers", (c) -> {
			var dock = new UIDockHost(INNER, 200);
			var explorer = new UIDockPanel("Explorer");
			addPanelLabel(explorer, "File tree");
			var mainGroup = dock.addPanel(explorer);
			var editor = new UIDockPanel("Editor");
			addPanelLabel(editor, "Code here");
			var editorGroup = dock.dock(editor, mainGroup, RIGHT);
			var output = new UIDockPanel("Output");
			addPanelLabel(output, "Build log");
			dock.dock(output, editorGroup, BOTTOM);
			c.addChild(dock);
			return 200;
		});

		section("Navigation");
		add("Tabs", (c) -> {
			c.addChild(new UITabs(INNER, [{label: "One"}, {label: "Two"}, {label: "Three"}], (i) -> setStatus('Tab: $i')));
			return 34;
		});
		add("Icon rail", (c) -> {
			var rail = new UIIconRail(56, 132, [{label: "A"}, {label: "B"}, {label: "C"}], (i) -> setStatus('Rail: $i'));
			rail.x = (INNER - 56) / 2;
			c.addChild(rail);
			return 132;
		});
		add("Toolbar", (c) -> {
			var toolbar = new UIToolbar(36);
			toolbar.addIconButton(UIIcon.fromGlyph(FILE, 16), () -> setStatus("New"));
			toolbar.addIconButton(UIIcon.fromGlyph(FOLDER_OPEN, 16), () -> setStatus("Open"));
			toolbar.addIconButton(UIIcon.fromGlyph(SAVE, 16), () -> setStatus("Save"));
			toolbar.addSeparator();
			toolbar.addButton("Build", 66, () -> setStatus("Build"));
			toolbar.addSpacer();
			toolbar.addIconButton(UIIcon.fromGlyph(GEAR, 16), () -> setStatus("Settings"));
			toolbar.resize(INNER, 36);
			c.addChild(toolbar);
			return 36;
		});
		add("Breadcrumb", (c) -> {
			var crumb = new UIBreadcrumb((i) -> setStatus('Breadcrumb: $i'));
			crumb.setPath(["Home", "Projects", "SmidrUI", "src"]);
			c.addChild(crumb);
			return 24;
		});
		add("Status bar", (c) -> {
			var sbar = new UIStatusBar(INNER, 24);
			sbar.setCells([{text: "Ready"}, {text: "Ln 1, Col 1", rightAlign: true}, {text: "UTF-8", rightAlign: true}]);
			c.addChild(sbar);
			return 24;
		});

		section("Data");
		add("List — virtualized rows", (c) -> {
			var items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Kiwi"];
			var list = new UIList(INNER, 132);
			list.setProvider(items.length, (i) -> items[i]);
			list.onSelect = (i) -> setStatus('List: ${items[i]}');
			c.addChild(list);
			return 132;
		});
		add("Tree view — click a chevron", (c) -> {
			var tree = new UITreeView(INNER, 160);
			tree.setRoots([
				new UITreeNode("src", [
					new UITreeNode("smidr", [
						new UITreeNode("widgets", [new UITreeNode("UIButton.hx"), new UITreeNode("UIList.hx")], true),
						new UITreeNode("types", [new UITreeNode("UIGlyph.hx")])
					], true),
					new UITreeNode("Main.hx")
				], true)
			]);
			tree.onSelect = (node) -> setStatus('Tree: ${node.label}');
			c.addChild(tree);
			return 160;
		});
		add("Data grid — click a header to sort", (c) -> {
			var files:Array<Array<String>> = [
				["README.md", "4", "Markdown"], ["UIList.hx", "18", "Haxe"], ["project.xml", "2", "XML"],
				["logo.png", "56", "Image"], ["Gallery.hx", "21", "Haxe"], ["haxelib.json", "1", "JSON"]
			];
			var grid = new UIDataGrid(INNER, 160);
			grid.setColumns([new UIDataColumn("Name", 130), new UIDataColumn("KB", 60, END, true, true), new UIDataColumn("Kind", 108)]);
			grid.setData(files.length, (row, col) -> files[row][col]);
			grid.onSelect = (row) -> setStatus('Grid: ${files[row][0]}');
			c.addChild(grid);
			return 160;
		});
		add("Tile grid — reflowing tiles", (c) -> {
			var names = ["Docs", "Readme", "Photo", "Star", "Heart", "Bell", "Home", "User", "Lock", "Clock", "Config", "Search"];
			var glyphs:Array<UIGlyph> = [FOLDER, FILE, IMAGE, STAR, HEART, BELL, HOME, USER, LOCK, CLOCK, GEAR, SEARCH];
			var tiles = new UITileGrid(INNER, 200);
			tiles.setProvider(names.length, (i) -> names[i], (i) -> glyphs[i]);
			tiles.onSelect = (i) -> setStatus('Tile: ${names[i]}');
			c.addChild(tiles);
			return 200;
		});

		section("Overlays & effects");
		add("Modal / toast", (c) -> {
			var openBtn = new UIButton("Open modal", (INNER - 10) / 2, 30, () -> openModal(), true);
			var toastBtn = new UIButton("Show toast", (INNER - 10) / 2, 30, () -> setStatus("Toast fired"));
			toastBtn.x = (INNER - 10) / 2 + 10;
			c.addChild(openBtn);
			c.addChild(toastBtn);
			return 30;
		});
		add("Context menu — right-click or click", (c) -> {
			var ctxBtn = new UIButton("Right-click me", INNER, 30, () -> openContextMenu());
			ctxBtn.onRightClick = openContextMenu;
			c.addChild(ctxBtn);
			return 30;
		});
		add("Balloon / pie menu", (c) -> {
			var balloonBtn = new UIButton("Balloon", (INNER - 10) / 2, 30);
			balloonBtn.onClick = () -> openBalloon(balloonBtn);
			var pieBtn = new UIButton("Pie menu", (INNER - 10) / 2, 30, () -> openPie());
			pieBtn.x = (INNER - 10) / 2 + 10;
			c.addChild(balloonBtn);
			c.addChild(pieBtn);
			return 30;
		});
		add("Gradient — panel + button", (c) -> {
			var gpanel = new UIPanel(INNER, 44);
			gpanel.corner = 8;
			gpanel.gradient = UIGradient.linear([UIColor.opaque(0x2A2440), UIColor.opaque(0x4A3A7E)], 90);
			c.addChild(gpanel);
			var gbtn = new UIButton("Gradient button", INNER, 32, () -> setStatus("Gradient button"));
			gbtn.y = 52;
			gbtn.gradient = UIGradient.horizontal(UITheme.accentDark, UITheme.accentAlt);
			c.addChild(gbtn);
			return 84;
		});
		add("Animation — replay a preset", (c) -> {
			var animTarget = new UIPanel(120, 40, PANEL2);
			animTarget.corner = 8;
			animTarget.outline = true;
			animTarget.x = (INNER - 120) / 2;
			var atl = new UILabel("Animate me", 12, SECONDARY);
			atl.x = 12;
			atl.y = 12;
			animTarget.addChild(atl);
			c.addChild(animTarget);
			var presets:Array<{n:String, p:UIAnimationPreset}> = [{n: "Pop", p: POP}, {n: "Zoom", p: ZOOM_IN}, {n: "Shake", p: SHAKE}, {n: "Pulse", p: PULSE}];
			var w = (INNER - 18) / 4;
			for (i in 0...presets.length) {
				var pr = presets[i];
				var ab = new UIButton(pr.n, w, 28, () -> {
					playDemo(animTarget, pr.p);
					setStatus('Animate: ${pr.n}');
				});
				ab.x = i * (w + 6);
				ab.y = 50;
				c.addChild(ab);
			}
			return 78;
		});
	}

	function addPanelLabel(panel:UIDockPanel, text:String):Void {
		var l = new UILabel(text, 12, SECONDARY);
		l.x = 12;
		l.y = 12;
		panel.content.addChild(l);
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
		win.x = 220;
		win.y = 140;
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
