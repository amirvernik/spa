tableextension 60005 ItemLedgerEntryExt extends "Item Ledger Entry"
{
    fields
    {
        field(60000; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Pallet Header";
        }
    }

    var
        myInt: Integer;
}