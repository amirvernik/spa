table 60004 "Packing Material Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; code[20])
        {
            Caption = 'Pallet ID';
            DataClassification = ToBeClassified;

        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = ToBeClassified;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;
        }
        field(5; Description; text[100])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(6; "Unit of Measure Code"; text[100])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = ToBeClassified;
        }
        field(7; "Location Code"; code[20])
        {
            Caption = 'Location Code';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Pallet ID", "Item No.", "Unit of Measure Code")
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