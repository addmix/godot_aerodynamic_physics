# From https://github.com/addmix/godot_utils

## Euler's number (not to be confused with Euler's constant)
const E := 2.718281828459045235360287471352



# type-less functions

## Returns the derivative (rate of change) of the provided values, given the current value, previous value, and the timestep between them.
static func derivative_of(current : Variant, previous : Variant, delta : float) -> Variant:
	return (current - previous) / delta

## An alternative syntax for ternary if/else.
static func toggle(condition : bool, _true : Variant, _false : Variant) -> Variant:
	if condition:
		return _true
	else:
		return _false



#float math functions



static func bias(x : float, bias : float) -> float:
	var f : float = 1 - bias
	var k : float = f * f * f
	return (x * k) / (x * k - x + 1)

## Similar to [code]@GlobalScope.ease()[/code], except it works for negative numbers. The sign of the input will be the same as the sign of the output.[br]
static func improved_ease(value : float, curve : float = 1.0) -> float:
	return ease(abs(value), curve) * sign(value)


#branchlessly toggles a float between two values given a condition
## Type-safe version of [code]toggle()[/code]
static func float_toggle(condition : bool, _true : float, _false : float) -> float:
	return float(condition) * _true + float(!condition) * _false

## This is a logarithm function that allows a base to be specified. [br]
## [code]@GlobalScope.log()[/code] returns the natural logarithm of the given number. (Logarithm of base e, approx 2.718. See: [code]E[/code])
static func log_with_base(value : float, base : float) -> float:
	return log(value) / log(base)


# TEST: not sure if this math is correct.
static func mix(a : float, b : float, amount : float) -> float:
	return (a - amount) * a + amount * b

## DEPRECATED: Use [code]@GlobalScope.move_toward()[/code]
static func move_to(position : float, target : float, speed : float = 1.0) -> float:
	var direction : float = sign(target - position)
	var new_position = position + direction * speed
	var new_direction : float = sign(target - new_position)

	return float_toggle(direction == new_direction, new_position, target)

## Checks if [code]number[/code] can be evenly divided by [code]multiple[/code], with a [code]tolerance[/code] that allows for slight inaccuracies.
# TODO: Should tolerance be used as a percentage tolerance, rather than a flat number?
static func number_is_divisible_with_tolerance(number : float, multiple : float, tolerance : float) -> bool:
	var multiple_of_32 = number / multiple 
	var absolute_difference : float = abs(multiple_of_32 - round(multiple_of_32)) * multiple
	return absolute_difference <= tolerance or is_equal_approx(absolute_difference, tolerance)

#smooth minimum
# https://iquilezles.org/articles/smin/
static func polynomial_smin(a : float, b : float, k : float =0.1) -> float:
	var h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0)
	return mix(a, b, h) - k * h * (1.0 - h)

## Sigmoid easing function.
static func sigmoid(x : float, e : float = E) -> float:
	return pow(e, x) / pow(e, x) + 1.0



#



static func v3log_with_base(vector : Vector3, base : float) -> Vector3:
	return vector.normalized() * log_with_base(vector.length() + 1, base)

static func max_magnitude(v1 : Vector3, v2 : Vector3) -> Vector3:
	return abs(v1).max(abs(v2))



#matrix math stuff, very inefficient stuff



#unused
static func check_squareness(a : Array) -> void:
	if a.size() != a[0].size():
		push_error("Matrix not square")

static func identity_matrix(n : int) -> Array:
	var matrix := []

	for y in range(n):
		var row := []
		for x in range(n):
			row.append(int(y == x))
		matrix.append(row)

	return matrix

#https://integratedmlai.com/matrixinverse/
static func inverse(a : Array) -> Array:
	var n := a.size()
	var am := a.duplicate(true)
	var I = identity_matrix(n)
	var im = I.duplicate(true)

	for fd in range(n):
		var fdScaler : float = 1.0 / am[fd][fd]

		for j in range(n):
			am[fd][j] *= fdScaler
			im[fd][j] *= fdScaler

		for i in range(n):
			if i == fd:
				continue

			var crScaler : float = am[i][fd]
			for j in range(n):
				am[i][j] = am[i][j] - crScaler * am[fd][j]
				im[i][j] = im[i][j] - crScaler * im[fd][j]

	return im

static func multiply(a : Array, b : Array) -> Array:
	var matrix := zero_matrix(a.size(), b[0].size())

	for i in range(a.size()):
		for j in range(b[0].size()):
			for k in range(a[0].size()):
				matrix[i][j] = matrix[i][j] + a[i][k] * b[k][j]
	return matrix

#plane intersection fucntion
#http://tbirdal.blogspot.com/2016/10/a-better-approach-to-plane-intersection.html
static func ray_plane_intersection(p1 : Vector3, n1 : Vector3, p2 : Vector3, n2 : Vector3, p0 : Vector3) -> Array[Vector3]:

	var M := [
		[2, 0, 0, n1.x, n2.x],
		[0, 2, 0, n1.y, n2.y],
		[0, 0, 2, n1.z, n2.z],
		[n1.x, n1.y, n1.z, 0, 0],
		[n2.x, n2.y, n2.z, 0, 0]]

	var bx := p1 * n1
	var by := p2 * n2

	var b4 := bx.x + bx.y + bx.z
	var b5 := by.x + by.y + by.z

	var b = [
		[2*p0.x],
		[2*p0.y],
		[2*p0.z],
		[b4],
		[b5]]

# warning-ignore:unused_variable
	var x := multiply(inverse(M), b)
	var p = Vector3(x[0][0], x[0][1], x[0][2])
	var n = n1.cross(n2)
	return [p, n]

#matrix multiplication funcs
#https://godotengine.org/qa/41768/matrix-matrix-vector-multiplication
static func zero_matrix(nX : int, nY : int) -> Array:
	var matrix := []
	for x in range(nX):
		matrix.append([])
# warning-ignore:unused_variable
		for y in range(nY):
			matrix[x].append(0)
	return matrix
