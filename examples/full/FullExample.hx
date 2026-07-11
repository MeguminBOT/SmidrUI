package;

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
import smidr.overlays.UIContextMenu;
import smidr.widgets.UIDropdown;
import smidr.widgets.UIIcon;
import smidr.widgets.UIIconRail;
import smidr.widgets.UIKeybind;
import smidr.widgets.UILabel;
import smidr.widgets.UIList;
import smidr.widgets.UIProgressBar;
import smidr.widgets.UIMenuBar;
import smidr.widgets.UIModal;
import smidr.widgets.UIPanel;
import smidr.widgets.UIScrollPane;
import smidr.widgets.UISegmentedControl;
import smidr.widgets.UISeparator;
import smidr.widgets.UISlider;
import smidr.widgets.UIStepper;
import smidr.widgets.UISwitch;
import smidr.widgets.UITabs;
import smidr.widgets.UITextInput;
import smidr.overlays.UIToast;
import smidr.overlays.UITooltip;

/**
	A full tour of SmiðrUI that instantiates **every widget** in the library. A left icon rail
	switches between three sections; a menu bar spans the top; toasts, a modal and a context menu
	are wired to actions. Everything here is plain OpenFL — no game framework required.

	```haxe
	addChild(new FullExample());
	```
**/
class FullExample extends Sprite {
	static inline var MENU_H:Float = 28;
	static inline var RAIL_W:Float = 56;
	static inline var OX:Float = RAIL_W + 16; // content origin x
	static inline var OY:Float = MENU_H + 16; // content origin y

	var ui:UIRoot;
	var sections:Array<Sprite> = [];
	var themeIndex:Int = 2;

	// live model the widgets read/write
	var volume:Float = 0.7;
	var quality:Int = 2;
	var fullscreen:Bool = true;
	var profiles:Array<String> = ["Default", "Competitive", "Cinematic", "Streaming", "Accessibility"];

	// accordion reflow state (Data section)
	var dataScroll:UIScrollPane;
	var accGeneral:UIAccordion;
	var accAdvanced:UIAccordion;
	var bodyGeneral:Sprite;
	var bodyAdvanced:Sprite;

	public function new() {
		super();

		// Global setup (once, before building widgets)
		UIFonts.register("assets/fonts/Inter.ttf");     // optional; no-ops if the asset is absent
		UILocale.translate = (key, fallback) -> fallback; // wire to your own i18n lookup
		UITheme.apply(UITheme.PRESETS[themeIndex].palette); // "Midnight"
		UITheme.applyAccent(0xFF3AA0FF);
		UITheme.setScale(1.0);

		// Root
		ui = new UIRoot();
		ui.attach(this);
		ui.setViewport(0, 0, 1, 1);
		UITooltip.install(); // shared tooltip singleton — install once after a root exists

		buildMenuBar();
		buildRail();
		buildSections();
		showSection(0);
	}

	// UIMenuBar
	function buildMenuBar():Void {
		var bar = new UIMenuBar(960, MENU_H);
		bar.brand = "SmiðrUI Demo";
		bar.setMenus([
			{
				title: "File",
				items: () -> [
					{label: "New", shortcut: "Ctrl+N", onSelect: () -> UIToast.show("New")},
					{label: "Open…", shortcut: "Ctrl+O", onSelect: () -> UIToast.show("Open")},
					{separator: true},
					{label: "Exit", onSelect: () -> UIToast.show("Exit")}
				]
			},
			{
				title: "View",
				items: () -> [
					{label: "Fullscreen", checked: fullscreen, onSelect: () -> {
						fullscreen = !fullscreen;
						UIToast.show(fullscreen ? "Fullscreen on" : "Fullscreen off");
					}},
					{label: "Cycle theme", shortcut: "Ctrl+T", onSelect: cycleTheme},
					{label: "Reset zoom", disabled: true}
				]
			}
		]);
		ui.content.addChild(bar);
	}

	function cycleTheme():Void {
		themeIndex = (themeIndex + 1) % UITheme.PRESETS.length;
		UITheme.apply(UITheme.PRESETS[themeIndex].palette);
		UIToast.show('Theme: ${UITheme.PRESETS[themeIndex].name}');
	}

	// UIIconRail (left activity bar, switches sections)
	function buildRail():Void {
		var rail = new UIIconRail(RAIL_W, 600 - MENU_H, [
			{label: "SET", tooltipFallback: "Controls"},
			{label: "DATA", tooltipFallback: "Data"},
			{label: "INFO", tooltipFallback: "About"}
		], (i) -> showSection(i));
		rail.y = MENU_H;
		ui.content.addChild(rail);
	}

