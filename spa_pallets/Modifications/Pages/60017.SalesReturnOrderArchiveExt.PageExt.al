pageextension 60017 SalesReturnOrderArchiveExt extends "Sales Return Order Archive"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addfirst(processing)
        {
            action("Show Pallet/s")
            {
                Image = ImportCodes;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    PalletLedgerEntry.reset;
                    PalletLedgerEntry.SetRange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Sales Return Order");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Order No.", rec."No.");
                    PalletLedgerEntry.setrange("Order Type", 'Return Order');
                    if PalletLedgerEntry.findfirst then
                        page.run(page::"Pallet Ledger Entries", PalletLedgerEntry)
                end;
            }
        }
    }

    var
        PalletLedgerEntry: Record "Pallet Ledger Entry";
}