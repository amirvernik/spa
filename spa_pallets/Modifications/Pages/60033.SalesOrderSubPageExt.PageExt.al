pageextension 60033 SalesOrderSubPageExt extends "Sales Order Subform"
{
    layout
    {
        modify("Variant Code")
        {
            Visible = true;
        }
        addafter("Shipment Date")
        {
            field("Dispatch Date"; "Dispatch Date")
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