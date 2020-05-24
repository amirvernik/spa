tableextension 60008 ReturnReceiptLineExt extends "Return Receipt Line"
{
    fields
    {
        field(60000; "SPA Order No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "SPA Order Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(60002; "Pallet/s Exist"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}