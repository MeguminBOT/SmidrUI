package smidr;

/**
	Small ARGB color math helpers (the library never depends on a framework color type).
**/
final class UIColor {
	/**
		Linear blend between two ARGB colors.
		@param a the start color (`0xAARRGGBB`)
		@param b the end color
		@param t blend amount, 0 (all `a`) .. 1 (all `b`)
		@return the interpolated ARGB color
	**/
	public static function mix(a:Int, b:Int, t:Float):Int {
		if (t <= 0)
			return a;
		if (t >= 1)
			return b;
		var aA:Int = (a >>> 24) & 0xFF;
		var aR:Int = (a >>> 16) & 0xFF;
		var aG:Int = (a >>> 8) & 0xFF;
		var aB:Int = a & 0xFF;
		var bA:Int = (b >>> 24) & 0xFF;
		var bR:Int = (b >>> 16) & 0xFF;
		var bG:Int = (b >>> 8) & 0xFF;
		var bB:Int = b & 0xFF;
		var oA:Int = aA + Std.int((bA - aA) * t);
		var oR:Int = aR + Std.int((bR - aR) * t);
		var oG:Int = aG + Std.int((bG - aG) * t);
		var oB:Int = aB + Std.int((bB - aB) * t);
		return (oA << 24) | (oR << 16) | (oG << 8) | oB;
	}

	/**
		Blends a color toward white.
		@param c the ARGB color
		@param f blend amount 0..1
		@return the lightened ARGB color
	**/
	public static inline function lighten(c:Int, f:Float):Int {
		return mix(c, 0xFFFFFFFF, f);
	}

	/**
		Blends a color toward black, keeping its alpha.
		@param c the ARGB color
		@param f blend amount 0..1
		@return the darkened ARGB color
	**/
	public static inline function darken(c:Int, f:Float):Int {
		return mix(c, (c & 0xFF000000) | 0x000000, f);
	}

	/**
		Drops the alpha channel, for APIs that take RGB + a separate alpha.
		@param c the ARGB color
		@return the `0xRRGGBB` part
	**/
	public static inline function rgb(c:Int):Int {
		return c & 0xFFFFFF;
	}

	/**
		Extracts the alpha channel.
		@param c the ARGB color
		@return alpha as 0..1
	**/
	public static inline function alphaOf(c:Int):Float {
		return ((c >>> 24) & 0xFF) / 255.0;
	}

	/**
		Perceived brightness of a color (ignores alpha).
		@param c the ARGB color
		@return luminance 0 (black) .. 1 (white)
	**/
	public static inline function luminance(c:Int):Float {
		var r:Int = (c >>> 16) & 0xFF;
		var g:Int = (c >>> 8) & 0xFF;
		var b:Int = c & 0xFF;
		return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
	}

