#include "aero_utils.h"
#include <algorithm>
#include <cmath>
#include <vector>

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
    
    //the second argument is force_readable_name, so the internal mode has to be passed explicitly
    if (parent) parent->add_child(vector, false, Node::INTERNAL_MODE_FRONT);
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

namespace {
//the tightest box a cloud of points fits in
Vector3 points_extents(const PackedVector3Array &p_points) {
    if (p_points.is_empty()) {
        return Vector3(1, 1, 1);
    }
    
    Vector3 low = p_points[0];
    Vector3 high = p_points[0];
    for (int i = 0; i < p_points.size(); i++) {
        low = low.min(p_points[i]);
        high = high.max(p_points[i]);
    }
    return high - low;
}
} // namespace

//the box a shape measures out to, which is what Godot turns every shape but the box and the sphere into when it wants an
//inertia. the data is the shape's own, read from the server so no shape class has to be bound into the plugin
Vector3 AeroUtils::shape_extents(PhysicsServer3D::ShapeType p_type, const Variant &p_data) {
    switch (p_type) {
        case PhysicsServer3D::SHAPE_BOX: {
            //the server hands back the half extents
            Vector3 half = p_data;
            return Vector3(half.x * 2.0, half.y * 2.0, half.z * 2.0);
        }
        case PhysicsServer3D::SHAPE_SPHERE: {
            double radius = p_data;
            return Vector3(radius * 2.0, radius * 2.0, radius * 2.0);
        }
        case PhysicsServer3D::SHAPE_CAPSULE:
        case PhysicsServer3D::SHAPE_CYLINDER: {
            Dictionary data = p_data;
            double radius = data["radius"];
            double height = data["height"];
            return Vector3(radius * 2.0, height, radius * 2.0);
        }
        case PhysicsServer3D::SHAPE_CONVEX_POLYGON:
            return points_extents(p_data);
        case PhysicsServer3D::SHAPE_CONCAVE_POLYGON:
            return points_extents(Dictionary(p_data)["faces"]);
        default:
            return Vector3(1, 1, 1);
    }
}

//the volume Godot shares the mass out by, in the same order of operations its own shapes use
double AeroUtils::shape_volume(PhysicsServer3D::ShapeType p_type, const Variant &p_data) {
    switch (p_type) {
        case PhysicsServer3D::SHAPE_BOX: {
            Vector3 half = p_data;
            return 8.0 * half.x * half.y * half.z;
        }
        case PhysicsServer3D::SHAPE_SPHERE: {
            double radius = p_data;
            return 4.0 / 3.0 * Math::PI * radius * radius * radius;
        }
        case PhysicsServer3D::SHAPE_CAPSULE: {
            Dictionary data = p_data;
            double radius = data["radius"];
            double height = data["height"];
            return 4.0 / 3.0 * Math::PI * radius * radius * radius + (height - radius * 2.0) * Math::PI * radius * radius;
        }
        case PhysicsServer3D::SHAPE_CYLINDER: {
            Dictionary data = p_data;
            double radius = data["radius"];
            double height = data["height"];
            return height * Math::PI * radius * radius;
        }
        case PhysicsServer3D::SHAPE_CONVEX_POLYGON:
        case PhysicsServer3D::SHAPE_CONCAVE_POLYGON: {
            //a hull is shared out by the box it is drawn in, which is what Godot's own volume falls back to
            Vector3 extents = shape_extents(p_type, p_data);
            return extents.x * extents.y * extents.z;
        }
        default:
            return 0.0;
    }
}

Vector3 AeroUtils::shape_moment_of_inertia(PhysicsServer3D::ShapeType p_type, const Variant &p_data, double p_mass) {
    if (p_type == PhysicsServer3D::SHAPE_SPHERE) {
        double radius = p_data;
        double moment = 0.4 * p_mass * radius * radius;
        return Vector3(moment, moment, moment);
    }
    
    Vector3 half = shape_extents(p_type, p_data) * 0.5;
    return Vector3(
            (p_mass / 3.0) * (half.y * half.y + half.z * half.z),
            (p_mass / 3.0) * (half.x * half.x + half.z * half.z),
            (p_mass / 3.0) * (half.x * half.x + half.y * half.y));
}

