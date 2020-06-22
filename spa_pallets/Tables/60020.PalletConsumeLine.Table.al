table 60020 "Pallet Consume Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Pallet Line"; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(3; "Item No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Variant Code"; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(5; Description; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(10; Quantity; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Consumed Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Remaining Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Pallet ID", "Pallet Line")
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