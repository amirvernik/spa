pageextension 60006 ItemLedgerEntriesExt extends "Item Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Pallet ID"; "Pallet ID")
            {
                ApplicationArea = all;
                trigger OnDrillDown()
                var
                    PalletHeader: Record "Pallet Header";
                begin
                    if PalletHeader.get("Pallet ID") then
                        page.Run(page::"Pallet Card", PalletHeader);
                end;
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