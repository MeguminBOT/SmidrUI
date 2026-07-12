package smidr.text;

import openfl.text.TextFormat;
import smidr.UIFonts;
import smidr.UITheme;

/**
	The built-in WYSIWYG styling module for `smidr.widgets.UITextArea`. Install an instance as the
	editor's `styler` and it renders the `UITextStyle` bit vocabulary as real formatting: bold /
	italic / underline / outline runs, a colour palette, inline size tiers, heading sizes, and
	bullet / numbered list markers with indentation. The static helpers (`toggleInline`, `setBlock`,
	`setColor`, `setSize`, `inlineAt`, `blockAt`) drive a `UIStyledText` from a toolbar, so the
	editor itself stays free of any WYSIWYG knowledge.
**/
class UIRichStyler implements UITextStyler {
	/**
		Inline colour palette. Index 0 is the "default" sentinel (resolves to the theme/editor text
		colour); 1+ are fixed ARGB colours a colour control cycles through.
	**/
	public static var PALETTE:Array<Int> = [
		0x00000000, // 0 = default (editor text colour)
		0xFFF05C7C, // red
		0xFFFFCA6E, // amber
		0xFF63D68A, // green
		0xFF5A8CFF, // blue
		0xFFC558D6, // purple
		0xFFE9E7EF, // near-white
		0xFF7F7D8A // grey
	];

	public function new() {}

	public function format(attr:Int, baseSize:Int, defaultColor:Int):TextFormat {
		var blockType:Int = UITextStyle.block(attr);
		var bold:Bool = UITextStyle.isHeading(blockType) || UITextStyle.has(attr, UITextStyle.BOLD);
		var italic:Bool = UITextStyle.has(attr, UITextStyle.ITALIC);
		var underline:Bool = UITextStyle.has(attr, UITextStyle.UNDERLINE);
		var fmt:TextFormat = new TextFormat(UIFonts.fontName, sizeFor(attr, baseSize), colorFor(attr, defaultColor), bold, italic, underline);
		fmt.leftMargin = UITextStyle.isList(blockType) ? Std.int(UITheme.px(20)) : 0;
		return fmt;
	}

	public function paragraphIndent(attr:Int):Float {
		return UITextStyle.isList(UITextStyle.block(attr)) ? UITheme.px(20) : 0;
	}

	public function paragraphMarker(text:String, attrs:Array<Int>, paragraphStart:Int):Null<String> {
		if (paragraphStart >= attrs.length)
			return null;
		var blockType:Int = UITextStyle.block(attrs[paragraphStart]);
		if (blockType == UITextStyle.BLOCK_BULLET)
			return "•";
		if (blockType != UITextStyle.BLOCK_NUMBER)
			return null;
		// count consecutive numbered paragraphs up to and including this one
		var ordinal:Int = 1;
		var scan:Int = paragraphStart - 2; // char before the newline that precedes this paragraph
		while (scan >= 0) {
			// walk back to the start of the previous paragraph
			while (scan >= 0 && text.charCodeAt(scan) != 10)
				scan--;
			var prevStart:Int = scan + 1;
			if (prevStart >= 0 && prevStart < attrs.length && UITextStyle.block(attrs[prevStart]) == UITextStyle.BLOCK_NUMBER) {
				ordinal++;
				scan = prevStart - 2;
			} else {
				break;
			}
		}
		return ordinal + ".";
	}

	public function outlined(attr:Int):Bool {
		return UITextStyle.has(attr, UITextStyle.OUTLINE);
	}

	public function styleForNewLine(previousWord:Int):Int {
		var blockType:Int = UITextStyle.block(previousWord);
		// lists continue onto the next line; headings drop back to a normal paragraph
		return UITextStyle.withBlock(previousWord, UITextStyle.isList(blockType) ? blockType : UITextStyle.BLOCK_NORMAL);
	}

	function sizeFor(attr:Int, baseSize:Int):Int {
		var explicit:Int = UITextStyle.fontSize(attr);
		if (explicit > 0)
			return Std.int(UITheme.px(explicit) + 0.5); // an explicit point size overrides everything
		var scale:Float = switch (UITextStyle.block(attr)) {
			case UITextStyle.BLOCK_H1: 1.9;
			case UITextStyle.BLOCK_H2: 1.5;
			case UITextStyle.BLOCK_H3: 1.22;
			default: 1.0;
		}
		var size:Int = Std.int(baseSize * scale + 0.5);
		return (size < 1) ? 1 : size;
	}

	function colorFor(attr:Int, defaultColor:Int):Int {
		var index:Int = UITextStyle.colorIndex(attr);
		if (index <= 0 || index >= PALETTE.length)
			return defaultColor & 0xFFFFFF;
		return PALETTE[index] & 0xFFFFFF;
	}

	/** Toggles an inline flag (`UITextStyle.BOLD` etc.) over the selection, or for new input. **/
	public static function toggleInline(target:UIStyledText, flag:Int):Void {
		var on:Bool;
		if (target.hasStyledSelection()) {
			on = false;
			for (i in target.selectionStart...target.selectionEnd)
				if (!UITextStyle.has(target.styleAt(i), flag)) {
					on = true;
					break;
				}
		} else {
			on = !UITextStyle.has(target.typingStyle, flag);
		}
		target.styleSelection((attr) -> UITextStyle.withFlag(attr, flag, on));
	}

	/** Sets the inline colour palette index over the selection, or for new input. **/
	public static function setColor(target:UIStyledText, index:Int):Void {
		target.styleSelection((attr) -> UITextStyle.withColor(attr, index));
	}

	/** Sets an explicit font size (points; 0 = inherit) over the selection, or for new input. **/
	public static function setFontSize(target:UIStyledText, points:Int):Void {
		target.styleSelection((attr) -> UITextStyle.withFontSize(attr, points));
	}

	/** Clears character formatting (flags, size, colour) on the selection, keeping the paragraph style. **/
	public static function clearFormatting(target:UIStyledText):Void {
		target.styleSelection((attr) -> UITextStyle.blockOnly(attr));
	}

	/** Sets the block type (`UITextStyle.BLOCK_*`) on every paragraph the selection touches. **/
	public static function setBlock(target:UIStyledText, blockType:Int):Void {
		target.styleParagraphs((attr) -> UITextStyle.withBlock(attr, blockType));
	}

	/** The explicit font size at the caret in points, or 0 when it inherits the base size. **/
	public static function fontSizeAt(target:UIStyledText):Int {
		if (target.hasStyledSelection() && target.selectionStart < target.styledText.length)
			return UITextStyle.fontSize(target.styleAt(target.selectionStart));
		return UITextStyle.fontSize(target.typingStyle);
	}

	/** The inline flags currently in effect at the caret (for reflecting toolbar toggle state). **/
	public static function inlineAt(target:UIStyledText):Int {
		if (target.hasStyledSelection() && target.selectionStart < target.styledText.length)
			return UITextStyle.inlineFlags(target.styleAt(target.selectionStart));
		return UITextStyle.inlineFlags(target.typingStyle);
	}

	/** The block type of the caret's paragraph (for reflecting the heading/list buttons). **/
	public static function blockAt(target:UIStyledText):Int {
		var text:String = target.styledText;
		var start:Int = target.caretIndex;
		while (start > 0 && text.charCodeAt(start - 1) != 10)
			start--;
		if (start < text.length && text.charCodeAt(start) != 10)
			return UITextStyle.block(target.styleAt(start));
		return UITextStyle.block(target.typingStyle);
	}
}
