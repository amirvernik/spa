tableextension 60022 SalesLineArchiveExt extends "Sales Line Archive"
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