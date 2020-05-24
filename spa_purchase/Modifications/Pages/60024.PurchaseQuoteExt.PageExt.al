pageextension 60024 PurchaseQuoteExt extends "Purchase Quote"
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