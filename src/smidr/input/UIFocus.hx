package smidr.input;

/**
	Keyboard focus manager. Exactly one `IUIFocusable` holds focus; `typing` is the single flag
	host applications check before processing their own keybinds.

	On mobile, focusing a typing component raises the platform IME (soft keyboard): committed
	text is routed into the existing `onKeyDown(0, charCode, ...)` path one character at a time,
	and Backspace/Enter/Escape are bridged from lime's window (the stage keyboard chain is
	unreliable on some Android builds) — the stage path suppresses those keys while the IME is
	up so no component ever sees them twice.
**/
final class UIFocus {
	/** The focused component, or `null`. **/
	public static var focused(default, null):IUIFocusable = null;

	/** `true` while the focused component captures raw typing. **/
	public static var typing(get, never):Bool;

	static inline function get_typing():Bool {
		return focused != null && focused.capturesKeyboard();
	}

	/**
		Moves focus (notifies the old and new holders).
		@param target the new focus holder, or `null` to blur
	**/
	public static function set(target:IUIFocusable):Void {
		if (focused == target)
			return;
		var old:IUIFocusable = focused;
		focused = target;
		if (old != null)
			old.onFocusLost();
		if (target != null)
			target.onFocusGained();
		#if mobile
		syncIme();
		#end
	}

	/**
		Clears focus.
		@param ifTarget when set, only clears if that component currently holds focus
	**/
	public static function clear(?ifTarget:IUIFocusable):Void {
		if (ifTarget != null && focused != ifTarget)
			return;
		set(null);
	}

	/**
		Routes a key event to the focused component.
		@param keyCode the platform key code
		@param charCode the printable character code (0 when none)
		@param ctrl `true` while a Control key is held
		@param shift `true` while a Shift key is held
		@param alt `true` while an Alt key is held
		@return `true` when the focused component consumed the key
	**/
	public static function keyDown(keyCode:Int, charCode:Int, ctrl:Bool, shift:Bool, alt:Bool):Bool {
		#if mobile
		// the lime-level IME bridge owns these while the soft keyboard is up
		if (imeActive && (keyCode == 8 || keyCode == 13 || keyCode == 27))
			return typing;
		#end
		return (focused != null) && focused.onKeyDown(keyCode, charCode, ctrl, shift, alt);
	}

	#if mobile
	static var imeActive:Bool = false;

	static function syncIme():Void {
		var app = lime.app.Application.current;
		var window = (app != null) ? app.window : null;
		if (window == null)
			return;
		var want:Bool = typing;
		if (want == imeActive)
			return;
		imeActive = want;
		if (want) {
			window.onTextInput.add(__onImeText);
			window.onKeyDown.add(__onImeKey);
			window.textInputEnabled = true;
		} else {
			window.onTextInput.remove(__onImeText);
			window.onKeyDown.remove(__onImeKey);
			window.textInputEnabled = false;
		}
	}

	static function __onImeText(text:String):Void {
		if (focused == null)
			return;
		for (code in new haxe.iterators.StringIteratorUnicode(text))
			focused.onKeyDown(0, code, false, false, false);
	}

	static function __onImeKey(code:lime.ui.KeyCode, _:lime.ui.KeyModifier):Void {
		if (focused == null)
			return;
		var key:Int = switch (code) {
			case BACKSPACE: 8;
			case RETURN | NUMPAD_ENTER: 13;
			case ESCAPE: 27;
			default: 0;
		}
		if (key != 0) {
			focused.onKeyDown(key, 0, false, false, false);
			syncIme(); // Enter/Escape blur; drop the IME the moment typing ends
		}
	}
	#end
}
