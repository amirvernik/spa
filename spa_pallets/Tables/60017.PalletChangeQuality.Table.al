table 60017 "Pallet Change Quality"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(5; "User Created"; code[50])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Pallet ID"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Pallet Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Line No."; integer)
        {
            DataClassification = ToBeClassified;
        }
        field(40; "New Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = item;
            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Item.get("New Item No.") then
                    Description := item.Description;
            end;
        }
        field(50; "New Quantity"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(60; Description; text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(70; "New Variant Code"; code[20])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("New Item No."));
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Pallet ID", "Pallet Line No.", "Line No.")
        {
            Clustered = true;
        }
    }


    trigger OnInsert()
    var
        PalletChangeQuality: Record "Pallet Change Quality";
        LineNumber: Integer;

    begin
        PalletChangeQuality.reset;
        PalletChangeQuality.setrange("Pallet ID", Rec."Pallet ID");
        PalletChangeQuality.setrange("Pallet Line No.", rec."Pallet Line No.");
        if PalletChangeQuality.findlast then
            LineNumber := PalletChangeQuality."Line No." + 10000
        else
            LineNumber := 10000;
        "Line No." := LineNumber;
        "User Created" := UserId;
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