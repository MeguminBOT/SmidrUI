package smidr.widgets;

import openfl.display.Graphics;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.UITween;
import smidr.types.UIEase;

/**
	A radial (pie) menu: entries laid out as donut sectors around the open point on
	`UIRoot.popupLayer`, behind a click-blocking backdrop. Moving the pointer highlights the
	sector under it; clicking a sector runs its `onSelect` and closes. Escape or an outside click
	closes with no selection. Reuses `UIMenuItem` (label/key/onSelect/disabled; separators and
	shortcuts are ignored here).
**/
final class UIPieMenu extends UIComponent {
	/** The open pie menu, if any (one at a time). **/
	public static var current(default, null):UIPieMenu = null;

	/** Fired when the menu closes (any reason). **/
	public var onClosed:Void->Void = null;

	final items:Array<UIMenuItem>;
	final labels:Array<TextField> = [];

	var blocker:UIComponent;
	var outerRadius:Float;
	var innerRadius:Float;
	var startAngle:Float = -Math.PI / 2;
	var step:Float;
	var hoveredSector:Int = -1;
	var closing:Bool = false;

	var centerX:Float = 0;
	var centerY:Float = 0;

	/**
		Opens a pie menu centered on a UI-space point, closing any menu already open.
		@param x the center x in UI (root content) coordinates
		@param y the center y in UI coordinates
		@param items the entries (an empty/`onSelect`-less entry is inert)
		@return the opened menu (assign `onClosed` for close notifications)
	**/
	public static function open(x:Float, y:Float, items:Array<UIMenuItem>):UIPieMenu {
		if (current != null)
			current.close();
		return new UIPieMenu(x, y, items);
	}

	function new(x:Float, y:Float, items:Array<UIMenuItem>) {
		super(true, true);
		this.items = items;
		current = this;
		centerX = x;
		centerY = y;
		outerRadius = UITheme.px(92);
		innerRadius = UITheme.px(40);
		step = (items.length > 0) ? (Math.PI * 2) / items.length : Math.PI * 2;

		blocker = new UIComponent(true, true);
		blocker.hoverCursor = null;
		blocker.onClick = close;
		blocker.graphics.beginFill(0, 0);
		blocker.graphics.drawRect(-16000, -16000, 32000, 32000);
		blocker.graphics.endFill();

		for (i in 0...items.length) {
			var field:TextField = UIFonts.make(UITheme.fs(11), UITheme.text);
			addChild(field);
			labels.push(field);
		}

		w = outerRadius * 2;
		h = outerRadius * 2;
		addEventListener(MouseEvent.MOUSE_MOVE, __onMove);

		var root:UIRoot = UIRoot.current;
		if (root != null) {
			root.popupLayer.addChild(blocker);
			root.popupLayer.addChild(this);
			UIRoot.pushOverlayCloser(close);
		}
		render();
		UITween.to(setOpenProgress, 0, 1, 150, OUT_BACK);
	}

	function setOpenProgress(progress:Float):Void {
		alpha = (progress < 0) ? 0 : (progress > 1 ? 1 : progress);
		var scale:Float = 0.85 + 0.15 * progress; // OUT_BACK overshoots then settles at 1
		scaleX = scale;
		scaleY = scale;
		// keep the center pinned while scaling from the top-left origin
		x = centerX - outerRadius * scale;
		y = centerY - outerRadius * scale;
	}

	function __onMove(_:MouseEvent):Void {
		if (closing || items.length == 0)
			return;
		var dx:Float = mouseX - outerRadius;
		var dy:Float = mouseY - outerRadius;
		var dist:Float = Math.sqrt(dx * dx + dy * dy);
		var idx:Int = -1;
		if (dist >= innerRadius * 0.55 && dist <= outerRadius) {
			var full:Float = Math.PI * 2;
			var a:Float = Math.atan2(dy, dx) - startAngle;
			a = (a % full + full) % full;
			idx = Std.int(a / step);
			if (idx >= items.length)
				idx = items.length - 1;
			if (items[idx].disabled == true)
				idx = -1;
		}
		if (idx != hoveredSector) {
			hoveredSector = idx;
			invalidate();
		}
	}

