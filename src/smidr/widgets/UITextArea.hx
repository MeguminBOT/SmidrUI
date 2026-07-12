package smidr.widgets;

import openfl.Lib;
import openfl.desktop.Clipboard;
import openfl.desktop.ClipboardFormats;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;
import smidr.text.UIStyledText;
import smidr.text.UITextStyler;

/**
	A multi-line, scrollable text editor — the note-taking / code surface the single-line
	`UITextInput` is not. It owns text editing (caret, selection, scrolling, clipboard, variable
	line heights) but is deliberately **style-agnostic**: it carries one opaque `Int` style word per
	character and defers all meaning to an optional installed `styler` (`smidr.text.UITextStyler`).

	- With **no styler** it is a plain uniform-format multi-line field (what mobile / plain callers
	  want) — the style words are ignored.
	- Install `styler = new smidr.text.UIRichStyler()` for WYSIWYG formatting (bold / italic /
	  underline / colour / size / headings / lists). The editor never interprets the bits; the styler
	  turns them into `TextFormat` runs, list markers, indentation and outline boxes, and decides how
	  style flows across a line break. Markdown import/export lives in `smidr.text.UIMarkdown`.

	Editing: printable input, Enter for newlines, Tab, Backspace/Delete, Left/Right (Ctrl = word
	jump), Up/Down with a desired column, Home/End (Ctrl = document ends), PageUp/PageDown,
	Ctrl+A/C/X/V. Word-wrap by default; vertical scroll via wheel, a draggable thumb and drag-to-
	scroll on mobile. Set `readOnly` for a selectable-but-immutable viewer. Implements `UIStyledText`
	so styling modules can transform its style words without depending on this widget.
**/
final class UITextArea extends UIComponent implements IUIFocusable implements UIStyledText {
	/** The full multi-line content. **/
	public var text(default, set):String = "";

	/** The installed styling policy, or `null` for a plain uniform-format field. **/
	public var styler:UITextStyler = null;

	/** Fired after every edit with the new text. **/
	public var onChange:String->Void = null;

	/** Fired whenever the caret or selection moves (for a line/column or toolbar readout). **/
	public var onCaretMove:Void->Void = null;

	/** The current caret position as a character index into `text`. **/
	public var caretIndex(get, never):Int;

	inline function get_caretIndex():Int {
		return caret;
	}

	/** Selection start (min of caret/anchor). **/
	public var selectionStart(get, never):Int;

	inline function get_selectionStart():Int {
		return selMin();
	}

	/** Selection end (max of caret/anchor). **/
	public var selectionEnd(get, never):Int;

	inline function get_selectionEnd():Int {
		return selMax();
	}

	/** Style word applied to newly typed characters (opaque to this widget). **/
	public var typingStyle(get, set):Int;

	var typingStyleValue:Int = 0;

	inline function get_typingStyle():Int {
		return typingStyleValue;
	}

	function set_typingStyle(value:Int):Int {
		typingStyleValue = value;
		return value;
	}

	/** The text buffer (the `UIStyledText` accessor; mirrors `text`). **/
	public var styledText(get, never):String;

	inline function get_styledText():String {
		return text;
	}

	/** Dim hint shown while the field is empty. **/
	public var placeholder(default, set):String = "";

	/** When `true`, the caret and editing keys are suppressed (a viewer). **/
	public var readOnly:Bool = false;

	/** Base (unscaled) font size for normal text. **/
	public var fontSize(default, set):Int = 13;

	/** Soft-wrap long lines to the field width (default on); `false` clips and scrolls the caret. **/
	public var wordWrap(default, set):Bool = true;

	/** Hard character cap (0 = unlimited). **/
	public var maxLength:Int = 0;

	/** Base (unscaled) inner inset. **/
	public var padding:Float = 10;

	final field:TextField;
	final placeholderField:TextField;
	final markerPool:Array<TextField> = [];

	/** Parallel opaque style words, one per character of `text`. **/
	var attrs:Array<Int> = [];

	var focusedNow:Bool = false;
	var caret:Int = 0;
	var anchor:Int = 0;
	var desiredCol:Int = -1;
	var topLine:Int = 1;
	var blink:Float = 0;
	var caretVisible:Bool = true;

	var lineHeights:Array<Float> = [];
	var lineTops:Array<Float> = []; // relative; lineTops[i] = summed height of lines above i
	var totalHeight:Float = 0;
	var innerW:Float = 0;
	var innerH:Float = 0;
	var visibleLines:Int = 1;
	var contentLines:Int = 1;
	var pendingCaretShow:Bool = false;

	static inline var MODE_NONE:Int = 0;
	static inline var MODE_SELECT:Int = 1;
	static inline var MODE_THUMB:Int = 2;
	static inline var MODE_SCROLL:Int = 3;

