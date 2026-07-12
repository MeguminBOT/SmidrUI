package smidr.widgets;

import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.types.UICursor;
import smidr.types.UIFill;

/**
	A draggable, titled window and the supported way to build movable tool panels. Parent the
	window's widgets into `content` (its origin sits just below the title bar) and they move with
	the window for free: they are plain display-list children, so layouts are written once in
	window-local coordinates and never touched again on drag.

	The window itself is a passive, blocking surface; the interactive title bar is a child, so
	widgets inside `content` receive the pointer normally. Pressing anywhere raises the window to
	the front and makes it the active window (its bar renders brighter). Options: `draggable`
	(the bar drags with viewport clamping), `resizable` (a bottom-right grip, honouring
	`minWidth`/`minHeight`), `closable` (an X that fires `onClose` or disposes), and `collapsible`
	(a chevron that rolls the body up to just the bar). The body is a `UIFill` (the `PANEL` slot by
	default) with a 1px outline and a `PANEL3` title band, so it follows theme swaps like `UIPanel`.
**/
final class UIWindow extends UIComponent {
	/** The active (front-most, most recently pressed) window, or `null`. **/
	public static var activeWindow(default, null):UIWindow = null;

	public var key(default, set):String = null;
	public var fallback:String = "";
	public var title(default, set):String;

	/** What the body paints: a theme slot (follows theme swaps) or a fixed ARGB colour. **/
	public var fill(default, set):UIFill = PANEL;

	/** `false` pins the window in place (the title bar stops dragging). **/
	public var draggable:Bool = true;

	/** Shows a bottom-right resize grip honouring `minWidth`/`minHeight`. **/
	public var resizable(default, set):Bool = false;

	/** Shows a close (X) button that fires `onClose`, or disposes the window when it is `null`. **/
	public var closable(default, set):Bool = false;

	/** Shows a collapse (chevron) button that rolls the body up to just the title bar. **/
	public var collapsible(default, set):Bool = false;

	/** `true` while the body is rolled up (bar only). **/
	public var collapsed(default, null):Bool = false;

	/** Title-bar height in base (unscaled) pixels. **/
	public var barHeight(default, set):Float = 26;

	/** Base (unscaled) title font size. **/
	public var fontSize(default, set):Int = 13;

	/** Smallest width a resize drag allows. **/
	public var minWidth:Float = 140;

	/** Smallest height a resize drag allows. **/
	public var minHeight:Float = 80;

	/** Fired after the user drags the window, with the new `x`/`y` (already applied). **/
	public var onMoved:(x:Float, y:Float) -> Void = null;

	/** Fired after the user resizes the window, with the new `w`/`h` (already applied). **/
	public var onResized:(w:Float, h:Float) -> Void = null;

	/** Fired when the close button is hit; when `null` the window disposes itself. **/
	public var onClose:Void->Void = null;

	/** Parent the window's widgets here; local `(0, 0)` is the body's top-left below the bar. **/
	public final content:Sprite;

	final bar:UIWindowBar;
	var closeButton:UIWindowButton = null;
	var collapseButton:UIWindowButton = null;
	var grip:UIWindowGrip = null;

	/**
		@param title the title-bar text (raw; use `localize` for translated titles)
		@param width layout width
		@param height TOTAL layout height, title bar included
		@param fill the body fill: a theme slot or a fixed ARGB colour
	**/
	public function new(title:String, width:Float, height:Float, fill:UIFill = PANEL) {
		super(false, true);
		@:bypassAccessor this.title = title;
		@:bypassAccessor this.fill = fill;
		content = new Sprite();
		bar = new UIWindowBar(this);
		addChild(content);
		addChild(bar);
		addEventListener(MouseEvent.MOUSE_DOWN, __onDown);
		resize(width, height);
		setActive(this);
		render();
	}

	/**
		Switches the title to a localized string.
		@param key the translation key
		@param fallback the source-language text
	**/
	public function localize(key:String, fallback:String):Void {
		this.fallback = fallback;
		this.key = key;
	}

	inline function barPx():Float
		return UITheme.px(barHeight);

	/** `true` while this is the active (front-most) window. **/
	public var isActive(get, never):Bool;

	inline function get_isActive():Bool
		return activeWindow == this;

	static function setActive(win:UIWindow):Void {
		if (activeWindow == win)
			return;
		var old:UIWindow = activeWindow;
		activeWindow = win;
		if (old != null)
			old.bar.invalidate();
		if (win != null)
			win.bar.invalidate();
	}

	/** Rolls the body up to just the title bar, or back down. **/
	public function toggleCollapse():Void {
		collapsed = !collapsed;
		invalidate();
	}

	/** Fires `onClose`, or disposes the window when no handler is set. **/
	public function requestClose():Void {
		if (onClose != null)
			onClose();
		else
			dispose();
	}

