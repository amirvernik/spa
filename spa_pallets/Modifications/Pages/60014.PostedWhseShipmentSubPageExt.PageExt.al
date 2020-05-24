pageextension 60014 PostedWhseShipmentSubPageExt extends "Posted Whse. Shipment Subform"
{
    layout
    {
        addafter(Quantity)
        {
            field("Remaining Quantiy"; "Remaining Quantity")
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