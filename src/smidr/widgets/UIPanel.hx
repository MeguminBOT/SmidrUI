package smidr.widgets;

import smidr.UIColor;
import smidr.UIComponent;
import smidr.UITheme;
import smidr.types.UISurface;

/**
	A filled surface: chrome bands, cards, placeholders. Non-interactive but blocking by default
	(children stay interactive, pointer hits never fall through). `corner` rounds the fill;
	the four `border*` flags draw 1px themed edges and `outline` draws a full 1px frame.

	Themed by default: a panel is bound to a `UISurface` role (`PANEL` unless you pass another),
	so it re-reads the palette every render and follows theme swaps like the rest of the library.
	For the rare fixed-colour surface (a static backdrop, brand splash) use `UIPanel.solid`.
**/
final class UIPanel extends UIComponent {
	/** The theme surface role driving the fill; follows theme swaps. `< 0` means use `fill`. **/
	public var surface(default, set):UISurface = PANEL;

	/** Fixed ARGB fill, used only when `surface` is cleared (via `UIPanel.solid` / setting `fill`). **/
	public var fill(default, set):Int = 0;

	/** Corner radius in scaled pixels (0 = square). **/
	public var corner(default, set):Float = 0;

	public var borderTop(default, set):Bool = false;
	public var borderBottom(default, set):Bool = false;
	public var borderLeft(default, set):Bool = false;
	public var borderRight(default, set):Bool = false;

	/** Full 1px frame (cards). **/
	public var outline(default, set):Bool = false;

	/**
		@param width layout width
		@param height layout height
		@param surface the theme surface role driving the fill (follows theme swaps)
		@param blocking `true` swallows pointer hits (children stay interactive)
	**/
	public function new(width:Float, height:Float, surface:UISurface = PANEL, blocking:Bool = true) {
		super(false, blocking);
		@:bypassAccessor this.surface = surface;
		resize(width, height);
		render();
	}

	/**
		Builds a panel with a fixed ARGB fill that does NOT follow theme swaps (static backdrops,
		brand colours). Prefer the themed constructor for normal chrome.
		@param width layout width
		@param height layout height
		@param fill the fixed fill colour (ARGB)
		@param blocking `true` swallows pointer hits (children stay interactive)
		@return the configured panel
	**/
	public static function solid(width:Float, height:Float, fill:Int, blocking:Bool = true):UIPanel {
		var p:UIPanel = new UIPanel(width, height, PANEL, blocking);
		p.fill = fill; // set_fill clears `surface`, switching to the fixed colour
		return p;
	}

	inline function resolveFill():Int {
		return switch (surface) {
			case BG: UITheme.bg;
			case PANEL: UITheme.panel;
			case PANEL2: UITheme.panel2;
			case PANEL3: UITheme.panel3;
			case CARD: UITheme.card;
			case INPUT: UITheme.inputBg;
			default: fill; // surface < 0 -> explicit fill
		}
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		var f:Int = resolveFill();
		g.beginFill(UIColor.rgb(f), UIColor.alphaOf(f));
		if (corner > 0)
			g.drawRoundRect(0, 0, w, h, corner, corner);
		else
			g.drawRect(0, 0, w, h);
		g.endFill();

		if (outline) {
			g.lineStyle(1, UIColor.rgb(UITheme.border));
			if (corner > 0)
				g.drawRoundRect(0.5, 0.5, w - 1, h - 1, corner, corner);
			else
				g.drawRect(0.5, 0.5, w - 1, h - 1);
			g.lineStyle();
			return;
		}

		g.beginFill(UIColor.rgb(UITheme.border));
		if (borderTop)
			g.drawRect(0, 0, w, 1);
		if (borderBottom)
			g.drawRect(0, h - 1, w, 1);
		if (borderLeft)
			g.drawRect(0, 0, 1, h);
		if (borderRight)
			g.drawRect(w - 1, 0, 1, h);
		g.endFill();
	}

	function set_fill(v:Int):Int {
		fill = v;
		surface = cast -1; // a fixed colour clears the theme role
		invalidate();
		return v;
	}

	function set_surface(v:UISurface):UISurface {
		surface = v;
		invalidate();
		return v;
	}

	function set_corner(v:Float):Float {
		corner = v;
		invalidate();
		return v;
	}

	function set_borderTop(v:Bool):Bool {
		borderTop = v;
		invalidate();
		return v;
	}

	function set_borderBottom(v:Bool):Bool {
		borderBottom = v;
		invalidate();
		return v;
	}

	function set_borderLeft(v:Bool):Bool {
		borderLeft = v;
		invalidate();
		return v;
	}

	function set_borderRight(v:Bool):Bool {
		borderRight = v;
		invalidate();
		return v;
	}

	function set_outline(v:Bool):Bool {
		outline = v;
		invalidate();
		return v;
	}
}
