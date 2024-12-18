//=============================================================================
// TpsMut.
//=============================================================================
class TpsMut expands Mutator;

function AddMutator(Mutator M)
{
	if ( M.IsA('ToprealMut') )
	{
		log("TopReal mutator not allowed (already have Third-Person mutator)");
		return;
	}
	Super.AddMutator(M);
}

function ModifyPlayer(Pawn Other)
{
	Local PickUp I;

	if ( Other.IsA('PlayerPawn') )
	{
		I = Spawn(class'TpsInv');
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

function bool alwaysKeep(Actor o)
{
	if (o.isA('TpsInv'))
		return true;
	if (NextMutator != None)
		return (NextMutator.AlwaysKeep(o));
}

defaultproperties
{
}
