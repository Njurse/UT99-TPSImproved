//=============================================================================
// EotsModMenuItem.
// Adds EOTS settings entry to the UT Mods menu.
//=============================================================================
class EotsModMenuItem expands UMenuModMenuItem;

function Execute()
{
	if ( MenuItem == None || MenuItem.Owner == None || MenuItem.Owner.Root == None )
		return;

	MenuItem.Owner.Root.CreateWindow(class'EotsSettingsWindow', 100, 80, 380, 560, None, True);
}

defaultproperties
{
	MenuCaption="EOTS Camera Settings"
	MenuHelp="Open settings for EOTS camera and aim-assist."
}
