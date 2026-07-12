package smidr.widgets;

import openfl.geom.Point;
import smidr.UIColor;
import smidr.UIComponent;
import smidr.UITheme;
import smidr.types.UICursor;
import smidr.types.UIDockZone;

/**
	An editor-style docking region: a tree of resizable splits with tabbed `UIDockGroup`s at the
	leaves. Add panels with `addPanel` (a new tab in the primary group) or `dock(panel, target,
	zone)` (split a target). Dragging a panel's tab re-docks it live — a drop-zone overlay shows
	where it will land (`CENTER` tabs into a group, the edges split it), and emptied groups
	collapse so the tree stays tidy. Split dividers drag to reproportion.

	The layout is a mutable node tree the host lays out to fill its bounds; call `invalidate()`
	after a structural change (the dock/undock operations do this for you).
**/
final class UIDockHost extends UIComponent {
	/** Base (unscaled) split-divider thickness. **/
	public var dividerThickness:Float = 6;

	/** Smallest a pane may be squeezed to by a divider drag, in UI pixels. **/
	public var minPane:Float = 60;

	var rootNode:UIDockNode = null;
	final groups:Array<UIDockGroup> = [];
	final dividers:Array<UIDockDivider> = [];
	var dividerCount:Int = 0;
	final overlay:UIDockOverlay;

	var dragPanel:UIDockPanel = null;
	var dragSource:UIDockGroup = null;
	var dropGroup:UIDockGroup = null;
	var dropZone:UIDockZone = CENTER;

	/**
		@param width layout width
		@param height layout height
	**/
	public function new(width:Float, height:Float) {
		super(false, false);
		overlay = new UIDockOverlay();
		overlay.visible = false;
		resize(width, height);
		render();
	}

	/**
		Adds a panel as a new tab in the primary (first) group, creating the group when the host
		is empty.
		@param panel the panel to dock
		@return the group the panel landed in
	**/
	public function addPanel(panel:UIDockPanel):UIDockGroup {
		if (rootNode == null) {
			var group:UIDockGroup = new UIDockGroup(this);
			group.addPanel(panel);
			rootNode = UIDockNode.leaf(group);
			invalidate();
			return group;
		}
		var group:UIDockGroup = firstGroup(rootNode);
		group.addPanel(panel);
		invalidate();
		return group;
	}

	/**
		Docks a panel into a target group: a new tab (`CENTER`) or a split on an edge.
		@param panel the panel to dock (need not already be in the host)
		@param target the group to dock into or split
		@param zone where the panel lands
		@return the group the panel landed in (a new group for edge zones)
	**/
	public function dock(panel:UIDockPanel, target:UIDockGroup, zone:UIDockZone):UIDockGroup {
		return performDock(null, panel, target, zone);
	}

	function firstGroup(node:UIDockNode):UIDockGroup {
		return node.isLeaf() ? node.group : firstGroup(node.first);
	}

	// --- tab-drag coordination (called by UIDockGroup) ---

	@:allow(smidr.widgets.UIDockGroup)
	function startPanelDrag(source:UIDockGroup, panel:UIDockPanel):Void {
		dragSource = source;
		dragPanel = panel;
		dropGroup = null;
		if (overlay.parent != this)
			addChild(overlay);
		setChildIndex(overlay, numChildren - 1);
		overlay.visible = false;
	}

	@:allow(smidr.widgets.UIDockGroup)
	function updatePanelDrag(stageX:Float, stageY:Float):Void {
		var local:Point = globalToLocal(new Point(stageX, stageY));
		var target:UIDockGroup = groupAt(local.x, local.y);
		if (target == null) {
			dropGroup = null;
			overlay.visible = false;
			return;
		}
		dropGroup = target;
		dropZone = zoneAt(target, local.x, local.y);
		overlay.showAt(target.x, target.y, target.w, target.h, dropZone);
		overlay.visible = true;
		setChildIndex(overlay, numChildren - 1);
	}

	@:allow(smidr.widgets.UIDockGroup)
	function endPanelDrag():Void {
		overlay.visible = false;
		if (dropGroup != null && dragPanel != null)
			performDock(dragSource, dragPanel, dropGroup, dropZone);
		dragPanel = null;
		dragSource = null;
		dropGroup = null;
	}

	function groupAt(localX:Float, localY:Float):UIDockGroup {
		var i:Int = groups.length;
		while (--i >= 0) {
			var group:UIDockGroup = groups[i];
			if (localX >= group.x && localX < group.x + group.w && localY >= group.y && localY < group.y + group.h)
				return group;
		}
		return null;
	}

