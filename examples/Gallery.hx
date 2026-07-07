package;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.types.UIGlyph;
import smidr.widgets.UIAccordion;
import smidr.widgets.UIButton;
import smidr.widgets.UICheckbox;
import smidr.widgets.UIChip;
import smidr.widgets.UIContextMenu;
import smidr.widgets.UIDropdown;
import smidr.widgets.UIIcon;
import smidr.widgets.UIIconRail;
import smidr.widgets.UIKeybind;
import smidr.widgets.UILabel;
import smidr.widgets.UIList;
import smidr.widgets.UILoadingBar;
import smidr.widgets.UIMenuBar;
import smidr.widgets.UIModal;
import smidr.widgets.UIPanel;
import smidr.widgets.UIScrollPane;
import smidr.widgets.UISegmented;
import smidr.widgets.UISeparator;
import smidr.widgets.UISlider;
import smidr.widgets.UIStepper;
import smidr.widgets.UISwitch;
import smidr.widgets.UITabs;
import smidr.widgets.UITextInput;
import smidr.widgets.UIToast;
import smidr.widgets.UITooltip;

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
	var bar:UILoadingBar;

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

		// themed, full-window backdrop (follows theme swaps because it's bound to a surface role)
		backdrop = UIPanel.themed(BG, 100, 100, false);
		ui.content.addChild(backdrop);

		buildMenuBar();

		title = new UILabel("SmiðrUI — widget gallery", 15, PRIMARY);
		ui.content.addChild(title);

		scroll = new UIScrollPane(PANE_W, 100);
		ui.content.addChild(scroll);

		statusBg = UIPanel.themed(PANEL2, 100, STATUS_H);
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

		head("UISegmented");
		var seg = new UISegmented("Quality", COL, ["Low", "Med", "High"], (i) -> setStatus('Segmented: $i'));
		seg.select(1);
		put(seg, 30);

		rule();

		head("UIDropdown");
		var dd = new UIDropdown("Resolution", COL, (i, value) -> setStatus('Dropdown: $value'));
		dd.setItems(["1280x720", "1920x1080", "2560x1440"]);
		dd.select(1);
		put(dd, 34);

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
		put(new UIIconRail(56, 132, [{caption: "A"}, {caption: "B"}, {caption: "C"}], (i) -> setStatus('Rail: $i')), 132);

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

		head("UILoadingBar — auto-animating");
		bar = new UILoadingBar("Downloading", COL, 0.0);
		bar.showPercent = true;
		put(bar, 30);

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
		var panel = UIPanel.themed(CARD, COL, 56);
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

		var rc = new UILabel("Right-click me for a context menu", 12, SECONDARY);
		rc.onRightClick = () -> {
			UIContextMenu.open(ui.mouseX, ui.mouseY, [
				{label: "Cut", onSelect: () -> setStatus("Context: Cut")},
				{label: "Copy", onSelect: () -> setStatus("Context: Copy")},
				{separator: true},
				{label: "Delete", onSelect: () -> setStatus("Context: Delete")}
			]);
		};
		put(rc, 24);
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
