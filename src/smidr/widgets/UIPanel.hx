package smidr.widgets;

import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIGradient;
import smidr.UITheme;
import smidr.types.UIFill;

/**
	A filled surface: chrome bands, cards, placeholders. Non-interactive but blocking by default
	(children stay interactive, pointer hits never fall through). `corner` rounds the fill;
	the four `border*` flags draw 1px themed edges and `outline` draws a full 1px frame.

	Themed by default: `fill` is a `UIFill` — a theme slot (`PANEL` unless you pass another)
	that re-reads the palette every render and follows theme swaps, or any ARGB colour literal
	(`new UIPanel(w, h, 0xFF1E1E21)`) for the rare fixed surface that shouldn't.
**/
final class UIPanel extends UIComponent {
	/** What the panel paints: a theme slot (follows theme swaps) or a fixed ARGB colour. **/
	public var fill(default, set):UIFill = PANEL;

	/** Optional gradient fill; overrides `fill` when set (fixed colours — see `UIGradient`). **/
	public var gradient(default, set):UIGradient = null;

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
		@param fill a theme slot (follows theme swaps) or a fixed ARGB colour
		@param blocking `true` swallows pointer hits (children stay interactive)
	**/
	public function new(width:Float, height:Float, fill:UIFill = PANEL, blocking:Bool = true) {
		super(false, blocking);
		@:bypassAccessor this.fill = fill;
		resize(width, height);
		render();
	}

	override public function render():Void {
		graphics.clear();
		if (gradient != null)
			gradient.fillRect(graphics, 0, 0, w, h, corner);
		else {
			var fillColor:Int = fill.resolve();
			graphics.beginFill(UIColor.rgb(fillColor), UIColor.alphaOf(fillColor));
			if (corner > 0)
				graphics.drawRoundRect(0, 0, w, h, corner, corner);
			else
				graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}

		if (outline) {
			graphics.lineStyle(1, UIColor.rgb(UITheme.border));
			if (corner > 0)
				graphics.drawRoundRect(0.5, 0.5, w - 1, h - 1, corner, corner);
			else
				graphics.drawRect(0.5, 0.5, w - 1, h - 1);
			graphics.lineStyle();
			return;
		}

		graphics.beginFill(UIColor.rgb(UITheme.border));
		if (borderTop)
			graphics.drawRect(0, 0, w, 1);
		if (borderBottom)
			graphics.drawRect(0, h - 1, w, 1);
		if (borderLeft)
			graphics.drawRect(0, 0, 1, h);
		if (borderRight)
			graphics.drawRect(w - 1, 0, 1, h);
		graphics.endFill();
	}

	function set_fill(value:UIFill):UIFill {
		fill = value;
		invalidate();
		return value;
	}

	function set_gradient(value:UIGradient):UIGradient {
		gradient = value;
		invalidate();
		return value;
	}

	function set_corner(value:Float):Float {
		corner = value;
		invalidate();
		return value;
	}

	function set_borderTop(value:Bool):Bool {
		borderTop = value;
		invalidate();
		return value;
	}

	function set_borderBottom(value:Bool):Bool {
		borderBottom = value;
		invalidate();
		return value;
	}

	function set_borderLeft(value:Bool):Bool {
		borderLeft = value;
		invalidate();
		return value;
	}

	function set_borderRight(value:Bool):Bool {
		borderRight = value;
		invalidate();
		return value;
	}

	function set_outline(value:Bool):Bool {
		outline = value;
		invalidate();
		return value;
	}
}
