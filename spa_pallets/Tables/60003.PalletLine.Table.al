table 60003 "Pallet Line"
{
    Caption = 'Pallet Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Pallet ID"; Code[20])
        {
            Caption = 'Pallet ID';
            DataClassification = ToBeClassified;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = ToBeClassified;
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = item;
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                if PAlletHeader.get("Pallet ID") then begin
                    if PAlletHeader."Location Code" = '' then
                        error(PalletHeaderLocError);
                    rec."Location Code" := PAlletHeader."Location Code";
                end;
                if item.get("Item No.") then begin
                    Description := item.Description;
                    "Unit of Measure" := item."Base Unit of Measure";
                    "User ID" := userid;
                end;
            end;
        }
        field(4; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = ToBeClassified;
        }
        field(5; "Location Code"; code[20])
        {
            Caption = 'Location';
            DataClassification = ToBeClassified;
        }
        field(6; "Lot Number"; code[20])

        {
            Caption = 'Lot Number';
            DataClassification = ToBeClassified;

        }
        field(7; "Unit of Measure"; code[20])
        {
            Caption = 'UOM';
            DataClassification = ToBeClassified;
        }
        field(8; Quantity; Integer)
        {
            Caption = 'Quantity';
            DataClassification = ToBeClassified;
        }
        field(9; "Expiration Date"; date)
        {
            Caption = 'Expiration Date';
            DataClassification = ToBeClassified;
        }
        field(10; "User ID"; code[50])
        {
            Caption = 'User ID';
            DataClassification = ToBeClassified;
        }
        field(11; "Exists on Warehouse Shipment"; Boolean)
        {
            Caption = 'Exists on Warehouse Shipment';
            DataClassification = ToBeClassified;
        }
        field(12; "Purchase Order No."; code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = ToBeClassified;

        }
        field(13; "Purchase Order Line No."; integer)
        {
            Caption = 'Purchase Order Line No.';
            DataClassification = ToBeClassified;

        }
        field(60020;"Variant Code";code[20])
        {
            caption='Variety';
            DataClassification=ToBeClassified;
            TableRelation="Item Variant".Code WHERE ("Item No."=field("Item No."));
        }
    }

    keys
    {
        key(PK; "Pallet ID", "Line No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    var
        RecLPalletLine: Record "Pallet Line";
        LineNumber: Integer;

    begin
        RecLPalletLine.reset;
        RecLPalletLine.setrange("Pallet ID", Rec."Pallet ID");
        if RecLPalletLine.findlast then
            LineNumber := RecLPalletLine."Line No." + 10000
        else
            LineNumber := 10000;

        "Line No." := LineNumber;
    end;

    var
        item: Record item;
        PAlletHeader: Record "Pallet Header";
        PalletHeaderLocError: label 'Location does not Exist on Pallet, Please Re-enter';

}
