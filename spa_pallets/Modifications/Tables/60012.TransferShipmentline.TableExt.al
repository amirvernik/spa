tableextension 60012 TransferShipmentLineExt extends "Transfer Shipment Line"
{
    fields
    {
        field(60000; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Pallet Header";
        }
        field(60001; "Lot No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}