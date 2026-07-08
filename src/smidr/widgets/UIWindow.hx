package smidr.widgets;

import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.types.UISurface;

/**
	A draggable, titled window and the supported way to build movable tool panels. Parent the
	window's widgets into `content` (its origin sits just below the title bar) and they move
	with the window for free: they are plain display-list children, so layouts are written once
	in window-local coordinates and never touched again on drag.

	The title bar is the drag handle (`draggable = false` pins the window); dragging clamps so
	part of the bar always stays reachable inside the stage viewport. The body is a themed
	`UISurface` fill (`PANEL` by default) with a 1px outline and a `PANEL3` title band, so it
	follows theme swaps like `UIPanel`.
**/
final class UIWindow extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var title(default, set):String;

	/** The theme surface role driving the body fill; follows theme swaps. **/
	public var surface(default, set):UISurface = PANEL;

	/** `false` pins the window in place (the title bar stops dragging). **/
	public var draggable:Bool = true;

	/** Title-bar height in base (unscaled) pixels. **/
	public var barHeight(default, set):Float = 26;

	/** Base (unscaled) title font size. **/
	public var fontSize(default, set):Int = 13;

	/** Fired after the user drags the window, with the new `x`/`y` (already applied). **/
	public var onMoved:(x:Float, y:Float) -> Void = null;

	/** Parent the window's widgets here; local `(0, 0)` is the body's top-left below the bar. **/
	public final content:Sprite;

	final tf:TextField;
	var dragging:Bool = false;
	var grabX:Float = 0;
	var grabY:Float = 0;

	/**
		@param title the title-bar text (raw; use `localize` for translated titles)
		@param width layout width
		@param height TOTAL layout height, title bar included
		@param surface the body's theme surface role
	**/
	public function new(title:String, width:Float, height:Float, surface:UISurface = PANEL) {
		super(true, true);
		@:bypassAccessor this.title = title;
		@:bypassAccessor this.surface = surface;
		tf = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		addChild(tf);
		content = new Sprite();
		addChild(content);
		resize(width, height);
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

	inline function resolveFill():Int {
		return switch (surface) {
			case BG: UITheme.bg;
			case PANEL: UITheme.panel;
			case PANEL2: UITheme.panel2;
			case PANEL3: UITheme.panel3;
			case CARD: UITheme.card;
			case INPUT: UITheme.inputBg;
			default: UITheme.panel;
		}
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var barH:Float = barPx();
		var f:Int = resolveFill();

		g.beginFill(UIColor.rgb(f), UIColor.alphaOf(f));
		g.drawRect(0, 0, w, h);
		g.endFill();

		g.beginFill(UIColor.rgb(UITheme.panel3));
		g.drawRect(0, 0, w, barH);
		g.endFill();

		g.lineStyle(1, UIColor.rgb(UITheme.border));
		g.drawRect(0.5, 0.5, w - 1, h - 1);
		g.moveTo(0, barH - 0.5);
		g.lineTo(w, barH - 0.5);
		g.lineStyle();

		UIFonts.restyle(tf, UITheme.fs(fontSize), UITheme.text);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : title;
		if (resolved == null)
			resolved = "";
		if (tf.text != resolved)
			tf.text = resolved;
		tf.x = UITheme.px(10);
		tf.y = (barH - tf.textHeight) / 2 - 1;

		content.x = 0;
		content.y = barH;
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (!draggable || localY > barPx())
			return;
		dragging = true;
		grabX = localX;
		grabY = localY;
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (!dragging || parent == null)
			return;
		var p:Point = parent.globalToLocal(new Point(stageX, stageY));
		x = p.x - grabX;
		y = p.y - grabY;
		clampToViewport();
		if (onMoved != null)
			onMoved(x, y);
	}

	override function onDragEnd():Void {
		dragging = false;
	}

	/** Keeps at least a grabbable sliver of the title bar inside the stage viewport. **/
	function clampToViewport():Void {
		if (stage == null || parent == null)
			return;
		var tl:Point = parent.globalToLocal(new Point(0, 0));
		var br:Point = parent.globalToLocal(new Point(stage.stageWidth, stage.stageHeight));
		var m:Float = UITheme.px(40);
		if (x < tl.x - w + m)
			x = tl.x - w + m;
		if (x > br.x - m)
			x = br.x - m;
		if (y < tl.y)
			y = tl.y;
		if (y > br.y - barPx())
			y = br.y - barPx();
	}

	override public function dispose():Void {
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

	function set_key(v:String):String {
		key = v;
		invalidate();
		return v;
	}

	function set_title(v:String):String {
		title = v;
		invalidate();
		return v;
	}

	function set_surface(v:UISurface):UISurface {
		surface = v;
		invalidate();
		return v;
	}

	function set_barHeight(v:Float):Float {
		barHeight = v;
		invalidate();
		return v;
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
