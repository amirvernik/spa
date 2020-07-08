pageextension 60040 ItemUnitsOfMeasureExt extends "Item Units of Measure"
{
    layout
    {
        addafter("Qty. per Unit of Measure")
        {
            field("Default Unit Of Measure"; "Default Unit Of Measure")
            {
                ApplicationArea = all;
            }
            field("Sticker Note Relation"; "Sticker Note Relation")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}