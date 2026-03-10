//=============================================================================
// EotsCameraMut.
// Rebranded third-person camera/aim-assist mutator.
//=============================================================================
class EotsCameraMut expands Mutator config(EOTSCamera);

var() config bool bDebugOverlayEnabled;
var() config bool bAimAssistEnabled;
var() config vector AimShoulderOffset;
var() config byte AimLaserHue;
var() config byte AimLaserSaturation;
var() config byte AimLaserBrightness;
var() config float AimRotationBlendSpeed;
var() config float AimMaxDistance;
var() config float AimTracePadding;
var() config bool bLaserEnabled;
var() config int CamArmX;
var() config int CamArmZ;
var() config float CamTraceDistance;
var() config float CamCullForwardDot;
var() config float CamCullMinDist;
var() config float CamOffsetLerpSpeed;
var() config float CamStrafeCompMax;
var() config float CamStrafeCompSpeed;
var() config float CamSmoothSpeed;

var string FriendlyNameText;
var string DescriptionText;

function string GetWordAt(string S, int Index)
{
	local int i, p, lenS, startPos, endPos;

	lenS = Len(S);
	p = 0;

	for ( i = 0; i <= Index; i++ )
	{
		while ( p < lenS && Mid(S, p, 1) == " " )
			p++;

		if ( p >= lenS )
			return "";

		startPos = p;
		while ( p < lenS && Mid(S, p, 1) != " " )
			p++;
		endPos = p;
	}

	return Mid(S, startPos, endPos - startPos);
}

function AddMutator(Mutator M)
{
	if ( M.IsA('ToprealMut') )
	{
		log("TopReal mutator not allowed (already have EOTS Camera mutator)");
		return;
	}
	Super.AddMutator(M);
}

function ModifyPlayer(Pawn Other)
{
	local PickUp I;

	if ( Other.IsA('PlayerPawn') )
	{
		I = Spawn(class'EotsInv');
		if ( I != None )
		{
			I.RespawnTime = 0.0;
			I.GiveTo(Other);
			I.PickupFunction(Other);
			EotsInv(I).ConfigureAimSettings(
				bAimAssistEnabled,
				AimShoulderOffset,
				AimLaserHue,
				AimLaserSaturation,
				AimLaserBrightness,
				AimRotationBlendSpeed,
				AimMaxDistance,
				AimTracePadding,
				bLaserEnabled
			);
			EotsInv(I).ConfigureDebugOverlay(bDebugOverlayEnabled);
			EotsInv(I).ConfigureCamSettings(
				CamArmX,
				CamArmZ,
				CamTraceDistance,
				CamCullForwardDot,
				CamCullMinDist,
				CamOffsetLerpSpeed,
				CamStrafeCompMax,
				CamStrafeCompSpeed,
				CamSmoothSpeed
			);
		}
	}
	if ( NextMutator != None )
		NextMutator.ModifyPlayer(Other);
}

function ApplySettingsToPlayers()
{
	local EotsAimAssist Assist;
	local EotsInv Inv;

	ForEach AllActors(class'EotsAimAssist', Assist)
	{
		Assist.Configure(
			bAimAssistEnabled,
			AimShoulderOffset,
			AimLaserHue,
			AimLaserSaturation,
			AimLaserBrightness,
			AimRotationBlendSpeed,
			AimMaxDistance,
			AimTracePadding,
			bLaserEnabled
		);
	}

	ForEach AllActors(class'EotsInv', Inv)
	{
		Inv.ConfigureAimSettings(
			bAimAssistEnabled,
			AimShoulderOffset,
			AimLaserHue,
			AimLaserSaturation,
			AimLaserBrightness,
			AimRotationBlendSpeed,
			AimMaxDistance,
			AimTracePadding,
			bLaserEnabled
		);
		Inv.ConfigureDebugOverlay(bDebugOverlayEnabled);
		Inv.ConfigureCamSettings(
			CamArmX,
			CamArmZ,
			CamTraceDistance,
			CamCullForwardDot,
			CamCullMinDist,
			CamOffsetLerpSpeed,
			CamStrafeCompMax,
			CamStrafeCompSpeed,
			CamSmoothSpeed
		);
	}
}

