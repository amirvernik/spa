tableextension 60004 SalesLineExt extends "Sales Line"
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
        field(60003; "Dispatch Date"; date)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}