	/**
		A readable, opaque text color for content sitting on `bg`: near-white on dark fills,
		near-black on light ones (so accent/danger surfaces stay legible under any theme).
		@param bg the background ARGB color
		@return an opaque ARGB text color
	**/
	public static inline function contrastText(bg:Int):Int {
		return luminance(bg) < 0.55 ? 0xFFF4F4F8 : 0xFF16161A;
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
		@param r red 0..255
		@param g green 0..255
		@param b blue 0..255
		@param a alpha 0..255 (default opaque)
		@return the packed `0xAARRGGBB` colour
	**/
	public static inline function fromRGB(r:Int, g:Int, b:Int, a:Int = 255):Int {
		return (byte(a) << 24) | (byte(r) << 16) | (byte(g) << 8) | byte(b);
	}

	/**
		Replaces a colour's alpha channel from a 0..1 opacity, keeping its RGB.
		@param c the ARGB colour
		@param a opacity 0..1
		@return the colour with the new alpha
	**/
	public static inline function withAlpha(c:Int, a:Float):Int {
		return (byte(Std.int(a * 255 + 0.5)) << 24) | (c & 0xFFFFFF);
	}

	/**
		Builds an ARGB colour from HSV.
		@param h hue in degrees (wraps; any value)
		@param s saturation 0..1
		@param v value/brightness 0..1
		@param a opacity 0..1 (default opaque)
		@return the packed `0xAARRGGBB` colour
	**/
	public static function hsv(h:Float, s:Float, v:Float, a:Float = 1.0):Int {
		s = unit(s);
		v = unit(v);
		var c:Float = v * s;
		var m:Float = v - c;
		return sectorToRGB(h, c, m, a);
	}

	/**
		Decomposes an ARGB colour to HSV (alpha ignored).
		@param c the ARGB colour
		@return `h` in degrees 0..360, `s`/`v` in 0..1
	**/
	public static function toHSV(c:Int):{h:Float, s:Float, v:Float} {
		var r:Float = ((c >>> 16) & 0xFF) / 255.0;
		var g:Float = ((c >>> 8) & 0xFF) / 255.0;
		var b:Float = (c & 0xFF) / 255.0;
		var max:Float = Math.max(r, Math.max(g, b));
		var min:Float = Math.min(r, Math.min(g, b));
		var d:Float = max - min;
		return {h: hue(r, g, b, max, d), s: (max == 0) ? 0 : d / max, v: max};
	}

	/**
		Builds an ARGB colour from HSL.
		@param h hue in degrees (wraps; any value)
		@param s saturation 0..1
		@param l lightness 0..1
		@param a opacity 0..1 (default opaque)
		@return the packed `0xAARRGGBB` colour
	**/
	public static function hsl(h:Float, s:Float, l:Float, a:Float = 1.0):Int {
		s = unit(s);
		l = unit(l);
		var c:Float = (1 - Math.abs(2 * l - 1)) * s;
		var m:Float = l - c / 2;
		return sectorToRGB(h, c, m, a);
	}

	/**
		Decomposes an ARGB colour to HSL (alpha ignored).
		@param c the ARGB colour
		@return `h` in degrees 0..360, `s`/`l` in 0..1
	**/
	public static function toHSL(c:Int):{h:Float, s:Float, l:Float} {
		var r:Float = ((c >>> 16) & 0xFF) / 255.0;
		var g:Float = ((c >>> 8) & 0xFF) / 255.0;
		var b:Float = (c & 0xFF) / 255.0;
		var max:Float = Math.max(r, Math.max(g, b));
		var min:Float = Math.min(r, Math.min(g, b));
		var d:Float = max - min;
		var l:Float = (max + min) / 2;
		var s:Float = (d == 0) ? 0 : d / (1 - Math.abs(2 * l - 1));
		return {h: hue(r, g, b, max, d), s: s, l: l};
	}

	/** Maps a hue sector (h degrees, chroma `c`, match `m`) to a packed ARGB colour. **/
	static inline function sectorToRGB(h:Float, c:Float, m:Float, a:Float):Int {
		h = h % 360;
		if (h < 0)
			h += 360;
		var hp:Float = h / 60.0;
		var x:Float = c * (1 - Math.abs(hp % 2 - 1));
		var r:Float = 0;
		var g:Float = 0;
		var b:Float = 0;
		if (hp < 1) {
			r = c;
			g = x;
		} else if (hp < 2) {
			r = x;
			g = c;
		} else if (hp < 3) {
			g = c;
			b = x;
		} else if (hp < 4) {
			g = x;
			b = c;
		} else if (hp < 5) {
			r = x;
			b = c;
		} else {
			r = c;
			b = x;
		}
		return fromRGB(Std.int((r + m) * 255 + 0.5), Std.int((g + m) * 255 + 0.5), Std.int((b + m) * 255 + 0.5), Std.int(unit(a) * 255 + 0.5));
	}

	/** Hue in degrees 0..360 from normalized channels and their max/spread. **/
	static inline function hue(r:Float, g:Float, b:Float, max:Float, d:Float):Float {
		if (d == 0)
			return 0;
		var h:Float;
		if (max == r)
			h = ((g - b) / d) % 6;
		else if (max == g)
			h = (b - r) / d + 2;
		else
			h = (r - g) / d + 4;
		h *= 60;
		return (h < 0) ? h + 360 : h;
	}

	static inline function byte(v:Int):Int {
		return (v < 0) ? 0 : (v > 255 ? 255 : v);
	}

	static inline function unit(v:Float):Float {
		return (v < 0) ? 0 : (v > 1 ? 1 : v);
	}
}
