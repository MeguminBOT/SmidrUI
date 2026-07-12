package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;

/**
	A small count/status bubble: a rounded pill sized to its text, meant to overlay a button or
	icon (position it yourself at the corner). A zero count hides it unless `showZero`; counts past
	`maxCount` show as `N+`. Set `text` for a non-numeric label (e.g. "NEW"). Non-interactive.
**/
final class UIBadge extends UIComponent {
	/** The count shown (hidden at 0 unless `showZero`). **/
	public var count(default, set):Int = 0;

	/** A non-numeric label; overrides `count` when set. **/
	public var text(default, set):String = null;

	/** Pill colour, or -1 for the theme danger colour. **/
	public var color:Int = -1;

	/** Show the badge even when the count is 0. **/
	public var showZero:Bool = false;

	/** Counts above this render as `maxCount+`. **/
	public var maxCount:Int = 99;

	final labelField:TextField;

	/**
		@param count the initial count
	**/
	public function new(?count:Int) {
		super(false, false);
		labelField = UIFonts.make(UITheme.fs(10), UITheme.highlight);
		addChild(labelField);
		if (count != null)
			this.count = count;
		resize(UITheme.px(16), UITheme.px(16));
		render();
	}

	function set_count(value:Int):Int {
		count = value;
		invalidate();
		return value;
	}

	function set_text(value:String):String {
		text = value;
		invalidate();
		return value;
	}

	function contentString():String {
		if (text != null)
			return text;
		if (count > maxCount)
			return maxCount + "+";
		return "" + count;
	}

	override public function render():Void {
		graphics.clear();

		var hidden:Bool = (text == null && count <= 0 && !showZero);
		labelField.visible = !hidden;
		if (hidden) {
			if (w != 0 || h != 0)
				resize(0, 0);
			return;
		}

		var content:String = contentString();
		UIFonts.restyle(labelField, UITheme.fs(10), UITheme.highlight);
		if (labelField.text != content)
			labelField.text = content;

		var height:Float = UITheme.px(16);
		var padX:Float = UITheme.px(6);
		var width:Float = labelField.width + padX * 2;
		if (width < height)
			width = height;
		if (w != width || h != height)
			resize(width, height);

		graphics.beginFill(UIColor.rgb((color == -1) ? UITheme.danger : color));
		graphics.drawRoundRect(0, 0, width, height, height, height);
		graphics.endFill();
		labelField.x = (width - labelField.width) / 2;
		labelField.y = (height - labelField.height) / 2;
	}
}
