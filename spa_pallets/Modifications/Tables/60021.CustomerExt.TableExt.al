tableextension 60021 customerExt extends Customer
{
    fields
    {
        field(60000; "Dispatch Format Code"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "Dispatch Format Description"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60002; "Item Label Format Code"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(60003; "Item Label Format Description"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60004; "Dispatch Format No. of Copies"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(60005; "SSCC Sticker Note"; Boolean)
        {
            BlankZero = true;
            DataClassification = ToBeClassified;
        }
        field(60006; "Packing Days"; integer)
        {
            BlankZero = true;
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}