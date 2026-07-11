package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextFormatAlign;
import smidr.UIRoot;
import smidr.UITheme;
import smidr.widgets.UIButton;
import smidr.widgets.UILabel;
import smidr.widgets.UIPanel;

/**
	A small four-function calculator built with SmiðrUI. It shows the common shape of a real app:
	one `UIRoot`, a themed backdrop and display panel, and a grid of `UIButton`s wired to a tiny
	state machine. Nothing here is calculator-specific in the library; it is all plain widgets.

	It also takes physical-keyboard input via a stage listener: digits, `. `/`,`, the four
	operators, `=`/Enter, `%`, Backspace, and Escape/Delete to clear.

	Build it from the repo root:
	```bash
	lime test examples/project.xml windows -Dex_calc
	```
**/
class Calculator extends Sprite {
	static inline var PAD:Float = 16;
	static inline var GAP:Float = 10;
	static inline var WIN_W:Float = 320;
	static inline var DISP_H:Float = 96;
	static inline var BTN_H:Float = 56;

	var ui:UIRoot;
	var display:UILabel;
	var expressionLabel:UILabel;

	// calculator state
	var shown:String = "0";
	var expression:String = "";
	var stored:Float = 0;
	var pendingOp:String = null;
	var freshEntry:Bool = true;

