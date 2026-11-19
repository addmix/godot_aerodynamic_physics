@tool
extends TextureRect
class_name LoadingSpinner

@export var frames : Array[Texture2D] = []:
	set(x):
		frames = x
		restart()
@export var frames_per_second : float = 8.0

var frame : int = 0
var tick_timer : SceneTreeTimer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _enter_tree() -> void:
	restart()

func _ready() -> void:
	if Engine.is_editor_hint() and frames.is_empty(): load_editor_frames()
	restart()

func _notification(what : int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED: return
	
	if is_visible_in_tree(): restart()
	else: stop_ticking()


func advance_frame() -> void:
	tick_timer = null
	if frames.is_empty(): return
	
	frame = (frame + 1) % frames.size()
	texture = frames[frame]
	tick()

func tick() -> void:
	if tick_timer != null or not is_inside_tree() or not is_visible_in_tree(): return
	
	tick_timer = get_tree().create_timer(1.0 / frames_per_second)
	tick_timer.timeout.connect(advance_frame)

func stop_ticking() -> void:
	if tick_timer == null: return
	
	tick_timer.timeout.disconnect(advance_frame)
	tick_timer = null


func load_editor_frames() -> void:
	var editor_theme : Theme = EditorInterface.get_editor_theme()
	var editor_frames : Array[Texture2D] = []
	for index : int in 8:
		editor_frames.append(editor_theme.get_icon("Progress%d" % (index + 1), "EditorIcons"))
	frames = editor_frames

func restart() -> void:
	frame = 0
	if not frames.is_empty(): texture = frames[0]
	tick()
