#include "register_types.h"

#include "aero_units/aero_units.h"

#include "aero_body_3d/aero_body_3d.h"
#include "aero_influencer_3d/aero_influencer_3d.h"
#include "aero_influencer_3d/aero_surface_3d/aero_surface_config.h"
#include "aero_influencer_3d/aero_surface_3d/aero_surface_3d.h"
#include "aero_influencer_3d/aero_surface_3d/manual_aero_surface_config.h"
#include "aero_influencer_3d/aero_surface_3d/manual_aero_surface.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static AeroUnits *aero_units;

void initialize_gdextension_types(ModuleInitializationLevel p_level)
{
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	GDREGISTER_ABSTRACT_CLASS(AeroUnits);
	aero_units = memnew(AeroUnits);
	Engine::get_singleton()->register_singleton("AeroUnits", AeroUnits::get_singleton());

	GDREGISTER_CLASS(AeroBody3D);
	GDREGISTER_CLASS(AeroInfluencer3D);
	GDREGISTER_CLASS(AeroSurfaceConfig);
	GDREGISTER_CLASS(AeroSurface3D);
	GDREGISTER_CLASS(ManualAeroSurfaceConfig);
	GDREGISTER_CLASS(ManualAeroSurface3D);
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C"
{
	// Initialization
	GDExtensionBool GDE_EXPORT example_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
	{
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_gdextension_types);
		init_obj.register_terminator(uninitialize_gdextension_types);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

		return init_obj.init();
	}
}