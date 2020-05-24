table 60000 "SPA Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(2; "Item Journal Batch"; code[10])
        {
            DataClassification = ToBeClassified;

        }
    }

    keys
    {
        key(PK; "Primary Key")
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