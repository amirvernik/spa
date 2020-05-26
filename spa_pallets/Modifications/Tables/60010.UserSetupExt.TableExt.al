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

        field(60002; "UI Password"; Text[50])
        {
            DataClassification = ToBeClassified;
            ExtendedDatatype = Masked;
        }
        field(60003; "WS Access Key"; Text[50])
        {
            DataClassification = ToBeClassified;
            ExtendedDatatype = Masked;
        }

    }

    var
        myInt: Integer;
}