package smidr.widgets;

import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.input.IUIFocusable;
import smidr.input.UIFocus;

/**
	A key-binding row: label left, binding box right showing the current key. Clicking the box
	enters listening mode (`UIFocus.typing` gates the host's keybinds automatically); the next
	key pressed becomes the binding and fires `onChange(keyCode)`. Escape cancels; with
	`allowClear` on, Backspace/Delete clears the binding (fires `onChange(-1)`) — disable
	`allowClear` to make those keys bindable. Works on mobile only with a hardware keyboard
	attached; desktop-oriented.
**/
final class UIKeybind extends UIComponent implements IUIFocusable {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	/** The bound key code, or -1 when unbound. **/
	public var keyCode(default, null):Int = -1;

	/** Fired with the new key code (-1 = cleared). **/
	public var onChange:Int->Void = null;

	/** Optional code filter; return `false` to reject a key while listening. **/
	public var filter:(keyCode:Int) -> Bool = null;

	/** Backspace/Delete clear the binding while listening (turn off to bind them). **/
	public var allowClear:Bool = true;

	public var fontSize(default, set):Int = 12;

	/** Width of the binding box on the right. **/
	public var controlWidth:Float;

	final labelField:TextField;
	final valueField:TextField;

	var listening:Bool = false;

	/**
		@param label the row text on the left
		@param width layout width (the binding box sits at the right edge)
		@param keyCode the initial binding (-1 = unbound)
		@param onChange fired with the new key code on rebind/clear
	**/
	public function new(label:String, width:Float, keyCode:Int = -1, ?onChange:Int->Void) {
		super(true, true);
		this.label = label;
		this.keyCode = keyCode;
		this.onChange = onChange;
		controlWidth = UITheme.px(110);
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
		valueField = UIFonts.make(UITheme.fs(fontSize), UITheme.text, TextFormatAlign.CENTER);
		valueField.autoSize = openfl.text.TextFieldAutoSize.NONE;
		addChild(valueField);
		resize(width, UITheme.px(#if mobile 30 #else 24 #end));
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

	/**
		Programmatically sets the binding without firing `onChange`.
		@param code the key code (-1 = unbound)
	**/
	public function setBinding(code:Int):Void {
		if (code == keyCode)
			return;
		keyCode = code;
		invalidate();
	}

	override function onPress(localX:Float, localY:Float):Void {
		if (localX < w - controlWidth)
			return;
		if (listening)
			UIFocus.clear(this);
		else
			UIFocus.set(this);
	}

	public function capturesKeyboard():Bool {
		return listening;
	}

	public function onFocusGained():Void {
		listening = true;
		invalidate();
	}

	public function onFocusLost():Void {
		listening = false;
		invalidate();
	}

	public function onKeyDown(keyCode:Int, charCode:Int, ctrl:Bool, shift:Bool, alt:Bool):Bool {
		if (!listening)
			return false;
		if (keyCode == 27) {
			UIFocus.clear(this);
			return true;
		}
		if (allowClear && (keyCode == 8 || keyCode == 46)) {
			this.keyCode = -1;
			UIFocus.clear(this);
			if (onChange != null)
				onChange(-1);
			return true;
		}
		if (filter != null && !filter(keyCode))
			return true;
		this.keyCode = keyCode;
		UIFocus.clear(this);
		if (onChange != null)
			onChange(keyCode);
		return true;
	}

	/**
		A short display name for a key code (letters, digits, numpad, F-keys, navigation and
		common punctuation; unknown codes render as `#<code>`).
		@param code the platform key code
		@return the display name
	**/
	public static function keyName(code:Int):String {
		if ((code >= 65 && code <= 90) || (code >= 48 && code <= 57))
			return String.fromCharCode(code);
		if (code >= 96 && code <= 105)
			return "NUM " + (code - 96);
		if (code >= 112 && code <= 123)
			return "F" + (code - 111);
		return switch (code) {
			case 8: "BACKSPACE";
			case 9: "TAB";
			case 13: "ENTER";
			case 16: "SHIFT";
			case 17: "CTRL";
			case 18: "ALT";
			case 20: "CAPS";
			case 32: "SPACE";
			case 33: "PG UP";
			case 34: "PG DN";
			case 35: "END";
			case 36: "HOME";
			case 37: "LEFT";
			case 38: "UP";
			case 39: "RIGHT";
			case 40: "DOWN";
			case 45: "INSERT";
			case 46: "DELETE";
			case 186: ";";
			case 187: "=";
			case 188: ",";
			case 189: "-";
			case 190: ".";
			case 191: "/";
			case 192: "`";
			case 219: "[";
			case 220: "\\";
			case 221: "]";
			case 222: "'";
			default: "#" + code;
		}
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var bx:Float = w - controlWidth;
		var radius:Float = UITheme.px(6);
		var fill:Int = listening ? UITheme.inputBg : UITheme.panel2;
		if (hovered && !listening)
			fill = UIColor.lighten(fill, 0.08);
		graphics.beginFill(UIColor.rgb(fill));
		graphics.drawRoundRect(bx, 1, controlWidth, h - 2, radius, radius);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(listening ? UITheme.accent : UITheme.border));
		graphics.drawRoundRect(bx + 0.5, 1.5, controlWidth - 1, h - 3, radius, radius);
		graphics.lineStyle();

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;

		UIFonts.restyle(valueField, UITheme.fs(fontSize), listening ? UITheme.highlight : UITheme.text, TextFormatAlign.CENTER);
		var text:String = listening ? UILocale.t("smidr.keybind.press", "Press a key") : (keyCode < 0 ? "-" : keyName(keyCode));
		if (valueField.text != text)
			valueField.text = text;
		valueField.width = controlWidth - UITheme.px(12);
		valueField.height = valueField.textHeight + 4;
		valueField.x = bx + UITheme.px(6);
		valueField.y = (h - valueField.height) / 2;
	}

	override public function dispose():Void {
		UIFocus.clear(this);
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

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
