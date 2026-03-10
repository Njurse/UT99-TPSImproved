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
var bool bLaserEnabled;
var bool bDebugOverlayEnabled;
var int CamArmX;
var int CamArmZ;
var float CamTraceDistance;
var float CamCullForwardDot;
var float CamCullMinDist;
var float CamOffsetLerpSpeed;
var float CamStrafeCompMax;
var float CamStrafeCompSpeed;
var float CamSmoothSpeed;
var bool bClientCameraSystemEnabled;
var bool bClientSettingsInitialized;
var int SettingsRevision;
var int LastAppliedRevision;

replication
{
	reliable if ( Role == ROLE_Authority )
		bAimAssistEnabled, AimShoulderOffset, AimLaserHue,
		AimLaserSaturation, AimLaserBrightness, AimRotationBlendSpeed,
		AimMaxDistance, AimTracePadding, bLaserEnabled, bDebugOverlayEnabled,
		CamArmX, CamArmZ, CamTraceDistance, CamCullForwardDot,
		CamCullMinDist, CamOffsetLerpSpeed, CamStrafeCompMax,
		CamStrafeCompSpeed, CamSmoothSpeed, SettingsRevision,
		ClientOpenSettings;
}

simulated function string GetNetPrefix()
{
	if ( Level.NetMode == NM_DedicatedServer )
		return "EOTS_CAMERA [DedicatedServer]:";
	if ( Level.NetMode == NM_ListenServer )
		return "EOTS_CAMERA [ListenServer]:";
	if ( Level.NetMode == NM_Client )
		return "EOTS_CAMERA [Client]:";
	return "EOTS_CAMERA [Standalone]:";
}

simulated function bool IsLocalViewportOwner()
{
	local PlayerPawn Pp;

	Pp = PlayerPawn(Owner);
	return Pp != None && Pp.Player != None && Viewport(Pp.Player) != None;
}

simulated function InitializeClientSettings()
{
	if ( bClientSettingsInitialized )
		return;

	bClientCameraSystemEnabled = class'EotsClientConfig'.static.IsCameraSystemEnabled();
	bClientSettingsInitialized = True;
}

simulated function SetClientCameraSystemEnabled(bool bEnabled)
{
	InitializeClientSettings();
	bClientCameraSystemEnabled = bEnabled;
	class'EotsClientConfig'.static.SetCameraSystemEnabled(bEnabled);
	ApplyMutatorSettings();
}

simulated function ConfigureAimSettings(
	bool bInEnabled,
	vector InShoulderOffset,
	byte InLaserHue,
	byte InLaserSaturation,
	byte InLaserBrightness,
	float InRotationBlendSpeed,
	float InMaxDistance,
	float InTracePadding,
	bool bInLaserEnabled
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
	bLaserEnabled = bInLaserEnabled;

	if ( Role == ROLE_Authority )
		SettingsRevision++;
	ApplyMutatorSettings();
}

