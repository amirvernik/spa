table 60016 "Packing Materials Select"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(10; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "PM Item No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(25; "Pallet Packing Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "PM Item Description"; text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(40; "Quantity"; Decimal)
        {
            MinValue = 0;
            DataClassification = ToBeClassified;
        }
        field(100; Select; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Pallet Packing Line No.", "Pallet ID", "PM Item No.")
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