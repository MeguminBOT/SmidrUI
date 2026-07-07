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
	the row flips the state and fires `onChange(on)`. The track colour and knob position tween
	between states. Larger track and row height on mobile for touch.
**/
final class UISwitch extends UIComponent {
	public var key(default, set):String = null;
	public var fallback:String = "";
	public var label(default, set):String;

	public var on(default, set):Bool;
	public var onChange:Bool->Void = null;
	public var fontSize(default, set):Int = 12;

	final tf:TextField;
	var knobP:Float;
	var knobTween:UITween = null;

	/**
		@param label the row text (empty string = standalone switch)
		@param width layout width (the switch sits at the right edge)
		@param on the initial state
		@param onChange fired after the state flips
	**/
	public function new(label:String, width:Float, on:Bool = false, ?onChange:Bool->Void) {
		super(true, true);
		this.label = label;
		@:bypassAccessor this.on = on;
		knobP = on ? 1 : 0;
		this.onChange = onChange;
		tf = UIFonts.make(UITheme.fs(fontSize), UITheme.text2);
		addChild(tf);
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
		if (onChange != null)
			onChange(on);
		super.click();
	}

	function animateKnob():Void {
		killTween();
		knobTween = UITween.to(applyKnob, knobP, on ? 1 : 0, 160, OUT_QUAD, endKnob);
	}

	function applyKnob(v:Float):Void {
		knobP = v;
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
		var g = graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var trackW:Float = UITheme.px(#if mobile 44 #else 34 #end);
		var trackH:Float = UITheme.px(#if mobile 24 #else 18 #end);
		var tx:Float = w - trackW;
		var ty:Float = (h - trackH) / 2;

		var fill:Int = UIColor.mix(UITheme.panel3, UITheme.accentDark, knobP);
		if (hovered)
			fill = UIColor.lighten(fill, 0.08);
		g.beginFill(UIColor.rgb(fill));
		g.drawRoundRect(tx, ty, trackW, trackH, trackH, trackH);
		g.endFill();
		g.lineStyle(1, UIColor.rgb(UIColor.mix(UITheme.border2, UITheme.accent, knobP)));
		g.drawRoundRect(tx + 0.5, ty + 0.5, trackW - 1, trackH - 1, trackH, trackH);
		g.lineStyle();

		var kr:Float = trackH / 2 - UITheme.px(2.5);
		g.beginFill(UIColor.rgb(UITheme.text));
		g.drawCircle(tx + trackH / 2 + (trackW - trackH) * knobP, ty + trackH / 2, kr);
		g.endFill();

		UIFonts.restyle(tf, UITheme.fs(fontSize), UITheme.text2);
		var resolved:String = (key != null) ? UILocale.t(key, fallback) : label;
		if (tf.text != resolved)
			tf.text = resolved;
		tf.visible = resolved != "";
		tf.x = 0;
		tf.y = (h - tf.height) / 2;
	}

	override public function dispose():Void {
		killTween();
		super.dispose();
	}

	function set_key(v:String):String {
		key = v;
		invalidate();
		return v;
	}

	function set_label(v:String):String {
		label = v;
		invalidate();
		return v;
	}

	function set_on(v:Bool):Bool {
		if (on == v)
			return v;
		on = v;
		animateKnob();
		invalidate();
		return v;
	}

	function set_fontSize(v:Int):Int {
		fontSize = v;
		invalidate();
		return v;
	}
}
