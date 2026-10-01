class_name GodotxToastStyles

const SUCCESS = "success"
const WARNING = "warning"
const INFO = "info"
const ERROR = "error"
const LIGHT = "light"
const DARK = "dark"
const LOADING = "loading"

static var _styles: Dictionary = {}
static var _default_font_path: String = "res://fonts/ithaca-font/Ithaca-LVB75.ttf"
static var _font_cache: Dictionary = {}

static func _static_init():
	_register_builtin_styles()

static func register(id: String, style: GodotxToastStyle) -> void:
	if id.is_empty():
		push_error("GodotxToastStyles: Cannot register style with empty id")
		return
	if style == null:
		push_error("GodotxToastStyles: Cannot register null style for id: %s" % id)
		return
	_styles[id.to_lower()] = style

static func unregister(id: String) -> void:
	_styles.erase(id.to_lower())

static func get_style(id: Variant) -> GodotxToastStyle:
	if id is GodotxToastStyle:
		return id
	if id is String:
		var key = id.to_lower()
		if _styles.has(key):
			return _styles[key]
		push_error("GodotxToastStyles: Style not found: %s" % id)
		return null
	push_error("GodotxToastStyles: Invalid style type: %s" % typeof(id))
	return null

static func has_style(id: String) -> bool:
	return _styles.has(id.to_lower())

static func get_default_font() -> Font:
	if not _font_cache.has("default"):
		var font = load(_default_font_path) if ResourceLoader.exists(_default_font_path) else null
		if font == null:
			font = ThemeDB.get_fallback_font()
		_font_cache["default"] = font
	return _font_cache["default"]

static func clear_font_cache() -> void:
	_font_cache.clear()

static func _register_builtin_styles() -> void:
	var font = get_default_font()
	var wood_texture = load("res://external/fantasy_pixelart_ui/buttons/wood_button_normal.png")
	
	var success = GodotxToastStyle.new()
	success.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	success.background_texture = wood_texture
	success.font = font
	success.font_size = 28
	success.font_color = Color(0.9, 0.85, 0.75)
	success.shadow_color = Color(0, 0, 0, 0.25)
	success.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	register(SUCCESS, success)
	
	var warning = GodotxToastStyle.new()
	warning.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	warning.background_texture = wood_texture
	warning.font = font
	warning.font_size = 28
	warning.font_color = Color(0.9, 0.85, 0.75)
	warning.shadow_color = Color(0, 0, 0, 0.25)
	warning.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	register(WARNING, warning)
	
	var info = GodotxToastStyle.new()
	info.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	info.background_texture = wood_texture
	info.font = font
	info.font_size = 28
	info.font_color = Color(0.9, 0.85, 0.75)
	info.shadow_color = Color(0, 0, 0, 0.25)
	info.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	register(INFO, info)
	
	var error = GodotxToastStyle.new()
	error.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	error.background_texture = wood_texture
	error.font = font
	error.font_size = 28
	error.font_color = Color(0.9, 0.85, 0.75)
	error.shadow_color = Color(0, 0, 0, 0.3)
	error.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	register(ERROR, error)
	
	var light = GodotxToastStyle.new()
	light.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	light.background_texture = wood_texture
	light.font = font
	light.font_size = 28
	light.font_color = Color(0.9, 0.85, 0.75)
	light.shadow_color = Color(0, 0, 0, 0.15)
	light.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	register(LIGHT, light)
	
	var dark = GodotxToastStyle.new()
	dark.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	dark.background_texture = wood_texture
	dark.font = font
	dark.font_size = 28
	dark.font_color = Color(0.9, 0.85, 0.75)
	dark.shadow_color = Color(0, 0, 0, 0.4)
	dark.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	register(DARK, dark)
	
	var loading = GodotxToastStyle.new()
	loading.background_type = GodotxToastEnums.BackgroundType.TEXTURE
	loading.background_texture = wood_texture
	loading.font = font
	loading.font_size = 28
	loading.font_color = Color(0.9, 0.85, 0.75)
	loading.shadow_color = Color(0, 0, 0, 0.4)
	loading.shadow_enabled = true
	loading.default_origin = GodotxToastEnums.ToastOrigin.TOP_RIGHT
	loading.spinner_type = GodotxToastEnums.SpinnerType.DEFAULT
	loading.spinner_tint = Color(0.4, 0.7, 1.0)
	loading.spinner_speed = 1.5
	loading.spinner_size = Vector2(28, 28)
	loading.icon_enabled = true
	loading.icon_size = Vector2(28, 28)
	loading.tap_to_dismiss = false
	loading.swipe_enabled = false
	loading.close_button_enabled = false
	loading.max_visible = 1
	loading.stack_strategy = GodotxToastEnums.StackStrategy.REPLACE_OLDEST
	loading.default_animation = GodotxToastEnums.ToastAnimation.FADE
	register(LOADING, loading)
