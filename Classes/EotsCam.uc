//=============================================================================
// EotsCam.
//=============================================================================
class EotsCam expands Actor;
Var() int CamX,CamZ;
Var EotsLaser Laser[99];
Var EotsAimAssist AimAssist;
Var ChallengeHUD cHUD;
Var Texture Crosshair;
Var int OriginalCrosshair;
var float MyTimer;
var vector CDO;

var EotsCameraController CamController;
var float AimTraceDistance;
var float AimCullMinForwardDot;
var float AimCullMinDistance;
var bool bDebugOverlayEnabled;
var bool bLaserEnabled;
var rotator LastPlayerViewRot;
var rotator LastCamViewRot;
var rotator LastTraceRot;

// Client-side smoothed shoulder offset.  Lerps toward AimAssist.ShoulderOffset
// each tick so changes to the offset animate in rather than snapping.
var vector CurrentShoulderOffset;
var bool bOffsetInitialized;
var() float OffsetLerpSpeed;

// Strafe compensation: shifts the camera laterally in the direction of player
// movement so the character stays toward the screen edge and doesn't drift
// into the centre of the view while strafing.
var float CurrentStrafeOffset;
var() float StrafeCompensationMax;
var() float StrafeCompensationSpeed;

// How fast the camera orbit chases the player's look direction.
// Higher = stiffer/more responsive.  Lower = floaty/relaxed.
var() float CamSmoothSpeed;
var bool bClientCameraSystemEnabled;
var int ActiveLaserCount;
var int OwnerSeeCounter;

simulated function ResolveAimAssist()
{
	// AimAssist reference is now set directly by EotsInv when the camera
	// is spawned, eliminating the per-tick AllActors scan.
}

simulated function SetClientCameraEnabled(bool bEnabled)
{
	local PlayerPawn Pp;

	bClientCameraSystemEnabled = bEnabled;
	Pp = PlayerPawn(Owner);
	if ( !bEnabled )
		DisableCameraForOwner(Pp);
}

simulated function DisableCameraForOwner(PlayerPawn Pp)
{
	local int i;

	for ( i = 0; i < 99; i++ )
	{
		if ( Laser[i] == None )
			break;
		Laser[i].Destroy();
		Laser[i] = None;
	}
	ActiveLaserCount = 0;

	if ( Pp == None )
		return;

	if ( Pp.ViewTarget == Self )
		Pp.ViewTarget = None;
	Pp.bBehindView = False;

	if ( cHUD != None )
		cHUD.Crosshair = OriginalCrosshair;

	if ( Pp.Weapon != None )
		Pp.Weapon.bOwnsCrossHair = False;
}

simulated function vector GetShakeOffset(float ElapsedTime, float Intensity, float Frequency)
{
    local vector ShakeOffset;

    ShakeOffset.X = Sin(ElapsedTime * Frequency) * Intensity;
    ShakeOffset.Y = Cos(ElapsedTime * Frequency * 1.5) * Intensity;
    ShakeOffset.Z = Sin(ElapsedTime * Frequency * 2.0) * Intensity;

    return ShakeOffset;
}

simulated function rotator GetShakeRotation(float ElapsedTime, float Intensity, float Frequency)
{
    local rotator ShakeRotation;

    ShakeRotation.Pitch = Sin(ElapsedTime * Frequency) * Intensity;
    ShakeRotation.Yaw = Cos(ElapsedTime * Frequency * Intensity) ;
    ShakeRotation.Roll = Sin(ElapsedTime * Frequency * 0.5) * Intensity;

    return ShakeRotation;
}

