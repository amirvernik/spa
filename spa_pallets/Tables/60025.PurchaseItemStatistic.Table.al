table 60025 "Purchase Items Statistic"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Grade; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(2; Size; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(3; TotalGrade; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(4; TotalSize; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(5; Proportion; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(6; "Purchase Number"; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(7; User; Code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(8; Done; Boolean) { }
    }

    keys
    {
        key(PK; Grade, Size, "Purchase Number", User)
        {
            Clustered = true;
        }
    }


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