simulated function ApplyMutatorSettings()
{
	if ( AimAssist != None )
	{
		AimAssist.Configure(
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

	if ( Cam != None )
	{
		Cam.bDebugOverlayEnabled = bDebugOverlayEnabled;
		Cam.bLaserEnabled = bLaserEnabled;
		Cam.SetClientCameraEnabled(bClientCameraSystemEnabled);
		Cam.CamX = CamArmX;
		Cam.CamZ = CamArmZ;
		Cam.AimTraceDistance = CamTraceDistance;
		Cam.AimCullMinForwardDot = CamCullForwardDot;
		Cam.AimCullMinDistance = CamCullMinDist;
		Cam.OffsetLerpSpeed = CamOffsetLerpSpeed;
		Cam.StrafeCompensationMax = CamStrafeCompMax;
		Cam.StrafeCompensationSpeed = CamStrafeCompSpeed;
		Cam.CamSmoothSpeed = CamSmoothSpeed;
	}
}

simulated function ConfigureDebugOverlay(bool bInEnabled)
{
	bDebugOverlayEnabled = bInEnabled;
	if ( Role == ROLE_Authority )
		SettingsRevision++;
	ApplyMutatorSettings();
}

simulated function ConfigureCamSettings(
	int InArmX,
	int InArmZ,
	float InTraceDist,
	float InCullDot,
	float InCullDist,
	float InLerpSpeed,
	float InStrafeCompMax,
	float InStrafeCompSpeed,
	float InSmoothSpeed
)
{
	CamArmX = InArmX;
	CamArmZ = InArmZ;
	CamTraceDistance = InTraceDist;
	CamCullForwardDot = InCullDot;
	CamCullMinDist = InCullDist;
	CamOffsetLerpSpeed = InLerpSpeed;
	CamStrafeCompMax = InStrafeCompMax;
	CamStrafeCompSpeed = InStrafeCompSpeed;
	CamSmoothSpeed = InSmoothSpeed;
	if ( Role == ROLE_Authority )
		SettingsRevision++;
	ApplyMutatorSettings();
}

function PickupFunction(Pawn Other)
{
	// Camera actors are spawned client-side in Tick.  Server just logs.
	log(GetNetPrefix() $ " Inventory attached to " $ Other.GetHumanName());
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

	if ( !IsLocalViewportOwner() )
		return;

	InitializeClientSettings();
	if ( Cam == None )
	{
		Cam = Spawn(class'EotsCam', Owner);
		AimAssist = Spawn(class'EotsAimAssist', Owner);
		Cam.AimAssist = AimAssist;
		ApplyMutatorSettings();
		log(GetNetPrefix() $ " Client camera spawned for " $ Owner.GetHumanName());
	}

	// Detect replicated settings changes from the server.
	if ( SettingsRevision != LastAppliedRevision )
	{
		ApplyMutatorSettings();
		LastAppliedRevision = SettingsRevision;
		log(GetNetPrefix() $ " Config sync received (rev " $ string(SettingsRevision) $ ")");
	}
}

simulated function ConfigureFromLocalDefaults()
{
	bAimAssistEnabled = class'EotsCameraMut'.default.bAimAssistEnabled;
	AimShoulderOffset = class'EotsCameraMut'.default.AimShoulderOffset;
	AimLaserHue = class'EotsCameraMut'.default.AimLaserHue;
	AimLaserSaturation = class'EotsCameraMut'.default.AimLaserSaturation;
	AimLaserBrightness = class'EotsCameraMut'.default.AimLaserBrightness;
	AimRotationBlendSpeed = class'EotsCameraMut'.default.AimRotationBlendSpeed;
	AimMaxDistance = class'EotsCameraMut'.default.AimMaxDistance;
	AimTracePadding = class'EotsCameraMut'.default.AimTracePadding;
	bLaserEnabled = class'EotsCameraMut'.default.bLaserEnabled;
	bDebugOverlayEnabled = class'EotsCameraMut'.default.bDebugOverlayEnabled;
	CamArmX = class'EotsCameraMut'.default.CamArmX;
	CamArmZ = class'EotsCameraMut'.default.CamArmZ;
	CamTraceDistance = class'EotsCameraMut'.default.CamTraceDistance;
	CamCullForwardDot = class'EotsCameraMut'.default.CamCullForwardDot;
	CamCullMinDist = class'EotsCameraMut'.default.CamCullMinDist;
	CamOffsetLerpSpeed = class'EotsCameraMut'.default.CamOffsetLerpSpeed;
	CamStrafeCompMax = class'EotsCameraMut'.default.CamStrafeCompMax;
	CamStrafeCompSpeed = class'EotsCameraMut'.default.CamStrafeCompSpeed;
	CamSmoothSpeed = class'EotsCameraMut'.default.CamSmoothSpeed;
	ApplyMutatorSettings();
}

exec function EOTSCameraSystemEnable(bool bEnable)
{
	SetClientCameraSystemEnabled(bEnable);
}

exec function EOTSCameraSystemToggle()
{
	SetClientCameraSystemEnabled(!bClientCameraSystemEnabled);
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

exec function EOTSOpenSettings()
{
	OpenSettingsWindow();
}

simulated function OpenSettingsWindow()
{
	local PlayerPawn Pp;
	local WindowConsole WC;

	Pp = PlayerPawn(Owner);
	if ( Pp == None || Pp.Player == None || Viewport(Pp.Player) == None )
		return;

	WC = WindowConsole(Viewport(Pp.Player).Console);
	if ( WC == None || WC.Root == None )
		return;

	WC.bQuickKeyEnable = True;
	WC.LaunchUWindow();
	WC.Root.CreateWindow(class'EotsSettingsWindow', 100, 80, 380, 560, None, True);
}

simulated function ClientOpenSettings()
{
	OpenSettingsWindow();
}

simulated function Destroyed()
{
	if ( Cam != None )
	{
		Cam.Destroy();
		Cam = None;
	}
	if ( AimAssist != None )
	{
		AimAssist.Destroy();
		AimAssist = None;
	}
	Super.Destroyed();
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
	bLaserEnabled=False
	bDebugOverlayEnabled=True
	CamArmX=90
	CamArmZ=32
	CamTraceDistance=100000.000000
	CamCullForwardDot=0.300000
	CamCullMinDist=96.000000
	CamOffsetLerpSpeed=8.000000
	CamStrafeCompMax=25.000000
	CamStrafeCompSpeed=5.000000
	CamSmoothSpeed=15.000000
	bClientCameraSystemEnabled=True
}
