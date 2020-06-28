pageextension 60037 ItemCardExt extends "Item Card"
{
    layout
    {
        addafter("Over-Receipt Code")
        {
            field("Max Qty Per Pallet"; "Max Qty Per Pallet")
            {
                ApplicationArea = all;
            }
            field("Reusable item"; "Reusable item")
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