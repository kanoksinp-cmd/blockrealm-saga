extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var folder:=OS.get_environment("BR_OUTPUT")
 var entries:Array=[]
 for name in ["ui_font","ui_font_bold","ui_font_title"]:
  var variation=load("res://assets/fonts/"+name+".tres")
  var font:FontFile=variation.base_font
  var original:=font.resource_path
  print("FONT_BEFORE ",name," ",original," oversampling=",font.oversampling," hinting=",font.hinting," subpixel=",font.subpixel_positioning)
  font.antialiasing=TextServer.FONT_ANTIALIASING_GRAY
  font.hinting=TextServer.HINTING_NORMAL
  font.force_autohinter=true
  font.oversampling=2.0
  font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_AUTO
  font.generate_mipmaps=false
  var resource:String="res://assets/fonts/crisp_"+name+".res"
  var file:=folder.path_join(resource.trim_prefix("res://"))
  DirAccess.make_dir_recursive_absolute(file.get_base_dir())
  var error:=ResourceSaver.save(font,file,ResourceSaver.FLAG_COMPRESS)
  assert(error==OK,"font save failed "+str(error))
  entries.append({"name":name,"resource":resource,"oversampling":font.oversampling,"hinting":font.hinting,"subpixel":font.subpixel_positioning})
 var output=FileAccess.open(folder.get_base_dir().path_join("font_manifest.json"),FileAccess.WRITE);output.store_string(JSON.stringify(entries,"  "));output.close()
 print("PASS_FONT_RESOURCES saved three oversampled hinted UI fonts")
 quit()
