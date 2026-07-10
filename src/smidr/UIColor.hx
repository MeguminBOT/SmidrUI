package smidr;

/**
	Small ARGB color math helpers (the library never depends on a framework color type).
**/
final class UIColor {
	/**
		Linear blend between two ARGB colors.
		@param from the start color (`0xAARRGGBB`)
		@param to the end color
		@param amount blend amount, 0 (all `from`) .. 1 (all `to`)
		@return the interpolated ARGB color
	**/
	public static function mix(from:Int, to:Int, amount:Float):Int {
		if (amount <= 0)
			return from;
		if (amount >= 1)
			return to;
		var fromA:Int = (from >>> 24) & 0xFF;
		var fromR:Int = (from >>> 16) & 0xFF;
		var fromG:Int = (from >>> 8) & 0xFF;
		var fromB:Int = from & 0xFF;
		var toA:Int = (to >>> 24) & 0xFF;
		var toR:Int = (to >>> 16) & 0xFF;
		var toG:Int = (to >>> 8) & 0xFF;
		var toB:Int = to & 0xFF;
		var outA:Int = fromA + Std.int((toA - fromA) * amount);
		var outR:Int = fromR + Std.int((toR - fromR) * amount);
		var outG:Int = fromG + Std.int((toG - fromG) * amount);
		var outB:Int = fromB + Std.int((toB - fromB) * amount);
		return (outA << 24) | (outR << 16) | (outG << 8) | outB;
	}

	/**
		Blends a color toward white.
		@param color the ARGB color
		@param amount blend amount 0..1
		@return the lightened ARGB color
	**/
	public static inline function lighten(color:Int, amount:Float):Int {
		return mix(color, 0xFFFFFFFF, amount);
	}

	/**
		Blends a color toward black, keeping its alpha.
		@param color the ARGB color
		@param amount blend amount 0..1
		@return the darkened ARGB color
	**/
	public static inline function darken(color:Int, amount:Float):Int {
		return mix(color, (color & 0xFF000000) | 0x000000, amount);
	}

	/**
		Drops the alpha channel, for APIs that take RGB + a separate alpha.
		@param color the ARGB color
		@return the `0xRRGGBB` part
	**/
	public static inline function rgb(color:Int):Int {
		return color & 0xFFFFFF;
	}

	/**
		Extracts the alpha channel.
		@param color the ARGB color
		@return alpha as 0..1
	**/
	public static inline function alphaOf(color:Int):Float {
		return ((color >>> 24) & 0xFF) / 255.0;
	}

	/**
		Perceived brightness of a color (ignores alpha).
		@param color the ARGB color
		@return luminance 0 (black) .. 1 (white)
	**/
	public static inline function luminance(color:Int):Float {
		var red:Int = (color >>> 16) & 0xFF;
		var green:Int = (color >>> 8) & 0xFF;
		var blue:Int = color & 0xFF;
		return (0.299 * red + 0.587 * green + 0.114 * blue) / 255.0;
	}

	/**
		A readable, opaque text color for content sitting on `background`: near-white on dark fills,
		near-black on light ones (so accent/danger surfaces stay legible under any theme).
		@param background the background ARGB color
		@return an opaque ARGB text color
	**/
	public static inline function contrastText(background:Int):Int {
		return luminance(background) < 0.55 ? 0xFFF4F4F8 : 0xFF16161A;
	}

	/**
		Forces a colour opaque, keeping its RGB. Use on a plain 6-digit hex literal (`0xRRGGBB`),
		whose alpha byte is 0 — i.e. fully transparent — before passing it anywhere that expects a
		`0xAARRGGBB` value.
		@param rgb the colour (any alpha; only the low 24 bits are kept)
		@return the colour with alpha forced to 0xFF
	**/
	public static inline function opaque(rgb:Int):Int {
		return 0xFF000000 | (rgb & 0xFFFFFF);
	}

	/**
		Builds an ARGB colour from 0..255 channels.
		@param red red 0..255
		@param green green 0..255
		@param blue blue 0..255
		@param alpha alpha 0..255 (default opaque)
		@return the packed `0xAARRGGBB` colour
	**/
	public static inline function fromRGB(red:Int, green:Int, blue:Int, alpha:Int = 255):Int {
		return (byte(alpha) << 24) | (byte(red) << 16) | (byte(green) << 8) | byte(blue);
	}

	/**
		Replaces a colour's alpha channel from a 0..1 opacity, keeping its RGB.
		@param color the ARGB colour
		@param alpha opacity 0..1
		@return the colour with the new alpha
	**/
	public static inline function withAlpha(color:Int, alpha:Float):Int {
		return (byte(Std.int(alpha * 255 + 0.5)) << 24) | (color & 0xFFFFFF);
	}

