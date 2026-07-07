package;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.types.UIGlyph;
import smidr.types.UITone;
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
	small test executable so users can poke at the whole library in one window.

	Build it (from the repo root):
	```bash
	lime test examples/project.xml windows -Dex_gallery
	```
**/
class Gallery extends Sprite {
	static inline var W:Float = 520;
	static inline var H:Float = 700;
	static inline var MENU_H:Float = 28;
	static inline var STATUS_H:Float = 30;
	static inline var COL:Float = 452; // widget column width inside the scroll pane

	var ui:UIRoot;
	var scroll:UIScrollPane;
	var statusTf:UILabel;
	var cy:Float = 0; // vertical cursor inside the scroll content

	public function new() {
		super();

		UILocale.translate = (key, fallback) -> fallback;
		UITheme.apply(UITheme.PRESETS[0].palette); // Dark
		UITheme.setScale(1.0);

		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);
		UITooltip.install();

		buildMenuBar();

		var title = new UILabel("SmiðrUI — widget gallery", 15, PRIMARY);
		title.x = 16;
		title.y = MENU_H + 8;
		ui.content.addChild(title);

		scroll = new UIScrollPane(W - 24, H - MENU_H - 36 - STATUS_H);
		scroll.x = 12;
		scroll.y = MENU_H + 34;
		ui.content.addChild(scroll);

		buildStatusBar();
		buildRows();
		scroll.refreshContent(cy);

		setStatus("Ready — scroll and try the widgets.");
	}

	// ── scaffolding ─────────────────────────────────────────────────────────────
	function buildMenuBar():Void {
		var bar = new UIMenuBar(W, MENU_H);
		bar.brand = "smidr";
		bar.setMenus([
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
					onSelect: () -> {
						UITheme.apply(UITheme.PRESETS[i].palette);
						setStatus('Theme: ${UITheme.PRESETS[i].name}');
					}
				}]
			}
		]);
		ui.content.addChild(bar);
	}

	function buildStatusBar():Void {
		var bg = new UIPanel(W, STATUS_H, UITheme.panel2);
		bg.borderTop = true;
		bg.y = H - STATUS_H;
		ui.content.addChild(bg);
		statusTf = new UILabel("", 12, SECONDARY);
		statusTf.x = 14;
		statusTf.y = H - STATUS_H + (STATUS_H - 16) / 2;
		ui.content.addChild(statusTf);
	}

	function setStatus(msg:String):Void {
		statusTf.text = msg;
		UIToast.show(msg);
	}

	/** Adds a small caption above the next widget. **/
	function head(name:String):Void {
		var l = new UILabel(name, 11, TERTIARY);
		l.x = 0;
		l.y = cy;
		scroll.content.addChild(l);
		cy += 18;
	}

	/** Places a display object at the cursor and advances by its height + a gap. **/
	function put(o:DisplayObject, height:Float):Void {
		o.x = 0;
		o.y = cy;
		scroll.content.addChild(o);
		cy += height + 16;
	}

	function rule():Void {
		var s = new UISeparator(COL);
		s.x = 0;
		s.y = cy;
		scroll.content.addChild(s);
		cy += 14;
	}

	// ── the widgets ─────────────────────────────────────────────────────────────
	function buildRows():Void {
		// Label
		head("UILabel");
		put(new UILabel("Primary / secondary / tertiary tones", 13, PRIMARY), 20);

		// Buttons
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

		// Icon buttons (glyph-backed)
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

		// Icons
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

		// Checkbox / switch / chip
		head("UICheckbox");
		put(new UICheckbox("Enable feature", COL, true, (on) -> setStatus('Checkbox: $on')), 24);

		head("UISwitch");
		put(new UISwitch("Dark mode", COL, true, (on) -> setStatus('Switch: $on')), 26);

		head("UIChip");
		put(new UIChip("Beta", true, false, (on) -> setStatus('Chip: $on')), 26);

		rule();

		// Sliders / steppers / segmented
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

		// Dropdown / text input / keybind
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

		// Tabs / icon rail
		head("UITabs");
		put(new UITabs(COL, [{label: "One"}, {label: "Two"}, {label: "Three"}], (i) -> setStatus('Tab: $i')), 34);

		head("UIIconRail");
		put(new UIIconRail(56, 132, [{caption: "A"}, {caption: "B"}, {caption: "C"}], (i) -> setStatus('Rail: $i')), 132);

		rule();

		// Accordion (toggles a small body; no reflow to keep the demo simple)
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

		// Loading bar + animate button
		head("UILoadingBar");
		var bar = new UILoadingBar("Downloading", COL, 0.3);
		bar.showPercent = true;
		put(bar, 30);
		var animate = new UIButton("Animate progress", 180, 30, () -> {
			bar.setProgress(Math.random(), true);
			setStatus("Loading bar animated");
		});
		put(animate, 30);

		rule();

		// Data-bound list
		head("UIList — data-bound rows");
		var items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Kiwi"];
		var list = new UIList(COL, 132);
		list.setProvider(items.length, (i) -> items[i]);
		list.onSelect = (i) -> setStatus('List select: ${items[i]}');
		list.onActivate = (i) -> setStatus('List activate: ${items[i]}');
		put(list, 132);

		rule();

		// Panel
		head("UIPanel");
		var panel = new UIPanel(COL, 56, UITheme.card);
		panel.corner = 8;
		panel.outline = true;
		var pl = new UILabel("A panel surface (card)", 12, SECONDARY);
		pl.x = 12;
		pl.y = 18;
		panel.addChild(pl);
		put(panel, 56);

		rule();

		// Overlays: modal, context menu, toast
		head("UIModal / UIContextMenu / UIToast");
		var openModal = new UIButton("Open modal", 130, 30, () -> openModal(), true);
		var toastBtn = new UIButton("Show toast", 130, 30, () -> setStatus("Toast fired"));
		toastBtn.x = 142;
		var overlayRow = new Sprite();
		overlayRow.addChild(openModal);
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
		put(rc, 20);
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
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
