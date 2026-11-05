#pragma once

#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/templates/vector.hpp>

using namespace godot;

namespace AeroUtils {
    double log_with_base(const double value, const double base);
    Vector3 v3log_with_base(const Vector3 vector, const double base);
    bool is_of_type(Node* node, const StringName &type);
    Node* get_first_child_of_type(Node* node, const StringName &type);
    void get_descendants_of_type(Node* node, const StringName &type, Vector<Node*> &r_descendants);
    Node3D* create_debug_point_node(const StringName &name, const Color &color, const bool checker, const double width, Node* parent = nullptr);
    Node3D* create_debug_vector_node(const StringName &name, const Color &color, const bool checker, const double width, Node* parent = nullptr);
}