simulated function tick(float Deltatime)
{
	Local Actor A,B;
	Local Vector X,Y,Z,TraceHitLocation,TraceHitNormal,RL,YOffset,HeadPos,ScreenCenterAimPoint,SafeAimPoint,AimDir;
	Local PlayerPawn Pp;
	Local Int I;
	Local rotator CamRot;
	Local float StrafeVel, TargetStrafeOffset;

	if ( Owner == none || Owner.Physics == PHYS_None || Pawn(Owner).Health <= 0 )
	{
		Destroy();
		Return;
	}
	Pp = PlayerPawn(Owner);
	if ( Pp == None )
		return;
	if ( !bClientCameraSystemEnabled )
	{
		DisableCameraForOwner(Pp);
		return;
	}
	EnsureCamController();

	// Phase 1: capture pure player input BEFORE aim-assist can write ViewRotation.
	if ( CamController != None )
		CamController.ConsumeInput(Pp);

	// Phase 2: smooth camera orbit so CamRot is ready for placement traces.
	// Aim-assist and ViewRotation updates happen after the cameras world
	// position is known, to break the rotation feedback loop causing drift.
	if ( CamController != None )
	{
		CamController.SmoothSpeed = CamSmoothSpeed;
		CamController.SmoothCamera(DeltaTime);
		CamRot = CamController.GetCameraRotation();
	}
	else
	{
		CamRot = Pp.ViewRotation;
	}

	// Lerp the shoulder offset client-side so changes animate smoothly
	// instead of snapping.  On the first tick we snap to avoid a swim-in
	// from the world origin.
	if ( AimAssist != None )
	{
		if ( !bOffsetInitialized )
		{
			CurrentShoulderOffset = AimAssist.ShoulderOffset;
			bOffsetInitialized = True;
		}
		else
		{
			CurrentShoulderOffset.X += (AimAssist.ShoulderOffset.X - CurrentShoulderOffset.X) * FClamp(OffsetLerpSpeed * DeltaTime, 0.0, 1.0);
			CurrentShoulderOffset.Y += (AimAssist.ShoulderOffset.Y - CurrentShoulderOffset.Y) * FClamp(OffsetLerpSpeed * DeltaTime, 0.0, 1.0);
			CurrentShoulderOffset.Z += (AimAssist.ShoulderOffset.Z - CurrentShoulderOffset.Z) * FClamp(OffsetLerpSpeed * DeltaTime, 0.0, 1.0);
		}
		YOffset.Y = CurrentShoulderOffset.Y;
	}
	else
	{
		YOffset.Y = 23;
	}
	YOffset = YOffset >> CamRot;
	if ( Pp.MyHUD.IsA('ChallengeHUD') )
			cHUD = ChallengeHUD(Pp.MyHUD);
		if ( Crosshair == None && cHUD != None )
		{
			Crosshair = cHUD.CrossHairTextures[cHUD.Crosshair];
			OriginalCrosshair = cHUD.Crosshair;
		}
	
	if ( Level.NetMode != NM_Standalone && Crosshair == None )
		Crosshair = texture'Botpack.Icons.Chair1';
	if ( Pp.Weapon != None && (Pp.Weapon.IsA('SniperRifle') || Pp.Weapon.IsA('IRPR'))
	&& Pp.Weapon.bOwnsCrossHair )
	{
		Pp.ViewTarget = None;
		Pp.bBehindView = False;
		Return;
	}
	else if ( Pp.Weapon != None && Pp.Weapon.IsA('WarHeadLauncher')
	&& WarHeadLauncher(Pp.Weapon).bGuiding )
	{
		Pp.bBehindView = True;
		Return;
	}
	else
	{
		if ( Pp.ViewTarget == None )
			Pp.ViewTarget = Self;
		if ( Pp.ViewTarget == Self )
			Pp.bBehindView = False;
	}
	Getaxes(CamRot,X,Y,Z);

	// Now that camera-space axes are known, apply ShoulderOffset X (forward/back)
	// and Z (up/down) using the smoothed value so all three axes lerp together.
	if ( AimAssist != None )
	{
		YOffset += CurrentShoulderOffset.X * X;
		YOffset += CurrentShoulderOffset.Z * Z;
	}

	// Strafe compensation: project player velocity onto the camera right axis,
	// normalise by approximate UT max strafe speed (350 u/s), then lerp a
	// lateral camera shift in the same direction.  This keeps the character
	// pushed toward the shoulder edge of the screen during lateral movement.
	if ( StrafeCompensationMax > 0 )
	{
		StrafeVel = Pp.Velocity Dot Y;
		TargetStrafeOffset = FClamp(StrafeVel / 350.0, -1.0, 1.0) * StrafeCompensationMax;
		CurrentStrafeOffset += (TargetStrafeOffset - CurrentStrafeOffset)
			* FClamp(StrafeCompensationSpeed * DeltaTime, 0.0, 1.0);
		YOffset += CurrentStrafeOffset * Y;
	}

	// Step 1: clamp vertical camera arm - pull down below ceiling if needed.
	A = Trace(RL,TraceHitNormal,Pp.Location+CamZ*Z,Pp.Location,false);
	if ( A == None )
		RL = Pp.Location+CamZ*Z;
	else
		RL = RL + TraceHitNormal * 6;

	// Step 2: clamp horizontal camera arm - keep camera out of walls behind player.
	B = Trace(TraceHitLocation,TraceHitNormal,RL-CamX*X,RL,false);
	if ( B == None )
		TraceHitLocation = RL-CamX*X;
	else
		TraceHitLocation = TraceHitLocation + TraceHitNormal * 6;

	// Phase 4: resolve screen-centre aim from camera world position.
	// This traces from the camera along its forward axis to preserve
	// centre-screen alignment while keeping camera/pawn rotation decoupled.
	ScreenCenterAimPoint = CamAimTrace(TraceHitLocation + YOffset, X);
	SafeAimPoint = (TraceHitLocation + YOffset) + AimTraceDistance * X;

	// Cull targets that would cause violent yaw lurches: too close to head,
	// behind camera-forward, or excessively sideways from camera-forward.
	HeadPos = Pp.Location + Pp.EyeHeight * vect(0,0,1);
	AimDir = ScreenCenterAimPoint - HeadPos;
	if ( VSize(AimDir) < AimCullMinDistance || (Normal(AimDir) Dot X) < AimCullMinForwardDot )
		ScreenCenterAimPoint = SafeAimPoint;

	// Phase 5: update Pp.ViewRotation from head → screen-centre direction so
	// weapons fire at what the camera is pointing at.
	if ( AimAssist != None )
	{
		AimAssist.UpdateRotationFromCamera(Pp, ScreenCenterAimPoint, DeltaTime);
		LastTraceRot = rotator(ScreenCenterAimPoint - HeadPos);
	}
	else
	{
		Pp.ViewRotation = rotator(ScreenCenterAimPoint - HeadPos);
		LastTraceRot = Pp.ViewRotation;
		Pp.ViewRotation.Roll = 0;
		if ( Pp.Role == ROLE_Authority )
		{
			CamRot = Pp.ViewRotation;
			CamRot.Pitch = 0;
			CamRot.Roll = 0;
			Pp.SetRotation(CamRot);
		}
	}

	// Phase 6: record ViewRotation post-update as the input baseline so next
	// frame's ConsumeInput delta reflects only actual player mouse movement.
	if ( CamController != None )
		CamController.RecordPostAssistRotation(Pp);
	LastPlayerViewRot = Pp.ViewRotation;
	LastCamViewRot = CamRot;

	OwnerSeeCounter++;
	if ( OwnerSeeCounter >= 5 )
	{
		OwnerSeeCounter = 0;
		OwnerSee();
	}

	if ( bLaserEnabled )
		UpdateLaserSight();
	else
		HideAllLasers();

	SetRotation(CamRot);

	// Lerp toward target, then clamp against geometry so the camera
	// cannot glide through walls during the interpolation step.
	RL = LerpVector(Location, TraceHitLocation + YOffset, 0.37);
	if ( Trace(SafeAimPoint, TraceHitNormal, RL, Pp.Location, false) != None )
		RL = SafeAimPoint + TraceHitNormal * 6;
	SetLocation(RL);

	if ( cHUD != None )
		cHUD.Crosshair = OriginalCrosshair;
	if ( Pp.Weapon != None )
		Pp.Weapon.bOwnsCrossHair = False;
}

