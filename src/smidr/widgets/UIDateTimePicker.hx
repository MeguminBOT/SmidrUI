package smidr.widgets;

import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.types.UIGlyph;

/**
	A labelled date (and optional time) field: label left, value box right. Clicking the box opens
	a calendar popup on `UIRoot.popupLayer` behind a click-blocking backdrop (Escape or an outside
	click closes it). Navigate months with the header arrows and click a day to pick it; with
	`showTime` the popup adds hour/minute steppers and a Set button, otherwise a day click commits
	immediately.

	Values are plain Haxe `Date`s; the field shows `YYYY-MM-DD` (plus ` HH:MM` when `showTime`).
**/
final class UIDateTimePicker extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	/** The selected value. **/
	public var value(default, null):Date;

	/** Fired when a value is committed (day click, or Set with `showTime`). **/
	public var onSelect:Date->Void = null;

	/** Show hour/minute steppers and require a Set click to commit. **/
	public var showTime:Bool = false;

	public var fontSize(default, set):Int = 12;

	/** Width of the value box on the right; the label uses the remaining row width. **/
	public var controlWidth:Float;

	static final MONTHS:Array<String> = [
		"January", "February", "March", "April", "May", "June", "July", "August", "September",
		"October", "November", "December"
	];
	static final WEEKDAYS:Array<String> = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

	final labelField:TextField;
	final valueField:TextField;

	var popup:Sprite = null;
	var pending:Date;
	var viewYear:Int = 0;
	var viewMonth:Int = 0;
	var cells:Array<UIDayCell> = [];
	var monthLabel:TextField = null;

	/**
		@param label the row text on the left
		@param width layout width (the value box sits at the right edge)
		@param value the initial value (defaults to now)
		@param onSelect fired when a value is committed
	**/
	public function new(label:String, width:Float, ?value:Date, ?onSelect:Date->Void) {
		super(true, true);
		this.label = label;
		this.value = (value != null) ? value : Date.now();
		this.pending = this.value;
		this.onSelect = onSelect;
		controlWidth = UITheme.px(150);
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
		valueField = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		valueField.autoSize = openfl.text.TextFieldAutoSize.NONE;
		addChild(valueField);
		resize(width, UITheme.px(24));
		render();
	}

	/**
		Switches the label to a localized string.
		@param key the translation key
		@param fallback the source-language text
	**/
	public function localize(key:String, fallback:String):Void {
		this.fallback = fallback;
		this.key = key;
	}

	/**
		Sets the value without firing `onSelect`.
		@param value the new date/time
	**/
	public function setValue(value:Date):Void {
		if (value == null)
			return;
		this.value = value;
		this.pending = value;
		invalidate();
	}

	inline function pad2(number:Int):String {
		return (number < 10) ? "0" + number : "" + number;
	}

	function formatValue(date:Date):String {
		var base:String = date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate());
		return showTime ? base + " " + pad2(date.getHours()) + ":" + pad2(date.getMinutes()) : base;
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (localX < w - controlWidth)
			return;
		if (popup == null)
			openPopup();
		else
			closePopup();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var bx:Float = w - controlWidth;
		var radius:Float = UITheme.px(6);
		var fill:Int = UITheme.panel2;
		if (hovered)
			fill = UIColor.lighten(fill, 0.08);
		graphics.beginFill(UIColor.rgb(fill));
		graphics.drawRoundRect(bx, 1, controlWidth, h - 2, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(popup != null ? UITheme.accent : UITheme.border));
		graphics.drawRoundRect(bx + 0.5, 1.5, controlWidth - 1, h - 3, radius, radius);
		graphics.lineStyle();
		// calendar glyph
		UIGlyphs.draw(graphics, UIGlyph.CLOCK, w - UITheme.px(18), h / 2 - UITheme.px(6), UITheme.px(12), UIColor.rgb(UITheme.text2));

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), UITheme.text);
		var formatted:String = formatValue(value);
		if (valueField.text != formatted)
			valueField.text = formatted;
		valueField.width = controlWidth - UITheme.px(28);
		valueField.height = valueField.textHeight + 4;
		valueField.x = bx + UITheme.px(8);
		valueField.y = (h - valueField.height) / 2;
	}

	function openPopup():Void {
		var root:UIRoot = UIRoot.current;
		if (root == null)
			return;

		pending = value;
		viewYear = value.getFullYear();
		viewMonth = value.getMonth();

		popup = new Sprite();
		var blocker:UIComponent = new UIComponent(true, true);
		blocker.hoverCursor = null;
		blocker.onClick = closePopup;
		blocker.graphics.beginFill(0, 0);
		blocker.graphics.drawRect(-16000, -16000, 32000, 32000);
		blocker.graphics.endFill();
		popup.addChild(blocker);

		var pad:Float = UITheme.px(10);
		var panelW:Float = UITheme.px(250);
		var headerH:Float = UITheme.px(30);
		var weekdayH:Float = UITheme.px(20);
		var cellW:Float = (panelW - pad * 2) / 7;
		var cellH:Float = UITheme.px(28);
		var gridH:Float = cellH * 6;
		var stepperH:Float = UITheme.px(34);
		var setH:Float = UITheme.px(30);
		var footerH:Float = showTime ? UITheme.px(6) + stepperH + UITheme.px(4) + stepperH + UITheme.px(8) + setH : 0;
		var panelH:Float = headerH + weekdayH + gridH + footerH + pad;

		var panel:Sprite = new Sprite();
		var panelGraphics = panel.graphics;
		var radius:Float = UITheme.px(8);
		panelGraphics.beginFill(UIColor.rgb(UITheme.panel2));
		panelGraphics.drawRoundRect(0, 0, panelW, panelH, radius, radius);
		panelGraphics.endFill();
		panelGraphics.lineStyle(1, UIColor.rgb(UITheme.border2));
		panelGraphics.drawRoundRect(0.5, 0.5, panelW - 1, panelH - 1, radius, radius);
		panelGraphics.lineStyle();

		var origin:Point = localToGlobal(new Point(w - controlWidth, h));
		var local:Point = root.popupLayer.globalToLocal(origin);
		panel.x = local.x;
		var vh:Float = (root.stage != null && root.scaleY > 0) ? root.stage.stageHeight / root.scaleY : 720;
		var py:Float = local.y + 2;
		if (py + panelH > vh - 4)
			py = local.y - h - panelH - 2;
		if (py < 4)
			py = 4;
		panel.y = py;
		popup.addChild(panel);

		// header: prev / month-year / next
		var prev:UIButton = UIButton.icon(UIIcon.fromGlyph(UIGlyph.CHEVRON_LEFT, 14), UITheme.px(24), prevMonth);
		prev.x = pad;
		prev.y = (headerH - UITheme.px(24)) / 2;
		panel.addChild(prev);
		var next:UIButton = UIButton.icon(UIIcon.fromGlyph(UIGlyph.CHEVRON_RIGHT, 14), UITheme.px(24), nextMonth);
		next.x = panelW - pad - UITheme.px(24);
		next.y = (headerH - UITheme.px(24)) / 2;
		panel.addChild(next);
		monthLabel = UIFonts.make(UITheme.fs(12), UITheme.text);
		panel.addChild(monthLabel);

		// weekday header
		for (col in 0...7) {
			var wd:TextField = UIFonts.make(UITheme.fs(10), UITheme.text3);
			wd.text = WEEKDAYS[col];
			wd.x = pad + col * cellW + (cellW - wd.width) / 2;
			wd.y = headerH + (weekdayH - wd.height) / 2;
			panel.addChild(wd);
		}

		// day grid
		cells.resize(0);
		var gridTop:Float = headerH + weekdayH;
		for (k in 0...42) {
			var cell:UIDayCell = new UIDayCell(this, cellW, cellH);
			cell.x = pad + (k % 7) * cellW;
			cell.y = gridTop + Std.int(k / 7) * cellH;
			panel.addChild(cell);
			cells.push(cell);
		}

		if (showTime) {
			var footTop:Float = gridTop + gridH + UITheme.px(6);
			var hourStepper:UIStepper = new UIStepper("Hour", panelW - pad * 2, pending.getHours(), 1, function(v:Float):Void {
				pending = new Date(pending.getFullYear(), pending.getMonth(), pending.getDate(), Std.int(v), pending.getMinutes(), 0);
			});
			hourStepper.min = 0;
			hourStepper.max = 23;
			hourStepper.x = pad;
			hourStepper.y = footTop;
			panel.addChild(hourStepper);
			var minStepper:UIStepper = new UIStepper("Minute", panelW - pad * 2, pending.getMinutes(), 5, function(v:Float):Void {
				pending = new Date(pending.getFullYear(), pending.getMonth(), pending.getDate(), pending.getHours(), Std.int(v), 0);
			});
			minStepper.min = 0;
			minStepper.max = 59;
			minStepper.x = pad;
			minStepper.y = footTop + stepperH + UITheme.px(4);
			panel.addChild(minStepper);
			var setBtn:UIButton = new UIButton("Set", panelW - pad * 2, setH, commit, true);
			setBtn.x = pad;
			setBtn.y = footTop + stepperH * 2 + UITheme.px(12);
			panel.addChild(setBtn);
		}

		panel.alpha = 0;
		smidr.UITween.to(function(p:Float):Void {
			panel.alpha = p;
			panel.scaleY = 0.96 + 0.04 * p;
		}, 0, 1, 145, smidr.types.UIEase.OUT_QUAD);

		rebuildCalendar();

		root.popupLayer.addChild(popup);
		UIRoot.pushOverlayCloser(closePopup);
		invalidate();
	}

	function rebuildCalendar():Void {
		if (monthLabel != null)
			monthLabel.text = MONTHS[viewMonth] + " " + viewYear;
		if (monthLabel != null) {
			var parentW:Float = UITheme.px(250);
			monthLabel.x = (parentW - monthLabel.width) / 2;
			monthLabel.y = (UITheme.px(30) - monthLabel.height) / 2;
		}

		var firstWeekday:Int = new Date(viewYear, viewMonth, 1, 12, 0, 0).getDay();
		var daysThis:Int = DateTools.getMonthDays(new Date(viewYear, viewMonth, 1, 12, 0, 0));
		var prevMonthIndex:Int = (viewMonth == 0) ? 11 : viewMonth - 1;
		var prevYear:Int = (viewMonth == 0) ? viewYear - 1 : viewYear;
		var daysPrev:Int = DateTools.getMonthDays(new Date(prevYear, prevMonthIndex, 1, 12, 0, 0));

		var now:Date = Date.now();
		for (k in 0...42) {
			var dayOffset:Int = k - firstWeekday;
			var dayNum:Int = dayOffset + 1;
			var cellYear:Int = viewYear;
			var cellMonth:Int = viewMonth;
			var cellDay:Int;
			var inMonth:Bool = true;
			if (dayNum < 1) {
				inMonth = false;
				cellMonth = prevMonthIndex;
				cellYear = prevYear;
				cellDay = daysPrev + dayNum;
			} else if (dayNum > daysThis) {
				inMonth = false;
				cellMonth = (viewMonth == 11) ? 0 : viewMonth + 1;
				cellYear = (viewMonth == 11) ? viewYear + 1 : viewYear;
				cellDay = dayNum - daysThis;
			} else {
				cellDay = dayNum;
			}
			var selected:Bool = (pending.getFullYear() == cellYear && pending.getMonth() == cellMonth && pending.getDate() == cellDay);
			var today:Bool = (now.getFullYear() == cellYear && now.getMonth() == cellMonth && now.getDate() == cellDay);
			cells[k].bind(cellYear, cellMonth, cellDay, inMonth, selected, today);
		}
	}

	function prevMonth():Void {
		if (viewMonth == 0) {
			viewMonth = 11;
			viewYear--;
		} else
			viewMonth--;
		rebuildCalendar();
	}

	function nextMonth():Void {
		if (viewMonth == 11) {
			viewMonth = 0;
			viewYear++;
		} else
			viewMonth++;
		rebuildCalendar();
	}

	@:allow(smidr.widgets.UIDayCell)
	function pickDay(year:Int, month:Int, day:Int):Void {
		var hour:Int = showTime ? pending.getHours() : 0;
		var minute:Int = showTime ? pending.getMinutes() : 0;
		pending = new Date(year, month, day, hour, minute, 0);
		if (showTime) {
			viewYear = year;
			viewMonth = month;
			rebuildCalendar();
		} else
			commit();
	}

	function commit():Void {
		value = pending;
		closePopup();
		invalidate();
		if (onSelect != null)
			onSelect(value);
	}

	/** Closes the calendar popup (no value change). **/
	public function closePopup():Void {
		if (popup == null)
			return;
		UIRoot.removeOverlayCloser(closePopup);
		monthLabel = null;
		cells.resize(0);
		var i:Int = popup.numChildren;
		while (--i >= 0) {
			var child = popup.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		disposeSprites(popup);
		popup.removeChildren();
		if (popup.parent != null)
			popup.parent.removeChild(popup);
		popup = null;
		invalidate();
	}

	static function disposeSprites(container:Sprite):Void {
		var i:Int = container.numChildren;
		while (--i >= 0) {
			var child = container.getChildAt(i);
			if (child is Sprite) {
				var sprite:Sprite = cast child;
				var j:Int = sprite.numChildren;
				while (--j >= 0) {
					var inner = sprite.getChildAt(j);
					if (inner is UIComponent)
						(cast inner : UIComponent).dispose();
				}
			}
		}
	}

	override public function dispose():Void {
		closePopup();
		super.dispose();
	}

	function set_key(value:String):String {
		key = value;
		invalidate();
		return value;
	}

	function set_label(value:String):String {
		label = value;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}

/** One day cell in the calendar grid: number, hover, selection fill, today ring, month dimming. **/
private final class UIDayCell extends UIComponent {
	final owner:UIDateTimePicker;
	final numberField:TextField;

	var cellYear:Int = 0;
	var cellMonth:Int = 0;
	var cellDay:Int = 1;
	var inMonth:Bool = true;
	var selected:Bool = false;
	var today:Bool = false;

	public function new(owner:UIDateTimePicker, width:Float, height:Float) {
		super(true, true);
		this.owner = owner;
		numberField = UIFonts.make(UITheme.fs(11), UITheme.text);
		addChild(numberField);
		resize(width, height);
	}

	public function bind(year:Int, month:Int, day:Int, inMonth:Bool, selected:Bool, today:Bool):Void {
		this.cellYear = year;
		this.cellMonth = month;
		this.cellDay = day;
		this.inMonth = inMonth;
		this.selected = selected;
		this.today = today;
		numberField.text = "" + day;
		invalidate();
	}

	override function click():Void {
		owner.pickDay(cellYear, cellMonth, cellDay);
		super.click();
	}

	override public function render():Void {
		graphics.clear();
		var inset:Float = UITheme.px(2);
		var radius:Float = UITheme.px(5);
		if (selected) {
			graphics.beginFill(UIColor.rgb(UITheme.accent));
			graphics.drawRoundRect(inset, inset, w - inset * 2, h - inset * 2, radius, radius);
			graphics.endFill();
		} else if (hovered) {
			graphics.beginFill(UIColor.rgb(UITheme.panel3));
			graphics.drawRoundRect(inset, inset, w - inset * 2, h - inset * 2, radius, radius);
			graphics.endFill();
		} else {
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
			if (today) {
				graphics.lineStyle(1, UIColor.rgb(UITheme.accent));
				graphics.drawRoundRect(inset + 0.5, inset + 0.5, w - inset * 2 - 1, h - inset * 2 - 1, radius, radius);
				graphics.lineStyle();
			}
		}

		var color:Int = selected ? UITheme.highlight : (inMonth ? UITheme.text : UITheme.text3);
		UIFonts.restyle(numberField, UITheme.fs(11), color);
		numberField.x = (w - numberField.width) / 2;
		numberField.y = (h - numberField.height) / 2;
	}
}