function Mutate(string MutateString, PlayerPawn Sender)
{
	local string Cmd;
	local string P1, P2, P3;
	local float FX, FY, FZ;
	local int IH, IS, IB;

	Cmd = Caps(MutateString);
	if ( Cmd ~= "EOTSAIM ON" )
	{
		bAimAssistEnabled = True;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Aim Assist enabled");
		return;
	}

	if ( Cmd ~= "EOTSAIM OFF" )
	{
		bAimAssistEnabled = False;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Aim Assist disabled");
		return;
	}

	if ( Cmd ~= "EOTSAIM TOGGLE" )
	{
		bAimAssistEnabled = !bAimAssistEnabled;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Aim Assist toggled to " $ string(bAimAssistEnabled));
		return;
	}

	if ( Cmd ~= "EOTSAIM APPLY" )
	{
		// Sync all instance vars from saved config defaults so the
		// settings panel's StaticSaveConfig values take effect live.
		bAimAssistEnabled = class'EotsCameraMut'.default.bAimAssistEnabled;
		bDebugOverlayEnabled = class'EotsCameraMut'.default.bDebugOverlayEnabled;
		bLaserEnabled = class'EotsCameraMut'.default.bLaserEnabled;
		AimShoulderOffset = class'EotsCameraMut'.default.AimShoulderOffset;
		AimLaserHue = class'EotsCameraMut'.default.AimLaserHue;
		AimLaserSaturation = class'EotsCameraMut'.default.AimLaserSaturation;
		AimLaserBrightness = class'EotsCameraMut'.default.AimLaserBrightness;
		AimRotationBlendSpeed = class'EotsCameraMut'.default.AimRotationBlendSpeed;
		AimMaxDistance = class'EotsCameraMut'.default.AimMaxDistance;
		AimTracePadding = class'EotsCameraMut'.default.AimTracePadding;
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS settings applied");
		return;
	}

	if ( Left(Cmd, 15) ~= "EOTSAIM OFFSET " )
	{
		P1 = GetWordAt(MutateString, 2);
		P2 = GetWordAt(MutateString, 3);
		P3 = GetWordAt(MutateString, 4);
		FX = float(P1);
		FY = float(P2);
		FZ = float(P3);

		AimShoulderOffset = vect(0,0,0);
		AimShoulderOffset.X = FX;
		AimShoulderOffset.Y = FY;
		AimShoulderOffset.Z = FZ;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Aim offset set to " $ string(AimShoulderOffset));
		return;
	}

	if ( Left(Cmd, 14) ~= "EOTSAIM LASER " )
	{
		P1 = GetWordAt(MutateString, 2);
		P2 = GetWordAt(MutateString, 3);
		P3 = GetWordAt(MutateString, 4);
		IH = int(P1);
		IS = int(P2);
		IB = int(P3);

		AimLaserHue = Clamp(IH, 0, 255);
		AimLaserSaturation = Clamp(IS, 0, 255);
		AimLaserBrightness = Clamp(IB, 0, 255);
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Laser color updated");
		return;
	}

	if ( Cmd ~= "EOTSDEBUG ON" )
	{
		bDebugOverlayEnabled = True;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Debug overlay enabled");
		return;
	}

	if ( Cmd ~= "EOTSDEBUG OFF" )
	{
		bDebugOverlayEnabled = False;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Debug overlay disabled");
		return;
	}

	if ( Cmd ~= "EOTSDEBUG TOGGLE" )
	{
		bDebugOverlayEnabled = !bDebugOverlayEnabled;
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Debug overlay toggled to " $ string(bDebugOverlayEnabled));
		return;
	}

	// Sync all settings from the client in one command.  All values are passed
	// inline so the server does not need to reload its own config file.
	// Format: mutate eotsaim setall <bAim> <bLaser> <bDebug> <blend> <maxdist> <pad> <offX> <offY> <offZ> <camX> <camZ> <traceDist> <cullDot> <cullDist> <lerpSpeed>
	if ( Left(Cmd, 14) ~= "EOTSAIM SETALL" )
	{
		bAimAssistEnabled    = (GetWordAt(MutateString, 2) != "0");
		bLaserEnabled        = (GetWordAt(MutateString, 3) != "0");
		bDebugOverlayEnabled = (GetWordAt(MutateString, 4) != "0");
		AimRotationBlendSpeed = FClamp(float(GetWordAt(MutateString, 5)), 1, 40);
		AimMaxDistance        = FClamp(float(GetWordAt(MutateString, 6)), 1000, 30000);
		AimTracePadding       = FClamp(float(GetWordAt(MutateString, 7)), 0, 64);
		AimShoulderOffset.X   = FClamp(float(GetWordAt(MutateString, 8)), -100, 100);
		AimShoulderOffset.Y   = FClamp(float(GetWordAt(MutateString, 9)), -100, 100);
		AimShoulderOffset.Z   = FClamp(float(GetWordAt(MutateString, 10)), -100, 100);
		CamArmX            = Clamp(int(float(GetWordAt(MutateString, 11))), 10, 300);
		CamArmZ            = Clamp(int(float(GetWordAt(MutateString, 12))), 0, 150);
		CamTraceDistance   = FClamp(float(GetWordAt(MutateString, 13)), 1000, 200000);
		CamCullForwardDot  = FClamp(float(GetWordAt(MutateString, 14)) / 100.0, 0.0, 1.0);
		CamCullMinDist     = FClamp(float(GetWordAt(MutateString, 15)), 0, 500);
		CamOffsetLerpSpeed = FClamp(float(GetWordAt(MutateString, 16)), 1, 30);
		CamStrafeCompMax   = FClamp(float(GetWordAt(MutateString, 17)), 0, 150);
		CamStrafeCompSpeed = FClamp(float(GetWordAt(MutateString, 18)), 1, 30);
		CamSmoothSpeed     = FClamp(float(GetWordAt(MutateString, 19)), 1, 50);
		SaveConfig();
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS settings applied");
		return;
	}

	if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
}

