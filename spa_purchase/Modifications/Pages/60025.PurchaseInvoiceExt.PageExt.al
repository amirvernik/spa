pageextension 60025 PurchaseInvoiceExt extends "Purchase Invoice"
{
    layout
    {
        modify("Purchaser Code")
        {
            ShowMandatory = true;
        }
    }


    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}