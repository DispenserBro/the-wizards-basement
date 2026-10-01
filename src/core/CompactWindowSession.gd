class_name CompactWindowSession
extends Object

const WindowSize = Vector2i(360, 360)
const UnfocusedOpacity = 0.55

static var IsActive: bool = false

static var _originalSize: Vector2i
static var _originalPosition: Vector2i
static var _originalMode: Window.Mode
static var _originalContentScaleSize: Vector2i
static var _originalContentScaleFactor: float
static var _originalContentScaleMode: Window.ContentScaleMode
static var _originalContentScaleAspect: Window.ContentScaleAspect
static var _originalAlwaysOnTop: bool
static var _originalBorderless: bool
static var _originalTransparent: bool
static var _originalTransparentBackground: bool
static var _focusEnteredCallback: Callable
static var _focusExitedCallback: Callable
static var _opacityRoots: Dictionary = {}

static func enter(window: Window) -> void:
	if window == null:
		return
	if IsActive:
		ConnectFocusSignals(window)
		ApplyFocusState(window, window.has_focus())
		return

	_originalSize = window.size
	_originalPosition = window.position
	_originalMode = window.mode
	_originalContentScaleSize = window.content_scale_size
	_originalContentScaleFactor = window.content_scale_factor
	_originalContentScaleMode = window.content_scale_mode
	_originalContentScaleAspect = window.content_scale_aspect
	_originalAlwaysOnTop = window.always_on_top
	_originalBorderless = window.borderless
	_originalTransparent = window.transparent
	_originalTransparentBackground = window.transparent_bg

	IsActive = true
	window.mode = Window.MODE_WINDOWED
	window.always_on_top = true
	window.borderless = true
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size = WindowSize
	window.content_scale_factor = 1.0
	window.size = WindowSize
	ConnectFocusSignals(window)
	ApplyFocusState(window, window.has_focus())

	var usableRect = DisplayServer.screen_get_usable_rect(window.current_screen)
	window.position = Vector2i(
		usableRect.position.x + usableRect.size.x - WindowSize.x - 10,
		usableRect.position.y + usableRect.size.y - WindowSize.y - 10)

static func exit(window: Window) -> void:
	if window == null or not IsActive:
		return

	RestoreSceneOpacity()
	window.transparent_bg = _originalTransparentBackground
	window.transparent = _originalTransparent
	DisconnectFocusSignals(window)
	window.content_scale_mode = _originalContentScaleMode
	window.content_scale_aspect = _originalContentScaleAspect
	window.content_scale_size = _originalContentScaleSize
	window.content_scale_factor = _originalContentScaleFactor
	window.always_on_top = _originalAlwaysOnTop
	window.borderless = _originalBorderless
	window.size = _originalSize
	window.position = _originalPosition
	window.mode = _originalMode
	IsActive = false

static func ConnectFocusSignals(window: Window) -> void:
	if not _focusEnteredCallback.is_valid():
		_focusEnteredCallback = func(): ApplyFocusState(window, true)
	if not _focusExitedCallback.is_valid():
		_focusExitedCallback = func(): ApplyFocusState(window, false)

	if not window.focus_entered.is_connected(_focusEnteredCallback):
		window.focus_entered.connect(_focusEnteredCallback)
	if not window.focus_exited.is_connected(_focusExitedCallback):
		window.focus_exited.connect(_focusExitedCallback)

static func DisconnectFocusSignals(window: Window) -> void:
	if _focusEnteredCallback.is_valid() and window.focus_entered.is_connected(_focusEnteredCallback):
		window.focus_entered.disconnect(_focusEnteredCallback)
	if _focusExitedCallback.is_valid() and window.focus_exited.is_connected(_focusExitedCallback):
		window.focus_exited.disconnect(_focusExitedCallback)

	_focusEnteredCallback = Callable()
	_focusExitedCallback = Callable()

static func ApplyFocusState(window: Window, hasFocus: bool) -> void:
	RestoreSceneOpacity()
	if window == null or not IsActive:
		return

	if hasFocus or not DisplayServer.has_feature(DisplayServer.FEATURE_WINDOW_TRANSPARENCY):
		window.transparent_bg = _originalTransparentBackground
		window.transparent = _originalTransparent
		return

	window.transparent_bg = true
	window.transparent = true
	ApplySceneOpacity(window.get_tree().current_scene, UnfocusedOpacity)

static func ApplySceneOpacity(sceneRoot: Node, opacity: float) -> void:
	if sceneRoot == null:
		return

	var renderRoots: Array[CanvasItem] = []
	CollectRenderRoots(sceneRoot, false, renderRoots)
	for root in renderRoots:
		_opacityRoots[root] = root.modulate
		var fadedColor = root.modulate
		fadedColor.a *= opacity
		root.modulate = fadedColor

static func CollectRenderRoots(node: Node, hasCanvasItemAncestor: bool, roots: Array[CanvasItem]) -> void:
	var isCanvasLayer = node is CanvasLayer
	var isCanvasItem = node is CanvasItem
	var inheritsOpacity = hasCanvasItemAncestor and not isCanvasLayer

	if isCanvasItem and not inheritsOpacity:
		roots.append(node as CanvasItem)

	var childHasCanvasItemAncestor = inheritsOpacity or isCanvasItem
	if isCanvasLayer:
		childHasCanvasItemAncestor = false

	for child in node.get_children():
		CollectRenderRoots(child, childHasCanvasItemAncestor, roots)

static func RestoreSceneOpacity() -> void:
	for root in _opacityRoots:
		if is_instance_valid(root):
			(root as CanvasItem).modulate = _opacityRoots[root]
	_opacityRoots.clear()
