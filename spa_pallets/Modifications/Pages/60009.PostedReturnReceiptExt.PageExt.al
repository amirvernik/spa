pageextension 60009 PostedReturnReceiptExt extends "Posted Return Receipt"
{
    layout
    {
        addfirst(factboxes)
        {
            part(MyReturnPart; "Pallet Ledger Entry Factbox")
            {
                ApplicationArea = Warehouse;
                Provider = ReturnRcptLines;
                SubPageLink = "Order No." = field("Return Order No."), "Order Line No." = field("Return Order Line No.");
                //Visible = PalletsExists;
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