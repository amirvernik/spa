table 60012 "Pallet Avail Error"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Error No."; Integer)
        {
            DataClassification = ToBeClassified;

        }

        field(2; "Error Description"; Text[1024])
        {
            DataClassification = ToBeClassified;

        }
        field(3; "Shipment No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Error No.")
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