	function buildSections():Void {
		for (i in 0...3) {
			var s = new Sprite();
			s.x = OX;
			s.y = OY;
			sections.push(s);
			ui.content.addChild(s);
		}
		buildControls(sections[0]);
		buildData(sections[1]);
		buildAbout(sections[2]);
	}

	function showSection(i:Int):Void {
		for (n in 0...sections.length)
			sections[n].visible = (n == i);
	}

	// Section 0: UITabs over the input widgets
	function buildControls(page:Sprite):Void {
		var panel = new UIPanel(560, 512, PANEL);
		panel.corner = 10;
		panel.outline = true;
		page.addChild(panel);

		var audio = new Sprite();
		var display = new Sprite();
		display.visible = false;

		var tabs = new UITabs(536, [{label: "Audio"}, {label: "Display"}], (i) -> {
			audio.visible = (i == 0);
			display.visible = (i == 1);
		});
		tabs.x = 12;
		tabs.y = 12;
		page.addChild(tabs);

		audio.x = display.x = 12;
		audio.y = display.y = 54;
		page.addChild(audio);
		page.addChild(display);

		buildAudioTab(audio);
		buildDisplayTab(display);
	}

	// UISlider, UIStepper, UISwitch, UICheckbox, UISegmentedControl, UIIconButton, UIProgressBar
	function buildAudioTab(page:Sprite):Void {
		var vol = new UISlider("Master volume", 512, 0, 1, volume, (v) -> volume = v);
		vol.decimals = 2;
		vol.y = 0;
		page.addChild(vol);

		var buffer = new UIStepper("Buffer", 512, 20, 5, (v) -> {});
		buffer.min = 5;
		buffer.max = 200;
		buffer.suffix = " ms";
		buffer.y = 40;
		page.addChild(buffer);

		var mono = new UISwitch("Force mono", 512, false, (on) -> UIToast.show(on ? "Mono" : "Stereo"));
		mono.y = 80;
		page.addChild(mono);

		var subtitles = new UICheckbox("Enable subtitles", 512, true, (on) -> {});
		subtitles.y = 120;
		page.addChild(subtitles);

		var q = new UISegmentedControl("Quality", 512, ["Low", "Medium", "High"], (i) -> quality = i);
		q.select(quality);
		q.y = 160;
		page.addChild(q);

		// A transport row of vector-glyph icon buttons (no assets needed).
		var transport:Array<UIGlyph> = [PREV, PLAY, NEXT, LOOP];
		for (n in 0...transport.length) {
			var kind = transport[n];
			var b = UIButton.icon(UIIcon.fromGlyph(kind, 16), 30, () -> {});
			b.x = n * 38;
			b.y = 208;
			b.onClick = () -> {
				if (kind == PLAY || kind == LOOP)
					b.accent = !b.accent; // toolbar toggle
				UIToast.show("transport " + n);
			};
			page.addChild(b);
		}

		var bar = new UIProgressBar("Streaming assets", 512, 0.35);
		bar.showPercent = true;
		bar.y = 256;
		page.addChild(bar);
	}

	// UIDropdown, UITextInput, UIChip, UIKeybind, UIIcon, UILabel
	function buildDisplayTab(page:Sprite):Void {
		var res = new UIDropdown("Resolution", 512, (i, value) -> UIToast.show('Set $value'));
		res.setItems(["1280x720", "1920x1080", "2560x1440"]);
		res.select(1);
		res.y = 0;
		page.addChild(res);

		var name = new UITextInput("Profile name", 512, "Player 1", (t) -> {});
		name.maxLength = 24;
		name.onEnter = (t) -> UIToast.show('Saved $t');
		name.y = 40;
		page.addChild(name);

		var chip = new UIChip("Beta features", true, false, (on) -> {});
		chip.y = 92;
		page.addChild(chip);

		var jump = new UIKeybind("Jump", 512, 32, (code) -> UIToast.show('Bound $code'));
		jump.y = 130;
		page.addChild(jump);

		// UIIcon drawing a built-in vector glyph (no asset needed); it can also load svg/png assets.
		var icon = UIIcon.fromGlyph(STAR, 24);
		icon.x = 0;
		icon.y = 178;
		page.addChild(icon);

		var iconNote = new UILabel("← UIIcon.fromGlyph(STAR) — vector, no asset (or pass an svg/png path)", 11, SECONDARY);
		iconNote.x = 34;
		iconNote.y = 182;
		page.addChild(iconNote);
	}

