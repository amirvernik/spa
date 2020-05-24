tableextension 60010 UserSetupExt extends "User Setup"
{
    fields
    {

        field(60000; "Can ReOpen Pallet"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "Remove Pallet from Whse. Ship"; Boolean)
        {
            DataClassification = ToBeClassified;
        }

    }

    var
        myInt: Integer;
}