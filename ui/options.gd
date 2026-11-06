class_name OptionsScreen
extends Control
## Écran des réglages : volumes de la musique et des effets, plein écran.
## Chaque changement est émis tout de suite ; Back ferme l'écran.

signal music_changed(linear: float)
signal sfx_changed(linear: float)
signal fullscreen_changed(enabled: bool)
signal closed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	music_slider.value_changed.connect(music_changed.emit)
	sfx_slider.value_changed.connect(sfx_changed.emit)
	fullscreen_check.toggled.connect(fullscreen_changed.emit)
	back_button.pressed.connect(closed.emit)
	music_slider.grab_focus()


## Pose les valeurs sans émettre de changement.
func set_settings(settings: SettingsStore) -> void:
	music_slider.set_value_no_signal(settings.music_volume)
	sfx_slider.set_value_no_signal(settings.sfx_volume)
	fullscreen_check.set_pressed_no_signal(settings.fullscreen)
