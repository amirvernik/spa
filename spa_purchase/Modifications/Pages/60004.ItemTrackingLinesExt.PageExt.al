pageextension 60004 ItemTrackingLinesExt extends "Item Tracking Lines"
{
    layout
    {
        addafter("Lot No.")
        {
            field("Packing Date"; "Packing Date")
            {
                ApplicationArea = all;
                Editable = false;
                Caption = 'Grading Date';
            }
        }
        modify("Expiration Date")
        {
            Visible = true;
            Editable = false;
        }
    }
    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}