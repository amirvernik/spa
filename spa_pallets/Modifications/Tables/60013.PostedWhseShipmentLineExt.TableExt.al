tableextension 60013 PostedWhseShipmentLineExt extends "Posted Whse. Shipment Line"
{
    fields
    {
        Field(60005; "Remaining Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}