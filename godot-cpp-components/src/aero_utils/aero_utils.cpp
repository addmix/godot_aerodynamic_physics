#include "aero_utils.h"

using namespace godot;

double AeroUtils::log_with_base(double value, double base) {
    return log(value) / log(base);
}
Vector3 AeroUtils::v3log_with_base(Vector3 vector, double base) {
    return vector.normalized() * AeroUtils::log_with_base(vector.length() + 1, base);
}

bool AeroUtils::is_of_type(Node* node, const StringName &type) {
    if (not node) return false;
    if (node->is_class(type)) return true;

    Ref<Script> script = node->get_script();
    while (script.is_valid()) {
        if (script->get_global_name() == type) return true;
        script = script->get_base_script();
    }
    return false;
}
Node* AeroUtils::get_first_child_of_type(Node* node, const StringName &type) {
    if (not node) return nullptr;

    TypedArray<Node> children = node->get_children();
    for (int i = 0; i < children.size(); i++) {
        Node* child = Object::cast_to<Node>(children[i]);
        if (AeroUtils::is_of_type(child, type)) return child;
    }
    return nullptr;
}
void AeroUtils::get_descendants_of_type(Node* node, const StringName &type, Vector<Node*> &r_descendants) {
    if (not node) return;

    TypedArray<Node> children = node->get_children();
    for (int i = 0; i < children.size(); i++) {
        Node* child = Object::cast_to<Node>(children[i]);
        if (not child) continue;
        if (AeroUtils::is_of_type(child, type)) r_descendants.push_back(child);
        AeroUtils::get_descendants_of_type(child, type, r_descendants);
    }
}

static Node3D* create_debug_node(const Ref<Script> &script, const StringName &name, const Color &color, bool checker, double width, Node* parent) {
    Node3D *vector = memnew(MeshInstance3D);
    vector->set_script(script);
    vector->set_name(name);
    vector->set("color", color);
    vector->set("checker", checker);
    vector->set("width", width);

    if (parent) parent->add_child(vector, Node::INTERNAL_MODE_FRONT);
    return vector;
}

Node3D* AeroUtils::create_debug_point_node(const StringName &name, const Color &color, bool checker, double width, Node* parent) {
    Ref<Script> point_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/point_3d/point_3d.gd");
    return create_debug_node(point_script, name, color, checker, width, parent);
}
Node3D* AeroUtils::create_debug_vector_node(const StringName &name, const Color &color, bool checker, double width, Node* parent) {
    Ref<Script> vector_script = ResourceLoader::get_singleton()->load("res://addons/godot_aerodynamic_physics/utils/vector_3d/vector_3d.gd");
    return create_debug_node(vector_script, name, color, checker, width, parent);
}
