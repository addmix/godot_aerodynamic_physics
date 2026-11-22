# From https://github.com/addmix/godot_utils
@tool

# TODO: implement some dependency checker
func check_dependencies() -> void:

	pass

#wip
# NOTICE: Untested
static func get_enabled_plugins() -> Array:
	return ProjectSettings["editor_plugins/enabled"]

## Returns a list of plugins and the information within their config files.
static func get_plugin_list() -> Array:
	var plugins := []
	for directory in DirAccess.get_directories_at("res://addons"):
		var path := "res://addons/%s/plugin.cfg" % directory
		if FileAccess.file_exists(path):
			var config := ConfigFile.new()
			var err := config.load(path)

			# TODO: Adjust this to be dynamic, to allow arbitrary info to be saved/loaded in plugin.cfg
			plugins.append({
				"name": config.get_value("plugin", "name", ""),
				"description": config.get_value("plugin", "description", ""),
				"author": config.get_value("plugin", "author", ""),
				"version": config.get_value("plugin", "version", ""),
				"script": config.get_value("plugin", "script", ""),
				"path": path.get_base_dir()
			})

	return plugins

## Returns a formatted dictionary of plugins and their properties.
static func get_plugin_dictionary() -> Dictionary:
	var plugin_dictionary := {}
	
	var list := get_plugin_list()
	for plugin in list:
		plugin_dictionary[plugin["name"]] = plugin
	
	return plugin_dictionary

#very slow, use sparingly.
## Returns the installation path of the given plugin.
static func get_plugin_path(plugin_name : String) -> String:
	var dictionary := get_plugin_dictionary()
	if not dictionary.has(plugin_name):
		push_error("Plugin name not found in plugin dictionary.")
	return dictionary[plugin_name ]["path"]
