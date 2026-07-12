package smidr.widgets;

import openfl.text.TextField;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UILocale;
import smidr.UITheme;
import smidr.UITween;
import smidr.types.UIEase;

/**
	A labelled toggle switch row: label left, animated track + knob right. Clicking anywhere on
	the row flips the state and fires `onToggle(on)`. The track colour and knob position tween
	between states. Larger track and row height on mobile for touch.
**/
final class UISwitch extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var on(default, set):Bool;
	public var onToggle:Bool->Void = null;
	public var fontSize(default, set):Int = 12;

	final labelField:TextField;
	var knobProgress:Float;
	var knobTween:UITween = null;

	/**
		@param label the row text (empty string = standalone switch)
		@param width layout width (the switch sits at the right edge)
		@param on the initial state
		@param onToggle fired after the state flips
	**/
	public function new(label:String, width:Float, on:Bool = false, ?onToggle:Bool->Void) {
		super(true, true);
		this.label = label;
		@:bypassAccessor this.on = on;
		knobProgress = on ? 1 : 0;
		this.onToggle = onToggle;
		labelField = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(labelField);
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

	override function click():Void {
		@:bypassAccessor on = !on;
		animateKnob();
		if (onToggle != null)
			onToggle(on);
		super.click();
	}

	function animateKnob():Void {
		killTween();
		knobTween = UITween.to(applyKnob, knobProgress, on ? 1 : 0, 160, OUT_QUAD, endKnob);
	}

	function applyKnob(value:Float):Void {
		knobProgress = value;
		invalidate();
	}

	function endKnob():Void {
		knobTween = null;
	}

	function killTween():Void {
		if (knobTween != null) {
			knobTween.cancel();
			knobTween = null;
		}
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();

		var trackW:Float = UITheme.px(#if mobile 44 #else 34 #end);
		var trackH:Float = UITheme.px(#if mobile 24 #else 18 #end);
		var tx:Float = w - trackW;
		var ty:Float = (h - trackH) / 2;

		var fill:Int = UIColor.mix(UITheme.panel3, UITheme.accentDark, knobProgress);
		if (hovered)
			fill = UIColor.lighten(fill, 0.08);
		graphics.beginFill(UIColor.rgb(fill));
		graphics.drawRoundRect(tx, ty, trackW, trackH, trackH, trackH);
		graphics.endFill();
		graphics.lineStyle(1, UIColor.rgb(UIColor.mix(UITheme.border2, UITheme.accent, knobProgress)));
		graphics.drawRoundRect(tx + 0.5, ty + 0.5, trackW - 1, trackH - 1, trackH, trackH);
		graphics.lineStyle();

		var kr:Float = trackH / 2 - UITheme.px(2.5);
		graphics.beginFill(UIColor.rgb(UITheme.text));
		graphics.drawCircle(tx + trackH / 2 + (trackW - trackH) * knobProgress, ty + trackH / 2, kr);
		graphics.endFill();

		UIFonts.restyle(labelField, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (labelField.text != resolved)
			labelField.text = resolved;
		labelField.visible = resolved != "";
		labelField.x = 0;
		labelField.y = (h - labelField.height) / 2;
	}

	override public function dispose():Void {
		killTween();
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

	function set_on(value:Bool):Bool {
		if (on == value)
			return value;
		on = value;
		animateKnob();
		invalidate();
		return value;
	}

	function set_fontSize(value:Int):Int {
		fontSize = value;
		invalidate();
		return value;
	}
}
