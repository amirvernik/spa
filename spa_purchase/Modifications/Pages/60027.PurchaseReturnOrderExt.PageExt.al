pageextension 60027 PurchaseReturnOrderExt extends "Purchase return order"
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