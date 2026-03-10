//=============================================================================
// EotsSettingsClientWindow.
// In-menu settings panel for EOTS mutator config values.
//=============================================================================
class EotsSettingsClientWindow expands UMenuPageWindow;

var UWindowCheckbox AimAssistCheck;
var UWindowCheckbox LaserCheck;
var UWindowCheckbox DebugOverlayCheck;
var UWindowEditControl BlendEdit;
var UWindowEditControl MaxDistanceEdit;
var UWindowEditControl TracePaddingEdit;
var UWindowLabelControl OffsetLabel;
var UWindowEditControl OffsetXEdit;
var UWindowEditControl OffsetYEdit;
var UWindowEditControl OffsetZEdit;
var UWindowSmallButton SaveButton;
var UWindowLabelControl CameraLabel;
var UWindowEditControl CamArmXEdit;
var UWindowEditControl CamArmZEdit;
var UWindowEditControl CamTraceDistEdit;
var UWindowEditControl CamCullDotEdit;
var UWindowEditControl CamCullDistEdit;
var UWindowEditControl LerpSpeedEdit;
var UWindowEditControl CamSmoothSpeedEdit;
var UWindowEditControl StrafeCompMaxEdit;
var UWindowEditControl StrafeCompSpeedEdit;

function Created()
{
	local float RowY, Margin, CtrlW;
	Super.Created();

	Margin = 20;
	CtrlW = WinWidth - Margin * 2;

	RowY = 26;
	AimAssistCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', Margin, RowY, CtrlW, 1));
	AimAssistCheck.SetText("Enable Aim Assist");
	AimAssistCheck.SetHelpText("Master toggle for EOTS aim-assist behavior.");

	RowY += 24;
	LaserCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', Margin, RowY, CtrlW, 1));
	LaserCheck.SetText("Enable Laser Sight");
	LaserCheck.SetHelpText("Toggle the laser beam from weapon to aim point.");

	RowY += 24;
	DebugOverlayCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', Margin, RowY, CtrlW, 1));
	DebugOverlayCheck.SetText("Show Debug Overlay");
	DebugOverlayCheck.SetHelpText("Draw camera/trace debug values on the left side of HUD.");

	RowY += 34;
	BlendEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	BlendEdit.SetText("Blend Speed");
	BlendEdit.SetHelpText("Aim rotation blend speed (1 - 40).");
	BlendEdit.SetNumericOnly(True);
	BlendEdit.SetMaxLength(4);
	BlendEdit.EditBoxWidth = 60;

	RowY += 28;
	MaxDistanceEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	MaxDistanceEdit.SetText("Max Distance");
	MaxDistanceEdit.SetHelpText("Maximum aim trace distance (1000 - 30000).");
	MaxDistanceEdit.SetNumericOnly(True);
	MaxDistanceEdit.SetMaxLength(6);
	MaxDistanceEdit.EditBoxWidth = 60;

	RowY += 28;
	TracePaddingEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	TracePaddingEdit.SetText("Trace Padding");
	TracePaddingEdit.SetHelpText("Backoff from trace hit for wall-clip avoidance (0 - 64).");
	TracePaddingEdit.SetNumericOnly(True);
	TracePaddingEdit.SetMaxLength(4);
	TracePaddingEdit.EditBoxWidth = 60;

	RowY += 34;
	OffsetLabel = UWindowLabelControl(CreateControl(class'UWindowLabelControl', Margin, RowY, CtrlW, 1));
	OffsetLabel.SetText("Shoulder Offset  [default: X=16  Y=18  Z=8]");

	RowY += 22;
	OffsetXEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, 96, 1));
	OffsetXEdit.SetText("X");
	OffsetXEdit.SetHelpText("Shoulder offset forward/back (-25 to 25).");
	OffsetXEdit.SetMaxLength(5);
	OffsetXEdit.EditBoxWidth = 50;

	OffsetYEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin + 106, RowY, 96, 1));
	OffsetYEdit.SetText("Y");
	OffsetYEdit.SetHelpText("Shoulder offset left/right (-100 to 100).");
	OffsetYEdit.SetMaxLength(5);
	OffsetYEdit.EditBoxWidth = 50;

	OffsetZEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin + 212, RowY, 96, 1));
	OffsetZEdit.SetText("Z");
	OffsetZEdit.SetHelpText("Shoulder offset up/down (-100 to 100).");
	OffsetZEdit.SetMaxLength(5);
	OffsetZEdit.EditBoxWidth = 50;

	RowY += 34;
	CameraLabel = UWindowLabelControl(CreateControl(class'UWindowLabelControl', Margin, RowY, CtrlW, 1));
	CameraLabel.SetText("Camera Arm  [default: Length=90  Height=32]");

	RowY += 22;
	CamArmXEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, 140, 1));
	CamArmXEdit.SetText("Arm Length");
	CamArmXEdit.SetHelpText("Camera distance behind player (10 - 300).");
	CamArmXEdit.SetNumericOnly(True);
	CamArmXEdit.SetMaxLength(4);
	CamArmXEdit.EditBoxWidth = 50;

	CamArmZEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin + 150, RowY, 110, 1));
	CamArmZEdit.SetText("Arm Height");
	CamArmZEdit.SetHelpText("Camera vertical height above player (0 - 150).");
	CamArmZEdit.SetNumericOnly(True);
	CamArmZEdit.SetMaxLength(4);
	CamArmZEdit.EditBoxWidth = 50;

	RowY += 28;
	CamTraceDistEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	CamTraceDistEdit.SetText("Camera Trace Dist");
	CamTraceDistEdit.SetHelpText("How far camera traces forward for screen-centre aim (1000 - 200000).");
	CamTraceDistEdit.SetNumericOnly(True);
	CamTraceDistEdit.SetMaxLength(7);
	CamTraceDistEdit.EditBoxWidth = 70;

	RowY += 28;
	CamCullDotEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	CamCullDotEdit.SetText("Aim Cull Dot x100");
	CamCullDotEdit.SetHelpText("Min forward alignment to allow aim-cull (0-100 = 0.00-1.00). Default: 30.");
	CamCullDotEdit.SetNumericOnly(True);
	CamCullDotEdit.SetMaxLength(3);
	CamCullDotEdit.EditBoxWidth = 50;

	RowY += 28;
	CamCullDistEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	CamCullDistEdit.SetText("Aim Cull Min Dist");
	CamCullDistEdit.SetHelpText("Min distance from head before aim-cull activates (0 - 500).");
	CamCullDistEdit.SetNumericOnly(True);
	CamCullDistEdit.SetMaxLength(4);
	CamCullDistEdit.EditBoxWidth = 60;

	RowY += 28;
	LerpSpeedEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	LerpSpeedEdit.SetText("Offset Lerp Speed");
	LerpSpeedEdit.SetHelpText("How fast the shoulder offset animates to new values (1 - 30).");
	LerpSpeedEdit.SetNumericOnly(True);
	LerpSpeedEdit.SetMaxLength(3);
	LerpSpeedEdit.EditBoxWidth = 50;

	RowY += 28;
	CamSmoothSpeedEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	CamSmoothSpeedEdit.SetText("Camera Smooth Speed");
	CamSmoothSpeedEdit.SetHelpText("Camera orbit stiffness - higher is tighter/faster, lower is floaty (1 - 50).");
	CamSmoothSpeedEdit.SetNumericOnly(True);
	CamSmoothSpeedEdit.SetMaxLength(3);
	CamSmoothSpeedEdit.EditBoxWidth = 50;

	RowY += 28;
	StrafeCompMaxEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	StrafeCompMaxEdit.SetText("Strafe Comp Max");
	StrafeCompMaxEdit.SetHelpText("Max camera shift when strafing to keep character off-centre (0 = off, 0 - 150).");
	StrafeCompMaxEdit.SetNumericOnly(True);
	StrafeCompMaxEdit.SetMaxLength(4);
	StrafeCompMaxEdit.EditBoxWidth = 50;

	RowY += 28;
	StrafeCompSpeedEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', Margin, RowY, CtrlW, 1));
	StrafeCompSpeedEdit.SetText("Strafe Comp Speed");
	StrafeCompSpeedEdit.SetHelpText("How fast strafe compensation blends in and out (1 - 30).");
	StrafeCompSpeedEdit.SetNumericOnly(True);
	StrafeCompSpeedEdit.SetMaxLength(3);
	StrafeCompSpeedEdit.EditBoxWidth = 50;

	RowY += 32;
	SaveButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', Margin, RowY, 100, 16));
	SaveButton.SetText("Save & Apply");

	LoadValues();
}

