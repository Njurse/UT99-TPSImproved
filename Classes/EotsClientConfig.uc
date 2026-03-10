//=============================================================================
// EotsClientConfig.
// Client-local camera preferences stored in the EOTSCamera ini.
//=============================================================================
class EotsClientConfig expands Object config(EOTSCamera);

var() config bool bCameraSystemEnabled;

static function bool IsCameraSystemEnabled()
{
	return default.bCameraSystemEnabled;
}

static function SetCameraSystemEnabled(bool bEnabled)
{
	default.bCameraSystemEnabled = bEnabled;
	StaticSaveConfig();
}

defaultproperties
{
	bCameraSystemEnabled=True
}