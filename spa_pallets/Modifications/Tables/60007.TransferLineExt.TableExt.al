tableextension 60007 TransferLineExt extends "Transfer Line"
{
    fields
    {
        field(60000; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Pallet Header"."Pallet ID" where("Pallet Status" = filter(closed)
             , "Location Code" = field("Transfer-to Code"));
        }
        field(60001; "Lot No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(60002; "Pallet Type"; Text[20])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}