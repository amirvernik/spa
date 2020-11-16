tableextension 60019 BOMComponentExt extends "BOM Component"
{
    fields
    {
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                ItemRec: Record Item;
            begin
                if ItemRec.get(rec."No.") then begin
                    rec."Reusable item" := ItemRec."Reusable item";
                    rec.modify;
                end;
            end;
        }
        field(60019; "Reusable item"; Boolean)
        {
            Caption = 'Reusable item';
            DataClassification = ToBeClassified;
        }
        field(60020; "Fixed Value"; Boolean)
        {
            Caption = 'Fixed Value';
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}