// Spawns the camera controller if it does not yet exist.
simulated function EnsureCamController()
{
	if ( CamController == None && Owner != None )
		CamController = Spawn(class'EotsCameraController', Owner);
}

// Returns world-space point at screen centre using a camera-forward trace.
// Self/owner hits are ignored and fall back to far forward point.
simulated function vector CamAimTrace(vector CamPos, vector CamForward)
{
	local vector HitLoc, HitNorm;
	local vector EndPoint;
	local actor HitActor;

	EndPoint = CamPos + AimTraceDistance * CamForward;
	HitActor = Trace(HitLoc, HitNorm, EndPoint, CamPos, True);
	if ( HitActor == None )
		return EndPoint;

	if ( HitActor == Self || HitActor == Owner )
		return EndPoint;

	return HitLoc;
}

simulated function LaserSight()
{
	// Deprecated — use UpdateLaserSight() for pooled laser management.
}

simulated function HideAllLasers()
{
	local int i;

	for ( i = 0; i < ActiveLaserCount; i++ )
	{
		if ( Laser[i] != None )
			Laser[i].bHidden = True;
	}
	ActiveLaserCount = 0;
}

simulated function UpdateLaserSight()
{
	Local Vector X2,Y2,Z2,X,Y,Z,TraceHitLocation,TraceHitNormal,TraceStart,LL,PlayerLoc;
	local actor A;
	Local PlayerPawn Pp;
	local float dist2,dist3,scale;
	local int i, NeededCount;

	Pp = PlayerPawn(Owner);
	if ( Pp == None )
		return;

	GetAxes(Pp.ViewRotation,X,Y,Z);

	if ( AimAssist != None )
	{
		TraceStart = AimAssist.GetShoulderStart(Pp);
		TraceHitLocation = AimAssist.ResolveAimPoint(Pp);
	}
	else
	{
		if ( Pp.Weapon == None || Pp.Weapon.IsA('SniperRifle') )
			TraceStart = Pp.Location + Pp.Eyeheight * Z;
		else
		{
			CDO = Pp.Weapon.CalcDrawOffset()
				+ Pp.Weapon.FireOffset.Y * Y + Pp.Weapon.FireOffset.Z * Z;
			TraceStart = Pp.Location + CDO + vect(0,0,20);
		}
		A = Trace(TraceHitLocation,TraceHitNormal,TraceStart + 100000 * X,TraceStart,True);
		if ( A == None )
			TraceHitLocation = TraceStart + 100000 * X;
	}

	LL = TraceHitLocation;
	dist2 = vSize(LL-Location);
	if ( vSize(LL-TraceStart) < 80 )
	{
		HideAllLasers();
		Return;
	}
	dist3 = dist2/10;
	scale = 1/(dist3+1);

	if ( Level.NetMode == NM_Standalone )
	{
		if ( Pp.Weapon != None )
			PlayerLoc = Pp.Location+Pp.Eyeheight*Z+Pp.Weapon.FireOffset.Y*Y+Pp.Weapon.FireOffset.Z*Z;
		else
			PlayerLoc = TraceStart;
	}
	else
	{
		PlayerLoc = TraceStart;
	}

	GetAxes(rotator(LL-PlayerLoc),X2,Y2,Z2);

	NeededCount = int(dist3) + 1;
	if ( NeededCount > 99 )
		NeededCount = 99;

	for ( i = 0; i < NeededCount; i++ )
	{
		if ( Laser[i] == None )
			Laser[i] = Spawn(class'EotsLaser',Pp,,PlayerLoc + (i*10)*X2,rotator(LL-PlayerLoc));
		else
		{
			Laser[i].SetLocation(PlayerLoc + (i*10)*X2);
			Laser[i].SetRotation(rotator(LL-PlayerLoc));
			Laser[i].bHidden = False;
		}
		if ( Laser[i] != None )
		{
			Laser[i].Scaleglow = 1 - (i*scale);
			if ( AimAssist != None )
			{
				Laser[i].LightType = LT_Steady;
				Laser[i].LightEffect = LE_NonIncidence;
				Laser[i].LightHue = AimAssist.LaserHue;
				Laser[i].LightSaturation = AimAssist.LaserSaturation;
				Laser[i].LightBrightness = AimAssist.LaserBrightness;
				Laser[i].AmbientGlow = AimAssist.LaserBrightness;
			}
		}
	}

	// Hide excess lasers from previous frame.
	for ( i = NeededCount; i < ActiveLaserCount; i++ )
	{
		if ( Laser[i] != None )
			Laser[i].bHidden = True;
	}
	ActiveLaserCount = NeededCount;
}

