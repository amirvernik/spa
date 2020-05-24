table 60005 "Pallet Ledger Entry"
{

    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;

        }
        field(2; "Entry Type"; Enum "Pallet Ledger Type")
        {
            DataClassification = ToBeClassified;

        }
        field(3; "Posting Date"; date)
        {
            DataClassification = ToBeClassified;

        }
        field(4; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Pallet Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Item No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Item Description"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Lot Number"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Location Code"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Unit of Measure"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(11; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Document No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(13; "User ID"; code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Item Ledger Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(15; "Document Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(16; "Order No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(17; "Order Line No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(18; "Order Type"; Text[20])
        {
            DataClassification = ToBeClassified;
        }
        field(19; "Date Time Created"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(60020;"Variant Code";code[20])
        {
            caption='Variety';
            DataClassification=ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin
        "Date Time Created" := CurrentDateTime

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