function LoadValues()
{
	AimAssistCheck.bChecked = class'EotsCameraMut'.default.bAimAssistEnabled;
	LaserCheck.bChecked = class'EotsCameraMut'.default.bLaserEnabled;
	DebugOverlayCheck.bChecked = class'EotsCameraMut'.default.bDebugOverlayEnabled;
	BlendEdit.SetValue(string(int(class'EotsCameraMut'.default.AimRotationBlendSpeed)));
	MaxDistanceEdit.SetValue(string(int(class'EotsCameraMut'.default.AimMaxDistance)));
	TracePaddingEdit.SetValue(string(int(class'EotsCameraMut'.default.AimTracePadding)));
	OffsetXEdit.SetValue(string(int(class'EotsCameraMut'.default.AimShoulderOffset.X)));
	OffsetYEdit.SetValue(string(int(class'EotsCameraMut'.default.AimShoulderOffset.Y)));
	OffsetZEdit.SetValue(string(int(class'EotsCameraMut'.default.AimShoulderOffset.Z)));
	CamArmXEdit.SetValue(string(class'EotsCameraMut'.default.CamArmX));
	CamArmZEdit.SetValue(string(class'EotsCameraMut'.default.CamArmZ));
	CamTraceDistEdit.SetValue(string(int(class'EotsCameraMut'.default.CamTraceDistance)));
	CamCullDotEdit.SetValue(string(int(class'EotsCameraMut'.default.CamCullForwardDot * 100)));
	CamCullDistEdit.SetValue(string(int(class'EotsCameraMut'.default.CamCullMinDist)));
	LerpSpeedEdit.SetValue(string(int(class'EotsCameraMut'.default.CamOffsetLerpSpeed)));
	CamSmoothSpeedEdit.SetValue(string(int(class'EotsCameraMut'.default.CamSmoothSpeed)));
	StrafeCompMaxEdit.SetValue(string(int(class'EotsCameraMut'.default.CamStrafeCompMax)));
	StrafeCompSpeedEdit.SetValue(string(int(class'EotsCameraMut'.default.CamStrafeCompSpeed)));
}

