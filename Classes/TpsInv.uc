//=============================================================================
// TpsInv.
//=============================================================================
class TpsInv expands TournamentPickup;

var TpsCam Cam;

function PickupFunction(Pawn Other)
{
	Cam = Spawn(class'TPsCam',Other); 
}

simulated function Tick(Float Deltatime)
{
	local PlayerPawn P;
	local bool bFound;

	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( Owner == None )
	{
		Destroy();
		Return;
	}
	P = PlayerPawn(Owner);

}

defaultproperties
{
}
