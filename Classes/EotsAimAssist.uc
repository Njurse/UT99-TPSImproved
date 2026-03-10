//=============================================================================
// EotsAimAssist.
// Reusable aim-assist component for third-person shoulder aiming.
//=============================================================================
class EotsAimAssist expands Info;

var bool bEnabled;
var vector ShoulderOffset;
var byte LaserHue;
var byte LaserSaturation;
var byte LaserBrightness;
var float RotationBlendSpeed;
var float MaxAimDistance;
var float TracePadding;

var vector CurrentAimPoint;

simulated function Configure(
	bool bInEnabled,
	vector InShoulderOffset,
	byte InLaserHue,
	byte InLaserSaturation,
	byte InLaserBrightness,
	float InRotationBlendSpeed,
	float InMaxAimDistance,
	float InTracePadding,
	bool bInLaserEnabled
)
{
	bEnabled = bInEnabled;
	ShoulderOffset = InShoulderOffset;
	LaserHue = InLaserHue;
	LaserSaturation = InLaserSaturation;
	LaserBrightness = InLaserBrightness;
	RotationBlendSpeed = InRotationBlendSpeed;
	MaxAimDistance = InMaxAimDistance;
	TracePadding = InTracePadding;
}

simulated function vector GetShoulderStart(PlayerPawn Pp)
{
	local vector X, Y, Z;
	local vector Start;

	if ( Pp == None )
		return Location;

	GetAxes(Pp.ViewRotation, X, Y, Z);

	if ( Pp.Weapon != None )
	{
		Start = Pp.Location + Pp.Weapon.CalcDrawOffset()
			+ Pp.Weapon.FireOffset.Y * Y + Pp.Weapon.FireOffset.Z * Z;
	}
	else
	{
		Start = Pp.Location + Pp.EyeHeight * Z;
	}

	return Start + ShoulderOffset.X * X + ShoulderOffset.Y * Y + ShoulderOffset.Z * Z;
}

simulated function vector ResolveAimPoint(PlayerPawn Pp)
{
	local vector X, Y, Z;
	local vector Start, HitLoc, HitNorm, EndPoint;
	local actor HitActor;

	if ( Pp == None )
		return Location;

	GetAxes(Pp.ViewRotation, X, Y, Z);
	Start = GetShoulderStart(Pp);
	EndPoint = Start + MaxAimDistance * X;

	HitActor = Trace(HitLoc, HitNorm, EndPoint, Start, True);
	if ( HitActor == None )
	{
		CurrentAimPoint = EndPoint;
	}
	else
	{
		CurrentAimPoint = HitLoc - TracePadding * X;
	}

	return CurrentAimPoint;
}

simulated function int BlendAxis(int CurrentValue, int TargetValue, float Alpha)
{
	local int Delta;

	Delta = ((TargetValue - CurrentValue + 32768) & 65535) - 32768;
	return CurrentValue + int(float(Delta) * Alpha);
}

simulated function rotator BlendRotation(rotator CurrentRot, rotator TargetRot, float Alpha)
{
	local rotator OutRot;

	OutRot.Pitch = BlendAxis(CurrentRot.Pitch, TargetRot.Pitch, Alpha);
	OutRot.Yaw = BlendAxis(CurrentRot.Yaw, TargetRot.Yaw, Alpha);
	OutRot.Roll = 0;

	return OutRot;
}

simulated function rotator BuildTargetRotation(PlayerPawn Pp, vector AimPoint)
{
	local vector X, Y, Z;
	local vector EyeLoc;

	GetAxes(Pp.ViewRotation, X, Y, Z);
	EyeLoc = Pp.Location + Pp.EyeHeight * Z;

	return rotator(AimPoint - EyeLoc);
}

simulated function rotator UpdateRotation(PlayerPawn Pp, float DeltaTime)
{
	local rotator TargetRot, NewRot;
	local float Alpha;

	if ( Pp == None )
		return Rotation;

	if ( !bEnabled )
		return Pp.ViewRotation;

	ResolveAimPoint(Pp);
	TargetRot = BuildTargetRotation(Pp, CurrentAimPoint);

	Alpha = FClamp(RotationBlendSpeed * DeltaTime, 0.0, 1.0);
	NewRot = BlendRotation(Pp.ViewRotation, TargetRot, Alpha);

	Pp.ViewRotation = NewRot;
	if ( Pp.Role == ROLE_Authority )
		Pp.SetRotation(NewRot);

	return NewRot;
}

// Updates Pp.ViewRotation from the direction between the player's head and the
// camera's screen-centre world aim point.  Call this instead of UpdateRotation.
// Using the camera position as aim source eliminates the rotation feedback loop
// that caused the player to drift when aim assist was active.
simulated function rotator UpdateRotationFromCamera(
	PlayerPawn Pp,
	vector CamWorldAimPoint,
	float DeltaTime
)
{
	local vector HeadPos;
	local rotator TargetRot, NewRot;
	local float Alpha;

	if ( Pp == None )
		return Rotation;

	// Use world-up eye origin; using view-rotated Z introduces lateral drift.
	HeadPos = Pp.Location + Pp.EyeHeight * vect(0,0,1);
	if ( VSize(CamWorldAimPoint - HeadPos) < 1.0 )
		return Pp.ViewRotation;

	// Head → screen-centre direction.  Stable because CamWorldAimPoint
	// comes from the camera's independent orbit, not from Pp.ViewRotation.
	TargetRot = rotator(CamWorldAimPoint - HeadPos);
	TargetRot.Roll = 0;

	// Update CurrentAimPoint so LaserSight traces along the camera direction.
	CurrentAimPoint = CamWorldAimPoint;

	if ( !bEnabled )
	{
		// No aim assist: snap view directly to camera aim, no blend.
		Pp.ViewRotation = TargetRot;
		if ( Pp.Role == ROLE_Authority )
		{
			TargetRot.Pitch = 0;
			TargetRot.Roll = 0;
			Pp.SetRotation(TargetRot);
		}
		return TargetRot;
	}

	Alpha = FClamp(RotationBlendSpeed * DeltaTime, 0.0, 1.0);
	NewRot = BlendRotation(Pp.ViewRotation, TargetRot, Alpha);
	Pp.ViewRotation = NewRot;
	if ( Pp.Role == ROLE_Authority )
	{
		TargetRot = NewRot;
		TargetRot.Pitch = 0;
		TargetRot.Roll = 0;
		Pp.SetRotation(TargetRot);
	}

	return NewRot;
}

defaultproperties
{
	bEnabled=False
	ShoulderOffset=(X=16.000000,Y=18.000000,Z=8.000000)
	LaserHue=0
	LaserSaturation=255
	LaserBrightness=160
	RotationBlendSpeed=7.500000
	MaxAimDistance=12000.000000
	TracePadding=4.000000
	bHidden=True
	RemoteRole=ROLE_None
	DrawType=DT_None
}
