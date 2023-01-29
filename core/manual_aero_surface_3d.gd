@tool
extends AeroSurface3D
class_name ManualAeroSurface3D

@export var manual_config := ManualAeroSurfaceConfig.new()

func calculate_forces(_world_air_velocity : Vector3, _air_density : float, _air_pressure : float, _relative_position : Vector3, _altitude : float) -> PackedVector3Array:
	super.calculate_forces(_world_air_velocity, _air_density, _air_pressure, _relative_position, _altitude)

	var force := Vector3.ZERO
	var torque := Vector3.ZERO

	var aerodynamic_coefficients : Vector3 = calculate_curve_coefficients()
	var lift_coefficient : float = manual_config.lift_aoa_curve.sample(angle_of_attack / PI / 2.0 + 0.5)
	var lift : float = dynamic_pressure * wing_config.chord * wing_config.span * lift_coefficient
	var form_drag : float = dynamic_pressure * projected_wing_area * manual_config.drag_aoa_curve.sample(angle_of_attack / PI / 2.0 + 0.5) * wing_config.sweep_drag_multiplier_curve.sample(sweep_angle) * wing_config.drag_at_mach_multiplier_curve.sample(mach / 10.0)
	var induced_drag : float = lift * lift / (0.5 * dynamic_pressure * PI * wing_config.span * wing_config.span)
#	this still needs a lot of work. Reynolds number is relevant here
#	https://en.wikipedia.org/wiki/Skin_friction_drag
	var skin_friction_drag : float = wing_config.skin_friction * dynamic_pressure

	var _torque : Vector3 = global_transform.basis.x * aerodynamic_coefficients.z * dynamic_pressure * area * wing_config.chord


	var total_drag = form_drag + induced_drag + skin_friction_drag
#	print("Percentages of total drag:\nSkin friction: %s\nForm drag: %s\nInduced drag: %s" % [skin_friction_drag / total_drag, form_drag / total_drag, induced_drag / total_drag])

	var lift_vector : Vector3 = lift * lift_direction
#	if name == "WingL":
#		print(lift_direction)
	var drag_vector : Vector3 = Vector3.ZERO #drag_direction * form_drag# + skin_friction_drag)

	force = lift_vector# + drag_vector
	torque += relative_position.cross(force)
	torque += _torque

	_current_lift = lift_vector
	_current_drag = drag_vector
	_current_torque = torque

	return PackedVector3Array([force, torque])



func calculate_curve_coefficients() -> Vector3:
	var aerodynamic_coefficients : Vector3

	#lift
	aerodynamic_coefficients.x = manual_config.lift_aoa_curve.sample(angle_of_attack)
	#drag
	aerodynamic_coefficients.y = manual_config.drag_aoa_curve.sample(angle_of_attack)
	#torque

	return aerodynamic_coefficients


#// Token: 0x06001C9A RID: 7322 RVA: 0x000B3F70 File Offset: 0x000B2170
#	public void BPU_FixedUpdate()
#	{
#		if (!this.rb.isKinematic)
#		{
#			Vector3 vector = this.rb.worldCenterOfMass + this.rb.transform.TransformVector(this.manualOffset);
#			Vector3 up = this.wingTransform.up;
#			Quaternion rotation = Quaternion.identity;
#			if (this.usePhaseLag)
#			{
#				Vector3 vector2 = this.rb.worldCenterOfMass + (this.phaseLagAxis.position - this.rb.transform.TransformPoint(this.rb.centerOfMass));
#				Vector3 point = vector - vector2;
#				rotation = Quaternion.AngleAxis(this.phaseLagAngle, this.phaseLagAxis.forward);
#				vector = vector2 + rotation * point;
#			}
#			Vector3 vector3;
#			if (this.usePointVelocity)
#			{
#				vector3 = this.rb.GetPointVelocity(vector);
#			}
#			else
#			{
#				vector3 = this.rb.velocity;
#			}
#			if (this.useRotorVelocity)
#			{
#				vector3 += this.rotorVelocity;
#			}
#			if (WindVolumes.windEnabled)
#			{
#				if (!this.windMaster)
#				{
#					this.windMaster = this.rb.gameObject.GetComponent<WindMaster>();
#					if (!this.windMaster)
#					{
#						this.windMaster = this.rb.gameObject.AddComponent<WindMaster>();
#					}
#				}
#				vector3 -= this.windMaster.wind;
#			}
#			float sqrMagnitude = vector3.sqrMagnitude;
#			float num = Mathf.Sqrt(sqrMagnitude);
#			this.wingAirspeed = num;
#			if (!this.cullAtMinAirspeed || sqrMagnitude > 400f)
#			{
#				float num2 = AerodynamicsController.fetch.AtmosDensityAtPosition(vector);
#				float num3 = Vector3.Angle(up, vector3) - 90f;
#				this.currAoA = num3;
#				float time = Mathf.Abs(num3);
#				float num4 = num2 * sqrMagnitude;
#				float num5 = (this.aeroProfile.mirroredCurves ? this.aeroProfile.liftCurve.Evaluate(time) : this.aeroProfile.liftCurve.Evaluate(num3));
#				float num6 = this.liftConstant * num4 * Mathf.Sign(num3) * num5;
#				float num7 = (this.aeroProfile.mirroredCurves ? this.aeroProfile.dragCurve.Evaluate(time) : this.aeroProfile.dragCurve.Evaluate(num3));
#				float num8 = this.dragConstant * num4 * num7;
#				float sweep = this.CalculateSweep(vector3);
#				if (this.debugSweep)
#				{
#					this.currDynamicSweep = sweep;
#				}
#				num8 *= AerodynamicsController.fetch.DragMultiplierAtSpeedAndSweep(num, WaterPhysics.GetAltitude(vector), sweep);
#				Vector3 vector4;
#				if (this.useOverrideLiftDir)
#				{
#					vector4 = this.overrideLiftDir.transform.forward;
#				}
#				else
#				{
#					vector4 = (this.aeroProfile.perpLiftVector ? Vector3.Cross(vector3, Vector3.Cross(up, vector3)) : up);
#				}
#				this.dragVector = num8 * vector3.normalized;
#				this.liftVector = num6 * vector4.normalized;
#				Vector3 vector5 = this.dragVector + this.liftVector;
#				if (this.usePhaseLag)
#				{
#					vector5 = rotation * (this.liftVector + this.dragVector);
#				}
#				this.currentLiftForce = num6;
#				this.currentDragForce = num8;
#				if (this.useBuffet)
#				{
#					Vector3 b = VectorUtils.FullRangePerlinNoise(this.buffetRand, Time.time * sqrMagnitude * this.aeroProfile.buffetTimeFactor) * this.aeroProfile.buffetCurve.Evaluate(num3) * this.aeroProfile.buffetMagnitude * sqrMagnitude * this.liftArea * up;
#					vector5 += b;
#				}
#				this.rb.AddForceAtPosition(vector5, vector);
#				if (this.hasSoundEffects)
#				{
#					float force = num6 + 2f * num8;
#					for (int i = 0; i < this.soundEffects.Length; i++)
#					{
#						this.soundEffects[i].Update(force, num);
#					}
#				}
#				if (this.dragCamShake && this.camRigShaker)
#				{
#					Vector3 force2 = (float)this.shakeDir * this.dragShakeFactor * this.dragVector;
#					this.shakeDir *= -1;
#					CamRigRotationInterpolator.ShakeAll(force2);
#					return;
#				}
#			}
#			else
#			{
#				this.dragVector = Vector3.zero;
#				this.liftVector = Vector3.zero;
#			}
#		}
#	}
