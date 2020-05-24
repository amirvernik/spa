pageextension 60034 SalesOrderListExt extends "Sales Order List"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("SPA Location"; "SPA Location")
            {
                ApplicationArea = all;
            }
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