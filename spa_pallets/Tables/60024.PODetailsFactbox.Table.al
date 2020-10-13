table 60024 "PO Details Factbox"
{
    DataClassification = ToBeClassified;
    Caption = 'Pallet Information';

    fields
    {
        field(1; "Purchase Order No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Purchase Order Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }

        field(3; "Pallet ID"; code[20])
        {


        }
        field(4; "Pallet Line No."; Integer)
        {
            DataClassification = ToBeClassified;

        }
        field(5; "Whse Shipment No."; code[20])
        {

        }
        field(6; "Whse Shipment Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Posted Whse Shipment No."; code[20])
        {

        }
        field(8; "Posted Whse Shipment Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(9; "User Created"; code[50])
        {
            DataClassification = ToBeClassified;

        }

        field(10; "Sales Order No."; code[20])
        {
        }
        field(11; "Pallet Type"; Text[20]) { }
    }

    keys
    {
        key(PK; "Purchase Order No.", "Purchase Order Line No.", "User Created", "Pallet ID", "Pallet Line No.")
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}