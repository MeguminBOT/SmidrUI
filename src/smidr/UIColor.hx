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
}
