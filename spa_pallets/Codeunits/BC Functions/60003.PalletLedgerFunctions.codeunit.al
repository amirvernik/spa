codeunit 60003 "Pallet Ledger Functions"
{
    //Put Time Stamp on Pallet Ledger Entry
    [EventSubscriber(ObjectType::table, database::"Pallet Ledger Entry", 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertPalletLedgerEntry(var Rec: Record "Pallet Ledger Entry")
    begin
        rec."Date Time Created" := CurrentDateTime;
        rec.modify;
    end;

    //Negative Pallet Ledger Entry from a Pallet - Reopen Pallet
    procedure NegPalletLedger(var PalletHeader: Record "Pallet Header")
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Remove from a pallet";
                PalletLedgerEntry."Pallet ID" := PalletHeader."Pallet ID";
                PalletLedgerEntry."Document No." := PalletHeader."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, palletlines.Quantity);
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    PalletLedgerEntry.Insert();
                LineNumber += 1;
            until palletlines.next = 0;
    end;

    //Positive Pallet Ledger Entry from a Pallet - Close Pallet
    procedure PosPalletLedger(var PalletHeader: Record "Pallet Header")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Add to a pallet";
                PalletLedgerEntry."Pallet ID" := PalletHeader."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry."Document No." := PalletLines."Pallet ID";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, palletlines.Quantity);
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    if not PalletLedgerEntry.Insert() then PalletLedgerEntry.Modify();
                LineNumber += 1;
            until palletlines.next = 0;
    end;

    procedure PalletCancelledPalletLedger(var PalletHeader: Record "Pallet Header"; EntryNo: Integer)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Pallet Cancelled";
                PalletLedgerEntry."Pallet ID" := PalletHeader."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry."Document No." := PalletLines."Pallet ID";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, palletlines.Quantity);
                PalletLedgerEntry.Validate("Item Ledger Entry No.", EntryNo);
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    if not PalletLedgerEntry.Insert() then PalletLedgerEntry.Modify();
                LineNumber += 1;
            until palletlines.next = 0;
    end;


    procedure PalletDisposeledPalletLedger(var pPalletHeader: Record "Pallet Header")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemLedgerEntries: Record "Item Ledger Entry";
        PalletSetup: Record "Pallet Process Setup";
    begin
        PalletSetup.Get();
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Pallet Disposed";
                PalletLedgerEntry."Pallet ID" := pPalletHeader."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry."Document No." := PalletLines."Pallet ID";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, palletlines.Quantity);
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    if not PalletLedgerEntry.Insert() then PalletLedgerEntry.Modify();
                LineNumber += 1;
            until palletlines.next = 0;
    end;


    //Negative Pallet Ledger Entry from a Pallet - Transfer Order (Shipment)
    procedure NegPalletLedgerTransfer(var pTransferShipLine: record "Transfer Shipment Line");
    begin
        TransferShipHeader.get(pTransferShipLine."Document No.");
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pTransferShipLine."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Transfer-Ship";
                PalletLedgerEntry."Document No." := pTransferShipLine."Document No.";
                PalletLedgerEntry."Pallet ID" := palletlines."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", TransferShipHeader."Transfer-from Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, palletlines.Quantity * -1);
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    PalletLedgerEntry.Insert();
                LineNumber += 1;
            until palletlines.next = 0;
    end;

    //Positive Pallet Ledger Entry from a Pallet - Transfer Order (Receipt)
    procedure PosPalletLedgerTransfer(var pTransferReceiptLine: record "Transfer Receipt Line");
    begin
        TransferReceiptHeader.get(pTransferReceiptLine."Document No.");
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pTransferReceiptLine."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Transfer-Receipt";
                PalletLedgerEntry."Document No." := pTransferReceiptLine."Document No.";
                PalletLedgerEntry."Pallet ID" := palletlines."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", TransferReceiptHeader."Transfer-to Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, palletlines.Quantity);
                PalletLedgerEntry."User ID" := userid;
                PalletLedgerEntry.Insert();
                LineNumber += 1;
            until palletlines.next = 0;
    end;

    //Pallet Ledger Entry Reclass
    procedure PalletLedgerEntryReclass(var ItemLedgerEntry: Record "Item Ledger Entry")

    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", ItemLedgerEntry."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.reset;
                PalletLedgerEntry.setrange(PalletLedgerEntry."Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
                if not PalletLedgerEntry.findfirst then begin
                    PalletLedgerEntry.Init();
                    PalletLedgerEntry."Entry No." := LineNumber;
                    PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Transfer-Reclass";
                    PalletLedgerEntry."Pallet ID" := ItemLedgerEntry."Pallet ID";
                    PalletLedgerEntry."Document No." := PalletLines."Pallet ID";
                    PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                    PalletLedgerEntry.validate("Posting Date", Today);
                    PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                    PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                    PalletLedgerEntry."Item Description" := PalletLines.Description;
                    PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                    PalletLedgerEntry.validate("Location Code", ItemLedgerEntry."Location Code");
                    PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                    PalletLedgerEntry.validate(Quantity, ItemLedgerEntry.Quantity);
                    PalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
                    PalletLedgerEntry."User ID" := userid;
                    PalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
                    if PalletLedgerEntry.Quantity <> 0 then
                        PalletLedgerEntry.Insert();
                    LineNumber += 1;
                end;
            until palletlines.next = 0;
    end;


    //Pallet Ledger Entry Item Journal - Negative
    procedure NegPalletLedgerEntryItem(var ItemJournalLine: Record "Item Journal Line"; PalletLedgerEntryType: Enum "Pallet Ledger Type")
    var
        PackingMaterialLine: Record "Packing Material Line";
        LPalletLine: Record "Pallet Line";
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLedgerEntry.Init();
        PalletLedgerEntry."Entry No." := LineNumber;
        PalletLedgerEntry."Entry Type" := PalletLedgerEntryType;
        PalletLedgerEntry."Pallet ID" := ItemJournalLine."Pallet ID";
        PalletLedgerEntry."Pallet Line No." := ItemJournalLine."Pallet Line No.";
        PalletLedgerEntry."Document No." := ItemJournalLine."Pallet ID";
        //PalletLedgerEntry."Item Ledger Entry No." := ItemJournalLine."Pallet Entry No.";
        PalletLedgerEntry.validate("Posting Date", Today);
        PalletLedgerEntry.validate("Item No.", ItemJournalLine."Item No.");
        if item.get(ItemJournalLine."Item No.") then
            PalletLedgerEntry."Item Description" := item.Description;
        PalletLedgerEntry."Variant Code" := ItemJournalLine."Variant Code";
        PalletLedgerEntry.validate("Location Code", ItemJournalLine."Location Code");
        PalletLedgerEntry.validate("Unit of Measure", ItemJournalLine."Unit of Measure Code");
        if ItemJournalLine.Quantity > 0 then
            PalletLedgerEntry.validate(Quantity, -1 * ItemJournalLine.Quantity)
        else
            PalletLedgerEntry.validate(Quantity, ItemJournalLine.Quantity);
        PalletLedgerEntry."User ID" := userid;
        LPalletLine.Reset();
        LPalletLine.SetRange("Pallet ID", PalletLedgerEntry."Pallet ID");
        LPalletLine.SetRange("Line No.", PalletLedgerEntry."Pallet Line No.");
        LPalletLine.SetRange("Item No.", PalletLedgerEntry."Item No.");
        if LPalletLine.FindFirst() then begin
            PalletLedgerEntry."Order Type" := 'Order';
            PalletLedgerEntry."Order No." := LPalletLine."Purchase Order No.";
            PalletLedgerEntry."Order Line No." := LPalletLine."Purchase Order Line No.";
        end;
        PalletLedgerEntry.Insert();
    end;

    //Pallet Ledger Entry Item Journal
    procedure PosPalletLedgerEntryItem(var ItemJournalLine: Record "Item Journal Line"; PalletLedgerEntryType: Enum "Pallet Ledger Type")
    var
        LPalletLine: Record "Pallet Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLedgerEntry.Init();
        PalletLedgerEntry."Entry No." := LineNumber;
        PalletLedgerEntry."Entry Type" := PalletLedgerEntryType;
        PalletLedgerEntry."Pallet ID" := ItemJournalLine."Pallet ID";
        PalletLedgerEntry."Pallet Line No." := ItemJournalLine."Pallet Line No.";
        PalletLedgerEntry."Document No." := ItemJournalLine."Pallet ID";
        //PalletLedgerEntry."Item Ledger Entry No." := ItemJournalLine."Entry No.";
        PalletLedgerEntry.validate("Posting Date", Today);
        PalletLedgerEntry.validate("Item No.", ItemJournalLine."Item No.");
        if item.get(ItemJournalLine."Item No.") then
            PalletLedgerEntry."Item Description" := item.Description;
        PalletLedgerEntry."Variant Code" := ItemJournalLine."Variant Code";
        PalletLedgerEntry.validate("Location Code", ItemJournalLine."Location Code");
        PalletLedgerEntry.validate("Unit of Measure", ItemJournalLine."Unit of Measure Code");
        ItemUOM.reset;
        ItemUOM.setrange("Item No.", ItemJournalLine."Item No.");
        ItemUOM.setrange(code, ItemJournalLine."Unit of Measure Code");
        if ItemUOM.findfirst then
            PalletLedgerEntry.validate(Quantity, ItemJournalLine.Quantity * ItemUOM."Qty. per Unit of Measure")
        else
            PalletLedgerEntry.validate(Quantity, ItemJournalLine.Quantity);
        PalletLedgerEntry."User ID" := userid;
        LPalletLine.Reset();
        LPalletLine.SetRange("Pallet ID", PalletLedgerEntry."Pallet ID");
        LPalletLine.SetRange("Item No.", PalletLedgerEntry."Item No.");
        if LPalletLine.FindFirst() then begin
            PalletLedgerEntry."Order Type" := 'Order';
            PalletLedgerEntry."Order No." := LPalletLine."Purchase Order No.";
            PalletLedgerEntry."Order Line No." := LPalletLine."Purchase Order Line No.";
        end;
        if PalletLedgerEntry.Quantity <> 0 then
            PalletLedgerEntry.Insert();

    end;

    //Posted Warehouse Shipments
    procedure PalletLedgerEntryWarehouseShipment(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    var
        PalletHeader: Record "Pallet Header";

    begin
        if PostedWhseShipmentLine."Item No." <> '' then begin
            PalletLedgerEntry.LockTable();
            LineNumber := GetLastEntry();

            PostedWarehousePallet.reset;
            PostedWarehousePallet.SetRange("Whse Shipment No.", PostedWhseShipmentLine."No.");
            PostedWarehousePallet.SetRange("Whse Shipment Line No.", PostedWhseShipmentLine."Line No.");
            if PostedWarehousePallet.findset then
                repeat
                    // if PalletHeader.get(PostedWarehousePallet."Pallet ID") then begin
                    //    PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::closed;
                    //     palletheader.modify;
                    // end;
                    if PalletLines.get(PostedWarehousePallet."Pallet ID", PostedWarehousePallet."Pallet Line No.") then begin
                        PalletLedgerEntry.Init();
                        PalletLedgerEntry."Entry No." := LineNumber;
                        PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Sales Shipment";
                        PalletLedgerEntry."Document No." := PostedWhseShipmentLine."No.";
                        PalletLedgerEntry."Document Line No." := PostedWhseShipmentLine."Line No.";
                        PalletLedgerEntry."Order Type" := 'Sales Order';
                        PalletLedgerEntry."Order No." := PostedWhseShipmentLine."Source No.";
                        PalletLedgerEntry."Order Line No." := PostedWhseShipmentLine."Source Line No.";
                        PalletLedgerEntry."Pallet ID" := PostedWarehousePallet."Pallet ID";
                        PalletLedgerEntry."Pallet Line No." := PostedWarehousePallet."Pallet Line No.";
                        PalletLedgerEntry.validate("Posting Date", PostedWhseShipmentLine."Posting Date");
                        PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                        PalletLedgerEntry."Item Description" := PalletLines.Description;
                        PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                        PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                        PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                        PalletLedgerEntry.validate(Quantity, -1 * PalletLines.Quantity);
                        PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                        PalletLedgerEntry."User ID" := userid;
                        if PalletLedgerEntry.Quantity <> 0 then
                            PalletLedgerEntry.Insert();
                    end;

                    //Change Status of Pallet to Shipped
                    if PalletHeader.get(PostedWarehousePallet."Pallet ID") then begin
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Shipped;
                        PalletHeader.modify;
                    end;

                    LineNumber += 1;
                until PostedWarehousePallet.next = 0;
        end;
    end;

    //Posted Return Receipts
    procedure PalletLedgerEntryReturnReceipt(var ReturnReceiptLine: Record "Return Receipt Line"; var SalseLine: Record "Sales Line")
    begin
        if ReturnReceiptLine."No." <> '' then begin


            PostedWarehousePallet.reset;
            PostedWarehousePallet.setrange("Sales Order No.", SalseLine."SPA Order No.");
            PostedWarehousePallet.setrange("Sales Order Line No.", SalseLine."SPA Order Line No.");
            if PostedWarehousePallet.findset then
                repeat
                    if PalletHeader.get(PostedWarehousePallet."Pallet ID") then begin
                        PalletLedgerEntry.LockTable();
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::closed;
                        palletheader.modify;
                    end;
                    if PalletLines.get(PostedWarehousePallet."Pallet ID", PostedWarehousePallet."Pallet Line No.") then begin
                        LineNumber := GetLastEntry();
                        PalletLedgerEntry.Init();
                        PalletLedgerEntry."Entry No." := LineNumber;
                        PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Sales Return Order";
                        PalletLedgerEntry."Document No." := ReturnReceiptLine."Document No.";
                        PalletLedgerEntry."Document Line No." := ReturnReceiptLine."Line No.";
                        PalletLedgerEntry."Order Type" := 'Return Order';
                        PalletLedgerEntry."Order No." := ReturnReceiptLine."Return Order No.";
                        PalletLedgerEntry."Order Line No." := ReturnReceiptLine."Return Order Line No.";
                        PalletLedgerEntry."Pallet ID" := PostedWarehousePallet."Pallet ID";
                        PalletLedgerEntry."Pallet Line No." := PostedWarehousePallet."Pallet Line No.";
                        PalletLedgerEntry.validate("Posting Date", Today);

                        PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                        PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                        PalletLedgerEntry."Item Description" := PalletLines.Description;
                        PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                        PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                        PalletLedgerEntry.validate(Quantity, PalletLines.Quantity);
                        PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                        PalletLedgerEntry."User ID" := userid;
                        if PalletLedgerEntry.Quantity <> 0 then
                            PalletLedgerEntry.Insert();
                        //Change Status of Pallet to closed after Post Sales Return Order
                        if PalletHeader.get(PostedWarehousePallet."Pallet ID") then begin
                            PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Closed;
                            PalletHeader."Exist in warehouse shipment" := false;
                            PalletHeader.Attention := true;
                            PalletHeader.modify;
                        end;

                        //   LineNumber += 1;
                    end;
                until PostedWarehousePallet.next = 0;
        end;
    end;

    //Consume Raw Materials for MW
    procedure ConsumeRawMaterials(var PalletHeader: Record "Pallet Header")
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");
        if palletlines.FindSet() then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Consume Raw Materials";
                PalletLedgerEntry."Pallet ID" := PalletHeader."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLines."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLines.Description;
                PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLines."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, -1 * palletlines.Quantity);
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    PalletLedgerEntry.Insert();
                LineNumber += 1;
            until palletlines.next = 0;
    end;

    //Consume Raw Materials for MW
    procedure ValueAddConsume(var PalletLine: Record "Pallet Line"; pQty: Decimal)
    begin
        PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLedgerEntry.Init();
        PalletLedgerEntry."Entry No." := LineNumber;
        PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Consume Value Add";
        PalletLedgerEntry."Pallet ID" := PalletLine."Pallet ID";
        PalletLedgerEntry."Document No." := PalletLine."Pallet ID";
        PalletLedgerEntry."Pallet Line No." := PalletLine."Line No.";
        PalletLedgerEntry.validate("Posting Date", Today);
        PalletLedgerEntry.validate("Item No.", PalletLine."Item No.");
        PalletLedgerEntry."Variant Code" := PalletLine."Variant Code";
        PalletLedgerEntry."Item Description" := PalletLine.Description;
        PalletLedgerEntry."Lot Number" := PalletLine."Lot Number";
        PalletLedgerEntry.validate("Location Code", PalletLine."Location Code");
        PalletLedgerEntry.validate("Unit of Measure", PalletLine."Unit of Measure");
        PalletLedgerEntry.validate(Quantity, -pQty);
        PalletLedgerEntry."User ID" := userid;
        if PalletLedgerEntry.Quantity <> 0 then
            PalletLedgerEntry.Insert();
        LineNumber += 1;
    end;

    procedure ValueAddUnConsume(var pPalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";

    begin
        PalletLedgerEntry.LockTable();
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                LineNumber := GetLastEntry();
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"UnConsume Value Add";
                PalletLedgerEntry."Pallet ID" := PalletLine."Pallet ID";
                PalletLedgerEntry."Document No." := PalletLine."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := PalletLine."Line No.";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", PalletLine."Item No.");
                PalletLedgerEntry."Variant Code" := PalletLine."Variant Code";
                PalletLedgerEntry."Item Description" := PalletLine.Description;
                PalletLedgerEntry."Lot Number" := PalletLine."Lot Number";
                PalletLedgerEntry.validate("Location Code", PalletLine."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", PalletLine."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, PalletLine."QTY Consumed");
                PalletLedgerEntry."User ID" := userid;
                if PalletLedgerEntry.Quantity <> 0 then
                    PalletLedgerEntry.Insert();
                LineNumber += 1;

                PalletLine."QTY Consumed" := 0;
                PalletLine."Remaining Qty" := PalletLine.Quantity;
                PalletLine.modify;

            until PalletLine.next = 0;

    end;

    //Get Last Number of Pallet Ledger Entry
    local procedure GetLastEntry(): Integer
    begin
        PalletLedgerEntry.reset;
        if PalletLedgerEntry.findlast then
            exit(PalletLedgerEntry."Entry No." + 1)
        else
            exit(1);
    end;

    var
        LineNumber: Integer;
        SalesLine: Record "Sales Line";
        Item: Record item;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        PalletLines: Record "Pallet Line";
        TransferShipHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        WarehousePallet: Record "Warehouse Pallet";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PalletHeader: Record "Pallet Header";
        PostedWarehousePallet: Record "Posted Warehouse Pallet";
        PostedReturnReceipt: Record "Return Receipt Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
}