	var mode:Int = MODE_NONE;
	var dragStartStageY:Float = 0;
	var dragStartTop:Int = 1;
	var thumbGrab:Float = 0;
	final thumbRect:Rectangle = new Rectangle();

	// undo/redo history (coalesced by edit kind: 1 = typing run, 2 = deletion run, 0 = discrete)
	static inline var UNDO_LIMIT:Int = 400;
	final undoStack:Array<UITextAreaState> = [];
	final redoStack:Array<UITextAreaState> = [];
	var coalesceKind:Int = 0;

	// multi-click (double = word, triple = paragraph)
	static inline var MULTI_CLICK_MS:Int = 400;
	var lastClickTime:Int = 0;
	var lastClickX:Float = 0;
	var lastClickY:Float = 0;
	var clickCount:Int = 0;

	/**
		@param width layout width (the scrollbar lives inside it)
		@param height the visible viewport height
		@param text the initial content
	**/
	public function new(width:Float, height:Float, text:String = "") {
		super(true, true);
		hoverCursor = openfl.ui.MouseCursor.IBEAM;
		field = UIFonts.make(UITheme.fs(fontSize), UITheme.text);
		field.multiline = true;
		field.wordWrap = true;
		field.autoSize = TextFieldAutoSize.NONE;
		addChild(field);
		placeholderField = UIFonts.make(UITheme.fs(fontSize), UITheme.text3);
		placeholderField.multiline = true;
		placeholderField.wordWrap = true;
		placeholderField.autoSize = TextFieldAutoSize.NONE;
		addChild(placeholderField);
		@:bypassAccessor this.text = text;
		attrs = [for (i in 0...text.length) 0];
		caret = text.length;
		anchor = caret;
		addEventListener(MouseEvent.MOUSE_WHEEL, __onWheel);
		resize(width, height);
		render();
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

	inline function resetBlink():Void {
		blink = 0;
		caretVisible = true;
	}

	inline function fireCaret():Void {
		if (onCaretMove != null)
			onCaretMove();
	}


	inline function scrollFactorY():Float {
		var root = UIRoot.current;
		return (root != null && root.scaleY > 0) ? root.scaleY : 1.0;
	}

	override function onPress(localX:Float, localY:Float):Void {
		UIFocus.set(this);
		if (thumbRect.width > 0 && thumbRect.contains(localX, localY)) {
			mode = MODE_THUMB;
			thumbGrab = localY - thumbRect.y;
			beginCapture();
			return;
		}
		var index:Int = indexAtLocal(localX, localY);
		coalesceKind = 0;
		var now:Int = Lib.getTimer();
		if (now - lastClickTime <= MULTI_CLICK_MS && Math.abs(localX - lastClickX) < 6 && Math.abs(localY - lastClickY) < 6)
			clickCount++;
		else
			clickCount = 1;
		lastClickTime = now;
		lastClickX = localX;
		lastClickY = localY;

		#if !mobile
		if (clickCount == 2)
			selectWordAt(index);
		else if (clickCount >= 3)
			selectParagraphAt(index);
		else {
			caret = index;
			anchor = index;
		}
		#else
		caret = index;
		anchor = index;
		#end
		desiredCol = -1;
		syncTypingStyle();
		resetBlink();
		pendingCaretShow = true;
		#if mobile
		mode = MODE_SCROLL;
		dragStartStageY = 0;
		dragStartTop = topLine;
		#else
		mode = MODE_SELECT;
		#end
		beginCapture();
		invalidate();
		fireCaret();
	}

	/** Selects the word (run of non-space characters) around an index; a run of spaces if on space. **/
	function selectWordAt(index:Int):Void {
		if (text.length == 0) {
			caret = 0;
			anchor = 0;
			return;
		}
		if (index >= text.length)
			index = text.length - 1;
		if (index < 0)
			index = 0;
		var onSpace:Bool = isSpace(text.charCodeAt(index));
		var start:Int = index;
		var end:Int = index;
		while (start > 0 && isSpace(text.charCodeAt(start - 1)) == onSpace && text.charCodeAt(start - 1) != 10)
			start--;
		while (end < text.length && isSpace(text.charCodeAt(end)) == onSpace && text.charCodeAt(end) != 10)
			end++;
		anchor = start;
		caret = end;
	}

	/** Selects the whole paragraph (line) around an index, excluding the trailing newline. **/
	function selectParagraphAt(index:Int):Void {
		if (index > text.length)
			index = text.length;
		var start:Int = index;
		while (start > 0 && text.charCodeAt(start - 1) != 10)
			start--;
		var end:Int = index;
		while (end < text.length && text.charCodeAt(end) != 10)
			end++;
		anchor = start;
		caret = end;
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		switch (mode) {
			case MODE_SELECT:
				var local = globalToLocal(new openfl.geom.Point(stageX, stageY));
				caret = indexAtLocal(local.x, local.y);
				desiredCol = -1;
				pendingCaretShow = true;
				resetBlink();
				invalidate();
				fireCaret();
			case MODE_THUMB:
				var local = globalToLocal(new openfl.geom.Point(stageX, stageY));
				thumbDragTo(local.y);
			case MODE_SCROLL:
				if (dragStartStageY == 0)
					dragStartStageY = stageY;
				var pxAvg:Float = averageLineHeight();
				var dyLines:Int = Std.int(((dragStartStageY - stageY) / scrollFactorY()) / pxAvg);
				setTop(dragStartTop + dyLines);
			default:
		}
	}

	override function onDragEnd():Void {
		mode = MODE_NONE;
	}

	function __onWheel(event:MouseEvent):Void {
		setTop(topLine - Std.int(event.delta));
		event.stopPropagation();
	}

	function thumbDragTo(localY:Float):Void {
		var trackTop:Float = UITheme.px(padding);
		var trackH:Float = innerH;
		if (totalHeight <= innerH || thumbRect.height >= trackH) {
			setTop(1);
			return;
		}
		var usable:Float = trackH - thumbRect.height;
		var rel:Float = (localY - thumbGrab - trackTop) / usable;
		if (rel < 0)
			rel = 0;
		if (rel > 1)
			rel = 1;
		var targetPx:Float = rel * (totalHeight - innerH);
		setTop(lineAtOffset(targetPx) + 1);
	}

	inline function averageLineHeight():Float {
		return (contentLines > 0 && totalHeight > 0) ? totalHeight / contentLines : UITheme.fs(fontSize) * 1.4;
	}

	function lineAtOffset(px:Float):Int {
		var line:Int = 0;
		while (line + 1 < contentLines && lineTops[line + 1] <= px)
			line++;
		return line;
	}

	inline function maxTopLine():Int {
		var max:Int = field.maxScrollV;
		return (max > 1) ? max : 1;
	}

	function setTop(line:Int):Void {
		var maxTop:Int = maxTopLine();
		if (line < 1)
			line = 1;
		if (line > maxTop)
			line = maxTop;
		if (line == topLine)
			return;
		topLine = line;
		invalidate();
	}

	function indexAtLocal(localX:Float, localY:Float):Int {
		var fx:Float = localX - field.x;
		var fy:Float = localY - field.y;
		if (fx < 3)
			fx = 3;
		if (fx > field.width + 3)
			fx = field.width + 3;
		if (fy < 1)
			fy = 1;
		if (fy > field.height + 3)
			fy = field.height + 3;
		var idx:Int = field.getCharIndexAtPoint(fx, fy);
		if (idx >= 0) {
			// round to the nearest glyph boundary: clicking the right half places the caret after it
			var bounds:Rectangle = field.getCharBoundaries(idx);
			if (bounds != null && idx < text.length && text.charCodeAt(idx) != 10 && (fx + field.scrollH) > bounds.x + bounds.width * 0.5)
				return idx + 1;
			return idx;
		}
		var line:Int = field.getLineIndexAtPoint(fx, fy);
		if (line < 0)
			return (fy <= 1) ? 0 : text.length;
		return lineEndIndex(line);
	}


	public function onKeyDown(keyCode:Int, charCode:Int, ctrl:Bool, shift:Bool, alt:Bool):Bool {
		if (!focusedNow)
			return false;
		switch (keyCode) {
			case 27: // escape
				UIFocus.clear(this);
				return true;
			case 8: // backspace
				if (readOnly)
					return true;
				if (hasSelection())
					deleteSelection();
				else if (caret > 0) {
					spliceText(caret - 1, caret, "", 2);
					caret--;
					anchor = caret;
				}
				afterEdit();
				return true;
			case 46: // delete
				if (readOnly)
					return true;
				if (hasSelection())
					deleteSelection();
				else if (caret < text.length)
					spliceText(caret, caret + 1, "", 2);
				afterEdit();
				return true;
			case 37: // left
				moveHorizontal(ctrl ? wordLeft(caret) : caret - 1, shift);
				return true;
			case 39: // right
				moveHorizontal(ctrl ? wordRight(caret) : caret + 1, shift);
				return true;
			case 38: // up
				moveVertical(-1, shift);
				return true;
			case 40: // down
				moveVertical(1, shift);
				return true;
			case 36: // home
				moveHorizontal(ctrl ? 0 : lineStartIndex(visualLineOf(caret)), shift);
				desiredCol = -1;
				return true;
			case 35: // end
				moveHorizontal(ctrl ? text.length : lineEndIndex(visualLineOf(caret)), shift);
				desiredCol = -1;
				return true;
			case 33: // page up
				pageMove(-1, shift);
				return true;
			case 34: // page down
				pageMove(1, shift);
				return true;
			case 9: // tab
				if (!readOnly) {
					insert("\t");
					afterEdit();
				}
				return true;
		}
		if (ctrl) {
			switch (keyCode) {
				case 90: // Z -> undo (Shift+Z -> redo)
					if (!readOnly) {
						if (shift)
							redo();
						else
							undo();
					}
				case 89: // Y -> redo
					if (!readOnly)
						redo();
				case 65: // A
					anchor = 0;
					caret = text.length;
					coalesceKind = 0;
					pendingCaretShow = true;
					resetBlink();
					invalidate();
					fireCaret();
				case 67: // C
					if (hasSelection())
						Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, selectionText());
				case 88: // X
					if (hasSelection() && !readOnly) {
						Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, selectionText());
						deleteSelection();
						afterEdit();
					}
				case 86: // V
					if (!readOnly) {
						var clip:Dynamic = Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT);
						if (clip != null) {
							insert(Std.string(clip));
							afterEdit();
						}
					}
			}
			return true;
		}
		if (keyCode == 13) { // enter -> newline
			if (!readOnly) {
				insert("\n");
				if (styler != null)
					typingStyleValue = styler.styleForNewLine(typingStyleValue);
				afterEdit();
			}
			return true;
		}
		if (charCode >= 32 && charCode != 127) {
			if (!readOnly) {
				insert(String.fromCharCode(charCode), 1); // typing run (coalesced undo)
				afterEdit();
			}
			return true;
		}
		return true;
	}

	inline function afterEdit():Void {
		desiredCol = -1;
		pendingCaretShow = true;
		resetBlink();
		invalidate();
		fireCaret();
	}

	function moveHorizontal(target:Int, extend:Bool):Void {
		if (target < 0)
			target = 0;
		if (target > text.length)
			target = text.length;
		caret = target;
		if (!extend)
			anchor = caret;
		desiredCol = -1;
		coalesceKind = 0;
		syncTypingStyle();
		pendingCaretShow = true;
		resetBlink();
		invalidate();
		fireCaret();
	}

	function moveVertical(dir:Int, extend:Bool):Void {
		var line:Int = visualLineOf(caret);
		if (desiredCol < 0)
			desiredCol = caret - lineStartIndex(line);
		var target:Int = line + dir;
		if (target < 0) {
			caret = 0;
		} else if (target > contentLines - 1) {
			caret = text.length;
		} else {
			var start:Int = lineStartIndex(target);
			var len:Int = lineVisibleLength(target);
			caret = start + (desiredCol < len ? desiredCol : len);
		}
		if (!extend)
			anchor = caret;
		coalesceKind = 0;
		syncTypingStyle();
		pendingCaretShow = true;
		resetBlink();
		invalidate();
		fireCaret();
	}

	function pageMove(dir:Int, extend:Bool):Void {
		setTop(topLine + dir * visibleLines);
		moveVertical(dir * visibleLines, extend);
	}

	function wordLeft(from:Int):Int {
		var i:Int = from;
		while (i > 0 && isSpace(text.charCodeAt(i - 1)))
			i--;
		while (i > 0 && !isSpace(text.charCodeAt(i - 1)))
			i--;
		return i;
	}

	function wordRight(from:Int):Int {
		var i:Int = from;
		var length:Int = text.length;
		while (i < length && !isSpace(text.charCodeAt(i)))
			i++;
		while (i < length && isSpace(text.charCodeAt(i)))
			i++;
		return i;
	}

	inline function isSpace(code:Int):Bool {
		return code == 32 || code == 9 || code == 10 || code == 13;
	}


	function insert(content:String, kind:Int = 0):Void {
		var from:Int = selMin();
		var to:Int = selMax();
		if (maxLength > 0 && (text.length - (to - from) + content.length) > maxLength)
			return;
		spliceText(from, to, content, kind);
		caret = from + content.length;
		anchor = caret;
	}

	function deleteSelection():Void {
		var start:Int = selMin();
		var end:Int = selMax();
		spliceText(start, end, "");
		caret = start;
		anchor = start;
	}

	/** The single edit primitive: replaces `text[from...to)` with `ins`, keeping `attrs` in step. **/
	function spliceText(from:Int, to:Int, ins:String, kind:Int = 0):Void {
		snapshot(kind);
		var replacement:Array<Int> = [];
		var current:Int = typingStyleValue;
		var i:Int = 0;
		while (i < ins.length) {
			if (i > 0 && ins.charCodeAt(i - 1) == 10 && styler != null)
				current = styler.styleForNewLine(current);
			replacement.push(current);
			i++;
		}
		text = text.substring(0, from) + ins + text.substring(to);
		attrs = attrs.slice(0, from).concat(replacement).concat(attrs.slice(to));
		if (onChange != null)
			onChange(text);
	}

	inline function hasSelection():Bool {
		return caret != anchor;
	}

	inline function selMin():Int {
		return (caret < anchor) ? caret : anchor;
	}

	inline function selMax():Int {
		return (caret < anchor) ? anchor : caret;
	}

	function selectionText():String {
		return text.substring(selMin(), selMax());
	}

	/** Adopt the surrounding style so new input matches (paragraph-start uses the styler's rule). **/
	function syncTypingStyle():Void {
		if (text.length == 0) {
			typingStyleValue = 0;
			return;
		}
		if (caret > 0 && caret <= text.length && text.charCodeAt(caret - 1) == 10) {
			if (caret < attrs.length && text.charCodeAt(caret) != 10)
				typingStyleValue = attrs[caret];
			else
				typingStyleValue = (styler != null) ? styler.styleForNewLine(attrs[caret - 1]) : attrs[caret - 1];
			return;
		}
		if (caret > 0 && caret <= attrs.length)
			typingStyleValue = attrs[caret - 1];
		else if (caret < attrs.length)
			typingStyleValue = attrs[caret];
	}


	public function hasStyledSelection():Bool {
		return hasSelection();
	}

	public function styleAt(index:Int):Int {
		return (index >= 0 && index < attrs.length) ? attrs[index] : typingStyleValue;
	}

	/** Applies `map` to every selected character's style, or to `typingStyle` when nothing is selected. **/
	public function styleSelection(map:Int->Int):Void {
		if (hasSelection()) {
			snapshot(0);
			var start:Int = selMin();
			var end:Int = selMax();
			for (i in start...end)
				attrs[i] = map(attrs[i]);
			if (onChange != null)
				onChange(text);
		} else {
			typingStyleValue = map(typingStyleValue);
		}
		invalidate();
		fireCaret();
	}

	/** Applies `map` to every character in the paragraphs the selection touches (and `typingStyle`). **/
	public function styleParagraphs(map:Int->Int):Void {
		snapshot(0);
		var start:Int = selMin();
		var end:Int = selMax();
		while (start > 0 && text.charCodeAt(start - 1) != 10)
			start--;
		while (end < text.length && text.charCodeAt(end) != 10)
			end++;
		for (i in start...end)
			attrs[i] = map(attrs[i]);
		typingStyleValue = map(typingStyleValue);
		if (onChange != null)
			onChange(text);
		invalidate();
		fireCaret();
	}

	// undo/redo

	function snapshot(kind:Int):Void {
		if (kind != 0 && kind == coalesceKind && undoStack.length > 0) {
			coalesceKind = kind;
			return; // fold into the current run (typing/deleting) so undo is word-sized, not char-sized
		}
		undoStack.push({text: text, attrs: attrs.copy(), caret: caret, anchor: anchor});
		if (undoStack.length > UNDO_LIMIT)
			undoStack.shift();
		redoStack.resize(0);
		coalesceKind = kind;
	}

	function applyState(state:UITextAreaState):Void {
		@:bypassAccessor text = state.text;
		attrs = state.attrs.copy();
		caret = (state.caret <= text.length) ? state.caret : text.length;
		anchor = (state.anchor <= text.length) ? state.anchor : text.length;
		desiredCol = -1;
		coalesceKind = 0;
		pendingCaretShow = true;
		resetBlink();
		if (onChange != null)
			onChange(text);
		invalidate();
		fireCaret();
	}

	/** Reverts the most recent edit (Ctrl+Z). **/
	public function undo():Void {
		if (undoStack.length == 0)
			return;
		redoStack.push({text: text, attrs: attrs.copy(), caret: caret, anchor: anchor});
		applyState(undoStack.pop());
	}

	/** Re-applies the most recently undone edit (Ctrl+Y / Ctrl+Shift+Z). **/
	public function redo():Void {
		if (redoStack.length == 0)
			return;
		undoStack.push({text: text, attrs: attrs.copy(), caret: caret, anchor: anchor});
		applyState(redoStack.pop());
	}


	/** A copy of the per-character style words, to persist alongside `text`. **/
	public function getStyleData():Array<Int> {
		return attrs.copy();
	}

	/** Loads text and its parallel style words together (restores saved formatting). **/
	public function setRich(newText:String, styleData:Array<Int>):Void {
		if (newText == null)
			newText = "";
		@:bypassAccessor text = newText;
		attrs = (styleData != null && styleData.length == newText.length) ? styleData.copy() : [for (i in 0...newText.length) 0];
		caret = 0;
		anchor = 0;
		topLine = 1;
		desiredCol = -1;
		typingStyleValue = 0;
		coalesceKind = 0;
		undoStack.resize(0);
		redoStack.resize(0);
		invalidate();
	}


	inline function lineStartIndex(line:Int):Int {
		var offset:Int = field.getLineOffset(line);
		return (offset >= 0) ? offset : 0;
	}

	function lineEndIndex(line:Int):Int {
		return lineStartIndex(line) + lineVisibleLength(line);
	}

	function lineVisibleLength(line:Int):Int {
		var start:Int = lineStartIndex(line);
		var len:Int = field.getLineLength(line);
		if (len > 0 && text.charCodeAt(start + len - 1) == 10)
			len--;
		return len;
	}

	function visualLineOf(index:Int):Int {
		if (text.length == 0)
			return 0;
		if (index > 0 && index <= text.length && text.charCodeAt(index - 1) == 10) {
			var prev:Int = field.getLineIndexOfChar(index - 1);
			return (prev >= 0) ? prev + 1 : 0;
		}
		var line:Int = field.getLineIndexOfChar(index < text.length ? index : text.length);
		if (line < 0)
			line = field.getLineIndexOfChar(text.length > 0 ? text.length - 1 : 0);
		return (line >= 0) ? line : 0;
	}

	function caretXAbs(index:Int):Float {
		if (text.length == 0 || index <= 0)
			return paragraphIndent(index) + 2;
		if (index < text.length) {
			var bounds:Rectangle = field.getCharBoundaries(index);
			if (bounds != null)
				return bounds.x;
		}
		var prev:Rectangle = field.getCharBoundaries(index - 1);
		if (prev != null)
			return prev.x + prev.width;
		return paragraphIndent(index) + 2;
	}

	inline function paragraphIndent(index:Int):Float {
		if (styler == null)
			return 0;
		var line:Int = visualLineOf(index);
		if (line < 0 || line >= contentLines)
			return 0;
		var start:Int = lineStartIndex(line);
		return (start < attrs.length) ? styler.paragraphIndent(attrs[start]) : 0;
	}


	inline function baseSize():Int {
		return UITheme.fs(fontSize);
	}

	function rebuildContent():Void {
		field.embedFonts = UIFonts.fontName != "_sans";
		field.defaultTextFormat = new TextFormat(UIFonts.fontName, baseSize(), UITheme.text & 0xFFFFFF);
		field.wordWrap = wordWrap;
		field.multiline = true;
		field.width = innerW;
		field.height = innerH;
		field.text = text; // reassigning resets format ranges to the default

		var length:Int = text.length;
		if (length > 0 && styler != null) {
			var defaultColor:Int = UITheme.text & 0xFFFFFF;
			var runStart:Int = 0;
			while (runStart < length) {
				var value:Int = attrs[runStart];
				var runEnd:Int = runStart + 1;
				while (runEnd < length && attrs[runEnd] == value)
					runEnd++;
				field.setTextFormat(styler.format(value, baseSize(), defaultColor), runStart, runEnd);
				runStart = runEnd;
			}
		}

		contentLines = field.numLines;
		lineHeights.resize(contentLines);
		lineTops.resize(contentLines + 1);
		lineTops[0] = 0;
		for (i in 0...contentLines) {
			var height:Float = 0;
			try {
				var metrics = field.getLineMetrics(i);
				if (metrics != null)
					height = metrics.height;
			} catch (error:Dynamic) {}
			if (height <= 0)
				height = baseSize() * 1.4;
			lineHeights[i] = height;
			lineTops[i + 1] = lineTops[i] + height;
		}
		totalHeight = lineTops[contentLines];
	}

	inline function visibleY(line:Int):Float {
		return field.y + lineTops[line] - lineTops[topLine - 1];
	}

	override public function render():Void {
		graphics.clear();
		var pad:Float = UITheme.px(padding);
		var radius:Float = UITheme.px(6);

		graphics.beginFill(UIColor.rgb(UITheme.inputBg));
		graphics.drawRoundRect(0, 0, w, h, radius, radius);
		graphics.endFill();

		innerH = h - pad * 2;
		var sbW:Float = UITheme.px(8);

		innerW = w - pad * 2;
		rebuildContent();
		var overflow:Bool = totalHeight > innerH + 1;
		if (overflow) {
			innerW = w - pad * 2 - sbW - UITheme.px(3);
			rebuildContent();
			overflow = totalHeight > innerH + 1;
		}
		field.x = pad;
		field.y = pad;

		visibleLines = Std.int(innerH / averageLineHeight());
		if (visibleLines < 1)
			visibleLines = 1;

		if (pendingCaretShow) {
			scrollCaretIntoView();
			pendingCaretShow = false;
		}
		var maxTop:Int = maxTopLine();
		if (topLine > maxTop)
			topLine = maxTop;
		if (topLine < 1)
			topLine = 1;
		field.scrollV = topLine;
		if (!wordWrap)
			followCaretHorizontally();
		else if (field.scrollH != 0)
			field.scrollH = 0;

		var empty:Bool = text.length == 0;
		placeholderField.visible = empty && placeholder != "";
		if (placeholderField.visible) {
			UIFonts.restyle(placeholderField, baseSize(), UITheme.text3);
			placeholderField.width = innerW;
			placeholderField.height = innerH;
			placeholderField.x = pad;
			placeholderField.y = pad;
			if (placeholderField.text != placeholder)
				placeholderField.text = placeholder;
		}

		if (!empty && hasSelection() && focusedNow)
			drawSelection(graphics);

		if (styler != null) {
			drawListMarkers(graphics);
			drawOutlines(graphics);
		} else {
			hideMarkers(0);
		}

		if (focusedNow && caretVisible && !readOnly)
			drawCaret(graphics);

		if (overflow)
			drawScrollbar(graphics, pad, sbW);
		else
			thumbRect.width = 0;

		graphics.lineStyle(1, UIColor.rgb(focusedNow ? UITheme.accent : UITheme.border));
		graphics.drawRoundRect(0.5, 0.5, w - 1, h - 1, radius, radius);
		graphics.lineStyle();
	}

	function scrollCaretIntoView():Void {
		var line:Int = visualLineOf(caret);
		if (line > contentLines - 1)
			line = contentLines - 1;
		if (line < topLine - 1) {
			topLine = line + 1;
			return;
		}
		while (topLine - 1 < line && (lineTops[line] + lineHeights[line] - lineTops[topLine - 1]) > innerH)
			topLine++;
	}

	function followCaretHorizontally():Void {
		var caretAbs:Float = caretXAbs(caret);
		var view:Float = innerW - 4;
		if (caretAbs - field.scrollH > view)
			field.scrollH = Std.int(caretAbs - view + 8);
		else if (caretAbs - field.scrollH < 0)
			field.scrollH = Std.int(Math.max(0, caretAbs - 8));
	}

	function drawCaret(graphics:openfl.display.Graphics):Void {
		var line:Int = visualLineOf(caret);
		if (line < topLine - 1 || line >= contentLines)
			return;
		var cy:Float = visibleY(line);
		if (cy - field.y > innerH)
			return;
		var cx:Float = field.x + caretXAbs(caret) - field.scrollH;
		graphics.beginFill(UIColor.rgb(UITheme.text));
		graphics.drawRect(cx, cy + 1, 1.5, lineHeights[line] - 3);
		graphics.endFill();
	}

	function drawSelection(graphics:openfl.display.Graphics):Void {
		var start:Int = selMin();
		var end:Int = selMax();
		graphics.beginFill(UIColor.rgb(UITheme.accentDark), 0.45);
		var line:Int = topLine - 1;
		var newlinePad:Float = UITheme.px(6);
		while (line < contentLines) {
			var cy:Float = visibleY(line);
			if (cy - field.y >= innerH)
				break;
			var lineStart:Int = lineStartIndex(line);
			var lineFull:Int = lineStart + field.getLineLength(line);
			var spanStart:Int = (start > lineStart) ? start : lineStart;
			var spanEnd:Int = (end < lineFull) ? end : lineFull;
			if (spanEnd > spanStart || (start <= lineStart && end > lineFull)) {
				var x0:Float = field.x + caretXAbs(spanStart) - field.scrollH;
				var x1:Float;
				var spansNewline:Bool = spanEnd >= lineFull && lineFull > lineStart && text.charCodeAt(lineFull - 1) == 10;
				if (spansNewline)
					x1 = field.x + caretXAbs(lineFull - 1) - field.scrollH + newlinePad;
				else
					x1 = field.x + caretXAbs(spanEnd) - field.scrollH;
				if (x1 > x0)
					graphics.drawRect(x0, cy + 1, x1 - x0, lineHeights[line] - 2);
			}
			line++;
		}
		graphics.endFill();
	}

	/** Draws the styler's list markers in the margin (kept out of the char buffer). **/
	function drawListMarkers(graphics:openfl.display.Graphics):Void {
		var used:Int = 0;
		var pos:Int = 0;
		var length:Int = text.length;
		while (pos <= length) {
			var paragraphStart:Int = pos;
			var end:Int = pos;
			while (end < length && text.charCodeAt(end) != 10)
				end++;
			var marker:String = (paragraphStart < length) ? styler.paragraphMarker(text, attrs, paragraphStart) : null;
			if (marker != null) {
				var line:Int = field.getLineIndexOfChar(paragraphStart);
				if (line >= topLine - 1 && line < contentLines) {
					var cy:Float = visibleY(line);
					if (cy - field.y < innerH && cy - field.y >= -lineHeights[line]) {
						var markerField:TextField = markerAt(used++);
						UIFonts.restyle(markerField, baseSize(), UITheme.text2);
						if (markerField.text != marker)
							markerField.text = marker;
						markerField.visible = true;
						markerField.x = field.x + 2 - field.scrollH;
						markerField.y = cy + 1;
					}
				}
			}
			pos = end + 1;
			if (end >= length)
				break;
		}
		hideMarkers(used);
	}

	function hideMarkers(from:Int):Void {
		for (i in from...markerPool.length)
			markerPool[i].visible = false;
	}

	function markerAt(index:Int):TextField {
		while (markerPool.length <= index) {
			var marker:TextField = UIFonts.make(baseSize(), UITheme.text2);
			addChild(marker);
			markerPool.push(marker);
		}
		return markerPool[index];
	}

	/** Strokes a thin box around outlined runs (per-run glyph outlining is not possible in OpenFL). **/
	function drawOutlines(graphics:openfl.display.Graphics):Void {
		if (text.length == 0)
			return;
		graphics.lineStyle(1, UIColor.rgb(UITheme.border2));
		var i:Int = 0;
		var length:Int = text.length;
		while (i < length) {
			if (text.charCodeAt(i) == 10 || !styler.outlined(attrs[i])) {
				i++;
				continue;
			}
			var runEnd:Int = i;
			while (runEnd < length && text.charCodeAt(runEnd) != 10 && styler.outlined(attrs[runEnd]))
				runEnd++;
			var line:Int = visualLineOf(i);
			var endLine:Int = visualLineOf(runEnd - 1);
			if (line == endLine && line >= topLine - 1 && line < contentLines) {
				var cy:Float = visibleY(line);
				if (cy - field.y < innerH) {
					var x0:Float = field.x + caretXAbs(i) - field.scrollH;
					var x1:Float = field.x + caretXAbs(runEnd) - field.scrollH;
					graphics.drawRect(x0 - 1, cy + 1, (x1 - x0) + 2, lineHeights[line] - 3);
				}
			}
			i = runEnd;
		}
		graphics.lineStyle();
	}

	function drawScrollbar(graphics:openfl.display.Graphics, pad:Float, sbW:Float):Void {
		var trackX:Float = w - pad * 0.5 - sbW;
		var trackH:Float = innerH;
		var frac:Float = (totalHeight > 0) ? innerH / totalHeight : 1;
		if (frac > 1)
			frac = 1;
		var thumbH:Float = trackH * frac;
		var minThumb:Float = UITheme.px(24);
		if (thumbH < minThumb)
			thumbH = minThumb;
		var scrolled:Float = lineTops[topLine - 1];
		var span:Float = totalHeight - innerH;
		var fraction:Float = (span > 0) ? scrolled / span : 0;
		if (fraction > 1)
			fraction = 1;
		var thumbY:Float = pad + fraction * (trackH - thumbH);
		var rr:Float = sbW * 0.5;

		graphics.beginFill(UIColor.rgb(UITheme.panel2), 0.6);
		graphics.drawRoundRect(trackX, pad, sbW, trackH, rr, rr);
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(mode == MODE_THUMB ? UITheme.border2 : UITheme.border));
		graphics.drawRoundRect(trackX, thumbY, sbW, thumbH, rr, rr);
		graphics.endFill();
		thumbRect.setTo(trackX, thumbY, sbW, thumbH);
	}


	function set_text(value:String):String {
		if (value == null)
			value = "";
		if (text == value)
			return value;
		text = value;
		if (attrs.length > value.length)
			attrs.resize(value.length);
		else
			while (attrs.length < value.length)
				attrs.push(0);
		if (caret > value.length)
			caret = value.length;
		if (anchor > value.length)
			anchor = value.length;
		desiredCol = -1;
		invalidate();
		return value;
	}

	function set_placeholder(value:String):String {
		placeholder = value;
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}

	function set_wordWrap(value:Bool):Bool {
		wordWrap = value;
		invalidate();
		return value;
	}

	override public function dispose():Void {
		removeEventListener(MouseEvent.MOUSE_WHEEL, __onWheel);
		UIFocus.clear(this);
		UIRoot.removeTicker(tick);
		super.dispose();
	}
}

/** A captured editor state for the undo/redo history (text + parallel styles + selection). **/
private typedef UITextAreaState = {
	var text:String;
	var attrs:Array<Int>;
	var caret:Int;
	var anchor:Int;
};
