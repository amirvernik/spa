page 60006 "Pallet Card Subpage"
{

    PageType = ListPart;
    SourceTable = "Pallet Line";
    Caption = 'Pallet Card Subpage';

    layout
    {

        area(content)
        {
            repeater(General)
            {
                field("Line No."; "Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = all;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Lot Number"; "Lot Number")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = all;
                    editable = false;
                    BlankZero = true;
                }
                field("QTY Consumed"; "QTY Consumed")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Remaining Qty"; "Remaining Qty")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Exists on Warehouse Shipment"; "Exists on Warehouse Shipment")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Purchase Order No."; "Purchase Order No.")
                {

                    ApplicationArea = all;
                    editable = false;

                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";

                    begin
                        PurchaseHeader.reset;
                        PurchaseHeader.setrange(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::order);
                        PurchaseHeader.setrange("No.", "Purchase Order No.");
                        if PurchaseHeader.findfirst then
                            page.run(page::"Purchase Order", PurchaseHeader);
                    end;

                }
                field("Purchase Order Line No."; "Purchase Order Line No.")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Reusable item"; "Reusable item")
                {
                    Editable = false;
                    ApplicationArea = all;
                }
                field(Replaced; Replaced)
                {
                    ApplicationArea = All;
                }
                field("Item Label No. of Copies"; "Item Label No. of Copies")
                {
                    Editable = false;
                    ApplicationArea = all;
                }

            }
        }
    }


    actions
    {
        area(Processing)
        {
            action("Change Item Quality")
            {
                ApplicationArea = All;
                image = TaskQualityMeasure;

                trigger OnAction()
                var
                    ChangeQualityPage: page "Pallet Change Quality";
                    MsgCannotChange: Label 'Change quality is available only for closed pallets and pallets that were not allocated to a dispatch process (Shipment)';
                    LPalletHeader: Record "Pallet Header";
                begin
                    LPalletHeader.Reset();
                    LPalletHeader.SetRange("Pallet ID", Rec."Pallet ID");
                    LPalletHeader.FindFirst();
                    if ((LPalletHeader."Pallet Status" = "Pallet Status"::Closed) and
                            (LPalletHeader."Exist in warehouse shipment" = false)) then begin
                        ChangeQualityPage.SetPalletIDAndPalletLine(rec."Pallet ID", rec."Line No.");
                        ChangeQualityPage.CalcChangeQuality(rec."Pallet ID", Rec."Line No.");
                        ChangeQualityPage.run;
                    end
                    else
                        message(MsgCannotChange);
                end;
            }
            group(Tracking)
            {
                action("Item Tracking")
                {
                    ApplicationArea = All;
                    Image = ItemTracking;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = PalletCancelled;

                    trigger OnAction();
                    var
                        PageLotSelection: Page "Lot Selection";
                        LotSelection: Record "Lot Selection" temporary;
                        ItemLedgerEntry: Record "Item Ledger Entry";
                        PalletReservationFunctions: Codeunit "Pallet Reservation Functions";
                        Err001: Label 'There are no Lot to Select for Item %1, Location %2';
                        PurchaseReceiptLine: Record "Purch. Rcpt. Line";

                    begin

                        if LotSelection.findset then
                            LotSelection.deleteall;

                        //Get Item Ledger Entries
                        ItemLedgerEntry.RESET;
                        ItemLedgerEntry.SETCURRENTKEY("Item No.", Open, "Variant Code", "Location Code", "Item Tracking",
                          "Lot No.", "Serial No.");
                        ItemLedgerEntry.SETRANGE("Item No.", rec."Item No.");
                        ItemLedgerEntry.setrange("Variant Code", rec."Variant Code");
                        ItemLedgerEntry.SETRANGE(Open, TRUE);
                        ItemLedgerEntry.SETRANGE("Location Code", rec."Location Code");
                        ItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');
                        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
                        if ItemLedgerEntry.findset then
                            repeat
                                if not LotSelection.get(rec."Pallet ID",
                                    rec."Line No.", ItemLedgerEntry."Lot No.") then begin
                                    LotSelection.init;
                                    LotSelection."Pallet ID" := rec."Pallet ID";
                                    LotSelection."Pallet Line No." := rec."Line No.";
                                    LotSelection.Lot := ItemLedgerEntry."Lot No.";
                                    LotSelection."Qty. to Reserve" := rec.Quantity;
                                    LotSelection.Quantity := ItemLedgerEntry.Quantity;
                                    LotSelection."Item No." := ItemLedgerEntry."Item No.";
                                    LotSelection."Variant code" := ItemLedgerEntry."Variant Code";
                                    LotSelection."Expiration Date" := ItemLedgerEntry."Expiration Date";
                                    LotSelection."Quantity Available" := ItemLedgerEntry.Quantity;
                                    LotSelection."Qty. to Reserve" := LotSelection."Quantity Available";
                                    PurchaseReceiptLine.Reset();
                                    PurchaseReceiptLine.SetRange("Document No.", ItemLedgerEntry."Document No.");
                                    PurchaseReceiptLine.SetRange("Line No.", ItemLedgerEntry."Document Line No.");
                                    if PurchaseReceiptLine.FindFirst() then begin
                                        LotSelection."Purchase Order" := PurchaseReceiptLine."Order No.";
                                        LotSelection."Purchase Order Line" := PurchaseReceiptLine."Order Line No.";
                                    end;
                                    LotSelection.insert;
                                end;
                            until ItemLedgerEntry.next = 0;

                        LotSelection.reset;
                        LotSelection.setrange(LotSelection."Quantity Available", 0);
                        if LotSelection.findset then
                            LotSelection.deleteall;

                        LotSelection.reset;
                        if not LotSelection.findset then
                            error(Err001, rec."Item No.", rec."Location Code");

                        LotSelection.reset;
                        clear(PageLotSelection);
                        PageLotSelection.LOOKUPMODE := true;

                        LotSelection.reset;
                        LotSelection.setrange("Pallet ID", rec."Pallet ID");
                        LotSelection.setrange("Pallet Line No.", "Line No.");
                        if LotSelection.findset then begin
                            if page.RUNMODAL(60013, LotSelection) = ACTION::LookupOK THEN begin
                                PageLotSelection.GETRECORD(LotSelection);

                            end;
                        end;

                        CurrPage.update(false);
                    end;
                }
                action("Delete Tracking")
                {
                    ApplicationArea = All;
                    Image = DeleteQtyToHandle;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction();
                    var
                        Conf001: Label 'Are you sure you want to delete reservation for this item?';
                    begin
                        if Confirm(Conf001) then begin
                            rec.Validate(Quantity, 0);
                            rec.Validate("Lot Number", '');
                            rec."Purchase Order No." := '';
                            rec."Purchase Order Line No." := 0;
                            rec.modify;
                        end;
                    end;
                }
            }
        }
    }
    trigger OnAfterGetCurrRecord();
    var
        LPalletHeader: Record "Pallet Header";
    begin
        LPalletHeader.Get("Pallet ID");
        if LPalletHeader."Pallet Status" = LPalletHeader."Pallet Status"::Canceled then
            PalletCancelled := false
        else
            PalletCancelled := true;
    end;

    var
        PalletCancelled: Boolean;
}