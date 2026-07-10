package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.types.UITone;

/** One `UIStatusBar` cell. `width` fixes the cell width (0/omitted auto-sizes to the text);
	`rightAlign` packs it from the right edge instead of the left. **/
typedef UIStatusCell = {
	@:optional var text:String;
	@:optional var key:String;
	@:optional var fallback:String;
	@:optional var width:Float;
	@:optional var rightAlign:Bool;
	@:optional var tone:UITone;
}

/**
	A bottom status bar: a themed strip of text cells, left-packed by default with a `rightAlign`
	flag to pack from the right (line/column, encoding, clock). Thin separators divide adjacent
	cells on the same side. Passive but blocking, so it never leaks pointer hits to content behind
	it; span it across the window and update cells in place with `setText`.
**/
final class UIStatusBar extends UIComponent {
	public var fontSize(default, set):Int = 11;

	var cells:Array<UIStatusCell> = [];
	var fields:Array<TextField> = [];

	/**
		@param width layout width (typically spans the window)
		@param height the bar height
	**/
	public function new(width:Float, height:Float) {
		super(false, true);
		resize(width, height);
		render();
	}

	/**
		Replaces the cell set.
		@param cells the cells (left-packed unless `rightAlign` is set)
	**/
	public function setCells(cells:Array<UIStatusCell>):Void {
		this.cells = cells;
		var i:Int = fields.length;
		while (--i >= 0)
			removeChild(fields[i]);
		fields.resize(0);
		i = 0;
		while (i < cells.length) {
			var field:TextField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
			addChild(field);
			fields.push(field);
			i++;
		}
		invalidate();
	}

	/**
		Updates a cell's text in place (cheaper than rebuilding).
		@param index the cell index
		@param text the new text (clears any localization key)
	**/
	public function setText(index:Int, text:String):Void {
		if (index < 0 || index >= cells.length)
			return;
		cells[index].text = text;
		cells[index].key = null;
		invalidate();
	}

	inline function resolveTone(tone:UITone):Int {
		return switch (tone) {
			case PRIMARY: UITheme.text;
			case TERTIARY: UITheme.text3;
			default: UITheme.text2;
		}
	}

	override public function render():Void {
		var g = graphics;
		g.clear();
		g.beginFill(UIColor.rgb(UITheme.panel2));
		g.drawRect(0, 0, w, h);
		g.endFill();
		g.beginFill(UIColor.rgb(UITheme.border));
		g.drawRect(0, 0, w, 1);
		g.endFill();

		var padX:Float = UITheme.px(10);
		var gap:Float = UITheme.px(14);
		var leftX:Float = padX;
		var rightX:Float = w - padX;
		var leftCount:Int = 0;
		var rightCount:Int = 0;

		var i:Int = 0;
		var n:Int = cells.length;
		while (i < n) {
			var cell:UIStatusCell = cells[i];
			var field:TextField = fields[i];
			var tone:UITone = (cell.tone != null) ? cell.tone : SECONDARY;
			UIFonts.restyle(field, UITheme.fs(fontSize), resolveTone(tone));
			var resolved:String = (cell.key != null) ? UILocale.t(cell.key, cell.fallback != null ? cell.fallback : cell.text) : cell.text;
			if (resolved == null)
				resolved = "";
			if (field.text != resolved)
				field.text = resolved;
			var cellW:Float = (cell.width != null && cell.width > 0) ? UITheme.px(cell.width) : field.width;

			if (cell.rightAlign == true) {
				if (rightCount > 0)
					separator(g, rightX + gap / 2);
				rightX -= cellW;
				field.x = rightX + (cellW - field.width) / 2;
				rightX -= gap;
				rightCount++;
			} else {
				if (leftCount > 0)
					separator(g, leftX - gap / 2);
				field.x = leftX;
				leftX += cellW + gap;
				leftCount++;
			}
			field.y = (h - field.height) / 2;
			i++;
		}
	}

	inline function separator(g:openfl.display.Graphics, x:Float):Void {
		g.beginFill(UIColor.rgb(UITheme.border));
		g.drawRect(x, UITheme.px(5), 1, h - UITheme.px(10));
		g.endFill();
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
