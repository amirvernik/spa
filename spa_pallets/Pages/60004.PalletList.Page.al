page 60004 "Pallet List"
{

    PageType = List;
    SourceTable = "Pallet Header";
    Caption = 'Pallet List';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "Pallet Card";
    Editable = false;
    SourceTableView = order(descending);
    DeleteAllowed = false;
    Permissions = tableData 32 = rm;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = All;
                }

                field("Pallet Status"; "Pallet Status")
                {
                    ApplicationArea = All;
                }
                field(PalletTypeText; PalletTypeText)
                {
                    Caption = 'Pallet Type';
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field(PurchaseOrder; PalletFunctions.GetFirstPO(Rec))
                {
                    Caption = ' Purchase Order';
                    ApplicationArea = all;
                    ToolTip = 'Show Purchase Order no. of First line on Pallet';
                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader.reset;
                        PurchaseHeader.setrange("Document Type", PurchaseHeader."Document Type"::Order);
                        PurchaseHeader.setrange("No.", PalletFunctions.GetFirstPO(Rec));
                        if PurchaseHeader.findfirst then
                            page.run(page::"Purchase Order", PurchaseHeader);
                    end;
                }
                field("Total Qty"; "Total Qty")
                {
                    ApplicationArea = All;
                }
                field("Raw Material Pallet"; "Raw Material Pallet")
                {
                    ApplicationArea = All;
                }
                field("Exist in warehouse shipment"; "Exist in warehouse shipment")
                {
                    ApplicationArea = All;
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = all;
                }
                field("User Created"; "User Created")
                {
                    ApplicationArea = all;
                }
                field(Attention; Attention)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {

            action("Fix Transfers")
            {
                ApplicationArea = All;
                Enabled = EnableTESTPROD1;
                trigger OnAction();
                var

                    LTransferLine: Record "Transfer Line";
                    LPalletHeader: Record "Pallet Header";
                    PalletSetup: Record "Pallet Process Setup";
                    LItemJournalLine: Record "Item Journal Line";
                begin


                    LPalletHeader.Reset();
                    if LPalletHeader.FindSet() then
                        repeat
                            LTransferLine.Reset();
                            LTransferLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                            LTransferLine.SetFilter("Quantity Received", '<>%1', LTransferLine.Quantity);
                            if LTransferLine.FindFirst() then begin
                                LPalletHeader.validate("Exist in Transfer Order", true);
                                LPalletHeader.Validate("Transfer Order", LTransferLine."Document No.");
                                LPalletHeader.Modify();
                            end;

                            PalletSetup.get;
                            LItemJournalLine.Reset();
                            LItemJournalLine.SetRange("Journal Template Name", PalletSetup."Item Reclass Template");
                            LItemJournalLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                            if LItemJournalLine.FindFirst() then begin
                                LPalletHeader.validate("Exist in Transfer Order", true);
                                LPalletHeader."Transfer Order" := LItemJournalLine."Journal Batch Name";
                                LPalletHeader.Modify();
                            end;
                        until LPalletHeader.Next() = 0
                end;
            }
            action("Fix Item Journal")
            {
                ApplicationArea = All;
                Visible = EnableTESTPROD1;
                trigger OnAction()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                    valueEntry: Record "Value Entry";
                    palletLedger: Record "Pallet Ledger Entry";
                begin
                    ItemLedgerEntry.Reset();
                    ItemLedgerEntry.SetRange("Posting Date", 0D);
                    ItemLedgerEntry.SetRange("Item No.", '');
                    if ItemLedgerEntry.FindSet() then
                        repeat
                            valueEntry.Reset();
                            valueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                            if valueEntry.FindFirst() then begin
                                ItemLedgerEntry."Entry Type" := valueEntry."Item Ledger Entry Type";
                                ItemLedgerEntry.validate("Posting Date", valueEntry."Posting Date");
                                // ItemLedgerEntry.validate("Pallet ID", LPalletLine."Pallet ID");
                                ItemLedgerEntry."Document No." := valueEntry."Document No.";
                                ItemLedgerEntry.Description := valueEntry.Description;
                                ItemLedgerEntry.validate("Item No.", valueEntry."Item No.");
                                ItemLedgerEntry.Validate("Variant Code", valueEntry."Variant Code");
                                ItemLedgerEntry.validate(Quantity, valueEntry."Item Ledger Entry Quantity");
                                ItemLedgerEntry.validate("Location Code", valueEntry."Location Code");
                                palletLedger.Reset();
                                palletLedger.SetRange("Item Ledger Entry No.", valueEntry."Item Ledger Entry No.");
                                palletLedger.SetRange("Item No.", valueEntry."Item No.");
                                palletLedger.SetRange("Posting Date", valueEntry."Posting Date");
                                if palletLedger.FindFirst() then begin
                                    ItemLedgerEntry."Lot No." := palletLedger."Lot Number";
                                    ItemLedgerEntry.Validate("Unit of Measure Code", palletLedger."Unit of Measure");
                                end;
                                ItemLedgerEntry.modify;
                            end;
                        until ItemLedgerEntry.Next() = 0;
                end;
            }
            action("Fix Shipped")//DELETE ME
            {
                ApplicationArea = All;
                Visible = EnableTESTPROD1;
                trigger OnAction()
                var
                    LPalletHeader: Record "Pallet Header";
                    PostedWarehousePallet: Record "Posted Warehouse Pallet";
                    PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
                    PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
                begin
                    LPalletHeader.Reset();
                    LPalletHeader.CopyFilters(Rec);
                    if LPalletHeader.FindSet() then
                        repeat
                            PostedWarehousePallet.Reset();
                            PostedWarehousePallet.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                            if PostedWarehousePallet.FindSet() then
                                repeat
                                    PostedWhseShipmentLine.Reset();
                                    PostedWhseShipmentLine.SetRange("No.", PostedWarehousePallet."Whse Shipment No.");
                                    PostedWhseShipmentLine.SetRange("Line No.", PostedWarehousePallet."Whse Shipment Line No.");
                                    if PostedWhseShipmentLine.FindSet() then
                                        repeat
                                            PalletLedgerFunctions.PalletLedgerEntryWarehouseShipment(PostedWhseShipmentLine);
                                        until PostedWhseShipmentLine.Next() = 0;
                                until PostedWarehousePallet.Next() = 0;
                        until LPalletHeader.Next() = 0;
                end;

            }

            action("Close Pallet")
            {
                ApplicationArea = All;
                image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowClose;

                trigger OnAction()
                begin
                    PalletFunctions.ClosePallet(rec, 'BC');
                end;
            }

            action("ReOpen Pallet")
            {
                ApplicationArea = All;
                image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowReopen;

                trigger OnAction()
                var
                    packingma: Record "Packing Material Line";
                begin
                    if rec."Pallet Status" <> rec."Pallet Status"::Canceled then
                        PalletFunctions.ChoosePackingMaterials(rec);
                    PalletFunctions.ReOpenPallet(rec);
                end;
            }
            action("Dispose Pallet")
            {
                ApplicationArea = All;
                image = NegativeLines;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowDisposed;

                trigger OnAction()
                begin
                    PalletDisposalMgmt.DisposePallet(rec);
                end;
            }
            action("Cancel Pallet")
            {
                ApplicationArea = All;
                image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = "Pallet Status" <> "Pallet Status"::Canceled;
                trigger OnAction()
                var
                    LPalletFunctions: Codeunit "Pallet Functions";
                begin
                    LPalletFunctions.CancelPallet(Rec);
                end;
            }


            action("Print Pallet")
            {
                ApplicationArea = All;
                image = Print;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var

                    PalletHeader: Record "Pallet Header";

                begin
                    PalletHeader.reset;
                    PalletHeader.setrange("Pallet ID", rec."Pallet ID");
                    if palletheader.findfirst then
                        Report.Run(report::"Pallet Print", false, false, palletheader);
                end;

            }
            action("Mark Shipped")
            {
                ApplicationArea = All;
                image = ReleaseShipment;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowShip;

            }
            action("Unmark Attention")
            {
                ApplicationArea = All;
                Image = UnApply;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Attention;
                trigger OnAction();
                begin
                    Rec.Attention := false;
                    if not Rec.Modify() then;
                end;
            }
        }
    }
    trigger OnOpenPage()
    begin
        EnableTESTPROD1 := UserId() = 'PRODWARE1';
    end;

    trigger OnAfterGetCurrRecord()
    var
        LUserSetup: Record "User Setup";
    begin
        case rec."Pallet Status" of
            rec."Pallet Status"::open:
                begin
                    ShowReopen := false;
                    ShowClose := true;
                    ShowShip := false;
                    ShowDisposed := false;

                end;
            rec."Pallet Status"::Closed:
                begin
                    ShowReopen := true;
                    ShowClose := false;
                    ShowShip := true;
                    ShowDisposed := true;
                end;
            rec."Pallet Status"::Shipped:
                begin
                    ShowReopen := true;
                    ShowClose := false;
                    ShowShip := false;
                    ShowDisposed := false;
                end;
            rec."Pallet Status"::Canceled:
                begin
                    ShowReopen := true;
                    ShowClose := false;
                    ShowShip := false;
                    ShowDisposed := false;
                end;

        end;

        if "Exist in warehouse shipment" or "Exist in Transfer Order" then ShowReopen := false;
        if "Pallet Status" = "Pallet Status"::Canceled then
            if LUserSetup.Get(UserId) then
                if not LUserSetup."Reopen Cancelled Pallets" then
                    ShowReopen := false;
        if "Pallet Type" = 'mw' then
            PalletTypeText := 'Microwave'
        else
            if "Pallet Type" = 'grade' then
                PalletTypeText := 'Grading'
            else
                PalletTypeText := '';

    end;

    var
        PalletFunctions: Codeunit "Pallet Functions";
        PalletDisposalMgmt: Codeunit "Pallet Disposal Management";
        ShowClose: Boolean;
        ShowShip: Boolean;
        ShowCancel: Boolean;
        ShowReopen: Boolean;
        ShowDisposed: Boolean;
        PalletTypeText: Text;
        EnableTESTPROD1: Boolean;
}