	// Section 1: UIList + a scrolling UIScrollPane of accordions
	function buildData(page:Sprite):Void {
		var heading = new UILabel("Saved profiles", 13, 1);
		page.addChild(heading);

		// UIList pulls rows from a provider (count + label) and only builds visible rows.
		var list = new UIList(260, 300);
		list.setProvider(profiles.length, (i) -> profiles[i]);
		list.onActivate = (i) -> UIToast.show('Loaded ${profiles[i]}');
		list.y = 24;
		page.addChild(list);

		// Right-click the heading → a context menu at the cursor.
		heading.onRightClick = () -> {
			UIContextMenu.open(ui.mouseX, ui.mouseY, [
				{label: "Rename", onSelect: () -> UIToast.show("Rename")},
				{label: "Duplicate", onSelect: () -> UIToast.show("Duplicate")},
				{separator: true},
				{label: "Delete", onSelect: () -> UIToast.show("Deleted")}
			]);
		};

		var sep = new UISeparator(340, true); // vertical
		sep.x = 288;
		page.addChild(sep);

		// A scroll pane whose content overflows so the scrollbar appears; two collapsible
		// accordions re-flow the content on toggle.
		dataScroll = new UIScrollPane(300, 340);
		dataScroll.x = 308;
		page.addChild(dataScroll);

		accGeneral = new UIAccordion("General", 280, true, (_) -> relayoutData());
		bodyGeneral = buildLabelStack(["Language: English", "Region: EU", "Autosave: on", "Telemetry: off"]);
		accAdvanced = new UIAccordion("Advanced", 280, false, (_) -> relayoutData());
		bodyAdvanced = buildLabelStack(["Renderer: GPU", "VSync: on", "Threads: 8", "Cache: 512 MB", "Log level: warn"]);

		dataScroll.content.addChild(accGeneral);
		dataScroll.content.addChild(bodyGeneral);
		dataScroll.content.addChild(accAdvanced);
		dataScroll.content.addChild(bodyAdvanced);
		relayoutData();
	}

	function buildLabelStack(lines:Array<String>):Sprite {
		var s = new Sprite();
		for (i in 0...lines.length) {
			var l = new UILabel(lines[i], 12, 2);
			l.x = 14;
			l.y = i * 20;
			s.addChild(l);
		}
		return s;
	}

	// Stacks the accordions and shows/hides each body, then re-measures the scroll content.
	function relayoutData():Void {
		var y:Float = 0;
		accGeneral.y = y;
		y += accGeneral.h + 4;
		bodyGeneral.visible = accGeneral.expanded;
		if (accGeneral.expanded) {
			bodyGeneral.y = y;
			y += bodyGeneral.height + 8;
		}
		accAdvanced.y = y;
		y += accAdvanced.h + 4;
		bodyAdvanced.visible = accAdvanced.expanded;
		if (accAdvanced.expanded) {
			bodyAdvanced.y = y;
			y += bodyAdvanced.height + 8;
		}
		dataScroll.refreshContent(y);
	}

	// Section 2: labels, a primary and a danger button, a modal trigger
	function buildAbout(page:Sprite):Void {
		var title = new UILabel("SmiðrUI", 22, 0);
		page.addChild(title);

		var body = new UILabel("A retained-mode UI toolkit for OpenFL.\nWidgets repaint only when invalidated.", 13, 1);
		body.wrapWidth = 520;
		body.y = 34;
		page.addChild(body);

		var about = new UIButton("About…", 160, 32, () -> openAbout(), true);
		about.y = 96;
		about.tooltip = "Show the about dialog";
		about.tooltipShortcut = "F1";
		page.addChild(about);

		var del = new UIButton("Delete save", 160, 32, () -> UIToast.show("Deleted"), false);
		del.danger = true;
		del.x = 176;
		del.y = 96;
		page.addChild(del);

		var hint = new UILabel("Tip: right-click the “Saved profiles” heading in the Data section.", 11, 2);
		hint.y = 144;
		page.addChild(hint);
	}

	// UIModal: add content to `body`, open() centers it over a dimmed backdrop.
	function openAbout():Void {
		var modal = new UIModal("About SmiðrUI", 320, 160);

		var text = new UILabel("Lightweight. Themable. Dependency-free.\nThis dialog lives on the popup layer.", 12, 1);
		text.wrapWidth = 288;
		text.x = 16;
		text.y = 8;
		modal.body.addChild(text);

		var ok = new UIButton("Got it", 100, 30, () -> modal.close(), true);
		ok.x = 16;
		ok.y = 70;
		modal.body.addChild(ok);

		modal.onClosed = () -> UIToast.show("Closed");
		modal.open();
	}

	/** Full teardown. Call when leaving the screen. **/
	public function destroy():Void {
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
