tableextension 60021 customerExt extends Customer
{
    fields
    {
        field(60000; "Dispatch Format"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "Item Label Format"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60002; "Dispatch Format No. of Copies"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(60003; "SSCC Sticker Note"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}