	public function new() {
		super();

		UITheme.apply(UITheme.PRESETS[0].palette); // Dark

		ui = new UIRoot();
		ui.attach(this);

		var contentW:Float = WIN_W - PAD * 2;
		var colW:Float = (contentW - GAP * 3) / 4;

		// full-window themed backdrop
		var backdrop = new UIPanel(WIN_W, PAD * 2 + DISP_H + GAP + 5 * BTN_H + 4 * GAP + PAD, BG, false);
		ui.content.addChild(backdrop);

		// display panel + right-aligned value
		var displayPanel = new UIPanel(contentW, DISP_H, PANEL2);
		displayPanel.x = PAD;
		displayPanel.y = PAD;
		displayPanel.corner = 12;
		displayPanel.outline = true;
		ui.content.addChild(displayPanel);

		// small running-expression line above the big value (e.g. "50 + 30 =")
		expressionLabel = new UILabel("", 14, TERTIARY, TextFormatAlign.RIGHT);
		expressionLabel.wrapWidth = contentW - 28;
		expressionLabel.x = PAD + 14;
		ui.content.addChild(expressionLabel);

		display = new UILabel("0", 36, PRIMARY, TextFormatAlign.RIGHT);
		display.wrapWidth = contentW - 28;
		display.x = PAD + 14;
		ui.content.addChild(display);
		positionDisplay();

		var gridTop:Float = PAD + DISP_H + GAP + 6;

		// row 0: clear / sign / percent / divide
		button("C", 0, 0, 1, colW, gridTop, 2, clearAll);
		button("+/-", 1, 0, 1, colW, gridTop, 0, negate);
		button("%", 2, 0, 1, colW, gridTop, 0, percent);
		button("/", 3, 0, 1, colW, gridTop, 1, () -> inputOp("/"));

		// rows 1..3: digits + operators
		var digitRows:Array<Array<String>> = [["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"]];
		var ops:Array<String> = ["*", "-", "+"];
		for (r in 0...3) {
			for (c in 0...3) {
				var d:String = digitRows[r][c];
				button(d, c, r + 1, 1, colW, gridTop, 0, () -> inputDigit(d));
			}
			var op:String = ops[r];
			button(op, 3, r + 1, 1, colW, gridTop, 1, () -> inputOp(op));
		}

		// row 4: wide zero / decimal / equals
		button("0", 0, 4, 2, colW, gridTop, 0, () -> inputDigit("0"));
		button(".", 2, 4, 1, colW, gridTop, 0, () -> inputDigit("."));
		button("=", 3, 4, 1, colW, gridTop, 1, equals);

		// physical keyboard support
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	function onAddedToStage(_:Event):Void {
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	function onKeyDown(e:KeyboardEvent):Void {
		var ch:Int = e.charCode;
		if (ch >= 48 && ch <= 57) { // '0'..'9'
			inputDigit(String.fromCharCode(ch));
			return;
		}
		switch (ch) {
			case 43: inputOp("+"); // '+'
			case 45: inputOp("-"); // '-'
			case 42: inputOp("*"); // '*'
			case 47: inputOp("/"); // '/'
			case 37: percent();    // '%'
			case 46, 44: inputDigit("."); // '.' or ','
			case 61: equals();     // '='
			default:
				switch (e.keyCode) {
					case 13: equals();     // Enter
					case 8: backspace();   // Backspace
					case 27, 46: clearAll(); // Escape or Delete
				}
		}
	}

	function backspace():Void {
		if (freshEntry || shown == "Error")
			return;
		var lastDigit:Bool = shown.length <= 1 || (shown.length == 2 && shown.charAt(0) == "-");
		if (lastDigit) {
			shown = "0";
			freshEntry = true;
		} else {
			shown = shown.substr(0, shown.length - 1);
		}
		refresh();
	}

	function button(text:String, col:Int, row:Int, span:Int, colW:Float, gridTop:Float, kind:Int, onClick:Void->Void):Void {
		var width:Float = colW * span + GAP * (span - 1);
		var btn = new UIButton(text, width, BTN_H, onClick, kind == 1);
		btn.fontSize = 19;
		if (kind == 2)
			btn.danger = true;
		btn.x = PAD + col * (colW + GAP);
		btn.y = gridTop + row * (BTN_H + GAP);
		ui.content.addChild(btn);
	}

	function positionDisplay():Void {
		display.measure();
		expressionLabel.measure();
		expressionLabel.y = PAD + 12;
		display.y = PAD + DISP_H - display.h - 14;
	}

	function refresh():Void {
		display.text = shown;
		expressionLabel.text = expression;
		positionDisplay();
	}

	inline function symbol(op:String):String {
		return switch (op) {
			case "+": "+";
			case "-": "−"; // minus sign
			case "*": "×"; // multiplication sign
			case "/": "÷"; // division sign
			default: op;
		}
	}

	function inputDigit(d:String):Void {
		// starting a brand-new number after "=" clears the finished equation
		if (freshEntry && pendingOp == null)
			expression = "";
		if (freshEntry) {
			shown = (d == ".") ? "0." : d;
			freshEntry = false;
		} else if (d == ".") {
			if (shown.indexOf(".") < 0)
				shown += ".";
		} else if (shown == "0") {
			shown = d;
		} else {
			shown += d;
		}
		refresh();
	}

	function inputOp(op:String):Void {
		var value:Float = Std.parseFloat(shown);
		if (pendingOp != null && !freshEntry) {
			stored = apply(stored, value, pendingOp);
			shown = format(stored);
		} else {
			stored = value;
		}
		expression = format(stored) + " " + symbol(op) + " ";
		pendingOp = op;
		freshEntry = true;
		refresh();
	}

	function equals():Void {
		if (pendingOp == null)
			return;
		var value:Float = Std.parseFloat(shown);
		expression = format(stored) + " " + symbol(pendingOp) + " " + shown + " =";
		stored = apply(stored, value, pendingOp);
		shown = format(stored);
		pendingOp = null;
		freshEntry = true;
		refresh();
	}

	function apply(a:Float, b:Float, op:String):Float {
		return switch (op) {
			case "+": a + b;
			case "-": a - b;
			case "*": a * b;
			case "/": (b == 0) ? Math.NaN : a / b;
			default: b;
		}
	}

	function negate():Void {
		if (shown == "0" || shown == "Error")
			return;
		shown = (shown.charAt(0) == "-") ? shown.substr(1) : "-" + shown;
		refresh();
	}

	function percent():Void {
		var value:Float = Std.parseFloat(shown);
		// For + and -, the percent is taken of the first operand (50 + 10% adds 10% OF 50 = 5).
		// For x, / and standalone it is a plain fraction (50 x 10% = 50 x 0.1).
		var result:Float = (pendingOp == "+" || pendingOp == "-") ? stored * value / 100 : value / 100;
		shown = format(result);
		freshEntry = true;
		refresh();
	}

	function clearAll():Void {
		shown = "0";
		expression = "";
		stored = 0;
		pendingOp = null;
		freshEntry = true;
		refresh();
	}

	function format(f:Float):String {
		if (Math.isNaN(f) || !Math.isFinite(f))
			return "Error";
		// Round to 8 decimals to absorb float error (0.1+0.2 etc). Math.fround returns a
		// Float, so unlike Math.round it does not overflow Int32 for values past ~2.1e9.
		var rounded:Float = Math.fround(f * 1e8) / 1e8;
		if (rounded == 0)
			return "0";
		if (rounded == Math.ffloor(rounded) && Math.abs(rounded) < 1e15)
			return wholeString(rounded);
		return Std.string(rounded);
	}

	// Whole-number string without Std.int (which overflows Int32) or Std.string's scientific
	// notation for large magnitudes (Std.string(1e12) is "1e+012").
	function wholeString(r:Float):String {
		var neg:Bool = r < 0;
		var a:Float = Math.abs(r);
		var digits:String = "";
		while (a >= 1) {
			var next:Float = Math.ffloor(a / 10);
			var digit:Int = Std.int(a - next * 10 + 0.5);
			digits = digit + digits;
			a = next;
		}
		return (neg ? "-" : "") + digits;
	}

	/** Call when the screen is torn down. **/
	public function destroy():Void {
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		if (stage != null)
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		if (ui != null) {
			ui.dispose();
			ui = null;
		}
	}
}
