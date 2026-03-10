//=============================================================================
// EotsCam.
//=============================================================================
class EotsCam expands Actor;
Var() int CamX,CamZ;
Var EotsDot Dot;
Var EotsCross Cross;
Var EotsLaser Laser[99];
Var EotsAimAssist AimAssist;
Var ChallengeHUD cHUD;
Var Texture Crosshair;
Var int OriginalCrosshair;
var float MyTimer;
var vector CDO;
var int CCamX,CCamZ,DCamX,DCamZ;
var EotsCameraController CamController;
var float AimTraceDistance;

simulated function ResolveAimAssist()
{
	local EotsAimAssist A;

	if ( AimAssist != None || Owner == None )
		return;

	ForEach AllActors(class'EotsAimAssist', A)
	{
		if ( A.Owner == Owner )
		{
			AimAssist = A;
			return;
		}
	}
}

replication
{
	reliable if ( Role == ROLE_Authority )
		CamX,CamZ;

	reliable if ( Role == ROLE_Authority )
		CDO;

	reliable if ( Role < ROLE_Authority )
		Crosshair;
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
	Local Vector X,Y,Z,TraceHitLocation,TraceHitNormal,RL,YOffset,HeadPos,ScreenCenterAimPoint;
	Local PlayerPawn Pp;
	Local Int I,TCamX,TCamZ;
	Local Float Scale1,Scale2;
	Local rotator CamRot;

	if ( Owner == none || Owner.Physics == PHYS_None || Pawn(Owner).Health <= 0 )
	{
		Destroy();
		Return;
	}
	if ( Cross != None )
		Cross.Destroy();
	if ( Dot != None )
		Dot.Destroy();
	for ( i = 0 ; i < 99 ; i++ )
	{
		if ( Laser[i] != None )
			Laser[i].Destroy();
		else
			Break;
	}
	Pp = PlayerPawn(Owner);
	if ( Pp == None )
		return;
	ResolveAimAssist();
	EnsureCamController();

	// Phase 1: capture pure player input BEFORE aim-assist can write ViewRotation.
	if ( CamController != None )
		CamController.ConsumeInput(Pp);

	// Phase 2: smooth camera orbit so CamRot is ready for placement traces.
	// Aim-assist and ViewRotation updates happen after the cameras world
	// position is known, to break the rotation feedback loop causing drift.
	if ( CamController != None )
	{
		CamController.SmoothCamera(DeltaTime);
		CamRot = CamController.GetCameraRotation();
	}
	else
	{
		CamRot = Pp.ViewRotation;
	}

	YOffset = vect(0,23,0) >> CamRot;
	if ( Role < ROLE_Authority || Level.NetMode == NM_Standalone)
	{
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
	
	CCamX = CamX;
	CCamZ = CamZ;
	A = Trace(RL,TraceHitNormal,Pp.Location+CamZ*Z,Pp.Location,false);
	if ( A == None )
		RL = Pp.Location+CamZ*Z + YOffset;
	else
	{
		RL -= 2*Z;
		Scale1 = vsize(RL-Pp.Location)/float(CamZ);
		TCamX = Scale1*CamX;
		if ( TCamX < DCamX )
			DCamX = TCamX;
	}
	B = Trace(TraceHitLocation,TraceHitNormal,RL-CCamX*X,RL,false);
	if ( B == None )
		TraceHitLocation = RL-CCamX*X;
	else
	{
		TraceHitLocation += 5*X;
		Scale2 = vsize(TraceHitLocation-RL)/float(CamX);
		TCamZ = Scale2*CamZ;
		if ( TCamZ < DCamZ )
			DCamZ = TCamZ;
	}

	// Phase 4: trace from the camera's target world position along its forward
	// vector to find the stable screen-centre world aim point.  This trace uses
	// the camera's independent orbit direction — NOT Pp.ViewRotation — which is
	// the key change that eliminates the rotation feedback drift.
	ScreenCenterAimPoint = CamAimTrace(TraceHitLocation + YOffset, X);

	// Phase 5: update Pp.ViewRotation from head → screen-centre direction so
	// weapons fire at what the camera is pointing at.
	if ( AimAssist != None )
	{
		AimAssist.UpdateRotationFromCamera(Pp, ScreenCenterAimPoint, DeltaTime);
	}
	else
	{
		HeadPos = Pp.Location + Pp.EyeHeight * vect(0,0,1);
		Pp.ViewRotation = rotator(ScreenCenterAimPoint - HeadPos);
		Pp.ViewRotation.Roll = 0;
		if ( Role == ROLE_Authority )
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

	OwnerSee();
	LaserSight();
	if ( MyTimer <= 0.01 )
		MyTimer += Deltatime;
	if ( MyTimer >= 0.01 )
	{

		if ( Role < ROLE_Authority || Level.NetMode == NM_Standalone )
		{
			SetRotation(CamRot);

			SetLocation(LerpVector(Location,TraceHitLocation + YOffset,0.37));

			if ( cHUD != None )
				cHUD.Crosshair = 999;
		}
		Pp.Weapon.bOwnsCrossHair = True;
	}
	}
}

// Spawns the camera controller if it does not yet exist.
simulated function EnsureCamController()
{
	if ( CamController == None && Owner != None )
		CamController = Spawn(class'EotsCameraController', Owner);
}

// Traces from the camera's target world position along its forward vector to
// find the world-space point at the centre of the screen.  This is the stable
// aim reference that replaces Pp.ViewRotation-derived shoulder traces.
simulated function vector CamAimTrace(vector CamPos, vector CamForward)
{
	local vector HitLoc, HitNorm;
	local actor HitActor;
	local vector EndPoint;

	EndPoint = CamPos + AimTraceDistance * CamForward;
	HitActor = Trace(HitLoc, HitNorm, EndPoint, CamPos, True);
	if ( HitActor == None )
		return EndPoint;

	// Ignore self/owner hits so the target does not orbit around the player body.
	if ( HitActor == Self || HitActor == Owner )
		return EndPoint;

	return HitLoc;
}

simulated function LaserSight()
{
	Local Vector X2,Y2,Z2,X,Y,Z,TraceHitLocation,TraceHitNormal,TraceStart,LL,PlayerLoc;
	local actor A;
	Local PlayerPawn Pp;
	local float dist1,dist2,dist3,scale;
	local int i;

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
			if ( Role == ROLE_Authority )
				CDO = Pp.Weapon.CalcDrawOffset()
				+ Pp.Weapon.FireOffset.Y * Y + Pp.Weapon.FireOffset.Z * Z;
			TraceStart = Pp.Location + CDO + vect(0,0,20);
		}
		A = Trace(TraceHitLocation,TraceHitNormal,TraceStart + 100000 * X,TraceStart,True);
		if ( A == None )
			TraceHitLocation = TraceStart + 100000 * X;
	}

	dist1 = vSize(TraceHitLocation-Location);
	if ( Role < ROLE_Authority )
	{
		Cross = Spawn(class'EotsCross',Pp,,TraceHitLocation);
		Cross.Drawscale = dist1/100*Pp.FovAngle/90;
		Cross.Texture = Crosshair;
		Cross.SpriteProjForward = 1;
		
	}
	LL = TraceHitLocation;
	dist2 = vSize(LL-Location);
	if ( Role < ROLE_Authority )
	{
		Dot = Spawn(class'EotsDot',Pp,,LL);
		Dot.Drawscale = dist2/2000*Pp.FovAngle/90;
		Dot.SpriteProjForward = 1;
	}
	if ( vSize(LL-TraceStart) < 80 )
		Return;
	dist3 = dist2/80;
	scale = 1/(dist3+1);
	if ( Level.NetMode == NM_Standalone )
	{
		PlayerLoc = Pp.Location+Pp.Eyeheight*Z+Pp.Weapon.FireOffset.Y*Y+Pp.Weapon.FireOffset.Z*Z;
	}
	else
	{
		PlayerLoc = TraceStart;
	}
		
	GetAxes(rotator(LL-PlayerLoc),X2,Y2,Z2);
	if ( Role < ROLE_Authority )
	{
		for ( i = 0 ; i < dist3+1 ; i++ )
		{
			Laser[i] = Spawn(class'EotsLaser',Pp,,PlayerLoc + (i*40)*X2,rotator(LL-PlayerLoc));
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

simulated function Destroyed()
{
	if ( cHUD != None && Role < ROLE_Authority )
		cHUD.Crosshair = OriginalCrosshair;
	if ( Dot != None )
		Dot.Destroy();
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
     RemoteRole=ROLE_SimulatedProxy 
     DrawType=DT_None
     Style=STY_None
}