function bool alwaysKeep(Actor o)
{
	if (o.isA('EotsInv'))
		return true;
	if (NextMutator != None)
		return (NextMutator.AlwaysKeep(o));
	return false;
}

simulated function PostRender(canvas Canvas)
{
	local PlayerPawn P;
	local EotsCam Cam;

	if ( Canvas == None )
		return;

	P = Canvas.Viewport.Actor;
	if ( P != None )
	{
		ForEach AllActors(class'EotsCam', Cam)
		{
			if ( Cam.Owner == P && Cam.bDebugOverlayEnabled )
			{
				Cam.DrawDebugOverlay(Canvas);
				break;
			}
		}
	}

	if ( NextHUDMutator != None )
		NextHUDMutator.PostRender(Canvas);
}

simulated function SetFriendlyNames(string InFriendlyName, string InDescription)
{
	FriendlyNameText = InFriendlyName;
	DescriptionText = InDescription;
}

function string GetFriendlyName()
{
	if (FriendlyNameText == "")
		return "EOTS Camera";
	return FriendlyNameText;
}

function string GetDescription()
{
	if (DescriptionText == "")
		return "Rebranded third-person camera/aim-assist mutator.";
	return DescriptionText;
}

defaultproperties
{
	bAimAssistEnabled=False
	AimShoulderOffset=(X=9.000000,Y=4.000000,Z=6.000000)
	AimLaserHue=0
	AimLaserSaturation=255
	AimLaserBrightness=160
	AimRotationBlendSpeed=7.500000
	AimMaxDistance=12000.000000
	AimTracePadding=4.000000
	bLaserEnabled=False
	bDebugOverlayEnabled=False
	CamArmX=90
	CamArmZ=32
	CamTraceDistance=100000.000000
	CamCullForwardDot=0.300000
	CamCullMinDist=96.000000
	CamOffsetLerpSpeed=8.000000
	CamStrafeCompMax=25.000000
	CamStrafeCompSpeed=5.000000
	CamSmoothSpeed=15.000000
	bHUDMutator=True
	FriendlyNameText="EOTS Camera"
	DescriptionText="Rebranded third-person camera/aim-assist mutator."
}
