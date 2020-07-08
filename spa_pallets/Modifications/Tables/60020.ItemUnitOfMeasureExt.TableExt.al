tableextension 60020 ItemUnitOfMeasureExt extends "Item Unit of Measure"
{
    fields
    {
        field(60000; "Default Unit Of Measure"; Boolean)
        {
            Caption = 'Default Unit Of Measure';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            var
                ItemUnitOfMeasure: Record "Item Unit of Measure";
            begin
                ItemUnitOfMeasure.reset;
                ItemUnitOfMeasure.setrange("Item No.", rec."Item No.");
                ItemUnitOfMeasure.setfilter(code, '<>%1', rec.code);
                if ItemUnitOfMeasure.findset then
                    ItemUnitOfMeasure.modifyall("Default Unit Of Measure", false);

            end;
        }
        field(60001;"Sticker Note Relation";integer)
        {
            Caption = 'Sticker Note Relation';
            DataClassification = ToBeClassified;            
        }
    }

    var
        myInt: Integer;
}