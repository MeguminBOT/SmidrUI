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
	A labelled text field: label left, input box right. Click to focus; while focused it
	captures the keyboard (`UIFocus.typing`) — caret, Shift+arrow selection, Home/End,
	Ctrl+A/C/X/V, Backspace/Delete word-aware basics, Enter commits (`onEnter`), Escape blurs.
	`onChange(text)` fires on every edit.

	Set `multiline` for a wrapping text area instead: the label moves above a full-width box,
	Enter inserts a line break (and no longer commits), Up/Down walk lines and the box scrolls
	vertically to follow the caret. Give it a taller `resize` height — the single-line default
	shows one row.
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

	/** Width of the input box on the right; 0 = whole row. Ignored while `multiline`. **/
	public var controlWidth:Float = 0;

	/** Wrapping text area: label above a full-width box, Enter inserts a line break. **/
	public var multiline(default, set):Bool = false;

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
		if (multiline)
			return 0;
		return (controlWidth > 0) ? (w - controlWidth) : ((label != "" || key != null) ? w * 0.42 : 0);
	}

	/** Top of the input box: below the label in multiline mode, the whole row otherwise. **/
	inline function inputY():Float {
		return (multiline && labelField.visible) ? (labelField.height + UITheme.px(2)) : 0;
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
		if (localX < ix || localY < inputY()) {
			return;
		}
		UIFocus.set(this);
		if (multiline) {
			var hit:Int = valueField.getCharIndexAtPoint(localX - valueField.x, localY - valueField.y);
			caret = (hit >= 0) ? hit : text.length;
		} else
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
				if (multiline) {
					insert("\n");
					return true;
				}
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
			case 38: // up
				if (multiline) {
					caret = caretOnLine(lineOfCaret() - 1);
					if (!shift)
						anchor = caret;
					resetBlink();
					return true;
				}
			case 40: // down
				if (multiline) {
					caret = caretOnLine(lineOfCaret() + 1);
					if (!shift)
						anchor = caret;
					resetBlink();
					return true;
				}
			case 36: // home
				caret = multiline ? lineStart(lineOfCaret()) : 0;
				if (!shift)
					anchor = caret;
				resetBlink();
				return true;
			case 35: // end
				caret = multiline ? lineEnd(lineOfCaret()) : text.length;
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

	/** The (wrapped) line the caret sits on, 0-based. **/
	function lineOfCaret():Int {
		var line:Int = valueField.getLineIndexOfChar(caret);
		return (line >= 0) ? line : 0;
	}

	inline function lineCount():Int {
		var n:Int = valueField.numLines;
		return (n > 0) ? n : 1;
	}

	/** First character index of a (clamped) line. **/
	function lineStart(line:Int):Int {
		if (line < 0)
			line = 0;
		else if (line > lineCount() - 1)
			line = lineCount() - 1;
		var offset:Int = valueField.getLineOffset(line);
		return (offset >= 0) ? offset : 0;
	}

	/** Index just past the last character of a line, excluding its line break. **/
	function lineEnd(line:Int):Int {
		var start:Int = lineStart(line);
		var end:Int = start + valueField.getLineLength(line);
		if (end > text.length)
			end = text.length;
		while (end > start && (text.charAt(end - 1) == "\n" || text.charAt(end - 1) == "\r"))
			end--;
		return end;
	}

	/** The caret moved to another line, keeping its column where the line is long enough. **/
	function caretOnLine(line:Int):Int {
		if (line < 0 || line > lineCount() - 1)
			return caret;
		var column:Int = caret - lineStart(lineOfCaret());
		var start:Int = lineStart(line);
		var end:Int = lineEnd(line);
		var target:Int = start + column;
		return (target > end) ? end : target;
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

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.visible = resolved != "";
		labelField.x = 0;

		var ix:Float = inputX();
		var iy:Float = inputY();
		var bw:Float = w - ix;
		var bh:Float = h - iy;
		var radius:Float = UITheme.px(6);
		graphics.beginFill(UIColor.rgb(UITheme.inputBg));
		graphics.drawRoundRect(ix, iy + 1, bw, bh - 2, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(focusedNow ? UITheme.accent : UITheme.border));
		graphics.drawRoundRect(ix + 0.5, iy + 1.5, bw - 1, bh - 3, radius, radius);
		graphics.lineStyle();

		labelField.y = multiline ? 0 : (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), UITheme.text);
		valueField.multiline = multiline;
		valueField.wordWrap = multiline;
		if (valueField.text != text)
			valueField.text = text;
		valueField.width = bw - UITheme.px(12);
		valueField.x = ix + UITheme.px(6);
		if (multiline) {
			valueField.height = bh - UITheme.px(8);
			valueField.y = iy + UITheme.px(4);
		} else {
			valueField.height = valueField.textHeight + 4;
			valueField.y = iy + (bh - valueField.height) / 2;
		}

		if (multiline)
			renderMultilineCaret();
		else
			renderCaret();
	}

	/** Single-line caret/selection, with the field scrolling horizontally to follow the caret. **/
	function renderCaret():Void {
		if (focusedNow) {
			var rawCaret:Float = rawCaretX(caret);
			var innerW:Float = valueField.width - 4;
			if (rawCaret - valueField.scrollH > innerW)
				valueField.scrollH = Std.int(rawCaret - innerW + 8);
			else if (rawCaret - valueField.scrollH < 0)
				valueField.scrollH = Std.int(Math.max(0, rawCaret - 8));
		} else if (valueField.scrollH != 0)
			valueField.scrollH = 0;

		if (!focusedNow)
			return;

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

	/** Text-area caret/selection: a band per selected line, the box scrolling vertically. **/
	function renderMultilineCaret():Void {
		if (!focusedNow)
			return;

		var lineH:Float = lineHeight();
		var caretLine:Int = lineOfCaret();
		// scrollV/bottomScrollV are 1-based line numbers
		if (caretLine + 1 < valueField.scrollV)
			valueField.scrollV = caretLine + 1;
		else if (caretLine + 1 > valueField.bottomScrollV)
			valueField.scrollV += caretLine + 1 - valueField.bottomScrollV;
		var top:Int = valueField.scrollV - 1;

		if (hasSelection()) {
			var start:Int = (caret < anchor) ? caret : anchor;
			var end:Int = (caret < anchor) ? anchor : caret;
			var first:Int = valueField.getLineIndexOfChar(start);
			var last:Int = valueField.getLineIndexOfChar(end);
			if (first < 0)
				first = 0;
			if (last < 0)
				last = lineCount() - 1;
			graphics.beginFill(UIColor.rgb(UITheme.accentDark), 0.45);
			for (line in first...last + 1) {
				var from:Int = (line == first) ? start : lineStart(line);
				var to:Int = (line == last) ? end : lineEnd(line);
				var x0:Float = columnX(from);
				var x1:Float = columnX(to);
				if (x1 <= x0)
					x1 = x0 + UITheme.px(4); // a selected (empty) line break still reads as selected
				graphics.drawRect(valueField.x + x0, valueField.y + (line - top) * lineH, x1 - x0, lineH);
			}
			graphics.endFill();
		}

		if (caretVisible) {
			graphics.beginFill(UIColor.rgb(UITheme.text));
			graphics.drawRect(valueField.x + columnX(caret), valueField.y + (caretLine - top) * lineH + 1, 1.5, lineH - 2);
			graphics.endFill();
		}
	}

	inline function lineHeight():Float {
		var lines:Int = lineCount();
		var total:Float = valueField.textHeight;
		return (total > 0 && lines > 0) ? total / lines : UITheme.fs(fontSize) * 1.2;
	}

	/** Horizontal offset of a character index inside its own line. **/
	function columnX(index:Int):Float {
		if (index <= 0 || text.length == 0)
			return 0;
		if (index > text.length)
			index = text.length;
		if (index == lineStart(valueField.getLineIndexOfChar(index)))
			return 0;
		var bounds = valueField.getCharBoundaries(index - 1);
		return (bounds != null) ? (bounds.x + bounds.width) : 0;
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

	function set_multiline(value:Bool):Bool {
		if (multiline == value)
			return value;
		multiline = value;
		if (!value)
			valueField.scrollV = 1;
		else
			valueField.scrollH = 0;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
