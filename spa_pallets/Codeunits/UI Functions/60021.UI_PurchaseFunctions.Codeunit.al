codeunit 60021 "Purch. UI Functions"
{
    //Create Purchase Order Header - Grade
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreatePurchaseHeader(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PurchaseHeader: Record "purchase header";
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PurchaseSetup: Record "Purchases & Payables Setup";
        Obj_JsonText: Text;
        VendorNo: Code[20];
        VendorShipmentNo: Text;
        BinQuantity: Decimal;
        HarvestDate: Date;
        PurchaseType: Text;
        RM_Item: code[20];
        RM_Location: code[20];
        RM_Qty: Decimal;
        RM_Lot: code[20];
        VendorRec: Record Vendor;
        OrderNumber: code[20];
        BatchNumber: code[20];

    begin
        IF pFunction <> 'CreatePurchaseHeader' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);
        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'vendorno' THEN
                        VendorNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'packingslipno' THEN
                        if JSONBuffer.Value <> '' then
                            VendorShipmentNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    if JSONBuffer.Value <> '' then
                        IF JSONBuffer.Path = 'binquantity' THEN
                            evaluate(BinQuantity, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'harvestdate' THEN
                        evaluate(HarvestDate, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'purchasetype' THEN
                        PurchaseType := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmitem' THEN
                        RM_Item := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmlocation' THEN
                        RM_Location := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmqty' THEN
                        if JSONBuffer.Value <> '' then
                            evaluate(RM_Qty, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmlotno' THEN
                        if JSONBuffer.Value <> '' then
                            RM_Lot := JSONBuffer.Value;

            UNTIL JSONBuffer.NEXT = 0;

            if (VendorNo <> '') and (VendorShipmentNo <> '') and (PurchaseType <> '') then begin
                PurchaseProcessSetup.get;
                if PurchaseProcessSetup."Batch No. Series" <> '' then begin
                    PurchaseSetup.get;
                    PurchaseHeader.init;
                    PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::order;
                    OrderNumber := NoSeriesManagement.GetNextNo(PurchaseSetup."Order Nos.", Today, true);
                    BatchNumber := NoSeriesManagement.GetNextNo(PurchaseProcessSetup."Batch No. Series", Today, true);
                    PurchaseHeader."No." := OrderNumber;

                    if PurchaseType = 'grading' then begin
                        PurchaseHeader."Grading Result PO" := true;
                        if Vendorrec.get(VendorNo) then
                            PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                        PurchaseHeader.validate("Order Date", Today);
                        PurchaseHeader.validate("Document Date", today);
                        PurchaseHeader.validate("posting Date", today);
                        PurchaseHeader."Number Of Raw Material Bins" := BinQuantity;
                        PurchaseHeader."Harvest Date" := HarvestDate;
                        PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                        PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                        PurchaseHeader."Batch Number" := BatchNumber;
                        PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                        PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                        PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                        PurchaseHeader.insert;
                    end;
                    if PurchaseType = 'microwave' then begin
                        PurchaseHeader."Microwave Process PO" := true;
                        if Vendorrec.get(VendorNo) then
                            PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                        PurchaseHeader.validate("Order Date", Today);
                        PurchaseHeader.validate("Document Date", today);
                        PurchaseHeader.validate("posting Date", today);
                        PurchaseHeader."Number Of Raw Material Bins" := BinQuantity;
                        PurchaseHeader."Harvest Date" := HarvestDate;
                        PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                        PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                        PurchaseHeader."Batch Number" := rm_lot;
                        PurchaseHeader."Raw Material Item" := RM_Item;
                        PurchaseHeader."RM Location" := RM_Location;
                        PurchaseHeader."RM Qty" := RM_Qty;
                        PurchaseHeader."Item LOT Number" := rm_lot;
                        PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                        PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                        PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";

                        PurchaseHeader.insert;
                    end;
                    if PurchaseType = 'regular' then begin
                        if Vendorrec.get(VendorNo) then
                            PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                        PurchaseHeader.validate("Order Date", Today);
                        PurchaseHeader.validate("Document Date", today);
                        PurchaseHeader.validate("posting Date", today);
                        PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                        PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                        PurchaseHeader."Batch Number" := BatchNumber;
                        PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                        PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                        PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                        PurchaseHeader.insert;
                    end;

                end;
            end;
        end;
        if PurchaseHeader.get(PurchaseHeader."Document Type"::order, OrderNumber) then begin
            Obj_JsonText += '[{' +
                        '"PO number": ' +
                        '"' + PurchaseHeader."No." + '"' +
                        ',' +
                        '"Batch Number": "' +
                        PurchaseHeader."Batch Number" +
                        '"},';

            Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
            Obj_JsonText += ']';
            pContent := Obj_JsonText;

        end;
    end;

    //Create Purchase Header - Microwave
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreatePurchaseHeaderMW(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PurchaseHeader: Record "purchase header";
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PurchaseSetup: Record "Purchases & Payables Setup";
        Obj_JsonText: Text;
        VendorNo: Code[20];
        VendorShipmentNo: Text;
        BinQuantity: Decimal;
        HarvestDate: Date;
        PurchaseType: Text;
        RM_Item: code[20];
        RM_Location: code[20];
        RM_Qty: Decimal;
        RM_Lot: code[20];
        VendorRec: Record Vendor;
        ScrapQty: Decimal;
        OrderNumber: code[20];
        BatchNumber: code[20];
        PalletHeaderTemp: Record "Pallet Header" temporary;
        PalletHeader: Record "Pallet Header";
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";

    begin
        IF pFunction <> 'CreatePurchaseHeaderMW' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);
        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'vendorno' THEN
                        VendorNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'packingslipno' THEN
                        if JSONBuffer.Value <> '' then
                            VendorShipmentNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    if JSONBuffer.Value <> '' then
                        IF JSONBuffer.Path = 'binquantity' THEN
                            evaluate(BinQuantity, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'harvestdate' THEN
                        evaluate(HarvestDate, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'purchasetype' THEN
                        PurchaseType := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmitem' THEN
                        RM_Item := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmlocation' THEN
                        RM_Location := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmqty' THEN
                        if JSONBuffer.Value <> '' then
                            evaluate(RM_Qty, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'rmlotno' THEN
                        if JSONBuffer.Value <> '' then
                            RM_Lot := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    if JsonBuffer.path = 'scrapqty' then
                        if JsonBuffer.value <> '' then
                            Evaluate(ScrapQty, JSONBuffer.Value);

            UNTIL JSONBuffer.NEXT = 0;

            if (VendorNo <> '') and (VendorShipmentNo <> '') and (PurchaseType <> '') then begin
                PurchaseProcessSetup.get;
                if PurchaseProcessSetup."Batch No. Series" <> '' then begin
                    PurchaseSetup.get;
                    PurchaseHeader.init;
                    PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::order;
                    OrderNumber := NoSeriesManagement.GetNextNo(PurchaseSetup."Order Nos.", Today, true);
                    BatchNumber := NoSeriesManagement.GetNextNo(PurchaseProcessSetup."Batch No. Series", Today, true);
                    PurchaseHeader."No." := OrderNumber;

                    if PurchaseType = 'grading' then begin
                        PurchaseHeader."Grading Result PO" := true;
                        if Vendorrec.get(VendorNo) then
                            PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                        PurchaseHeader.validate("Order Date", Today);
                        PurchaseHeader.validate("Document Date", today);
                        PurchaseHeader.validate("posting Date", today);
                        PurchaseHeader."Number Of Raw Material Bins" := BinQuantity;
                        PurchaseHeader."Harvest Date" := HarvestDate;
                        PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                        PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                        PurchaseHeader."Batch Number" := BatchNumber;
                        PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                        PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                        PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                        PurchaseHeader.insert;
                    end;
                    if PurchaseType = 'microwave' then begin
                        PurchaseHeader."Microwave Process PO" := true;
                        if Vendorrec.get(VendorNo) then
                            PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                        PurchaseHeader.validate("Order Date", Today);
                        PurchaseHeader.validate("Document Date", today);
                        PurchaseHeader.validate("posting Date", today);
                        PurchaseHeader."Number Of Raw Material Bins" := BinQuantity;
                        PurchaseHeader."Harvest Date" := HarvestDate;
                        PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                        PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                        PurchaseHeader."Batch Number" := rm_lot;
                        PurchaseHeader."Raw Material Item" := RM_Item;
                        PurchaseHeader."RM Location" := RM_Location;
                        PurchaseHeader."RM Qty" := RM_Qty;
                        PurchaseHeader."Item LOT Number" := rm_lot;
                        PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                        PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                        PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                        PurchaseHeader."Scrap QTY (KG)" := ScrapQty;
                        PurchaseHeader.insert;
                    end;
                    if PurchaseType = 'regular' then begin
                        if Vendorrec.get(VendorNo) then
                            PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                        PurchaseHeader.validate("Order Date", Today);
                        PurchaseHeader.validate("Document Date", today);
                        PurchaseHeader.validate("posting Date", today);
                        PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                        PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                        PurchaseHeader."Batch Number" := BatchNumber;
                        PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                        PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                        PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                        PurchaseHeader.insert;
                    end;

                end;
            end;
        end;

        //Assign the Pallets
        if PalletHeaderTemp.findset then
            PalletHeaderTemp.deleteall;

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 3);
        jsonbuffer.SetRange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                if strpos(JsonBuffer.path, 'palletid') > 0 then begin
                    PalletHeaderTemp.init;
                    PalletHeaderTemp."Pallet ID" := JSONBuffer.value;
                    PalletHeaderTemp.insert;
                end;
            until JsonBuffer.next = 0;
        end;

        PalletHeaderTemp.reset;
        if PalletHeaderTemp.findset then
            repeat
                if PalletHeader.get(PalletHeaderTemp."Pallet ID") then begin
                    PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Consumed;
                    PalletHeader.modify;
                    PalletLedgerFunctions.ConsumeRawMaterials(PalletHeader);
                end;
            until PalletHeaderTemp.next = 0;

        if PurchaseHeader.get(PurchaseHeader."Document Type"::order, OrderNumber) then begin
            Obj_JsonText += '[{' +
                        '"PO number": ' +
                        '"' + PurchaseHeader."No." + '"' +
                        ',' +
                        '"Batch Number": "' +
                        PurchaseHeader."Batch Number" +
                        '"},';

            Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
            Obj_JsonText += ']';

            pContent := Obj_JsonText;

        end;
    end;

    //Complete Purchsae Order Batch - CompleteMicrowaveBatch [8818]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CompleteMicrowaveBatch(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PurchaseHeader: Record "Purchase Header";
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        OrderNo: code[20];
        BatchNumber: code[20];
        ItemJournalLine: Record "Item Journal Line";
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";

    begin
        IF pFunction <> 'CompleteMicrowaveBatch' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        //JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
        JsonBuffer.SetRange(JSONBuffer.path, 'orderno');
        if JsonBuffer.FindFirst() then
            OrderNo := JsonBuffer.value;

        JSONBuffer.RESET;
        //JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
        JsonBuffer.SetRange(JSONBuffer.path, 'batch');
        if JsonBuffer.FindFirst() then
            BatchNumber := JsonBuffer.value;

        if PurchaseHeader.get(PurchaseHeader."Document Type"::order, OrderNo) then begin
            if PurchaseHeader."Microwave Process PO" then begin
                if not PurchaseHeader."RM Add Neg" then begin
                    PalletLedgerEntry.Reset;
                    PalletLedgerEntry.SetRange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Consume Raw Materials");
                    PalletLedgerEntry.setrange("Lot Number", BatchNumber);
                    if PalletLedgerEntry.findset then begin
                        repeat
                            CreateNegAdjustment(PalletLedgerEntry, OrderNo);
                        until PalletLedgerEntry.next = 0;

                        //Post the Journal
                        PurchaseProcessSetup.Get();
                        ItemJournalLine.reset;
                        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                        ItemJournalLine.setrange(ItemJournalLine."Document No.", OrderNo);
                        if ItemJournalLine.findset() then begin
                            CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
                            if GetLastErrorText = '' then begin
                                PurchaseHeader."RM Add Neg" := true;
                                PurchaseHeader.modify;
                                pContent := 'Success';
                            end
                            else
                                pContent := GetLastErrorText;
                        end;

                    end;
                end
                else
                    pcontent := 'error, raw material already been consumed';
            end
            else
                pcontent := 'error, order is not a microwave order';
        end
        else
            pContent := 'error,purchase order/batch cannot be found';
    end;

    //Create Negative Adjustment
    Procedure CreateNegAdjustment(PalletLedgEntry: Record "Pallet Ledger Entry"; PurchaseOrderNo: code[20])
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        maxEntry: Integer;
        ItemRec: Record Item;
    begin
        PurchaseProcessSetup.get();
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        if ItemJournalLine.FindLast() then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        ItemJournalLine.init;
        ItemJournalLine."Journal Template Name" := 'ITEM';
        ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
        ItemJournalLine."Line No." := LineNumber;
        ItemJournalLine.insert;
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
        ItemJournalLine."Posting Date" := Today;
        ItemJournalLine."Document No." := PurchaseOrderNo;
        ItemJournalLine."Document Date" := today;
        ItemJournalLine.validate("Item No.", PalletLedgEntry."Item No.");
        ItemJournalLine.validate("Variant Code", PalletLedgEntry."Variant Code");
        ItemJournalLine.validate("Location Code", PalletLedgEntry."Location Code");
        ItemJournalLine.validate(Quantity, PalletLedgEntry.Quantity);
        ItemJournalLine.modify;

        //Create Reservation Entry
        if ItemRec.get(PalletLedgEntry."Item No.") then
            if Itemrec."Lot Nos." <> '' then begin
                RecGReservationEntry2.reset;
                if RecGReservationEntry2.findlast then
                    maxEntry := RecGReservationEntry2."Entry No." + 1;

                RecGReservationEntry.init;
                RecGReservationEntry."Entry No." := MaxEntry;
                //V16.0 - Changed From [3] to "Prospect" on Enum
                RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                //V16.0 - Changed From [3] to "Prospect" on Enum
                RecGReservationEntry."Creation Date" := Today;
                RecGReservationEntry."Created By" := UserId;
                RecGReservationEntry."Expected Receipt Date" := Today;
                RecGReservationEntry."Source Type" := 83;
                RecGReservationEntry."Source Subtype" := 3;
                RecGReservationEntry."Source ID" := 'ITEM';
                RecGReservationEntry."Source Ref. No." := LineNumber;
                RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                RecGReservationEntry.validate("Location Code", PalletLedgEntry."Location Code");
                //V16.0 - Changed From [1] to "Lot No." on Enum
                RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                //V16.0 - Changed From [1] to "Lot No." on Enum
                RecGReservationEntry."Lot No." := PalletLedgEntry."Lot Number";
                RecGReservationEntry.validate("Item No.", PalletLedgEntry."Item No.");
                if PalletLedgEntry."Variant Code" <> '' then
                    RecGReservationEntry.validate("Variant Code", PalletLedgEntry."Variant Code");
                RecGReservationEntry.validate("Quantity (Base)", -1 * PalletLedgEntry.Quantity);
                RecGReservationEntry.validate(Quantity, -1 * PalletLedgEntry.Quantity);
                RecGReservationEntry.Positive := false;
                RecGReservationEntry.insert;
            end;
    end;

    //Complete Purchsae Order Batch - AddPalletsToMWPurchaseOrder [8820]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure AddPalletsToMWPurchaseOrder(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        OrderNo: code[20];
        BatchNumber: code[20];
        TotalQty: Decimal;
        PurchaseHeader: Record "Purchase Header";
        PalletHeader: Record "Pallet Header";
        PalletInt: Integer;
        TotalInt: Integer;
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";

    begin
        IF pFunction <> 'AddPalletsToMWPurchaseOrder' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
        if jsonbuffer.findset then
            repeat
                if JSONBuffer.path = 'orderNum' then
                    OrderNo := JsonBuffer.value;
                if JSONBuffer.path = 'batch' then
                    BatchNumber := JsonBuffer.value;
                if JSONBuffer.path = 'totalQty' then
                    evaluate(TotalQty, JsonBuffer.value);
            until jsonbuffer.next = 0;

        PurchaseHeader.reset;
        PurchaseHeader.setrange(purchaseheader."Document Type", PurchaseHeader."Document Type"::order);
        PurchaseHeader.setrange(PurchaseHeader."No.", OrderNo);
        PurchaseHeader.setrange(PurchaseHeader."Batch Number", BatchNumber);
        if PurchaseHeader.findfirst then begin
            TotalInt := 0;
            PalletInt := 0;
            JSONBuffer.RESET;
            JSONBuffer.SETRANGE(JSONBuffer.Depth, 3);
            JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
            if jsonbuffer.findset then
                repeat
                    if strpos(JsonBuffer.path, 'palletId') > 0 then begin
                        TotalInt += 1;
                        if PalletHeader.get(JsonBuffer.value) then begin
                            PalletInt += 1;
                            PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Consumed;
                            PalletHeader.modify;
                            PalletLedgerFunctions.ConsumeRawMaterials(PalletHeader);
                        end;
                    end;
                until JsonBuffer.next = 0;

            if PalletInt = TotalInt then begin
                pContent := 'Success';
                PurchaseHeader."RM Qty" += TotalQty;
                PurchaseHeader.modify;
            end
            else
                pContent := 'Error';
        end
        else
            pContent := 'error, no such Purchase Order exist';
    end;
}