Vector3 AeroUtils::body_moment_of_inertia(RigidBody3D *p_body) {
    if (not p_body) {
        return Vector3(1, 1, 1);
    }
    
    PhysicsServer3D *server = PhysicsServer3D::get_singleton();
    RID body = p_body->get_rid();
    
    Vector3 reported = server->body_get_param(body, PhysicsServer3D::BODY_PARAM_INERTIA);
    if (std::isfinite(reported.x) and reported.x > 0.0) {
        return reported;
    }
    
    //the engine leaves out the shapes whose owner is turned off, so their indices are gathered first
    std::vector<int> disabled;
    PackedInt32Array owners = p_body->call("get_shape_owners");
    for (int owner_index = 0; owner_index < owners.size(); owner_index++) {
        int owner = owners[owner_index];
        if (not bool(p_body->call("is_shape_owner_disabled", owner))) {
            continue;
        }
        
        int count = p_body->call("shape_owner_get_shape_count", owner);
        for (int shape_id = 0; shape_id < count; shape_id++) {
            disabled.push_back((int) p_body->call("shape_owner_get_shape_index", owner, shape_id));
        }
    }
    
    std::vector<int> indices;
    std::vector<double> areas;
    double total_area = 0.0;
    const int shape_count = server->body_get_shape_count(body);
    for (int index = 0; index < shape_count; index++) {
        if (std::find(disabled.begin(), disabled.end(), index) != disabled.end()) {
            continue;
        }
        
        RID shape = server->body_get_shape(body, index);
        Vector3 scale = (p_body->get_global_transform() * server->body_get_shape_transform(body, index)).basis.get_scale();
        double area = shape_volume(server->shape_get_type(shape), server->shape_get_data(shape)) * scale.x * scale.y * scale.z;
        if (area <= 0.0) {
            continue;
        }
        
        indices.push_back(index);
        areas.push_back(area);
        total_area += area;
    }
    
    if (total_area <= 0.0) {
        return Vector3(1, 1, 1);
    }
    
    const double mass = p_body->get_mass();
    Vector3 center = p_body->get_center_of_mass();
    if (p_body->get_center_of_mass_mode() == RigidBody3D::CENTER_OF_MASS_MODE_AUTO) {
        center = Vector3();
        for (size_t i = 0; i < indices.size(); i++) {
            double shape_mass = areas[i] * mass / total_area;
            center += server->body_get_shape_transform(body, indices[i]).origin * shape_mass;
        }
        center /= mass;
    }
    
    Basis tensor = Basis(Vector3(), Vector3(), Vector3());
    for (size_t i = 0; i < indices.size(); i++) {
        double shape_mass = areas[i] * mass / total_area;
        RID shape = server->body_get_shape(body, indices[i]);
        Transform3D placement = server->body_get_shape_transform(body, indices[i]);
        
        //the shape's own inertia, turned the way the shape is laid
        Basis facing = placement.basis.orthonormalized();
        Basis shape_inertia = facing * Basis::from_scale(shape_moment_of_inertia(server->shape_get_type(shape), server->shape_get_data(shape), shape_mass)) * facing.transposed();
        
        //and carried out to the center of mass by the parallel axis theorem. the two are added as one sum, in the same order
        //the engine adds them, so the last bit of the answer is the same too
        Vector3 offset = placement.origin - center;
        tensor += shape_inertia + (Basis() * offset.dot(offset) - offset.outer(offset)) * shape_mass;
    }
    
    //an axis set by hand overrides the shapes on that axis
    Vector3 set_inertia = p_body->get_inertia();
    if (set_inertia.x > 0.0) tensor[0][0] = set_inertia.x;
    if (set_inertia.y > 0.0) tensor[1][1] = set_inertia.y;
    if (set_inertia.z > 0.0) tensor[2][2] = set_inertia.z;
    
    //the engine keeps the principal moments, and hands them back through a reciprocal, so the same trip is taken here
    (void) tensor.diagonalize(); //the axes it hands back are not needed, only the moments
    Vector3 principal = tensor.get_main_diagonal().inverse().inverse();
    return principal.x > 0.0 ? principal : Vector3(1, 1, 1);
}
