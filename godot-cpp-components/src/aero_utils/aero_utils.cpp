#include "aero_utils.h"

using namespace godot;

double AeroUtils::log_with_base(const double value, const double base) {
    return log(value) / log(base);
}
Vector3 AeroUtils::v3log_with_base(const Vector3 vector, const double base) {
    return vector.normalized() * AeroUtils::log_with_base(vector.length() + 1, base);
}
