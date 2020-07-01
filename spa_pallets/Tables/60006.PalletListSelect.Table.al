table 60006 "Pallet List Select"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;

        }
        field(2; "Select"; Boolean)
        {
            DataClassification = ToBeClassified;

        }
        field(3; "Source Document"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(4; "Total Qty"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Pallet ID")
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