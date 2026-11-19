#pragma once

#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/rigid_body3d.hpp>
#include <godot_cpp/classes/physics_server3d.hpp>
#include <godot_cpp/classes/script.hpp>
#include <godot_cpp/classes/mesh_instance3d.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/templates/vector.hpp>

using namespace godot;

namespace AeroUtils {
    double log_with_base(double value, double base);
    Vector3 v3log_with_base(Vector3 vector, double base);
    bool is_of_type(Node* node, const StringName &type);
    Node* get_first_child_of_type(Node* node, const StringName &type);
    void get_descendants_of_type(Node* node, const StringName &type, Vector<Node*> &r_descendants);
    Node3D* create_debug_point_node(const StringName &name, const Color &color, bool checker, double width, Node* parent = nullptr);
    Node3D* create_debug_vector_node(const StringName &name, const Color &color, bool checker, double width, Node* parent = nullptr);
    
    //mass properties: the box and inertia of a collision shape, and the inertia a body turns with
    Vector3 shape_extents(PhysicsServer3D::ShapeType p_type, const Variant &p_data);
    double shape_volume(PhysicsServer3D::ShapeType p_type, const Variant &p_data);
    Vector3 shape_moment_of_inertia(PhysicsServer3D::ShapeType p_type, const Variant &p_data, double p_mass);
    Vector3 body_moment_of_inertia(RigidBody3D *p_body);
}
