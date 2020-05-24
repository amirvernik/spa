pageextension 60032 ShipToAddressCardExt extends "Ship-to Address"
{
    layout
    {
        addafter("Post Code")
        {
            field("Shipping Time"; "Shipping Time")
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