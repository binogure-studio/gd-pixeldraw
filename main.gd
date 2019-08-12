extends Control

onready var color_picker_node = get_node('container/container/colorPicker')
onready var texture_node = get_node('container/container/container/texture')
onready var brush_button = get_node('container/brushesGroup')

onready var reset_button = get_node('container/container/container/controls/reset')
onready var revert_button = get_node('container/container/container/controls/revert')
onready var save_button = get_node('container/container/container/controls/save')
onready var open_button = get_node('container/container/container/controls/open')

onready var file_dialog_popup = get_node('fileDialog')
onready var file_dialog_open_popup = get_node('fileDialogOpen')
onready var warning_popup = get_node('warningPopup')

var current_color = null

func _ready():
  file_dialog_popup.set_current_dir(OS.get_system_dir(OS.SYSTEM_DIR_PICTURES))
  file_dialog_open_popup.set_current_dir(OS.get_system_dir(OS.SYSTEM_DIR_PICTURES))

  color_picker_node.connect('color_changed', self, '_update_color')
  brush_button.connect('button_selected', self, '_update_mouse_cursor')

  reset_button.connect('pressed', texture_node, 'reset_image', [], CONNECT_DEFERRED)
  revert_button.connect('pressed', texture_node, 'revert_image', [], CONNECT_DEFERRED)

  save_button.connect('pressed', file_dialog_popup, 'set_hidden', [false])
  save_button.connect('pressed', file_dialog_popup, '_update_file_list', [], CONNECT_DEFERRED)

  file_dialog_popup.connect('file_selected', self, 'popup_closed', ['save_texture'])

  open_button.connect('pressed', file_dialog_open_popup, 'set_hidden', [false])
  open_button.connect('pressed', file_dialog_open_popup, '_update_file_list', [], CONNECT_DEFERRED)

  file_dialog_open_popup.connect('file_selected', self, 'popup_closed', ['open_texture'])

  texture_node.set_default_cursor_shape(Control.CURSOR_POINTING_HAND)

  set_preset_colors()
  _update_color()
  _update_mouse_cursor()

func popup_closed(file_path, action = 'open_texture'):
  if file_path != null:
    if texture_node.call(action, file_path) != OK:
      warning_popup.set_text('%s:\n %s' % [tr('LABEL_CANNOT_OPEN_FILE'), file_path])
      warning_popup.set_hidden(false)

func set_preset_colors():
  # White
  color_picker_node.add_preset(Color('#fefefe'))

  # Black
  color_picker_node.add_preset(Color('#222831'))

  # Blue
  color_picker_node.add_preset(Color('#6aacc1'))

  # Brown
  color_picker_node.add_preset(Color('#624324'))

  # Green
  color_picker_node.add_preset(Color('#7aa140'))

  # Red
  color_picker_node.add_preset(Color('#b15252'))

  # Yellow
  color_picker_node.add_preset(Color('#e8bd44'))

func _update_color(arg0 = null):
  current_color = color_picker_node.get_color()

  texture_node.set_color(current_color)

  var button_list = brush_button.get_button_list()

  for button in button_list:
    button.set_modulate(current_color)

  _update_mouse_cursor()

func _update_mouse_cursor(arg0 = null):
  var pressed_button = brush_button.get_pressed_button()
  var current_brush = pressed_button.get_normal_texture()
  var computed_brush = Image(current_brush.get_width(), current_brush.get_height(), false, current_brush.get_format())
  var image_texture = ImageTexture.new()

  for y_value in range(0, current_brush.get_height()):
    for x_value in range(0, current_brush.get_width()):
      var computed_color = current_brush.get_data().get_pixel(x_value, y_value)

      computed_color.b = current_color.b
      computed_color.g = current_color.g
      computed_color.r = current_color.r

      computed_brush.put_pixel(x_value, y_value, computed_color)

  image_texture.create_from_image(computed_brush)
  image_texture.set_flags(Texture.FLAG_MIPMAPS)

  texture_node.set_brush(image_texture)
  Input.set_custom_mouse_cursor(image_texture, Control.CURSOR_POINTING_HAND, image_texture.get_size() / 2.0)
