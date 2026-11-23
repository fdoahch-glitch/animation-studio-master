extends SceneTree

const RESOURCE_LIBRARY = preload("res://scripts/resource_library.gd")
const SCENE_MODEL = preload("res://scripts/scene_composition_model.gd")

func _initialize() -> void:
	var source_path := "user://resource_scene_integration_source.png"
	var image := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color("#4b9b62"))
	assert(image.save_png(source_path) == OK, "Debe crear el recurso de prueba")

	var library = RESOURCE_LIBRARY.new()
	var imported: Dictionary = library.import_file(source_path, "background", "Fondo de prueba", ["bosque", "demo"], "2D")
	assert(imported.get("ok", false), "La biblioteca debe importar el recurso")
	var resource: Dictionary = imported.resource
	assert(library.validate_resource(resource).get("ok", false), "El registro importado debe validar")

	var composition = SCENE_MODEL.new()
	var scene := {"id":"scene_library_link","name":"Escena de integración","objects":[],"transitions":{}}
	var instance: Dictionary = composition.create_instance(str(resource.id), str(resource.category), str(resource.name), Vector2(120, 80))
	assert(not instance.is_empty(), "Debe crear una instancia desde el recurso importado")
	assert(instance.resource_id == resource.id, "La instancia debe conservar el ID estable del recurso")
	assert(composition.add_instance(scene, instance).get("ok", false), "Debe añadir el recurso a la escena")
	assert(composition.validate_scene(scene).get("ok", false), "La escena con recurso vinculado debe validar")

	var references: Array = composition.find_resource_references([scene], str(resource.id))
	assert(references.size() == 1, "La escena debe registrar una referencia reutilizable al recurso")
	assert(references[0].instance_id == instance.id, "La referencia debe apuntar a la instancia correcta")

	var second_instance: Dictionary = composition.create_instance(str(resource.id), str(resource.category), "Otra instancia", Vector2(240, 80))
	assert(composition.add_instance(scene, second_instance).get("ok", false), "El mismo recurso debe poder reutilizarse")
	assert(composition.find_resource_references([scene], str(resource.id)).size() == 2, "Debe localizar todas las instancias que comparten el recurso")

	assert(library.remove_resource(resource).get("ok", false), "La biblioteca debe eliminar el archivo gestionado")
	assert(not FileAccess.file_exists(str(resource.path)), "El archivo gestionado debe desaparecer")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
	print("RESOURCE_SCENE_INTEGRATION_TESTS_OK")
	quit(0)
