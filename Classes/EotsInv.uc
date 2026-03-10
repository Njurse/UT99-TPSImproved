//=============================================================================
// EotsInv.
//=============================================================================
class EotsInv expands TournamentPickup;

var EotsCam Cam;
var EotsAimAssist AimAssist;
var bool bAimAssistEnabled;
var vector AimShoulderOffset;
var byte AimLaserHue;
var byte AimLaserSaturation;
var byte AimLaserBrightness;
var float AimRotationBlendSpeed;
var float AimMaxDistance;
var float AimTracePadding;

function ConfigureAimSettings(
	bool bInEnabled,
	vector InShoulderOffset,
	byte InLaserHue,
	byte InLaserSaturation,
	byte InLaserBrightness,
	float InRotationBlendSpeed,
	float InMaxDistance,
	float InTracePadding
)
{
	bAimAssistEnabled = bInEnabled;
	AimShoulderOffset = InShoulderOffset;
	AimLaserHue = InLaserHue;
	AimLaserSaturation = InLaserSaturation;
	AimLaserBrightness = InLaserBrightness;
	AimRotationBlendSpeed = InRotationBlendSpeed;
	AimMaxDistance = InMaxDistance;
	AimTracePadding = InTracePadding;

	ApplyMutatorSettings();
}

function ApplyMutatorSettings()
{
	if ( AimAssist == None )
		return;

	AimAssist.Configure(
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

function PickupFunction(Pawn Other)
{
	if ( Cam == None )
		Cam = Spawn(class'EotsCam',Other);
	if ( AimAssist == None )
		AimAssist = Spawn(class'EotsAimAssist',Other);

	ApplyMutatorSettings();
}

simulated function Tick(Float Deltatime)
{
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( Owner == None )
	{
		Destroy();
		Return;
	}
}

exec function EOTSaimEnable(bool bEnable)
{
	bAimAssistEnabled = bEnable;
	ApplyMutatorSettings();

	if ( bEnable )
		PlayerPawn(Owner).ConsoleCommand("mutate eotsaim on");
	else
		PlayerPawn(Owner).ConsoleCommand("mutate eotsaim off");
}

exec function EOTSaimToggle()
{
	EOTSaimEnable(!bAimAssistEnabled);
}

exec function EOTSaimSetOffset(float X, float Y, float Z)
{
	AimShoulderOffset.X = X;
	AimShoulderOffset.Y = Y;
	AimShoulderOffset.Z = Z;
	ApplyMutatorSettings();
	PlayerPawn(Owner).ConsoleCommand("mutate eotsaim offset " $ string(X) $ " " $ string(Y) $ " " $ string(Z));
}

exec function EOTSaimSetLaserColor(byte Hue, byte Saturation, byte Brightness)
{
	AimLaserHue = Hue;
	AimLaserSaturation = Saturation;
	AimLaserBrightness = Brightness;
	ApplyMutatorSettings();
	PlayerPawn(Owner).ConsoleCommand("mutate eotsaim laser " $ string(Hue) $ " " $ string(Saturation) $ " " $ string(Brightness));
}

defaultproperties
{
	bAimAssistEnabled=False
	AimShoulderOffset=(X=16.000000,Y=18.000000,Z=8.000000)
	AimLaserHue=0
	AimLaserSaturation=255
	AimLaserBrightness=160
	AimRotationBlendSpeed=7.500000
	AimMaxDistance=12000.000000
	AimTracePadding=4.000000
}
