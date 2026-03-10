//=============================================================================
// EotsCameraController.
// Decoupled input-driven third-person camera rotation controller.
//
// Design goals:
//   - Camera yaw/pitch are driven ONLY by player input deltas, never by
//     the pawn actor's rotation directly.
//   - Aim-assist writes to Pp.ViewRotation independently; we strip that out
//     each frame so it never accumulates into the camera orbit.
//   - Smoothing interpolates toward the target each tick to prevent jitter.
//   - Pitch is clamped to prevent gimbal flip.
//
// Tick order in EotsCam:
//   1. CamController.ConsumeInput(Pp)          -- capture pure player input
//   2. AimAssist.UpdateRotation(Pp, DT)        -- aim-assist may write ViewRot
//   3. CamController.RecordPostAssistRotation(Pp) -- note the post-assist state
//   4. CamController.SmoothCamera(DT)          -- interpolate toward target
//   5. Use GetCameraRotation() for placement
//=============================================================================
class EotsCameraController expands Info;

// Sensitivity multipliers applied to raw input deltas (1.0 = 1:1 passthrough).
var() float YawSensitivity;
var() float PitchSensitivity;

// How fast the current rotation chases the target.
// Higher values feel more responsive; lower values feel smoother/floaty.
var() float SmoothSpeed;

// Pitch limits in Unreal rotation units (65536 = 360 deg, 16384 = 90 deg).
// Negative pitch = looking down, positive = looking up.
var() int MinPitchLimit;
var() int MaxPitchLimit;

// Current smoothed camera rotation (independent of pawn rotation).
var int CamYaw;
var int CamPitch;

// Target rotation (what we are interpolating toward).
var int TargetYaw;
var int TargetPitch;

// Pawn ViewRotation captured AFTER aim-assist ran last tick.
// Subtracting this from the next tick's ViewRotation isolates pure player input.
var rotator PostAssistRotation;

var bool bInitialized;

//-----------------------------------------------------------------------------
// ConsumeInput
// Call BEFORE aim-assist runs.
// Reads the player-input-driven change in Pp.ViewRotation since last tick,
// applies sensitivity, and accumulates into TargetYaw / TargetPitch.
//-----------------------------------------------------------------------------
simulated function ConsumeInput(PlayerPawn Pp)
{
	local int DeltaYaw, DeltaPitch;

	if ( Pp == None )
		return;

	if ( !bInitialized )
	{
		CamYaw      = Pp.ViewRotation.Yaw;
		CamPitch    = NormalizePitch(Pp.ViewRotation.Pitch);
		TargetYaw   = CamYaw;
		TargetPitch = CamPitch;
		PostAssistRotation = Pp.ViewRotation;
		bInitialized = True;
		return;
	}

	// InputDelta = current ViewRotation - last post-assist rotation.
	// This strips out any aim-assist contribution from the previous frame,
	// leaving only what the player's mouse/stick actually did this frame.
	DeltaYaw   = RotAxisDelta(Pp.ViewRotation.Yaw,   PostAssistRotation.Yaw);
	DeltaPitch = RotAxisDelta(Pp.ViewRotation.Pitch, PostAssistRotation.Pitch);

	TargetYaw   += int(float(DeltaYaw)   * YawSensitivity);
	TargetPitch += int(float(DeltaPitch) * PitchSensitivity);

	// Clamp pitch to prevent looking past vertical limits.
	TargetPitch = Clamp(NormalizePitch(TargetPitch), MinPitchLimit, MaxPitchLimit);
}

//-----------------------------------------------------------------------------
// RecordPostAssistRotation
// Call AFTER aim-assist has written to Pp.ViewRotation.
// Saves the current pawn rotation as the baseline for the next frame's delta
// calculation, so aim-assist nudges are not treated as player input.
//-----------------------------------------------------------------------------
simulated function RecordPostAssistRotation(PlayerPawn Pp)
{
	if ( Pp != None )
		PostAssistRotation = Pp.ViewRotation;
}

//-----------------------------------------------------------------------------
// SmoothCamera
// Interpolates CamYaw/CamPitch toward their targets each tick.
//-----------------------------------------------------------------------------
simulated function SmoothCamera(float DeltaTime)
{
	local float Alpha;

	Alpha = FClamp(SmoothSpeed * DeltaTime, 0.0, 1.0);
	CamYaw   = BlendRotAxis(CamYaw,   TargetYaw,   Alpha);
	CamPitch = BlendRotAxis(CamPitch, TargetPitch, Alpha);
}

//-----------------------------------------------------------------------------
// GetCameraRotation
// Returns the current smoothed camera rotation for use in placement and traces.
//-----------------------------------------------------------------------------
simulated function rotator GetCameraRotation()
{
	local rotator R;

	R.Yaw   = CamYaw;
	R.Pitch = CamPitch;
	R.Roll  = 0;
	return R;
}

//-----------------------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------------------

// Wrapping signed delta between two rotation axis values.
simulated function int RotAxisDelta(int NewVal, int OldVal)
{
	return ((NewVal - OldVal + 32768) & 65535) - 32768;
}

// Normalize a pitch value into the [-32768, 32767] signed range.
simulated function int NormalizePitch(int P)
{
	P = P & 65535;
	if ( P > 32767 )
		P -= 65536;
	return P;
}

// Shortest-path blend between two rotation axis values.
simulated function int BlendRotAxis(int Current, int Target, float Alpha)
{
	local int Delta;

	Delta = ((Target - Current + 32768) & 65535) - 32768;
	return Current + int(float(Delta) * Alpha);
}

defaultproperties
{
	YawSensitivity=1.000000
	PitchSensitivity=1.000000
	SmoothSpeed=15.000000
	MinPitchLimit=-12000
	MaxPitchLimit=8000
	bHidden=True
	RemoteRole=ROLE_None
	DrawType=DT_None
}