simulated function OwnerSee()
{
	local Effects E;

	Foreach RadiusActors(class'Effects',E,300,Owner.Location)
	{
		if ( E.bOwnerNoSee && E.Owner == Owner )
			E.bOwnerNoSee = False;
	}
}

simulated function DrawDebugOverlay(canvas Canvas)
{
	local float BaseX, BaseY, LineH;

	if ( !bDebugOverlayEnabled || Canvas == None )
		return;

	BaseX = 16.0;
	BaseY = Canvas.ClipY * 0.62;
	LineH = 26.0;

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor.R = 255;
	Canvas.DrawColor.G = 32;
	Canvas.DrawColor.B = 32;

	Canvas.SetPos(BaseX, BaseY);
	Canvas.DrawText("EOTS DEBUG:", False);
	Canvas.SetPos(BaseX, BaseY + LineH);
	Canvas.DrawText("PLY        CAM", False);
	Canvas.SetPos(BaseX, BaseY + 2 * LineH);
	Canvas.DrawText("PITCH   " $ string(LastPlayerViewRot.Pitch) $ ", " $ string(LastTraceRot.Pitch), False);
	Canvas.SetPos(BaseX, BaseY + 3 * LineH);
	Canvas.DrawText("YAW     " $ string(LastPlayerViewRot.Yaw) $ ", " $ string(LastTraceRot.Yaw), False);
	Canvas.SetPos(BaseX, BaseY + 4 * LineH);
	Canvas.DrawText("ROLL    " $ string(LastPlayerViewRot.Roll) $ ", " $ string(LastTraceRot.Roll), False);
}

simulated function PostRender(canvas Canvas)
{
	DrawDebugOverlay(Canvas);
}

simulated function Destroyed()
{
	DisableCameraForOwner(PlayerPawn(Owner));
	if ( CamController != None )
	{
		CamController.Destroy();
		CamController = None;
	}
	Super.Destroyed();
}

simulated function vector LerpVector(vector Start, vector End, float Alpha)
{
    return Start + (End - Start) * Alpha;
}

defaultproperties
{
	CamX=90
	CamZ=32
	AimTraceDistance=100000.000000
	AimCullMinForwardDot=0.300000
	AimCullMinDistance=96.000000
	OffsetLerpSpeed=8.000000
	StrafeCompensationMax=25.000000
	StrafeCompensationSpeed=5.000000
	CamSmoothSpeed=15.000000
	bDebugOverlayEnabled=True
	bLaserEnabled=False
	bClientCameraSystemEnabled=True
	bHidden=True
	RemoteRole=ROLE_None
	DrawType=DT_None
	Style=STY_None
}
