extends SceneTree

func _initialize() -> void:
 call_deferred("capture")

func snapshot(path: String) -> void:
 # Explicit draws let CI simulate physics without rendering hundreds of frames
 # through a software GPU. These are actual viewport captures, not mockups.
 RenderingServer.force_draw()
 await process_frame
 RenderingServer.force_draw()
 var image=root.get_texture().get_image()
 assert(image and not image.is_empty(),"Native viewport image must exist")
 assert(image.save_png(path)==OK,"Native viewport capture must save")

func capture() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.best_time=0
 game.show_home()
 for i in 5:
  await process_frame
 var path=OS.get_environment("GITHUB_WORKSPACE")+"/godot/build/"
 DirAccess.make_dir_recursive_absolute(path)
 await snapshot(path+"preview-menu.png")
 game.start_race()
 game.countdown=0
 for i in 120:
  await physics_frame
 await snapshot(path+"preview-race.png")
 game.player.speed=48
 game.player.nitro=100
 Input.action_press("boost")
 for i in 20:
  await physics_frame
 await snapshot(path+"preview-nitro.png")
 Input.action_release("boost")
 game.queue_free()
 await process_frame
 quit()
