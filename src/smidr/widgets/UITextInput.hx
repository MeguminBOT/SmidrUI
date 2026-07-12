package smidr.widgets;

import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;
import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;

/**
	A labelled single-line text field: label left, input box right. Click to focus; while
	focused it captures the keyboard (`UIFocus.typing`) — caret, Shift+arrow selection,
	Home/End, Ctrl+A/C/X/V, Backspace/Delete word-aware basics, Enter commits (`onEnter`),
	Escape blurs. `onChange(text)` fires on every edit.
**/
final class UITextInput extends UIComponent implements IUIFocusable {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var text(default, set):String = "";
	public var onChange:String->Void = null;
	public var onEnter:String->Void = null;
	public var fontSize(default, set):Int = 12;

	/** Optional character filter; return false to reject a typed char. **/
	public var filter:(charCode:Int) -> Bool = null;

	public var maxLength:Int = 0;

	/** Width of the input box on the right; 0 = whole row. **/
	public var controlWidth:Float = 0;

	final valueField:TextField;
	final labelField:TextField;

	var focusedNow:Bool = false;
	var caret:Int = 0;
	var anchor:Int = 0;
	var blink:Float = 0;
	var caretVisible:Bool = true;

	/**
		@param label the row text on the left (empty = the box spans the whole row)
		@param width layout width
		@param text the initial content
		@param onChange fired on every edit
	**/
	public function new(label:String, width:Float, text:String = "", ?onChange:String->Void) {
		super(true, true);
		hoverCursor = openfl.ui.MouseCursor.IBEAM;
		this.label = label;
		this.onChange = onChange;
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
		valueField = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		valueField.autoSize = openfl.text.TextFieldAutoSize.NONE;
		addChild(valueField);
		@:bypassAccessor this.text = text;
		caret = text.length;
		anchor = caret;
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

	inline function inputX():Float {
		return (controlWidth > 0) ? (w - controlWidth) : ((label != "" || key != null) ? w * 0.42 : 0);
	}

	public function capturesKeyboard():Bool {
		return focusedNow;
	}

	public function onFocusGained():Void {
		focusedNow = true;
		blink = 0;
		caretVisible = true;
		UIRoot.addTicker(tick);
		invalidate();
	}

	public function onFocusLost():Void {
		focusedNow = false;
		UIRoot.removeTicker(tick);
		invalidate();
	}

	function tick(dtMs:Float):Void {
		blink += dtMs;
		if (blink >= 530) {
			blink = 0;
			caretVisible = !caretVisible;
			invalidate();
		}
	}

	override function onPress(localX:Float, localY:Float):Void {
		var ix:Float = inputX();
		if (localX < ix) {
			return;
		}
		UIFocus.set(this);
		caret = indexAt(localX - ix - UITheme.px(6) + valueField.scrollH);
		anchor = caret;
		caretVisible = true;
		blink = 0;
		invalidate();
	}

	function indexAt(px:Float):Int {
		var length:Int = text.length;
		if (length == 0 || px <= 0)
			return 0;
		var i:Int = 0;
		while (i < length) {
			var bounds = valueField.getCharBoundaries(i);
			if (bounds != null && px < bounds.x + bounds.width * 0.5 - 2)
				return i;
			i++;
		}
		return length;
	}

	public function onKeyDown(keyCode:Int, charCode:Int, ctrl:Bool, shift:Bool, alt:Bool):Bool {
		if (!focusedNow)
			return false;
		switch (keyCode) {
			case 27: // escape
				UIFocus.clear(this);
				return true;
			case 13: // enter
				UIFocus.clear(this);
				if (onEnter != null)
					onEnter(text);
				return true;
			case 8: // backspace
				if (hasSelection())
					deleteSelection();
				else if (caret > 0) {
					setTextInternal(text.substring(0, caret - 1) + text.substring(caret));
					caret--;
					anchor = caret;
				}
				return true;
			case 46: // delete
				if (hasSelection())
					deleteSelection();
				else if (caret < text.length)
					setTextInternal(text.substring(0, caret) + text.substring(caret + 1));
				return true;
			case 37: // left
				if (caret > 0)
					caret--;
				if (!shift)
					anchor = caret;
				resetBlink();
				return true;
			case 39: // right
				if (caret < text.length)
					caret++;
				if (!shift)
					anchor = caret;
				resetBlink();
				return true;
			case 36: // home
				caret = 0;
				if (!shift)
					anchor = caret;
				resetBlink();
				return true;
			case 35: // end
				caret = text.length;
				if (!shift)
					anchor = caret;
				resetBlink();
				return true;
		}
		if (ctrl) {
			switch (keyCode) {
				case 65: // A
					anchor = 0;
					caret = text.length;
					resetBlink();
					return true;
				case 67: // C
					if (hasSelection())
						Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, selectionText());
					return true;
				case 88: // X
					if (hasSelection()) {
						Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, selectionText());
						deleteSelection();
					}
					return true;
				case 86: // V
					var clip:Dynamic = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT);
					if (clip != null)
						insert(Std.string(clip));
					return true;
			}
			return true;
		}
		if (charCode >= 32 && charCode != 127) {
			if (filter == null || filter(charCode))
				insert(String.fromCharCode(charCode));
			return true;
		}
		return true;
	}

	function insert(content:String):Void {
		if (hasSelection())
			deleteSelection();
		var next:String = text.substring(0, caret) + content + text.substring(caret);
		if (maxLength > 0 && next.length > maxLength)
			return;
		setTextInternal(next);
		caret += content.length;
		anchor = caret;
	}

	inline function hasSelection():Bool {
		return caret != anchor;
	}

	function selectionText():String {
		var start:Int = (caret < anchor) ? caret : anchor;
		var end:Int = (caret < anchor) ? anchor : caret;
		return text.substring(start, end);
	}

	function deleteSelection():Void {
		var start:Int = (caret < anchor) ? caret : anchor;
		var end:Int = (caret < anchor) ? anchor : caret;
		setTextInternal(text.substring(0, start) + text.substring(end));
		caret = start;
		anchor = start;
	}

	function setTextInternal(value:String):Void {
		@:bypassAccessor text = value;
		resetBlink();
		invalidate();
		if (onChange != null)
			onChange(value);
	}

	inline function resetBlink():Void {
		blink = 0;
		caretVisible = true;
		invalidate();
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var ix:Float = inputX();
		var bw:Float = w - ix;
		var radius:Float = UITheme.px(6);
		graphics.beginFill(UIColor.rgb(UITheme.inputBg));
		graphics.drawRoundRect(ix, 1, bw, h - 2, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(focusedNow ? UITheme.accent : UITheme.border));
		graphics.drawRoundRect(ix + 0.5, 1.5, bw - 1, h - 3, radius, radius);
		graphics.lineStyle();

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.visible = resolved != "";
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), UITheme.text);
		if (valueField.text != text)
			valueField.text = text;
		valueField.width = bw - UITheme.px(12);
		valueField.height = valueField.textHeight + 4;
		valueField.x = ix + UITheme.px(6);
		valueField.y = (h - valueField.height) / 2;

		// keep the caret inside the box (the field scrolls horizontally with it)
		if (focusedNow) {
			var rawCaret:Float = rawCaretX(caret);
			var innerW:Float = valueField.width - 4;
			if (rawCaret - valueField.scrollH > innerW)
				valueField.scrollH = Std.int(rawCaret - innerW + 8);
			else if (rawCaret - valueField.scrollH < 0)
				valueField.scrollH = Std.int(Math.max(0, rawCaret - 8));
		} else if (valueField.scrollH != 0)
			valueField.scrollH = 0;

		if (focusedNow) {
			if (hasSelection()) {
				var start:Int = (caret < anchor) ? caret : anchor;
				var end:Int = (caret < anchor) ? anchor : caret;
				var x0:Float = caretX(start);
				var x1:Float = caretX(end);
				graphics.beginFill(UIColor.rgb(UITheme.accentDark), 0.45);
				graphics.drawRect(valueField.x + x0, valueField.y + 1, x1 - x0, valueField.height - 2);
				graphics.endFill();
			}
			if (caretVisible) {
				var cx:Float = valueField.x + caretX(caret);
				graphics.beginFill(UIColor.rgb(UITheme.text));
				graphics.drawRect(cx, valueField.y + 1, 1.5, valueField.height - 2);
				graphics.endFill();
			}
		}
	}

	function caretX(index:Int):Float {
		return rawCaretX(index) - valueField.scrollH;
	}

	function rawCaretX(index:Int):Float {
		if (index <= 0 || text.length == 0)
			return 0;
		if (index > text.length)
			index = text.length;
		var bounds = valueField.getCharBoundaries(index - 1);
		return (bounds != null) ? (bounds.x + bounds.width) : 0;
	}

	override public function dispose():Void {
		UIFocus.clear(this);
		UIRoot.removeTicker(tick);
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

	function set_text(value:String):String {
		if (text == value)
			return value;
		text = value;
		if (caret > value.length)
			caret = value.length;
		if (anchor > value.length)
			anchor = value.length;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
