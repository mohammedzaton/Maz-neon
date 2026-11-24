extends SceneTree
func _initialize() -> void:
 call_deferred("capture")
func capture() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.best_time = 0
 game.show_home()
 for i in 50:
  await process_frame
 await RenderingServer.frame_post_draw
 var path = OS.get_environment("GITHUB_WORKSPACE")+"/godot/build/"
 DirAccess.make_dir_recursive_absolute(path)
 var image = root.get_texture().get_image()
 if image and not image.is_empty():
  image.save_png(path+"preview-menu.png")
 game.start_race()
 game.countdown = 0
 for i in 120:
  await physics_frame
 await RenderingServer.frame_post_draw
 image = root.get_texture().get_image()
 print("TELEMETRY ",game.hud.speed_label.text," position ",game.hud.speed_label.global_position)
 if image and not image.is_empty():
  image.save_png(path+"preview-race.png")
 game.player.speed=48
 game.player.nitro=100
 Input.action_press("boost")
 for i in 20:
  await physics_frame
 await RenderingServer.frame_post_draw
 image=root.get_texture().get_image()
 if image and not image.is_empty():
  image.save_png(path+"preview-nitro.png")
 Input.action_release("boost")
 game.queue_free()
 await process_frame
 quit()
