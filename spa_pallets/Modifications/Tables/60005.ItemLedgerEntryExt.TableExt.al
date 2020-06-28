tableextension 60005 ItemLedgerEntryExt extends "Item Ledger Entry"
{
    fields
    {
        field(60000; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Pallet Header";
        }
        field(60001; "Pallet Type"; text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(60002;Disposal;Boolean)
        {
            DataClassification=ToBeClassified;
        }        
    }

    var
        myInt: Integer;
}