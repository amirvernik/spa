tableextension 60016 WarehouseShipmentHeaderExt extends "Warehouse Shipment Header"
{
    fields
    {

        field(60000; "User Created"; code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(60001; "Allocated"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
    var
        myInt: Integer;
}