	override function click():Void {
		if (hoveredSector >= 0 && hoveredSector < items.length)
			pick(items[hoveredSector]);
		super.click();
	}

	function pick(item:UIMenuItem):Void {
		close();
		if (item.onSelect != null)
			item.onSelect();
	}

	/** Closes and disposes the menu. **/
	public function close():Void {
		if (closing)
			return;
		closing = true;
		if (current == this)
			current = null;
		UIRoot.removeOverlayCloser(close);
		UITween.to(setAlpha, alpha, 0, 100, IN_QUAD, finishClose);
	}

	function setAlpha(value:Float):Void {
		alpha = value;
	}

	function finishClose():Void {
		if (blocker.parent != null)
			blocker.parent.removeChild(blocker);
		blocker.dispose();
		var done:Void->Void = onClosed;
		dispose();
		if (done != null)
			done();
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var cx:Float = outerRadius;
		var cy:Float = outerRadius;
		var pad:Float = UITheme.px(2) / outerRadius; // ~2px gap at the rim, as an angle
		var midR:Float = (innerRadius + outerRadius) / 2;

		var i:Int = 0;
		var n:Int = items.length;
		while (i < n) {
			var item:UIMenuItem = items[i];
			var disabled:Bool = (item.disabled == true);
			var hot:Bool = (i == hoveredSector);
			var a0:Float = startAngle + i * step + pad;
			var a1:Float = startAngle + (i + 1) * step - pad;

			g.beginFill(UIColor.rgb(hot ? UITheme.accentDark : UITheme.panel2));
			g.lineStyle(1, UIColor.rgb(hot ? UITheme.accent : UITheme.border));
			sector(g, cx, cy, innerRadius, outerRadius, a0, a1);
			g.endFill();
			g.lineStyle();

			var mid:Float = startAngle + (i + 0.5) * step;
			var field:TextField = labels[i];
			var color:Int = disabled ? UITheme.text3 : (hot ? UIColor.contrastText(UITheme.accentDark) : UITheme.text);
			UIFonts.restyle(field, UITheme.fs(11), color);
			var resolved:String = (item.key != null) ? UILocale.t(item.key, item.fallback != null ? item.fallback : item.label) : item.label;
			if (resolved == null)
				resolved = "";
			if (field.text != resolved)
				field.text = resolved;
			field.x = cx + midR * Math.cos(mid) - field.width / 2;
			field.y = cy + midR * Math.sin(mid) - field.height / 2;
			i++;
		}
	}

	/** Traces one donut sector (inner to outer radius, `fromAngle`..`toAngle`). **/
	function sector(graphics:Graphics, centerX:Float, centerY:Float, innerRadius:Float, outerRadius:Float, fromAngle:Float, toAngle:Float):Void {
		var steps:Int = Std.int((toAngle - fromAngle) / 0.18);
		if (steps < 2)
			steps = 2;
		graphics.moveTo(centerX + innerRadius * Math.cos(fromAngle), centerY + innerRadius * Math.sin(fromAngle));
		graphics.lineTo(centerX + outerRadius * Math.cos(fromAngle), centerY + outerRadius * Math.sin(fromAngle));
		var k:Int = 1;
		while (k <= steps) {
			var angle:Float = fromAngle + (toAngle - fromAngle) * k / steps;
			graphics.lineTo(centerX + outerRadius * Math.cos(angle), centerY + outerRadius * Math.sin(angle));
			k++;
		}
		graphics.lineTo(centerX + innerRadius * Math.cos(toAngle), centerY + innerRadius * Math.sin(toAngle));
		k = steps - 1;
		while (k >= 0) {
			var angle:Float = fromAngle + (toAngle - fromAngle) * k / steps;
			graphics.lineTo(centerX + innerRadius * Math.cos(angle), centerY + innerRadius * Math.sin(angle));
			k--;
		}
	}

	override public function dispose():Void {
		removeEventListener(MouseEvent.MOUSE_MOVE, __onMove);
		if (blocker.parent != null)
			blocker.parent.removeChild(blocker);
		blocker.dispose();
		super.dispose();
	}
}
