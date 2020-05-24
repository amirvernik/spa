table 60009 "Lot Selection"
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
        field(3; "Lot"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Quantity Available"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Qty. to Reserve"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Expiration Date"; date)
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Variant code"; Code[20])
        {
            caption='Variety';
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(PK; "Pallet ID", "Pallet Line No.", Lot)
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