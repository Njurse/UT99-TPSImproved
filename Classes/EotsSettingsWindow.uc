//=============================================================================
// EotsSettingsWindow.
// Framed window host for the EOTS settings page.
//=============================================================================
class EotsSettingsWindow expands UWindowFramedWindow;

function Created()
{
	Super.Created();
	bSizable = False;
	bStatusBar = False;
	ClientClass = class'EotsSettingsClientWindow';
	WindowTitle = "EOTS Camera Settings";
}

defaultproperties
{
	ClientClass=class'EotsSettingsClientWindow'
	WindowTitle="EOTS Camera Settings"
}
