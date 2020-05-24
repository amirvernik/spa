pageextension 60006 ItemLedgerEntriesExt extends "Item Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Pallet ID"; "Pallet ID")
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