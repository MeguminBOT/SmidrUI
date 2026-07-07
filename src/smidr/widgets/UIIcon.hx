package smidr.widgets;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.utils.Assets;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UIFonts;
import smidr.UITheme;

/**
	A themed icon that can be dropped into any widget or layout. Sources:
	- **SVG** (preferred) when the optional `svg` haxelib is present (`-lib svg` sets the
	  `svg` define automatically) — rasterized once per (asset, pixel size) into a shared
	  static cache, so N icons of the same glyph cost one texture and batch as bitmaps.
	- **Bitmap** assets (png etc.) otherwise, scaled into the same cache.

	Tinting forces every opaque pixel to a theme colour (`tone` ramp or `colorOverride`) via a
	reused `ColorTransform`, so monochrome icon sets follow theme swaps with zero extra
	bitmaps; set `tinted = false` for full-colour art. Missing assets render a placeholder
	ring so layouts never break. Non-interactive and pointer-transparent — attach freely to
	buttons, rows, rails (`addChild` + position).
**/
final class UIIcon extends UIComponent {
	/** The icon asset path (.svg with the `svg` lib, or any bitmap format). **/
	public var asset(default, set):String;

	/** Base (unscaled) square edge length. **/
	public var size(default, set):Float;

	/** Tint from the theme text ramp: 0 = primary, 1 = secondary, 2 = tertiary. **/
	public var tone(default, set):Int = 1;

	/** Explicit ARGB tint; overrides `tone` when != 0. **/
	public var colorOverride(default, set):Int = 0;

	/** `false` renders the source colours untouched (full-colour art). **/
	public var tinted(default, set):Bool = true;

	static final rasterCache:Map<String, BitmapData> = new Map();
	#if svg
	static final svgCache:Map<String, format.SVG> = new Map();
	#end
	static final ct:ColorTransform = new ColorTransform();
	static final mtx:Matrix = new Matrix();

	final bmp:Bitmap;

	/**
		@param asset the icon asset path
		@param size base (unscaled) square edge length
		@param tone theme text ramp tint: 0 = primary, 1 = secondary, 2 = tertiary
	**/
	public function new(asset:String, size:Float = 16, tone:Int = 1) {
		super(false, false);
		@:bypassAccessor this.asset = asset;
		@:bypassAccessor this.size = size;
		@:bypassAccessor this.tone = tone;
		bmp = new Bitmap(null, null, true);
		addChild(bmp);
		render();
	}

	/**
		The shared rasterized bitmap for an asset at an exact pixel size (rendered/scaled and
		cached on first request). Custom widgets can draw icons directly from this in their
		own `render()` without a child `UIIcon`.
		@param asset the icon asset path
		@param sizePx the exact square pixel size
		@return the cached bitmap, or `null` when the asset is missing (or .svg without the lib)
	**/
	public static function getBitmap(asset:String, sizePx:Int):BitmapData {
		if (asset == null || sizePx <= 0)
			return null;
		var cacheKey:String = asset + "|" + sizePx;
		var bd:BitmapData = rasterCache.get(cacheKey);
		if (bd != null)
			return bd;
		if (StringTools.endsWith(asset, ".svg")) {
			#if svg
			var doc:format.SVG = svgCache.get(asset);
			if (doc == null) {
				if (!UIFonts.libraryLoaded(asset) || !Assets.exists(asset))
					return null;
				var text:String = Assets.getText(asset);
				if (text == null)
					return null;
				doc = new format.SVG(text);
				svgCache.set(asset, doc);
			}
			var shape:Shape = new Shape();
			doc.render(shape.graphics, 0, 0, sizePx, sizePx);
			bd = new BitmapData(sizePx, sizePx, true, 0);
			bd.draw(shape, null, null, null, null, true);
			#else
			return null;
			#end
		} else {
			if (!UIFonts.libraryLoaded(asset) || !Assets.exists(asset))
				return null;
			var src:BitmapData = Assets.getBitmapData(asset);
			if (src == null)
				return null;
			if (src.width == sizePx && src.height == sizePx)
				bd = src;
			else {
				mtx.setTo(sizePx / src.width, 0, 0, sizePx / src.height, 0, 0);
				bd = new BitmapData(sizePx, sizePx, true, 0);
				bd.draw(src, mtx, null, null, null, true);
			}
		}
		rasterCache.set(cacheKey, bd);
		return bd;
	}

	/**
		Drops all cached rasters and parsed SVG documents (e.g. after a `UITheme.setScale`
		change made every old pixel size stale, or on state teardown). Live icons re-rasterize
		on their next render. Cached `BitmapData` is left to the GC — it may still be
		displayed by live `Bitmap`s.
	**/
	public static function clearCache():Void {
		rasterCache.clear();
		#if svg
		svgCache.clear();
		#end
	}

	inline function resolveColor():Int {
		return (colorOverride != 0) ? colorOverride : switch (tone) {
			case 0: UITheme.text;
			case 2: UITheme.text3;
			default: UITheme.text2;
		};
	}

	override public function render():Void {
		var p:Int = Std.int(UITheme.px(size) + 0.5);
		w = p;
		h = p;
		var g = graphics;
		g.clear();

		var bd:BitmapData = getBitmap(asset, p);
		if (bd == null) {
			bmp.visible = false;
			g.lineStyle(2, UIColor.rgb(resolveColor()));
			g.drawCircle(p * 0.5, p * 0.5, p * 0.32);
			g.lineStyle();
			return;
		}

		bmp.visible = true;
		if (bmp.bitmapData != bd)
			bmp.bitmapData = bd;
		bmp.smoothing = true;

		if (tinted) {
			var c:Int = resolveColor();
			ct.redMultiplier = 0;
			ct.greenMultiplier = 0;
			ct.blueMultiplier = 0;
			ct.alphaMultiplier = UIColor.alphaOf(c);
			ct.redOffset = (c >>> 16) & 0xFF;
			ct.greenOffset = (c >>> 8) & 0xFF;
			ct.blueOffset = c & 0xFF;
			ct.alphaOffset = 0;
		} else {
			ct.redMultiplier = 1;
			ct.greenMultiplier = 1;
			ct.blueMultiplier = 1;
			ct.alphaMultiplier = 1;
			ct.redOffset = 0;
			ct.greenOffset = 0;
			ct.blueOffset = 0;
			ct.alphaOffset = 0;
		}
		bmp.transform.colorTransform = ct;
	}

	function set_asset(v:String):String {
		if (asset == v)
			return v;
		asset = v;
		invalidate();
		return v;
	}

	function set_size(v:Float):Float {
		if (size == v)
			return v;
		size = v;
		invalidate();
		return v;
	}

	function set_tone(v:Int):Int {
		tone = v;
		invalidate();
		return v;
	}

	function set_colorOverride(v:Int):Int {
		colorOverride = v;
		invalidate();
		return v;
	}

	function set_tinted(v:Bool):Bool {
		if (tinted == v)
			return v;
		tinted = v;
		invalidate();
		return v;
	}
}
