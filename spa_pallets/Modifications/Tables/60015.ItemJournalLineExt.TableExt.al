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
        field(60002; Disposal; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(60003; "Packing Material UOM"; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(60004; "Packing Material Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(60005; "Pallet Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }

    }

    var
        myInt: Integer;
}