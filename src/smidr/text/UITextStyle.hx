package smidr.text;

/**
	The rich-text style vocabulary used by the WYSIWYG module (`UIRichStyler`) and the Markdown
	module (`UIMarkdown`). It packs a whole character style into a single `Int`: inline run flags
	(bold / italic / underline / outline), a colour-palette index, an inline size tier, and the
	paragraph block type (normal / H1-H3 / bullet / numbered).

	`smidr.widgets.UITextArea` itself never interprets these bits — it treats each character's style
	as an opaque `Int` and defers all meaning to the installed `UITextStyler`. This type is that
	styler's private encoding, kept here so the app and both modules share one vocabulary.

	Layout (low bits first):
	- bits 0..3   inline flags: `BOLD` | `ITALIC` | `UNDERLINE` | `OUTLINE`
	- bits 4..10  explicit font size in points (0 = inherit the editor's base size)
	- bits 11..15 colour palette index (0 = default/theme text)
	- bits 16..18 block type (`BLOCK_*`, 0 = normal paragraph)
**/
class UITextStyle {
	/** Bold inline flag. **/
	public static inline var BOLD:Int = 1;

	/** Italic inline flag. **/
	public static inline var ITALIC:Int = 2;

	/** Underline inline flag. **/
	public static inline var UNDERLINE:Int = 4;

	/** Outline (boxed emphasis) inline flag. **/
	public static inline var OUTLINE:Int = 8;

	/** All inline flag bits. **/
	public static inline var INLINE_MASK:Int = 15;

	static inline var SIZE_SHIFT:Int = 4;
	static inline var SIZE_MASK:Int = 127 << 4; // bits 4..10 (explicit point size, 0 = default)

	static inline var COLOR_SHIFT:Int = 11;
	static inline var COLOR_MASK:Int = 31 << 11; // bits 11..15

	static inline var BLOCK_SHIFT:Int = 16;
	static inline var BLOCK_MASK:Int = 7 << 16; // bits 16..18

	/** Everything except the block type (the part carried across new input). **/
	public static inline var INLINE_SIZE_COLOR_MASK:Int = INLINE_MASK | (127 << 4) | (31 << 11);

	/** Normal paragraph. **/
	public static inline var BLOCK_NORMAL:Int = 0;

	/** Heading level 1. **/
	public static inline var BLOCK_H1:Int = 1;

	/** Heading level 2. **/
	public static inline var BLOCK_H2:Int = 2;

	/** Heading level 3. **/
	public static inline var BLOCK_H3:Int = 3;

	/** Bulleted list item. **/
	public static inline var BLOCK_BULLET:Int = 4;

	/** Numbered list item. **/
	public static inline var BLOCK_NUMBER:Int = 5;

	/** The inline flag bits of a style word. **/
	public static inline function inlineFlags(attr:Int):Int {
		return attr & INLINE_MASK;
	}

	/** `true` when `flag` (e.g. `BOLD`) is set. **/
	public static inline function has(attr:Int, flag:Int):Bool {
		return (attr & flag) != 0;
	}

	/** Sets/clears an inline flag. **/
	public static inline function withFlag(attr:Int, flag:Int, on:Bool):Int {
		return on ? (attr | flag) : (attr & ~flag);
	}

	/** The explicit font size in points (0 = inherit the base size). **/
	public static inline function fontSize(attr:Int):Int {
		return (attr & SIZE_MASK) >> SIZE_SHIFT;
	}

	/** Replaces the explicit font size (points; 0 = inherit, clamped to 0..127). **/
	public static inline function withFontSize(attr:Int, points:Int):Int {
		if (points < 0)
			points = 0;
		if (points > 127)
			points = 127;
		return (attr & ~SIZE_MASK) | ((points << SIZE_SHIFT) & SIZE_MASK);
	}

	/** Only the block-type bits (used to clear character formatting while keeping the paragraph style). **/
	public static inline function blockOnly(attr:Int):Int {
		return attr & BLOCK_MASK;
	}

	/** The colour palette index (0 = default). **/
	public static inline function colorIndex(attr:Int):Int {
		return (attr & COLOR_MASK) >> COLOR_SHIFT;
	}

	/** Replaces the colour palette index. **/
	public static inline function withColor(attr:Int, index:Int):Int {
		return (attr & ~COLOR_MASK) | ((index << COLOR_SHIFT) & COLOR_MASK);
	}

	/** The paragraph block type (`BLOCK_*`). **/
	public static inline function block(attr:Int):Int {
		return (attr & BLOCK_MASK) >> BLOCK_SHIFT;
	}

	/** Replaces the paragraph block type. **/
	public static inline function withBlock(attr:Int, blockType:Int):Int {
		return (attr & ~BLOCK_MASK) | ((blockType << BLOCK_SHIFT) & BLOCK_MASK);
	}

	/** `true` for the heading block types (H1/H2/H3). **/
	public static inline function isHeading(blockType:Int):Bool {
		return blockType == BLOCK_H1 || blockType == BLOCK_H2 || blockType == BLOCK_H3;
	}

	/** `true` for the list block types (bullet/numbered). **/
	public static inline function isList(blockType:Int):Bool {
		return blockType == BLOCK_BULLET || blockType == BLOCK_NUMBER;
	}
}
