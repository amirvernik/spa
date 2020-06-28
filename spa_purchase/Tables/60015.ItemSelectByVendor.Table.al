table 60015 "Item Select By Vendor"
{
    LookupPageId = "Item Select By Vendor";
    DataClassification = ToBeClassified;

    fields
    {
        field(10; "Item No."; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(13; "Variant Code"; code[10])
        {
            DataClassification = ToBeClassified;
        }
        field(15; "Unit of Measure"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Direct Unit Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Item Description"; text[50])
        {
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(PK; "Item No.", "Variant Code", "Unit of Measure")
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