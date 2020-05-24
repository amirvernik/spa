table 60010 "Pallet reservation Entry"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Pallet Line"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Lot No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(5; "Item No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Variant Code"; code[20])
        {
            caption = 'Variety';
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Pallet ID", "Pallet Line", "Lot No.")
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