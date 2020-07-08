table 60019 "Sticker note Printer"
{
    DataClassification = ToBeClassified;
    fields
    {
        field(10; "User Code"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = user."User Name";
            ValidateTableRelation = false;
        }
        field(20; "Sticker Note Type"; code[20])
        {
            TableRelation = "Format Type".code;
            DataClassification = ToBeClassified;
        }
        field(30; "Sticker Note Format"; code[20])
        {
            TableRelation = "Sticker Format"."Sticker Code" where("Format Type" = field("Sticker Note Type"));
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                StickerFormat: Record "Sticker Format";
            begin
                StickerFormat.reset;
                StickerFormat.setrange("Format Type", rec."Sticker Note Type");
                StickerFormat.setrange("Sticker Code", rec."Sticker Note Format");
                if StickerFormat.findfirst then
                    rec."Sticker Note Description" := StickerFormat."Sticker Description";

            end;
        }

        field(40; "Sticker Note Description"; code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(50; "Location Code"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = location.code;
        }

        field(60; "Printer Path"; text[1024])
        {
            DataClassification = ToBeClassified;
        }
        field(70; "Printer Description"; Text[80])
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "User Code", "Sticker Note Type", "Sticker Note Format", "Location Code")
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