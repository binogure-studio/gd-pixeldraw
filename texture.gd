extends TextureFrame

const GRID_THICKNESS = 1.0
const GRID_COLOR = Color('#959595')
const HISTORY_MAX_SIZE = 16

export(int, 0, 2048) var image_height = 128
export(int, 0, 2048) var image_width = 128

var image_loader = Image(image_width, image_height, false, Image.FORMAT_RGBA)
var current_image = Image(image_width, image_height, false, Image.FORMAT_RGBA)
var current_color = Color('#ffffff')
var current_brush = null
var current_brush_texture = ImageTexture.new()
var current_brush_mouse_decal = Vector2(0.0, 0.0)
var image_texture = ImageTexture.new()
var image_scaled = 1.0
var button_pressed = false
var image_history = []
var show_grid = false
var last_pixel_pos = Vector2(0.0, 0.0)

func _ready():
  image_scaled = image_width / get_size().x

  _initialize_image()

  connect('mouse_enter', self, 'set_process_input', [true])
  connect('mouse_exit', self, 'set_process_input', [false])

  set_process_unhandled_key_input(true)

func set_color(color):
  current_color = color

func set_brush(brush):
  current_brush = brush.get_data()

  var brush_size = Vector2(current_brush.get_width() * 1.0 / image_scaled, current_brush.get_height() * 1.0 / image_scaled)

  current_brush_texture.create_from_image(current_brush.resized(brush_size.x, brush_size.y))
  current_brush_mouse_decal = brush_size / 2.0

func reset_image():
  var old_brush = current_brush
  var old_color = current_color

  if image_history.size() < 2:
    return

  current_color = Color('#ffffff')
  current_brush = null

  _initialize_image()

  current_color = old_color
  current_brush = old_brush

func _draw():
  if show_grid:
    var image_size = get_size()
    var column_interval = image_size.x / image_width * 1.0
    var row_interval = image_size.y / image_height * 1.0

    # Draw horizontal lines
    for row in range(0, image_height):
      var from = Vector2(0.0, row * row_interval)
      var to = Vector2(image_size.x, row * row_interval)

      draw_line(from, to, GRID_COLOR, GRID_THICKNESS)

    # Draw vertical lines
    for column in range(0, image_width):
      var from = Vector2(column * column_interval, 0.0)
      var to = Vector2(column * column_interval, image_size.y)

      draw_line(from, to, GRID_COLOR, GRID_THICKNESS)

  if is_processing_input():
    var texture_pos = get_local_mouse_pos() - current_brush_mouse_decal

    texture_pos.x = round(texture_pos.x - (int(texture_pos.x) % int(round(1.0 / image_scaled))))
    texture_pos.y = round(texture_pos.y - (int(texture_pos.y) % int(round(1.0 / image_scaled))))

    last_pixel_pos = get_local_mouse_pos() * image_scaled
    draw_texture(current_brush_texture, texture_pos, Color('#ffffff'))

func toggle_grid(toggled):
  show_grid = toggled
  update()

func save_texture(file_path):
  current_image.save_png(file_path)

  return OK

func open_texture(file_path):
  var image_texture = image_loader.load(file_path)

  if image_texture == OK:
    current_image = image_loader.resized(image_width, image_height)
    _refresh_image()
    save_image()

  return image_texture

func get_custom_scale():
  return Vector2(1.0 / image_scaled, 1.0 / image_scaled)

func _initialize_image():
  image_history = []

  for y_value in range(0, image_height):
    for x_value in range(0, image_width):
      set_pixel(x_value, y_value, false)

  _refresh_image()
  save_image()

func _unhandled_key_input(key_event):
  _input(key_event)

func _input(event):
  if event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT:
    if button_pressed != event.pressed and button_pressed == true:
      save_image()

    button_pressed = event.pressed
    accept_event()

  if button_pressed and (event.type == InputEvent.MOUSE_BUTTON or event.type == InputEvent.MOUSE_MOTION):
    if last_pixel_pos.y < image_height and last_pixel_pos.x < image_width and \
      last_pixel_pos.y >= 0 and last_pixel_pos.x >= 0:
      set_pixel(last_pixel_pos.x, last_pixel_pos.y)
      accept_event()

  if event.type == InputEvent.MOUSE_MOTION:
    update()

  if event.is_action_pressed('ui_revert'):
    revert_image()
    accept_event()

func set_pixel(x_value, y_value, refresh_image = true):
  if current_brush != null:
    var rect2 = Rect2(Vector2(0.0, 0.0), Vector2(current_brush.get_width(), current_brush.get_height()))
    var pos = Vector2(x_value, y_value) - (rect2.size / 2.0)

    current_image.blend_rect(current_brush, rect2, pos)
  else:
    current_image.put_pixel(x_value, y_value, current_color)

  if refresh_image:
    _refresh_image()

func revert_image():
  if image_history.size() > 1:
    image_history.pop_front()

    current_image = image_history[0]
    _refresh_image()

func save_image():
  image_history.push_front(current_image)

  while image_history.size() > HISTORY_MAX_SIZE:
    image_history.pop_back()

func _refresh_image():
  image_texture.create_from_image(current_image)
  image_texture.set_flags(Texture.FLAG_MIPMAPS)

  set_texture(image_texture)
