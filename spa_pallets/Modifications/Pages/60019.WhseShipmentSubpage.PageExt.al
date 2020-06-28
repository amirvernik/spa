pageextension 60019 WhseShipmentSubpage extends "Whse. Shipment Subform"
{
    layout
    {
        modify("Variant Code")
        {
            Visible = true;
            caption = 'Variety Code';
        }
        addafter(quantity)
        {
            field("Remaining Quantity"; "Remaining Quantity")
            {
                ApplicationArea = all;
                Editable = false;
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