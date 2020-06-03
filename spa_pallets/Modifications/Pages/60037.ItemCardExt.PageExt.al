pageextension 60037 ItemCardExt extends "Item Card"
{
    layout
    {
        addafter("Over-Receipt Code")
        {
            field(MaxQtyPerPallet; MaxQtyPerPallet)
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