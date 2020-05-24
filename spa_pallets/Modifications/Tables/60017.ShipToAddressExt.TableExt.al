tableextension 60017 ShipToAddressExt extends "Ship-to Address"
{
    fields
    {
        field(60000; "Shipping Time"; DateFormula)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}