	/**
		Builds an ARGB colour from HSV.
		@param hue hue in degrees (wraps; any value)
		@param saturation saturation 0..1
		@param value value/brightness 0..1
		@param alpha opacity 0..1 (default opaque)
		@return the packed `0xAARRGGBB` colour
	**/
	public static function hsv(hue:Float, saturation:Float, value:Float, alpha:Float = 1.0):Int {
		saturation = unit(saturation);
		value = unit(value);
		var chroma:Float = value * saturation;
		var match:Float = value - chroma;
		return sectorToRGB(hue, chroma, match, alpha);
	}

	/**
		Decomposes an ARGB colour to HSV (alpha ignored).
		@param color the ARGB colour
		@return `hue` in degrees 0..360, `saturation`/`value` in 0..1
	**/
	public static function toHSV(color:Int):{hue:Float, saturation:Float, value:Float} {
		var red:Float = ((color >>> 16) & 0xFF) / 255.0;
		var green:Float = ((color >>> 8) & 0xFF) / 255.0;
		var blue:Float = (color & 0xFF) / 255.0;
		var max:Float = Math.max(red, Math.max(green, blue));
		var min:Float = Math.min(red, Math.min(green, blue));
		var spread:Float = max - min;
		return {hue: hueOf(red, green, blue, max, spread), saturation: (max == 0) ? 0 : spread / max, value: max};
	}

	/**
		Builds an ARGB colour from HSL.
		@param hue hue in degrees (wraps; any value)
		@param saturation saturation 0..1
		@param lightness lightness 0..1
		@param alpha opacity 0..1 (default opaque)
		@return the packed `0xAARRGGBB` colour
	**/
	public static function hsl(hue:Float, saturation:Float, lightness:Float, alpha:Float = 1.0):Int {
		saturation = unit(saturation);
		lightness = unit(lightness);
		var chroma:Float = (1 - Math.abs(2 * lightness - 1)) * saturation;
		var match:Float = lightness - chroma / 2;
		return sectorToRGB(hue, chroma, match, alpha);
	}

	/**
		Decomposes an ARGB colour to HSL (alpha ignored).
		@param color the ARGB colour
		@return `hue` in degrees 0..360, `saturation`/`lightness` in 0..1
	**/
	public static function toHSL(color:Int):{hue:Float, saturation:Float, lightness:Float} {
		var red:Float = ((color >>> 16) & 0xFF) / 255.0;
		var green:Float = ((color >>> 8) & 0xFF) / 255.0;
		var blue:Float = (color & 0xFF) / 255.0;
		var max:Float = Math.max(red, Math.max(green, blue));
		var min:Float = Math.min(red, Math.min(green, blue));
		var spread:Float = max - min;
		var lightness:Float = (max + min) / 2;
		var saturation:Float = (spread == 0) ? 0 : spread / (1 - Math.abs(2 * lightness - 1));
		return {hue: hueOf(red, green, blue, max, spread), saturation: saturation, lightness: lightness};
	}

	/** Maps a hue sector (`hue` degrees, chroma, match offset) to a packed ARGB colour. **/
	static inline function sectorToRGB(hue:Float, chroma:Float, match:Float, alpha:Float):Int {
		hue = hue % 360;
		if (hue < 0)
			hue += 360;
		var sextant:Float = hue / 60.0;
		var x:Float = chroma * (1 - Math.abs(sextant % 2 - 1));
		var red:Float = 0;
		var green:Float = 0;
		var blue:Float = 0;
		if (sextant < 1) {
			red = chroma;
			green = x;
		} else if (sextant < 2) {
			red = x;
			green = chroma;
		} else if (sextant < 3) {
			green = chroma;
			blue = x;
		} else if (sextant < 4) {
			green = x;
			blue = chroma;
		} else if (sextant < 5) {
			red = x;
			blue = chroma;
		} else {
			red = chroma;
			blue = x;
		}
		return fromRGB(Std.int((red + match) * 255 + 0.5), Std.int((green + match) * 255 + 0.5), Std.int((blue + match) * 255 + 0.5),
			Std.int(unit(alpha) * 255 + 0.5));
	}

	/** Hue in degrees 0..360 from normalized channels and their max/spread. **/
	static inline function hueOf(red:Float, green:Float, blue:Float, max:Float, spread:Float):Float {
		if (spread == 0)
			return 0;
		var hue:Float;
		if (max == red)
			hue = ((green - blue) / spread) % 6;
		else if (max == green)
			hue = (blue - red) / spread + 2;
		else
			hue = (red - green) / spread + 4;
		hue *= 60;
		return (hue < 0) ? hue + 360 : hue;
	}

	static inline function byte(value:Int):Int {
		return (value < 0) ? 0 : (value > 255 ? 255 : value);
	}

	static inline function unit(value:Float):Float {
		return (value < 0) ? 0 : (value > 1 ? 1 : value);
	}
}
