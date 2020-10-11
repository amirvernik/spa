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
        //PalletLedgerEntry.LockTable();
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
        //PalletLedgerEntry.LockTable();
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

    //Negative Pallet Ledger Entry from a Pallet - Transfer Order (Shipment)
    procedure NegPalletLedgerTransfer(var pTransferShipLine: record "Transfer Shipment Line");
    begin
        TransferShipHeader.get(pTransferShipLine."Document No.");
        //PalletLedgerEntry.LockTable();
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
        //PalletLedgerEntry.LockTable();
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
                if PalletLedgerEntry.Quantity <> 0 then
                    PalletLedgerEntry.Insert();
                LineNumber += 1;
            until palletlines.next = 0;
    end;

    //Pallet Ledger Entry Reclass
    procedure PalletLedgerEntryReclass(var ItemLedgerEntry: Record "Item Ledger Entry")

    begin
        //PalletLedgerEntry.LockTable();
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
                    if PalletLedgerEntry.Quantity <> 0 then
                        PalletLedgerEntry.Insert();
                    LineNumber += 1;
                end;
            until palletlines.next = 0;
    end;

    //Pallet Ledger Entry Item Journal - Negative
    procedure NegPalletLedgerEntryItem(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        PackingMaterialLine: Record "Packing Material Line";
    begin
        // PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLedgerEntry.Init();
        PalletLedgerEntry."Entry No." := LineNumber;
        if ItemLedgerEntry.Disposal then
            PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Dispose Raw Materials"
        else
            PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Consume Packing Materials";
        PalletLedgerEntry."Pallet ID" := ItemLedgerEntry."Pallet ID";
        PalletLedgerEntry."Document No." := ItemLedgerEntry."Pallet ID";
        PalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        PalletLedgerEntry.validate("Posting Date", Today);
        PalletLedgerEntry.validate("Item No.", ItemLedgerEntry."Item No.");
        if item.get(ItemLedgerEntry."Item No.") then
            PalletLedgerEntry."Item Description" := item.Description;
        PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
        PalletLedgerEntry.validate("Location Code", ItemLedgerEntry."Location Code");
        //PalletLedgerEntry.validate("Unit of Measure", ItemLedgerEntry."Unit of Measure Code");
        //PalletLedgerEntry.validate(Quantity, ItemLedgerEntry.Quantity);
        PalletLedgerEntry.validate("Unit of Measure", ItemLedgerEntry."Packing Material UOM");
        PalletLedgerEntry.validate(Quantity, -1 * ItemLedgerEntry."Packing Material Qty");
        PalletLedgerEntry."User ID" := userid;
        if PalletLedgerEntry.Quantity <> 0 then
            PalletLedgerEntry.Insert();
    end;

    //Pallet Ledger Entry Item Journal - Negative
    procedure PosPalletLedgerEntryItem(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemUOM: Record "Item Unit of Measure";
    begin
        //PalletLedgerEntry.LockTable();
        LineNumber := GetLastEntry();
        PalletLedgerEntry.Init();
        PalletLedgerEntry."Entry No." := LineNumber;
        PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Return Packing Materials";
        PalletLedgerEntry."Pallet ID" := ItemLedgerEntry."Pallet ID";
        PalletLedgerEntry."Document No." := ItemLedgerEntry."Pallet ID";
        PalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        PalletLedgerEntry.validate("Posting Date", Today);
        PalletLedgerEntry.validate("Item No.", ItemLedgerEntry."Item No.");
        if item.get(ItemLedgerEntry."Item No.") then
            PalletLedgerEntry."Item Description" := item.Description;
        PalletLedgerEntry."Variant Code" := PalletLines."Variant Code";
        PalletLedgerEntry.validate("Location Code", ItemLedgerEntry."Location Code");
        //PalletLedgerEntry.validate("Unit of Measure", ItemLedgerEntry."Unit of Measure Code");
        //PalletLedgerEntry.validate(Quantity, ItemLedgerEntry.Quantity);
        PalletLedgerEntry.validate("Unit of Measure", ItemLedgerEntry."Packing Material UOM");
        ItemUOM.reset;
        ItemUOM.setrange("Item No.", ItemLedgerEntry."Item No.");
        ItemUOM.setrange(code, ItemLedgerEntry."Packing Material UOM");
        if ItemUOM.findfirst then
            //PalletLedgerEntry.validate(Quantity, ItemLedgerEntry."Packing Material Qty");
            PalletLedgerEntry.validate(Quantity, ItemLedgerEntry.Quantity * ItemUOM."Qty. per Unit of Measure")
        else
            PalletLedgerEntry.validate(Quantity, ItemLedgerEntry.Quantity);
        PalletLedgerEntry."User ID" := userid;
        if PalletLedgerEntry.Quantity <> 0 then
            PalletLedgerEntry.Insert();
    end;

    //Posted Warehouse Shipments
    procedure PalletLedgerEntryWarehouseShipment(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line")
    var
        PalletHeader: Record "Pallet Header";

    begin
        if SalesShipmentLine."No." <> '' then begin
            LineNumber := GetLastEntry();
            PostedWarehousePallet.reset;
            PostedWarehousePallet.setrange("Sales Order No.", SalesLine."Document No.");
            PostedWarehousePallet.setrange("Sales Order Line No.", SalesLine."Line No.");
            if PostedWarehousePallet.findset then
                repeat
                    if PalletHeader.get(PostedWarehousePallet."Pallet ID") then begin
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::closed;
                        palletheader.modify;
                    end;

                    PalletLedgerEntry.Init();
                    PalletLedgerEntry."Entry No." := LineNumber;
                    PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Sales Shipment";
                    PalletLedgerEntry."Document No." := SalesShipmentLine."Document No.";
                    PalletLedgerEntry."Document Line No." := SalesShipmentLine."Line No.";
                    PalletLedgerEntry."Order Type" := 'Sales Order';
                    PalletLedgerEntry."Order No." := SalesShipmentLine."Order No.";
                    PalletLedgerEntry."Order Line No." := SalesShipmentLine."Order Line No.";
                    PalletLedgerEntry."Pallet ID" := PostedWarehousePallet."Pallet ID";
                    PalletLedgerEntry."Pallet Line No." := PostedWarehousePallet."Pallet Line No.";
                    PalletLedgerEntry.validate("Posting Date", Today);
                    PalletLines.get(PostedWarehousePallet."Pallet ID", PostedWarehousePallet."Pallet Line No.");
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
            LineNumber := GetLastEntry();
            PostedWarehousePallet.reset;
            PostedWarehousePallet.setrange("Sales Order No.", SalseLine."SPA Order No.");
            PostedWarehousePallet.setrange("Sales Order Line No.", SalseLine."SPA Order Line No.");
            if PostedWarehousePallet.findset then
                repeat
                    if PalletHeader.get(PostedWarehousePallet."Pallet ID") then begin
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::closed;
                        palletheader.modify;
                    end;

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
                    PalletLines.get(PostedWarehousePallet."Pallet ID", PostedWarehousePallet."Pallet Line No.");
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
                        PalletHeader.modify;
                    end;

                    LineNumber += 1;
                until PostedWarehousePallet.next = 0;
        end;
    end;

    //Consume Raw Materials for MW
    procedure ConsumeRawMaterials(var PalletHeader: Record "Pallet Header")
    begin
        //PalletLedgerEntry.LockTable();
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
        // PalletLedgerEntry.LockTable();
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
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                //PalletLedgerEntry.LockTable();
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