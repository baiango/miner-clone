@tool
extends Node

# [Scene -> Reload Saved Scene] to run the script
# Alt+tab 2 times to let Godot import the image
# Please use WebP instead of JPG or PNG to stop trashing your friend's bandwidth
enum WebPQuality { Low, High, Lossless }
var Webp_quality_set := WebPQuality.Lossless

var image: Texture2D = load("res://image/blocks.png")
const cache_path_prefix := "res://cache/texture_atlas/"
const DIMENSION := 32 # Square only!

func _ready():
	if not image: return
	var img := image.get_image()

	var webp_lossless := false
	var webp_quality := 0.50

	if Webp_quality_set == WebPQuality.Low:
		webp_lossless = false
		webp_quality = 0.50 # Go even lower won't help you with file size, and it looks muddy
	if Webp_quality_set == WebPQuality.High:
		webp_lossless = false
		webp_quality = 0.80 # Better off using lossless if you want go higher than 80
	if Webp_quality_set == WebPQuality.Lossless:
		webp_lossless = true
		webp_quality = 1.0 # Use it for pixel art

	var img_out := Image.create(DIMENSION, DIMENSION, false, Image.FORMAT_RGBA8)

	for x in img.get_width() / DIMENSION:
		for y in img.get_height() / DIMENSION:

			for px in DIMENSION:
				for py in DIMENSION:
					img_out.set_pixel(px, py, img.get_pixel(px + (x * DIMENSION), py + (y * DIMENSION)))

			var cache_path := "".join([cache_path_prefix, x + (y * img.get_width() / DIMENSION), ".webp"])
			img_out.save_webp(cache_path, webp_lossless, webp_quality)
