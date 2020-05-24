tableextension 60015 ItemJournalLineExt extends "Item Journal Line"
{
    fields
    {
        field(60000; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "Pallet Type"; text[20])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}