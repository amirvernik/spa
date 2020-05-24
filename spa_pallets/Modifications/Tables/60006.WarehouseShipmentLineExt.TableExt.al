tableextension 60006 WarehouseShipmentLine extends "Warehouse Shipment Line"
{

    fields
    {
        Field(60005; "Remaining Quantity"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}