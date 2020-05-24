pageextension 60021 PurchaseOrderMWExt extends "Purchase Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addlast(processing)
        {
            action("RM Pallets")
            {
                ApplicationArea = All;
                Image = OrderList;
                Visible = PO_Microwave_Process;

                trigger OnAction()
                begin
                    PalletFilter := '';
                    PalletLedgerEntry.reset;
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Consume Raw Materials");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Lot Number", rec."Batch Number");
                    if PalletLedgerEntry.findset then begin
                        repeat
                            if PalletHeader.get(PalletLedgerEntry."Pallet ID") then
                                PalletHeader.Mark(true);
                        until PalletLedgerEntry.next = 0;

                        //CLEAR(PalletList);
                        //PalletList.LOOKUPMODE := TRUE;
                        PalletHeader.MARKEDONLY(TRUE);
                        page.run(page::"Pallet List", PalletHeader);
                        //PalletList.SETRECORD(PalletHeader);
                        //PalletList.SETTABLEVIEW(PalletHeader);
                        //PalletList.RUN;
                        //ItemList.GETRECORD(Item);
                        //Sender.VALIDATE(Sender."No.", Item."No.");
                        //end;
                    end;
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        PO_Microwave_Process := true;
        if not rec."Microwave Process PO" then
            PO_Microwave_Process := false;
    end;

    trigger OnAfterGetRecord()
    begin
        PO_Microwave_Process := true;
        if not rec."Microwave Process PO" then
            PO_Microwave_Process := false;
        PalletLedgerEntry.reset;
        PalletLedgerEntry.setrange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Consume Raw Materials");
        PalletLedgerEntry.setrange(PalletLedgerEntry."Lot Number", rec."Batch Number");
        if not PalletLedgerEntry.findfirst then
            PO_Microwave_Process := false;
    end;

    var
        PO_Microwave_Process: Boolean;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        PalletHeader: Record "Pallet Header";
        PalletList: Page "Pallet List";
        PalletFilter: Text[1024];
}