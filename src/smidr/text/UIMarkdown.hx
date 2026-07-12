package smidr.text;

/** A styled document: plain `text` and its parallel `UITextStyle` style words (see `UIMarkdown.parse`). **/
typedef UIRichDoc = {
	var text:String;
	var styles:Array<Int>;
};

/**
	The Markdown module for `smidr.widgets.UITextArea`: converts between the `UITextStyle` style
	model and Markdown, for import/export. `toMarkdown` flattens headings, bullet/numbered lists and
	bold/italic/underline runs; `parse` reads them back. It is a pair of pure functions over
	`(text, styles)` so it stays independent of the editor widget.
**/
class UIMarkdown {
	/** Flattens styled content (`text` + its `styles` words) to Markdown. **/
	public static function toMarkdown(text:String, styles:Array<Int>):String {
		var out:StringBuf = new StringBuf();
		var pos:Int = 0;
		var length:Int = text.length;
		var number:Int = 0;
		var firstParagraph:Bool = true;
		while (pos <= length) {
			var start:Int = pos;
			var end:Int = pos;
			while (end < length && text.charCodeAt(end) != 10)
				end++;
			if (!firstParagraph)
				out.add("\n");
			firstParagraph = false;
			var blockType:Int = (start < styles.length) ? UITextStyle.block(styles[start]) : UITextStyle.BLOCK_NORMAL;
			switch (blockType) {
				case UITextStyle.BLOCK_H1:
					out.add("# ");
				case UITextStyle.BLOCK_H2:
					out.add("## ");
				case UITextStyle.BLOCK_H3:
					out.add("### ");
				case UITextStyle.BLOCK_BULLET:
					out.add("- ");
				case UITextStyle.BLOCK_NUMBER:
					number++;
					out.add(number + ". ");
				default:
			}
			if (blockType != UITextStyle.BLOCK_NUMBER)
				number = 0;
			out.add(inlineToMarkdown(text, styles, start, end));
			pos = end + 1;
			if (end >= length)
				break;
		}
		return out.toString();
	}

	static function inlineToMarkdown(text:String, styles:Array<Int>, from:Int, to:Int):String {
		var out:StringBuf = new StringBuf();
		var i:Int = from;
		while (i < to) {
			var flags:Int = (i < styles.length) ? UITextStyle.inlineFlags(styles[i]) : 0;
			var runEnd:Int = i;
			while (runEnd < to && runEnd < styles.length && UITextStyle.inlineFlags(styles[runEnd]) == flags)
				runEnd++;
			var open:String = "";
			var close:String = "";
			if (UITextStyle.has(flags, UITextStyle.BOLD)) {
				open += "**";
				close = "**" + close;
			}
			if (UITextStyle.has(flags, UITextStyle.ITALIC)) {
				open += "*";
				close = "*" + close;
			}
			if (UITextStyle.has(flags, UITextStyle.UNDERLINE)) {
				open += "<u>";
				close = "</u>" + close;
			}
			out.add(open);
			out.add(text.substring(i, runEnd));
			out.add(close);
			i = runEnd;
		}
		return out.toString();
	}

	/** Parses Markdown (headings, lists, bold/italic/underline) into a styled document. **/
	public static function parse(md:String):UIRichDoc {
		if (md == null)
			md = "";
		var body:StringBuf = new StringBuf();
		var styles:Array<Int> = [];
		var lines:Array<String> = md.split("\n");
		for (li in 0...lines.length) {
			if (li > 0) {
				body.add("\n");
				styles.push(0);
			}
			var line:String = lines[li];
			var blockType:Int = UITextStyle.BLOCK_NORMAL;
			if (StringTools.startsWith(line, "### ")) {
				blockType = UITextStyle.BLOCK_H3;
				line = line.substr(4);
			} else if (StringTools.startsWith(line, "## ")) {
				blockType = UITextStyle.BLOCK_H2;
				line = line.substr(3);
			} else if (StringTools.startsWith(line, "# ")) {
				blockType = UITextStyle.BLOCK_H1;
				line = line.substr(2);
			} else if (StringTools.startsWith(line, "- ")) {
				blockType = UITextStyle.BLOCK_BULLET;
				line = line.substr(2);
			} else {
				var numbered = ~/^([0-9]+)\. /;
				if (numbered.match(line)) {
					blockType = UITextStyle.BLOCK_NUMBER;
					line = numbered.matchedRight();
				}
			}
			parseInline(line, blockType, body, styles);
		}
		var text:String = body.toString();
		if (styles.length != text.length) // guard against any desync
			styles = [for (i in 0...text.length) 0];
		return {text: text, styles: styles};
	}

	static function parseInline(line:String, blockType:Int, body:StringBuf, styles:Array<Int>):Void {
		var flags:Int = 0;
		var i:Int = 0;
		var length:Int = line.length;
		while (i < length) {
			if (i + 1 < length && line.charCodeAt(i) == 42 && line.charCodeAt(i + 1) == 42) { // **
				flags = UITextStyle.withFlag(flags, UITextStyle.BOLD, !UITextStyle.has(flags, UITextStyle.BOLD));
				i += 2;
				continue;
			}
			if (line.charCodeAt(i) == 42) { // *
				flags = UITextStyle.withFlag(flags, UITextStyle.ITALIC, !UITextStyle.has(flags, UITextStyle.ITALIC));
				i++;
				continue;
			}
			if (line.substr(i, 3) == "<u>") {
				flags = UITextStyle.withFlag(flags, UITextStyle.UNDERLINE, true);
				i += 3;
				continue;
			}
			if (line.substr(i, 4) == "</u>") {
				flags = UITextStyle.withFlag(flags, UITextStyle.UNDERLINE, false);
				i += 4;
				continue;
			}
			body.addChar(line.charCodeAt(i));
			styles.push(UITextStyle.withBlock(flags, blockType));
			i++;
		}
	}
}
