package smidr.types;

/** One `UIIconRail` tab definition: a short label (<=4 chars reads best) + optional tooltip. **/
typedef UIRailTabDef = {
	var label:String;
	@:optional var tooltipKey:String;
	@:optional var tooltipFallback:String;
}