	function __onDown(_:MouseEvent):Void {
		if (parent != null)
			parent.setChildIndex(this, parent.numChildren - 1);
		setActive(this);
	}

	override public function render():Void {
		graphics.clear();
		var barH:Float = barPx();
		var bodyH:Float = collapsed ? barH : h;
		var fillColor:Int = fill.resolve();

		graphics.beginFill(UIColor.rgb(fillColor), UIColor.alphaOf(fillColor));
		graphics.drawRect(0, 0, w, bodyH);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(UITheme.border));
		graphics.drawRect(0.5, 0.5, w - 1, bodyH - 1);
		graphics.lineStyle();

		bar.resize(w, barH);
		content.x = 0;
		content.y = barH;
		content.visible = !collapsed;

		// buttons pack from the right edge of the bar, each a bar-height square
		var rightX:Float = w;
		if (closeButton != null) {
			rightX -= barH;
			closeButton.x = rightX;
			closeButton.resize(barH, barH);
		}
		if (collapseButton != null) {
			rightX -= barH;
			collapseButton.x = rightX;
			collapseButton.resize(barH, barH);
			collapseButton.setCollapsed(collapsed);
		}
		bar.setTitleInset(w - rightX);

		if (grip != null) {
			grip.visible = resizable && !collapsed;
			var gs:Float = UITheme.px(14);
			grip.resize(gs, gs);
			grip.x = w - gs;
			grip.y = bodyH - gs;
		}
	}

	/** Keeps at least a grabbable sliver of the title bar inside the stage viewport. **/
	@:allow(smidr.widgets.UIWindowBar)
	function clampToViewport():Void {
		if (stage == null || parent == null)
			return;
		var tl:Point = parent.globalToLocal(new Point(0, 0));
		var br:Point = parent.globalToLocal(new Point(stage.stageWidth, stage.stageHeight));
		var minSize:Float = UITheme.px(40);
		if (x < tl.x - w + minSize)
			x = tl.x - w + minSize;
		if (x > br.x - minSize)
			x = br.x - minSize;
		if (y < tl.y)
			y = tl.y;
		if (y > br.y - barPx())
			y = br.y - barPx();
	}

	@:allow(smidr.widgets.UIWindowGrip)
	function resizeByDrag(newW:Float, newH:Float):Void {
		if (newW < minWidth)
			newW = minWidth;
		if (newH < minHeight)
			newH = minHeight;
		if (newW == w && newH == h)
			return;
		resize(newW, newH);
		if (onResized != null)
			onResized(w, h);
	}

	override public function dispose():Void {
		removeEventListener(MouseEvent.MOUSE_DOWN, __onDown);
		if (activeWindow == this)
			activeWindow = null;
		// `content` is a plain Sprite, so the base class's direct-children walk would miss the
		// hosted widgets; dispose them explicitly first.
		var i:Int = content.numChildren;
		while (--i >= 0) {
			var child = content.getChildAt(i);
			if (child is UIComponent)
				(cast child : UIComponent).dispose();
		}
		content.removeChildren();
		super.dispose();
	}

	function set_key(value:String):String {
		key = value;
		if (bar != null)
			bar.invalidate();
		return value;
	}

	function set_title(value:String):String {
		title = value;
		if (bar != null)
			bar.invalidate();
		return value;
	}

	function set_fill(value:UIFill):UIFill {
		fill = value;
		invalidate();
		return value;
	}

	function set_barHeight(value:Float):Float {
		barHeight = value;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		if (bar != null)
			bar.invalidate();
		return value;
	}

	function set_resizable(value:Bool):Bool {
		resizable = value;
		if (value && grip == null) {
			grip = new UIWindowGrip(this);
			addChild(grip);
		}
		invalidate();
		return value;
	}

	function set_closable(value:Bool):Bool {
		closable = value;
		if (value && closeButton == null) {
			closeButton = new UIWindowButton(true);
			closeButton.onClick = requestClose;
			addChild(closeButton);
		} else if (!value && closeButton != null) {
			removeChild(closeButton);
			closeButton.dispose();
			closeButton = null;
		}
		invalidate();
		return value;
	}

	function set_collapsible(value:Bool):Bool {
		collapsible = value;
		if (value && collapseButton == null) {
			collapseButton = new UIWindowButton(false);
			collapseButton.onClick = toggleCollapse;
			addChild(collapseButton);
		} else if (!value && collapseButton != null) {
			removeChild(collapseButton);
			collapseButton.dispose();
			collapseButton = null;
		}
		invalidate();
		return value;
	}
}

/** The interactive title bar: drags the window (with viewport clamping) and draws the title band. **/
private final class UIWindowBar extends UIComponent {
	final owner:UIWindow;
	final tf:TextField;
	var dragging:Bool = false;
	var grabX:Float = 0;
	var grabY:Float = 0;
	var titleInset:Float = 0;

