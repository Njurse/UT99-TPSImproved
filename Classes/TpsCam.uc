//=============================================================================
// TpsCam.
//=============================================================================
class TpsCam expands Actor;
Var() int CamX,CamZ;
Var TpsDot Dot;
Var TpsCross Cross;
Var TpsLaser Laser[99];
Var ChallengeHUD cHUD;
Var Texture Crosshair;
Var int OriginalCrosshair;
var float MyTimer;
var vector CDO;
var int CCamX,CCamZ,DCamX,DCamZ;

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

    // Calculate smooth shake offset using sine and cosine
    ShakeOffset.X = Sin(ElapsedTime * Frequency) * Intensity;          // Forward/back shake
    ShakeOffset.Y = Cos(ElapsedTime * Frequency * 1.5) * Intensity;    // Left/right shake
    ShakeOffset.Z = Sin(ElapsedTime * Frequency * 2.0) * Intensity;    // Up/down shake

    return ShakeOffset;
}

simulated function rotator GetShakeRotation(float ElapsedTime, float Intensity, float Frequency)
{
    local rotator ShakeRotation;

    // Calculate smooth rotational shake using sine and cosine
    ShakeRotation.Pitch = Sin(ElapsedTime * Frequency) * Intensity;    // Pitch oscillation
    ShakeRotation.Yaw = Cos(ElapsedTime * Frequency) * Intensity;      // Yaw oscillation
    ShakeRotation.Roll = Sin(ElapsedTime * Frequency * 0.5) * Intensity; // Roll oscillation

    return ShakeRotation;
}

simulated function tick(float Deltatime)
{
	Local Actor A,B;
	Local Vector X,Y,Z,HL,HN,RL,YOffset;
	Local PlayerPawn Pp;
	Local Int I,TCamX,TCamZ;
	Local Float Scale1,Scale2;
	
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
	YOffset = vect(0,-23,0) >> Pp.ViewRotation;
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
	if ( Pp.Weapon != None && Pp.Weapon.IsA('SniperRifle')
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
	Getaxes(Pp.ViewRotation,X,Y,Z);
	
	CCamX = CamX;
	CCamZ = CamZ;
	A = Trace(RL,HN,Pp.Location+CamZ*Z,Pp.Location,false);
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
	B = Trace(HL,HN,RL-CCamX*X,RL,false);
	if ( B == None )
		HL = RL-CCamX*X;
	else
	{
		HL += 5*X;
		Scale2 = vsize(HL-RL)/float(CamX);
		TCamZ = Scale2*CamZ;
		if ( TCamZ < DCamZ )
			DCamZ = TCamZ;
	}

	OwnerSee();
	LaserSight();
	if ( MyTimer <= 0.01 )
		MyTimer += Deltatime;
	if ( MyTimer >= 0.01 )
	{

		if ( Role < ROLE_Authority || Level.NetMode == NM_Standalone )
		{
			Pp.ClientMessage(string(Role));
			Pp.ClientMessage(string(Role<ROLE_Authority));
			Pp.ClientMessage(string(HL));
			SetRotation(Pp.ViewRotation);

	

    		SetLocation(LerpVector(Location,HL + YOffset,0.33)); // Apply the offset here for final positioning

			if ( cHUD != None )
				cHUD.Crosshair = 999;
		}
		Pp.Weapon.bOwnsCrossHair = True;
	}
	}
}

simulated function LaserSight()
{
	Local Vector X2,Y2,Z2,X,Y,Z,HL,HN,ET1,ET2,ST,LL,WL;
	local actor A,B;
	Local PlayerPawn Pp;
	local float dist1,dist2,dist3,scale;
	local int i;

	Pp = PlayerPawn(Owner);
	GetAxes(Pp.ViewRotation,X,Y,Z);
	if ( Pp.Weapon == None || Pp.Weapon.IsA('SniperRifle') )
		ST = Pp.Location + Pp.Eyeheight * Z;
	else
	{
		if ( Role == Role_Authority )
			CDO = Pp.Weapon.CalcDrawOffset()
			+ Pp.Weapon.FireOffset.Y * Y + Pp.Weapon.FireOffset.Z * Z;
		ST = Pp.Location + CDO;
	}
	ET1 = ST + 100000 * X;
	A = Trace(HL,HN,ET1,ST,False);
	if ( A == None )
		HL = ET1;
	dist1 = vSize(HL-Location);
	if ( Role < ROLE_Authority )
	{
		Cross = Spawn(class'TpsCross',Pp,,HL);
		Cross.Drawscale = dist1/100*Pp.FovAngle/90;
		Cross.Texture = Crosshair;
		Cross.SpriteProjForward = 1;
	}
	ET2 = ST + 5000 * X;
	B = Trace(LL,HN,ET2,ST,True);
	if ( B == None )
		LL = ET2;
	dist2 = vSize(LL-Location);
	if ( Role < ROLE_Authority )
	{
		Dot = Spawn(class'TpsDot',Pp,,LL);
		Dot.Drawscale = dist2/2000*Pp.FovAngle/90;
		Dot.SpriteProjForward = 1;
	}
	if ( vSize(LL-ST) < 80 )
		Return;
	dist3 = dist2/80;
	scale = 1/(dist3+1);
	if ( Level.NetMode == NM_Standalone )
		WL = Pp.Location+Pp.Eyeheight*Z+Pp.Weapon.FireOffset.Y*Y+Pp.Weapon.FireOffset.Z*Z;
	else
		WL = ST;
	GetAxes(rotator(LL-WL),X2,Y2,Z2);
	if ( Role < ROLE_Authority )
	{
		for ( i = 0 ; i < dist3+1 ; i++ )
		{
			Laser[i] = Spawn(class'TpsLaser',Pp,,WL + (i*40)*X2,rotator(LL-WL));
			Laser[i].Scaleglow = 1 - (i*scale);
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
     RemoteRole=ROLE_SimulatedProxy 
     DrawType=DT_None
     Style=STY_None
}
