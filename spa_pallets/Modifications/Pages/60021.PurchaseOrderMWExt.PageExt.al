pageextension 60021 PurchaseOrderMWExt extends "Purchase Order"
{
    layout
    {
        addfirst(factboxes)
        {
            part("PO Details Factbox"; "PO Details Factbox") //Pallet Inforamtion
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("Pallet Information")
            {
                ApplicationArea = All;
                Image = ExportToExcel;
                trigger OnAction();
                var
                    LPalletFunctionCodeunit: Codeunit "Pallet Functions";
                begin
                    LPalletFunctionCodeunit.ExportToExcelPODetials(Rec."No.");
                end;
            }
            action("PO Items Statistic")
            {
                ApplicationArea = All;
                Image = ExportToExcel;
                Caption = 'Grading Statistics';

                trigger OnAction();
                var
                    LPalletFunctionCodeunit: Codeunit "Pallet Functions";
                begin
                    LPalletFunctionCodeunit.ExportToExcelPurchaseItemsStatistic(rec."No.");
                end;
            }
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

                        PalletHeader.MARKEDONLY(TRUE);
                        page.run(page::"Pallet List", PalletHeader);
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

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage."PO Details Factbox".Page.SetPO(Rec."No.");
    end;

    var
        PO_Microwave_Process: Boolean;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        PalletHeader: Record "Pallet Header";
        PalletList: Page "Pallet List";
        PalletFilter: Text[1024];
}

pageextension 60043 Mode_PurchaseList extends "Purchase Order List"
{
    actions
    {
        addlast(processing)
        {
            action("Pallet Information")
            {
                ApplicationArea = All;
                Image = ExportToExcel;
                trigger OnAction();
                var
                    LPalletFunctionCodeunit: Codeunit "Pallet Functions";
                begin
                    LPalletFunctionCodeunit.ExportToExcelPODetials('');
                end;
            }
            action("PO Items Statistic")
            {
                ApplicationArea = All;
                Image = ExportToExcel;
                Caption = 'Grading Statistics';
                trigger OnAction();
                var
                    LPalletFunctionCodeunit: Codeunit "Pallet Functions";
                begin
                    LPalletFunctionCodeunit.ExportToExcelPurchaseItemsStatistic('');
                end;
            }
        }
    }
}

pageextension 60044 ModPurchaseStatistic extends "Purchase Order Statistics"
{
    layout
    {
        addafter(General)
        {
            part("Purchase Items Statistic"; "Purchase Items Statistic")
            {
                Caption = 'Grading Statistics';
                ApplicationArea = all;
            }
        }
    }

    trigger OnOpenPage();
    begin
        CurrPage."Purchase Items Statistic".Page.fillIn("No.");
    end;
}