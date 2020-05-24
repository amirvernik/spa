pageextension 60026 PurcasheCreditMemoExt extends "Purchase Credit Memo"
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