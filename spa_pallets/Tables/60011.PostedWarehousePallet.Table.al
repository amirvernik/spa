table 60011 "Posted Warehouse Pallet"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;

        }
        field(2; "Pallet Line No."; Integer)
        {
            DataClassification = ToBeClassified;

        }
        field(3; "Whse Shipment No."; code[20])
        {
            DataClassification = ToBeClassified;

        }
        field(4; "Whse Shipment Line No."; integer)
        {
            DataClassification = ToBeClassified;

        }
        field(5; "User Created"; code[50])
        {
            DataClassification = ToBeClassified;

        }
        field(6; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;

        }
        field(7; "Reserve. Entry No."; Integer)
        {
            DataClassification = ToBeClassified;

        }
        field(8; "Sales Order No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Sales Order Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Lot No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Whse Shipment No.", "Whse Shipment Line No.", "Pallet ID", "Pallet Line No.")
        {
            Clustered = true;
        }
    }

}