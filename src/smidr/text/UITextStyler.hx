package smidr.text;

import openfl.text.TextFormat;

/**
	The rendering-policy contract a `smidr.widgets.UITextArea` delegates to. The editor stores an
	opaque `Int` style word per character and knows nothing about what the bits mean; an installed
	styler turns those words into concrete formatting (per-run `TextFormat`, paragraph indent, list
	markers, an outline flag) and decides how style flows across a line break.

	Install one with `textArea.styler = new UIRichStyler()` for WYSIWYG formatting, or leave it
	`null` for a plain uniform-format multi-line field. The bit vocabulary the built-in
	`UIRichStyler` uses is `UITextStyle`, but a custom styler may encode the `Int` however it likes.
**/
interface UITextStyler {
	/**
		The `TextFormat` for a run of characters that all share the style word `attr`.
		@param attr the shared style word
		@param baseSize the editor's base (already theme-scaled) font size
		@param defaultColor the fallback text colour (RGB) when the style has no explicit colour
	**/
	function format(attr:Int, baseSize:Int, defaultColor:Int):TextFormat;

	/** The left indent (in px) a paragraph with style word `attr` reserves (e.g. for list markers). **/
	function paragraphIndent(attr:Int):Float;

	/**
		The marker text drawn in the margin for the paragraph starting at `paragraphStart` (a bullet
		or an ordinal like `"3."`), or `null` for a non-list paragraph. Receives the full buffers so
		a numbered list can count its position.
	**/
	function paragraphMarker(text:String, attrs:Array<Int>, paragraphStart:Int):Null<String>;

	/** Whether a run with this style word should be visually boxed/outlined by the editor. **/
	function outlined(attr:Int):Bool;

	/**
		The style word new characters take on the line after a break, given the previous line's word
		(e.g. headings drop to normal, lists continue). The editor calls this so paragraph flow stays
		the styler's policy, not the editor's.
	**/
	function styleForNewLine(previousWord:Int):Int;
}
