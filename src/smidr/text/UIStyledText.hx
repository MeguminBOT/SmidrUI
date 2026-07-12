package smidr.text;

/**
	The generic style-editing surface a `smidr.widgets.UITextArea` exposes to styling modules. It
	lets a module (e.g. `UIRichStyler`) read and transform the editor's opaque per-character style
	words without the module depending on the concrete widget — the editor stays policy-free and the
	modules stay widget-free, so the dependency only ever points widgets -> text.
**/
interface UIStyledText {
	/** Style word applied to newly typed characters. **/
	var typingStyle(get, set):Int;

	/** Current caret position (char index). **/
	var caretIndex(get, never):Int;

	/** Selection start (min of caret/anchor). **/
	var selectionStart(get, never):Int;

	/** Selection end (max of caret/anchor). **/
	var selectionEnd(get, never):Int;

	/** The full text buffer. **/
	var styledText(get, never):String;

	/** `true` while a (non-empty) selection exists. **/
	function hasStyledSelection():Bool;

	/** The style word at a character index (clamped). **/
	function styleAt(index:Int):Int;

	/** Transforms the style of every selected character (or `typingStyle` when nothing is selected). **/
	function styleSelection(map:Int->Int):Void;

	/** Transforms the style of every character in the paragraphs the selection touches. **/
	function styleParagraphs(map:Int->Int):Void;
}
