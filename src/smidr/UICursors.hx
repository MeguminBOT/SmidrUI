package smidr;

import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import smidr.types.UICursor;

/**
	Global mouse-cursor override, independent of the per-widget hover cursor
	(`UIComponent.hoverCursor`). Use it to force a shape regardless of what the pointer is over —
	e.g. a wait cursor across a blocking load.

	Custom bitmap cursors are not offered: OpenFL 9.5.2 compiles out `Mouse.registerCursor`, so
	only the built-in `UICursor` shapes are available. Desktop only in practice
	(`supportsCursor` is `false` on mobile).
**/
final class UICursors {
	/**
		Forces the global cursor shape until `reset`.
		@param cursor the shape (a `UICursor` or any OpenFL `MouseCursor`)
	**/
	public static inline function set(cursor:MouseCursor):Void {
		Mouse.cursor = cursor;
	}

	/** Restores automatic cursor selection (the object under the pointer decides). **/
	public static inline function reset():Void {
		Mouse.cursor = MouseCursor.AUTO;
	}

	/**
		Convenience busy toggle: the wait cursor while `on`, automatic otherwise.
		@param on `true` shows the wait cursor
	**/
	public static function busy(on:Bool):Void {
		Mouse.cursor = on ? UICursor.WAIT.toMouseCursor() : MouseCursor.AUTO;
	}

	/** Hides the pointer entirely (pair with `show`). **/
	public static inline function hide():Void {
		Mouse.hide();
	}

	/** Shows the pointer after `hide`. **/
	public static inline function show():Void {
		Mouse.show();
	}

	/** Whether the platform shows a persistent cursor (`false` on most mobile devices). **/
	public static var supportsCursor(get, never):Bool;

	static inline function get_supportsCursor():Bool {
		return Mouse.supportsCursor;
	}
}
