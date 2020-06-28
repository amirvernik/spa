table 60018 "Pallet Line Change Quality"
{
    Caption = 'Pallet Line Change Quality';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; Description; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Location Code"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Lot Number"; code[20])

        {
            DataClassification = ToBeClassified;

        }
        field(7; "Unit of Measure"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(8; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }

        field(9; "Expiration Date"; date)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "User ID"; code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Exists on Warehouse Shipment"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Purchase Order No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Purchase Order Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Replaced Qty"; Decimal)
        {
            Caption = 'Replaced Qty';
            DataClassification = ToBeClassified;
        }
        field(60020; "Variant Code"; code[10])
        {
            caption = 'Variety';
        }
    }

    keys
    {
        key(PK; "Pallet ID", "Line No.")
        {
            Clustered = true;
        }
    }

}
