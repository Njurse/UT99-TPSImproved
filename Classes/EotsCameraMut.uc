//=============================================================================
// EotsCameraMut.
// Rebranded third-person camera/aim-assist mutator.
//=============================================================================
class EotsCameraMut expands Mutator config(EOTSCamera);

var() config bool bAimAssistEnabled;
var() config vector AimShoulderOffset;
var() config byte AimLaserHue;
var() config byte AimLaserSaturation;
var() config byte AimLaserBrightness;
var() config float AimRotationBlendSpeed;
var() config float AimMaxDistance;
var() config float AimTracePadding;

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
		}
	}
	if ( NextMutator != None )
		NextMutator.ModifyPlayer(Other);
}

function ApplySettingsToPlayers()
{
	local EotsAimAssist Assist;

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
			AimTracePadding
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
		ApplySettingsToPlayers();
		if ( Sender != None )
			Sender.ClientMessage("EOTS Aim Assist settings reapplied");
		return;
	}

	if ( Left(Cmd, 14) ~= "EOTSAIM OFFSET " )
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

	if ( Left(Cmd, 13) ~= "EOTSAIM LASER " )
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
	bAimAssistEnabled=True
	AimShoulderOffset=(X=16.000000,Y=18.000000,Z=8.000000)
	AimLaserHue=0
	AimLaserSaturation=255
	AimLaserBrightness=160
	AimRotationBlendSpeed=7.500000
	AimMaxDistance=12000.000000
	AimTracePadding=4.000000
	FriendlyNameText="EOTS Camera"
	DescriptionText="Rebranded third-person camera/aim-assist mutator."
}
