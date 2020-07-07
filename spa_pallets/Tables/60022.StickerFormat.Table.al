table 60022 "Sticker Format"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(10; "Format Type"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Format Type".code;
        }
        field(20; "Sticker Code"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Sticker Description"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Format Type", "Sticker Code")
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