function SaveValues()
{
	local float fx, fy, fz, blendspeed, maxdist, tracepad;
	local int icamx, icamz, iculdot;
	local float tracedist, culldist, lerpspeed, camsmooth, strafemax, strafespeed;
	local PlayerPawn P;

	blendspeed = FClamp(float(BlendEdit.GetValue()), 1, 40);
	maxdist    = FClamp(float(MaxDistanceEdit.GetValue()), 1000, 30000);
	tracepad   = FClamp(float(TracePaddingEdit.GetValue()), 0, 64);
	fx = FClamp(float(OffsetXEdit.GetValue()), -100, 100);
	fy = FClamp(float(OffsetYEdit.GetValue()), -100, 100);
	fz = FClamp(float(OffsetZEdit.GetValue()), -100, 100);
	icamx    = Clamp(int(float(CamArmXEdit.GetValue())), 10, 300);
	icamz    = Clamp(int(float(CamArmZEdit.GetValue())), 0, 150);
	tracedist = FClamp(float(CamTraceDistEdit.GetValue()), 1000, 200000);
	iculdot  = Clamp(int(float(CamCullDotEdit.GetValue())), 0, 100);
	culldist  = FClamp(float(CamCullDistEdit.GetValue()), 0, 500);
	lerpspeed = FClamp(float(LerpSpeedEdit.GetValue()), 1, 30);
	camsmooth   = FClamp(float(CamSmoothSpeedEdit.GetValue()), 1, 50);
	strafemax   = FClamp(float(StrafeCompMaxEdit.GetValue()), 0, 150);
	strafespeed = FClamp(float(StrafeCompSpeedEdit.GetValue()), 1, 30);

	// Update local defaults and persist to this client's INI.
	class'EotsCameraMut'.default.bAimAssistEnabled    = AimAssistCheck.bChecked;
	class'EotsCameraMut'.default.bLaserEnabled         = LaserCheck.bChecked;
	class'EotsCameraMut'.default.bDebugOverlayEnabled  = DebugOverlayCheck.bChecked;
	class'EotsCameraMut'.default.AimRotationBlendSpeed = blendspeed;
	class'EotsCameraMut'.default.AimMaxDistance        = maxdist;
	class'EotsCameraMut'.default.AimTracePadding       = tracepad;
	class'EotsCameraMut'.default.AimShoulderOffset.X   = fx;
	class'EotsCameraMut'.default.AimShoulderOffset.Y   = fy;
	class'EotsCameraMut'.default.AimShoulderOffset.Z   = fz;
	class'EotsCameraMut'.default.CamArmX               = icamx;
	class'EotsCameraMut'.default.CamArmZ               = icamz;
	class'EotsCameraMut'.default.CamTraceDistance      = tracedist;
	class'EotsCameraMut'.default.CamCullForwardDot     = float(iculdot) / 100.0;
	class'EotsCameraMut'.default.CamCullMinDist        = culldist;
	class'EotsCameraMut'.default.CamOffsetLerpSpeed    = lerpspeed;
	class'EotsCameraMut'.default.CamSmoothSpeed        = camsmooth;
	class'EotsCameraMut'.default.CamStrafeCompMax      = strafemax;
	class'EotsCameraMut'.default.CamStrafeCompSpeed    = strafespeed;
	class'EotsCameraMut'.static.StaticSaveConfig();

	// Send all values inline so the server applies them directly without
	// reading its own config file (which the client cannot update remotely).
	P = GetPlayerOwner();
	if ( P != None )
		P.ConsoleCommand("mutate eotsaim setall "
			$ string(int(AimAssistCheck.bChecked)) $ " "
			$ string(int(LaserCheck.bChecked)) $ " "
			$ string(int(DebugOverlayCheck.bChecked)) $ " "
			$ string(blendspeed) $ " "
			$ string(maxdist) $ " "
			$ string(tracepad) $ " "
			$ string(fx) $ " "
			$ string(fy) $ " "
			$ string(fz) $ " "
			$ string(icamx) $ " "
			$ string(icamz) $ " "
			$ string(tracedist) $ " "
			$ string(iculdot) $ " "
			$ string(culldist) $ " "
			$ string(lerpspeed) $ " "
			$ string(camsmooth) $ " "
			$ string(strafemax) $ " "
			$ string(strafespeed));
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	// Checkboxes take effect immediately.
	if ( E == DE_Change && (C == AimAssistCheck || C == LaserCheck || C == DebugOverlayCheck) )
		SaveValues();

	// Save button commits numeric fields.
	if ( C == SaveButton && E == DE_Click )
		SaveValues();
}