	function zoneAt(target:UIDockGroup, localX:Float, localY:Float):UIDockZone {
		var fx:Float = (localX - target.x) / target.w;
		var fy:Float = (localY - target.y) / target.h;
		if (fx > 0.3 && fx < 0.7 && fy > 0.3 && fy < 0.7)
			return CENTER;
		var toLeft:Float = fx;
		var toRight:Float = 1 - fx;
		var toTop:Float = fy;
		var toBottom:Float = 1 - fy;
		var min:Float = Math.min(Math.min(toLeft, toRight), Math.min(toTop, toBottom));
		if (min == toLeft)
			return LEFT;
		if (min == toRight)
			return RIGHT;
		return (min == toTop) ? TOP : BOTTOM;
	}

	// --- tree mutation ---

	function performDock(source:UIDockGroup, panel:UIDockPanel, target:UIDockGroup, zone:UIDockZone):UIDockGroup {
		// can't split a single-panel group off from itself (nothing would be left behind)
		if (source == target && zone != CENTER && source.count <= 1)
			return null;
		if (source != null)
			source.removePanel(panel);
		var sourceEmptied:Bool = (source != null && source.count == 0);

		var result:UIDockGroup;
		if (zone == CENTER) {
			target.addPanel(panel);
			result = target;
		} else {
			var newGroup:UIDockGroup = new UIDockGroup(this);
			newGroup.addPanel(panel);
			var targetNode:UIDockNode = findNode(rootNode, target);
			if (targetNode != null) {
				var vertical:Bool = (zone == TOP || zone == BOTTOM);
				var newFirst:Bool = (zone == LEFT || zone == TOP);
				splitNode(targetNode, UIDockNode.leaf(newGroup), vertical, newFirst);
			}
			result = newGroup;
		}

		if (sourceEmptied && source != target)
			collapseGroup(source);
		invalidate();
		return result;
	}

	function splitNode(targetNode:UIDockNode, newLeaf:UIDockNode, vertical:Bool, newFirst:Bool):Void {
		var parent:UIDockNode = targetNode.parent;
		var split:UIDockNode = newFirst ? UIDockNode.split(vertical, newLeaf, targetNode, 0.5) : UIDockNode.split(vertical, targetNode, newLeaf, 0.5);
		split.parent = parent;
		if (parent == null)
			rootNode = split;
		else if (parent.first == targetNode)
			parent.first = split;
		else
			parent.second = split;
	}

	function collapseGroup(group:UIDockGroup):Void {
		var node:UIDockNode = findNode(rootNode, group);
		if (node == null)
			return;
		if (group.parent == this)
			removeChild(group);
		group.dispose();
		var parent:UIDockNode = node.parent;
		if (parent == null) {
			rootNode = null;
			return;
		}
		var sibling:UIDockNode = (parent.first == node) ? parent.second : parent.first;
		var grand:UIDockNode = parent.parent;
		sibling.parent = grand;
		if (grand == null)
			rootNode = sibling;
		else if (grand.first == parent)
			grand.first = sibling;
		else
			grand.second = sibling;
	}

	function findNode(node:UIDockNode, group:UIDockGroup):UIDockNode {
		if (node == null)
			return null;
		if (node.isLeaf())
			return (node.group == group) ? node : null;
		var found:UIDockNode = findNode(node.first, group);
		return (found != null) ? found : findNode(node.second, group);
	}

	// --- layout ---

	override public function render():Void {
		dividerCount = 0;
		groups.resize(0);
		if (rootNode != null)
			layoutNode(rootNode, 0, 0, w, h);
		// hide any pooled dividers left unused this pass
		var i:Int = dividerCount;
		while (i < dividers.length) {
			dividers[i].visible = false;
			i++;
		}
		if (overlay.parent == this)
			setChildIndex(overlay, numChildren - 1);
	}

	function layoutNode(node:UIDockNode, x:Float, y:Float, nw:Float, nh:Float):Void {
		node.rx = x;
		node.ry = y;
		node.rw = nw;
		node.rh = nh;
		if (node.isLeaf()) {
			if (node.group.parent != this)
				addChild(node.group);
			node.group.setBounds(x, y, nw, nh);
			groups.push(node.group);
			return;
		}
		var thickness:Float = UITheme.px(dividerThickness);
		if (node.vertical) {
			var firstH:Float = (nh - thickness) * node.ratio;
			layoutNode(node.first, x, y, nw, firstH);
			divider(node).setBounds(x, y + firstH, nw, thickness);
			layoutNode(node.second, x, y + firstH + thickness, nw, nh - firstH - thickness);
		} else {
			var firstW:Float = (nw - thickness) * node.ratio;
			layoutNode(node.first, x, y, firstW, nh);
			divider(node).setBounds(x + firstW, y, thickness, nh);
			layoutNode(node.second, x + firstW + thickness, y, nw - firstW - thickness, nh);
		}
	}

	function divider(node:UIDockNode):UIDockDivider {
		var handle:UIDockDivider;
		if (dividerCount < dividers.length)
			handle = dividers[dividerCount];
		else {
			handle = new UIDockDivider(this);
			addChild(handle);
			dividers.push(handle);
		}
		dividerCount++;
		handle.visible = true;
		handle.bind(node);
		return handle;
	}