	public function new(owner:UIWindow) {
		super(true, true);
		this.owner = owner;
		hoverCursor = UICursor.MOVE;
		tf = UIFonts.make(UITheme.fs(owner.fontSize), UITheme.text);
		addChild(tf);
	}

	public function setTitleInset(inset:Float):Void {
		titleInset = inset;
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (!owner.draggable)
			return;
		dragging = true;
		grabX = localX;
		grabY = localY;
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (!dragging || owner.parent == null)
			return;
		var point:Point = owner.parent.globalToLocal(new Point(stageX, stageY));
		owner.x = point.x - grabX;
		owner.y = point.y - grabY;
		owner.clampToViewport();
		if (owner.onMoved != null)
			owner.onMoved(owner.x, owner.y);
	}

	override function onDragEnd():Void {
		dragging = false;
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(UIColor.rgb(owner.isActive ? UITheme.panel3 : UITheme.panel2));
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(UITheme.border));
		graphics.drawRect(0, h - 1, w, 1);
		graphics.endFill();

		UIFonts.restyle(tf, UITheme.fs(owner.fontSize), owner.isActive ? UITheme.text : UITheme.text2);
		var resolved:String = (owner.key != null) ? UILocale.t(owner.key, owner.fallback) : owner.title;
		if (resolved == null)
			resolved = "";
		if (tf.text != resolved)
			tf.text = resolved;
		tf.x = UITheme.px(10);
		tf.y = (h - tf.textHeight) / 2 - 1;
		// clip the title so it never runs under the buttons on the right
		tf.width = Math.max(0, w - titleInset - UITheme.px(14));
	}
}

/** A title-bar close (X) or collapse (chevron) button. **/
private final class UIWindowButton extends UIComponent {
	final isClose:Bool;
	var collapsedState:Bool = false;

	public function new(isClose:Bool) {
		super(true, true);
		this.isClose = isClose;
		hoverCursor = UICursor.CLICK;
	}

	public function setCollapsed(value:Bool):Void {
		if (collapsedState == value)
			return;
		collapsedState = value;
		invalidate();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		if (hovered) {
			graphics.beginFill(UIColor.rgb(isClose ? UITheme.danger : UITheme.panel3), isClose ? 0.9 : 1.0);
			var inset:Float = UITheme.px(4);
			graphics.drawRoundRect(inset, inset, w - 2 * inset, h - 2 * inset, UITheme.px(4), UITheme.px(4));
			graphics.endFill();
		}
		var color:Int = (hovered && isClose) ? 0xFFF4F4F8 : UITheme.text2;
		graphics.lineStyle(1.6, UIColor.rgb(color));
		var cx:Float = w / 2;
		var cy:Float = h / 2;
		var size:Float = UITheme.px(3.4);
		if (isClose) {
			graphics.moveTo(cx - size, cy - size);
			graphics.lineTo(cx + size, cy + size);
			graphics.moveTo(cx + size, cy - size);
			graphics.lineTo(cx - size, cy + size);
		} else if (collapsedState) {
			graphics.moveTo(cx - size, cy - size * 0.5);
			graphics.lineTo(cx, cy + size * 0.5);
			graphics.lineTo(cx + size, cy - size * 0.5);
		} else {
			graphics.moveTo(cx - size, cy + size * 0.5);
			graphics.lineTo(cx, cy - size * 0.5);
			graphics.lineTo(cx + size, cy + size * 0.5);
		}
		graphics.lineStyle();
	}
}

/** A bottom-right resize grip. **/
private final class UIWindowGrip extends UIComponent {
	final owner:UIWindow;
	var startW:Float = 0;
	var startH:Float = 0;
	var grabX:Float = 0;
	var grabY:Float = 0;

	public function new(owner:UIWindow) {
		super(true, true);
		this.owner = owner;
		hoverCursor = UICursor.RESIZE_NWSE;
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (!owner.resizable || owner.parent == null || stage == null)
			return;
		startW = owner.w;
		startH = owner.h;
		var point:Point = owner.parent.globalToLocal(new Point(stage.mouseX, stage.mouseY));
		grabX = point.x;
		grabY = point.y;
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (owner.parent == null)
			return;
		var point:Point = owner.parent.globalToLocal(new Point(stageX, stageY));
		owner.resizeByDrag(startW + (point.x - grabX), startH + (point.y - grabY));
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(UITheme.border2));
		var pad:Float = UITheme.px(3);
		graphics.moveTo(w - pad, h - pad - UITheme.px(6));
		graphics.lineTo(w - pad - UITheme.px(6), h - pad);
		graphics.moveTo(w - pad, h - pad - UITheme.px(3));
		graphics.lineTo(w - pad - UITheme.px(3), h - pad);
		graphics.lineStyle();
	}
}