	@:allow(smidr.widgets.UIDockDivider)
	function dragDivider(node:UIDockNode, stageX:Float, stageY:Float):Void {
		var local:Point = globalToLocal(new Point(stageX, stageY));
		var extent:Float = node.vertical ? node.rh : node.rw;
		if (extent <= 0)
			return;
		var raw:Float = node.vertical ? (local.y - node.ry) : (local.x - node.rx);
		var ratio:Float = raw / extent;
		var minRatio:Float = minPane / extent;
		var maxRatio:Float = 1 - minRatio;
		if (ratio < minRatio)
			ratio = minRatio;
		if (ratio > maxRatio)
			ratio = maxRatio;
		if (minRatio < maxRatio) {
			node.ratio = ratio;
			invalidate();
		}
	}

	override public function dispose():Void {
		if (rootNode != null)
			disposeNode(rootNode);
		rootNode = null;
		super.dispose();
	}

	function disposeNode(node:UIDockNode):Void {
		if (node.isLeaf())
			node.group.dispose();
		else {
			disposeNode(node.first);
			disposeNode(node.second);
		}
	}
}

/** One node of a `UIDockHost` layout tree: a leaf (a group) or a split (two children + ratio). **/
private class UIDockNode {
	public var group:UIDockGroup = null;
	public var vertical:Bool = false;
	public var ratio:Float = 0.5;
	public var first:UIDockNode = null;
	public var second:UIDockNode = null;
	public var parent:UIDockNode = null;

	// bounds filled during layout, used for hit-testing the split during a divider drag
	public var rx:Float = 0;
	public var ry:Float = 0;
	public var rw:Float = 0;
	public var rh:Float = 0;

	public function new() {}

	public inline function isLeaf():Bool
		return group != null;

	public static function leaf(group:UIDockGroup):UIDockNode {
		var node:UIDockNode = new UIDockNode();
		node.group = group;
		return node;
	}

	public static function split(vertical:Bool, first:UIDockNode, second:UIDockNode, ratio:Float):UIDockNode {
		var node:UIDockNode = new UIDockNode();
		node.vertical = vertical;
		node.first = first;
		node.second = second;
		node.ratio = ratio;
		first.parent = node;
		second.parent = node;
		return node;
	}
}

/** A draggable split divider between two `UIDockNode`s. **/
private final class UIDockDivider extends UIComponent {
	final host:UIDockHost;
	var node:UIDockNode;

	public function new(host:UIDockHost) {
		super(true, true);
		this.host = host;
	}

	public function bind(node:UIDockNode):Void {
		this.node = node;
		hoverCursor = node.vertical ? UICursor.RESIZE_V : UICursor.RESIZE_H;
	}

	public function setBounds(x:Float, y:Float, w:Float, h:Float):Void {
		this.x = x;
		this.y = y;
		resize(w, h);
	}

	override function onPress(localX:Float, localY:Float):Void {
		beginCapture();
	}

	override function onDragMove(stageX:Float, stageY:Float):Void {
		if (node != null)
			host.dragDivider(node, stageX, stageY);
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(0, 0);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		graphics.beginFill(UIColor.rgb(hovered ? UITheme.border2 : UITheme.border));
		if (node != null && node.vertical)
			graphics.drawRect(0, h / 2 - 0.5, w, 1);
		else
			graphics.drawRect(w / 2 - 0.5, 0, 1, h);
		graphics.endFill();
	}
}

/** The translucent drop-zone indicator shown while a panel tab is dragged. **/
private final class UIDockOverlay extends UIComponent {
	var zone:UIDockZone = CENTER;

	public function new() {
		super(false, false);
	}

	public function showAt(x:Float, y:Float, w:Float, h:Float, zone:UIDockZone):Void {
		this.x = x;
		this.y = y;
		this.zone = zone;
		resize(w, h);
	}

	override public function render():Void {
		graphics.clear();
		graphics.beginFill(UIColor.rgb(UITheme.accent), 0.12);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		graphics.lineStyle(2, UIColor.rgb(UITheme.accent));
		graphics.drawRect(1, 1, w - 2, h - 2);
		graphics.lineStyle();
		graphics.beginFill(UIColor.rgb(UITheme.accent), 0.28);
		switch (zone) {
			case LEFT:
				graphics.drawRect(0, 0, w / 2, h);
			case RIGHT:
				graphics.drawRect(w / 2, 0, w / 2, h);
			case TOP:
				graphics.drawRect(0, 0, w, h / 2);
			case BOTTOM:
				graphics.drawRect(0, h / 2, w, h / 2);
			default:
				graphics.drawRect(0, 0, w, h);
		}
		graphics.endFill();
	}
}
