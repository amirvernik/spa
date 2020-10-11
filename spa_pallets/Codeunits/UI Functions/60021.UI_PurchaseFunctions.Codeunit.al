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
        VarietyCode: code[10];

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
                    IF JSONBuffer.Path = 'varietycode' THEN
                        if JSONBuffer.Value <> '' then
                            VarietyCode := JSONBuffer.Value;

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
                    OrderNumber := NoSeriesManagement.GetNextNo(PurchaseSetup."Order Nos.", GetCurrTime, true);
                    BatchNumber := NoSeriesManagement.GetNextNo(PurchaseProcessSetup."Batch No. Series", GetCurrTime, true);
                    PurchaseHeader."No." := OrderNumber;
                    if PurchaseHeader.Insert(true) then begin
                        case PurchaseType of
                            'grading':
                                begin
                                    PurchaseHeader."Grading Result PO" := true;
                                    if Vendorrec.get(VendorNo) then
                                        PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                                    PurchaseHeader."Document Date" := GetCurrTime;
                                    PurchaseHeader."posting Date" := GetCurrTime;
                                    PurchaseHeader."Order Date" := GetCurrTime;
                                    PurchaseHeader."Number Of Raw Material Bins" := BinQuantity;
                                    PurchaseHeader."Variety Code" := VarietyCode;
                                    PurchaseHeader."Harvest Date" := HarvestDate;
                                    PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                                    PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                                    PurchaseHeader."Batch Number" := BatchNumber;
                                    PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                                    PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                                    PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                                    PurchaseHeader."Variety Code" := VarietyCode;
                                    PurchaseHeader.Modify();
                                end;
                            'microwave':
                                begin
                                    PurchaseHeader."Microwave Process PO" := true;
                                    if Vendorrec.get(VendorNo) then
                                        PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                                    PurchaseHeader."Document Date" := GetCurrTime;
                                    PurchaseHeader."posting Date" := GetCurrTime;
                                    PurchaseHeader."Order Date" := GetCurrTime;
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

                                    PurchaseHeader.Modify();
                                end;
                            'regular':
                                begin
                                    if Vendorrec.get(VendorNo) then
                                        PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);
                                    PurchaseHeader."Document Date" := GetCurrTime;
                                    PurchaseHeader."posting Date" := GetCurrTime;
                                    PurchaseHeader."Order Date" := GetCurrTime;
                                    PurchaseHeader."Variety Code" := VarietyCode;
                                    PurchaseHeader."Vendor Shipment No." := VendorShipmentNo;
                                    PurchaseHeader."Vendor Invoice No." := VendorShipmentNo;
                                    PurchaseHeader."Batch Number" := BatchNumber;
                                    PurchaseHeader."No. Series" := PurchaseSetup."Order Nos.";
                                    PurchaseHeader."Posting No. Series" := PurchaseSetup."Posted Invoice Nos.";
                                    PurchaseHeader."Receiving No. Series" := PurchaseSetup."Posted Receipt Nos.";
                                    PurchaseHeader.Modify();
                                end;
                        end;
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
        PalletLineTemp: Record "Pallet Line" temporary;
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        JsonObj: JsonObject;
        JsonTknAll: JsonToken; //All Json
        JsonTkn: jsontoken; //Getting Data From
        JsonTkn2: JsonToken;
        JsontokenLines: JsonToken;
        JsonTokenLinesData: JsonToken;
        JsonArr: JsonArray;
        JsonArrLines: JsonArray;
        Searcher: Integer;
        Searcher_Lines: Integer;
        PalletID: code[20];
        PalletItem: code[20];
        PalletVariety: code[10];
        PalletConsumed: Decimal;
        Err001: Label 'Cant consume more than remaining';
        PalletsNotConsumed: Boolean;
        JsonResult: JsonObject;
        Variety_Code: code[10];
    begin
        IF pFunction <> 'CreatePurchaseHeaderMW' THEN
            EXIT;

        if PalletLineTemp.findset then
            PalletLineTemp.deleteall;

        JsonObj.ReadFrom(pContent);

        //Get Vendor No.
        JsonObj.SelectToken('vendorno', JsonTkn);
        VendorNo := JsonTkn.AsValue().AsText();

        //Get Packing Slip No. [Vendor Shipment No.]
        JsonObj.SelectToken('packingslipno', JsonTkn);
        VendorShipmentNo := JsonTkn.AsValue().AsText();

        //Get Packing Slip No. [Vendor Shipment No.]
        JsonObj.SelectToken('packingslipno', JsonTkn);
        VendorShipmentNo := JsonTkn.AsValue().AsText();

        //Get Bin Quantity
        JsonObj.SelectToken('binquantity', JsonTkn);
        BinQuantity := JsonTkn.AsValue().AsDecimal();

        //Get Harvest Date
        JsonObj.SelectToken('harvestdate', JsonTkn);
        evaluate(HarvestDate, JsonTkn.AsValue().AsText());

        //Get Purchase Type
        JsonObj.SelectToken('purchasetype', JsonTkn);
        PurchaseType := JsonTkn.AsValue().AsText();

        //Get Raw Material Item
        JsonObj.SelectToken('rmitem', JsonTkn);
        RM_Item := JsonTkn.AsValue().AsText();

        //Get Raw Material Location
        JsonObj.SelectToken('rmlocation', JsonTkn);
        RM_Location := JsonTkn.AsValue().AsText();

        //Get Raw Material Qty
        JsonObj.SelectToken('rmqty', JsonTkn);
        RM_Qty := JsonTkn.AsValue().AsDecimal();

        //Get Raw Material Lot No.
        JsonObj.SelectToken('rmlotno', JsonTkn);
        RM_Lot := JsonTkn.AsValue().AsText();

        //Get Scrap Qty
        JsonObj.SelectToken('scrapqty', JsonTkn);
        ScrapQty := JsonTkn.AsValue().AsDecimal();

        //Get Variety code
        JsonObj.SelectToken('varietycode', JsonTkn);
        Variety_Code := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('pallets', JsonTkn);
        JsonArr := JsonTkn.AsArray();

        pContent := '';
        Searcher := 0;
        while searcher < JsonArr.Count do begin

            //Getting PalletID for each Pallet
            JsonArr.get(searcher, JsonTknAll);
            JsonObj := JsonTknAll.AsObject();

            JsonObj.SelectToken('palletid', JsonTkn2);
            PalletID := JsonTkn2.AsValue().AsText();

            //Creating Pallet Header temp for consuming
            PalletHeaderTemp.init;
            PalletHeaderTemp."Pallet ID" := PalletID;
            PalletHeaderTemp.insert;

            searcher += 1;

            //Getting the Lines
            JsonObj.SelectToken('palletLines', JsonTkn);
            JsonArrLines := JsonTkn.AsArray();
            Searcher_Lines := 0;
            while Searcher_Lines < JsonArrLines.Count do begin

                //Getting Pllaet Line Data
                JsonArrLines.get(Searcher_Lines, JsontokenLines);
                JsonObj := JsontokenLines.AsObject();

                JsonObj.SelectToken('itemId', JsonTokenLinesData);
                PalletItem := JsonTokenLinesData.AsValue().AsText();

                JsonObj.SelectToken('variety', JsonTokenLinesData);
                PalletVariety := JsonTokenLinesData.AsValue().AsText();

                JsonObj.SelectToken('consumingQty', JsonTokenLinesData);
                PalletConsumed := JsonTokenLinesData.AsValue().AsDecimal();

                PalletLine.reset;
                PalletLine.setrange("Pallet ID", PalletID);
                PalletLine.SetRange("Lot Number", RM_Lot);
                PalletLine.setrange("Item No.", PalletItem);
                PalletLine.setrange("Variant Code", PalletVariety);
                if PalletLine.findfirst then begin
                    PalletLineTemp.init;
                    PalletLineTemp.TransferFields(PalletLine);
                    PalletLineTemp."QTY Consumed" := PalletConsumed;
                    palletlinetemp.insert();
                end;
                Searcher_Lines += 1;
            end;
        end;

        PalletLineTemp.reset;
        if PalletLineTemp.findset then
            repeat
                if PalletLine.get(PalletLineTemp."Pallet ID", PalletLineTemp."Line No.") then begin
                    if PalletLineTemp."QTY Consumed" <= PalletLine."Remaining Qty" then begin
                        PalletLine."QTY Consumed" += PalletLineTemp."QTY Consumed";
                        PalletLine."Remaining Qty" -= PalletLineTemp."QTY Consumed";
                        PalletLine.modify;

                        PalletLedgerFunctions.ValueAddConsume(PalletLine, PalletLineTemp."QTY Consumed");

                        PalletLineTemp."Exists on Warehouse Shipment" := true;
                        PalletLineTemp.modify;
                    end
                end;
            until PalletLineTemp.next = 0;

        //if all consumed
        PalletLineTemp.reset;
        PalletLineTemp.setrange("Exists on Warehouse Shipment", false);
        if PalletLineTemp.findfirst then
            PalletsNotConsumed := true;

        //Mark Pallets as consumed/Partially consumed
        if not PalletsNotConsumed then begin
            PalletHeaderTemp.reset;
            if PalletHeaderTemp.findset then
                repeat
                    PalletHeader.get(PalletHeaderTemp."Pallet ID");
                    PalletLine.reset;
                    PalletLine.setrange("Pallet ID", PalletHeaderTemp."Pallet ID");
                    PalletLine.setfilter("Remaining Qty", '<>%1', 0);
                    if PalletLine.findfirst then
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::"Partially consumed"
                    else
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Consumed;
                    PalletHeader.modify;
                    PalletLedgerFunctions.ConsumeRawMaterials(PalletHeader);
                until PalletHeaderTemp.next = 0;
        end;

        //Creating The PO
        if not PalletsNotConsumed then begin
            if (VendorNo <> '') and (VendorShipmentNo <> '') and (PurchaseType = 'microwave') then begin
                PurchaseProcessSetup.get;
                if PurchaseProcessSetup."Batch No. Series" <> '' then begin
                    PurchaseSetup.get;
                    PurchaseHeader.init;
                    PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::order;
                    OrderNumber := NoSeriesManagement.GetNextNo(PurchaseSetup."Order Nos.", GetCurrTime, true);
                    BatchNumber := NoSeriesManagement.GetNextNo(PurchaseProcessSetup."Batch No. Series", GetCurrTime, true);
                    PurchaseHeader."No." := OrderNumber;
                    purchaseheader.insert(true);

                    PurchaseHeader."Microwave Process PO" := true;
                    if Vendorrec.get(VendorNo) then
                        PurchaseHeader.validate("Buy-from Vendor No.", VendorNo);

                    PurchaseHeader."Document Date" := GetCurrTime;
                    PurchaseHeader."posting Date" := GetCurrTime;
                    PurchaseHeader."Order Date" := GetCurrTime;
                    PurchaseHeader."Number Of Raw Material Bins" := BinQuantity;
                    PurchaseHeader."Variety Code" := Variety_Code;
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
                    PurchaseHeader.modify;

                    //Sending Result Json
                    JsonResult.Add('PO number', OrderNumber);
                    JsonResult.add('Batch Number', BatchNumber);
                    JsonResult.WriteTo(pContent);
                end;
            end;
        end;

        //If po not created
        if PalletsNotConsumed then
            pContent := 'Pallets cannot be consumed, PO not created';

    end;



    /*if (VendorNo <> '') and (VendorShipmentNo <> '') and (PurchaseType <> '') then begin
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
    end;*/
    //end;





    //Complete Purchsae Order Batch - CompleteMicrowaveBatch [8818]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CompleteMicrowaveBatch(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        PurchaseHeader: Record "Purchase Header";
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        OrderNo: code[20];
        BatchNumber: code[20];
        ScrapQty: Decimal;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";

    begin
        IF pFunction <> 'CompleteMicrowaveBatch' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Order Number
        JsonObj.SelectToken('orderno', JsonTkn);
        OrderNo := JsonTkn.AsValue().AsText();

        //Get Batch Number
        JsonObj.SelectToken('batch', JsonTkn);
        BatchNumber := JsonTkn.AsValue().AsText();

        //Get Scrap Qty
        JsonObj.SelectToken('scrapqty', JsonTkn);
        ScrapQty := JsonTkn.AsValue().AsDecimal();

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
                            repeat
                                CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);
                            until ItemJournalLine.Next() = 0;
                            if GetLastErrorText = '' then begin
                                PurchaseHeader."RM Add Neg" := true;
                                //Edit Scrap Qty
                                PurchaseHeader."Scrap QTY (KG)" := ScrapQty;
                                PurchaseHeader.modify;
                                pContent := 'Success';
                            end
                            else
                                pContent := GetLastErrorText;
                        end
                        else
                            pContent := 'error, Raw materials not consumed, please consume and run again';
                    end
                    else
                        pContent := 'error,raw material was not consumed'
                end
                else
                    pcontent := 'error, raw material already been consumed';
            end
            else
                pcontent := 'error, order is not a microwave order';
        end
        else
            pContent := 'error,purchase order/batch cannot be found';
    end;//

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
        ItemJournalLine."Posting Date" := GetCurrTime;
        ItemJournalLine."Document No." := PurchaseOrderNo;
        ItemJournalLine."Document Date" := GetCurrTime;
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
                RecGReservationEntry."Creation Date" := GetCurrTime;
                RecGReservationEntry."Created By" := UserId;
                RecGReservationEntry."Expected Receipt Date" := GetCurrTime;
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
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        JsonArr: JsonArray;
        JsonArrLines: JsonArray;
        JsonTkn2: JsonToken;
        JsonTknAll: JsonToken;
        JsontokenLines: JsonToken;
        JsonTokenLinesData: JsonToken;
        OrderNo: code[20];
        BatchNumber: code[20];
        TotalQty: Decimal;
        PalletID: code[20];
        PurchaseHeader: Record "Purchase Header";
        PalletHeader: Record "Pallet Header";
        PalletInt: Integer;
        TotalInt: Integer;
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletHeaderTemp: Record "Pallet Header" temporary;
        PalletLineTemp: Record "Pallet Line" temporary;
        PalletLine: Record "Pallet Line";
        Searcher: Integer;
        Searcher_Lines: Integer;
        PalletItem: code[20];
        PalletVariety: code[10];
        PalletConsumed: Decimal;
        PalletsNotConsumed: Boolean;
    begin
        IF pFunction <> 'AddPalletsToMWPurchaseOrder' THEN
            EXIT;

        if PalletLineTemp.findset then
            PalletLineTemp.deleteall;

        JsonObj.ReadFrom(pContent);

        //Get Order No.
        JsonObj.SelectToken('orderNum', JsonTkn);
        OrderNo := JsonTkn.AsValue().AsText();

        //Get Batch Number
        JsonObj.SelectToken('batch', JsonTkn);
        BatchNumber := JsonTkn.AsValue().AsText();

        //Get total Qty
        JsonObj.SelectToken('totalQty', JsonTkn);
        TotalQty := JsonTkn.AsValue().AsDecimal();

        JsonObj.SelectToken('pallets', JsonTkn);
        JsonArr := JsonTkn.AsArray();

        pContent := '';
        Searcher := 0;
        while searcher < JsonArr.Count do begin

            //Getting PalletID for each Pallet
            JsonArr.get(searcher, JsonTknAll);
            JsonObj := JsonTknAll.AsObject();

            JsonObj.SelectToken('palletId', JsonTkn2);
            PalletID := JsonTkn2.AsValue().AsText();

            //Creating Pallet Header temp for consuming
            PalletHeaderTemp.init;
            PalletHeaderTemp."Pallet ID" := PalletID;
            PalletHeaderTemp.insert;

            searcher += 1;

            //Getting the Lines
            JsonObj.SelectToken('palletLines', JsonTkn);
            JsonArrLines := JsonTkn.AsArray();
            Searcher_Lines := 0;
            while Searcher_Lines < JsonArrLines.Count do begin

                //Getting Pllaet Line Data
                JsonArrLines.get(Searcher_Lines, JsontokenLines);
                JsonObj := JsontokenLines.AsObject();

                JsonObj.SelectToken('itemId', JsonTokenLinesData);
                PalletItem := JsonTokenLinesData.AsValue().AsText();

                JsonObj.SelectToken('variety', JsonTokenLinesData);
                PalletVariety := JsonTokenLinesData.AsValue().AsText();

                JsonObj.SelectToken('consumingQty', JsonTokenLinesData);
                PalletConsumed := JsonTokenLinesData.AsValue().AsDecimal();

                PalletLine.reset;
                PalletLine.setrange("Pallet ID", PalletID);
                PalletLine.SetRange("Lot Number", BatchNumber);
                PalletLine.setrange("Item No.", PalletItem);
                PalletLine.setrange("Variant Code", PalletVariety);
                if PalletLine.findfirst then begin
                    PalletLineTemp.init;
                    PalletLineTemp.TransferFields(PalletLine);
                    PalletLineTemp."QTY Consumed" := PalletConsumed;
                    palletlinetemp.insert();
                end;
                Searcher_Lines += 1;
            end;
        end;

        PalletLineTemp.reset;
        if PalletLineTemp.findset then
            repeat
                if PalletLine.get(PalletLineTemp."Pallet ID", PalletLineTemp."Line No.") then begin
                    if PalletLineTemp."QTY Consumed" <= PalletLine."Remaining Qty" then begin
                        PalletLine."QTY Consumed" += PalletLineTemp."QTY Consumed";
                        PalletLine."Remaining Qty" -= PalletLineTemp."QTY Consumed";
                        PalletLine.modify;

                        PalletLedgerFunctions.ValueAddConsume(PalletLine, PalletLineTemp."QTY Consumed");

                        PalletLineTemp."Exists on Warehouse Shipment" := true;
                        PalletLineTemp.modify;
                    end
                end;
            until PalletLineTemp.next = 0;

        //if all consumed
        PalletLineTemp.reset;
        PalletLineTemp.setrange("Exists on Warehouse Shipment", false);
        if PalletLineTemp.findfirst then
            PalletsNotConsumed := true;

        //Mark Pallets as consumed/Partially consumed
        if not PalletsNotConsumed then begin

            if purchaseheader.get(purchaseheader."Document Type"::order, OrderNo) then begin
                PurchaseHeader."RM Qty" += TotalQty;
                PurchaseHeader.modify;
            end;

            PalletHeaderTemp.reset;
            if PalletHeaderTemp.findset then
                repeat
                    PalletHeader.get(PalletHeaderTemp."Pallet ID");
                    PalletLine.reset;
                    PalletLine.setrange("Pallet ID", PalletHeaderTemp."Pallet ID");
                    PalletLine.setfilter("Remaining Qty", '<>%1', 0);
                    if PalletLine.findfirst then
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::"Partially consumed"
                    else
                        PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Consumed;

                    PalletHeader.modify;
                    PalletLedgerFunctions.ConsumeRawMaterials(PalletHeader);
                until PalletHeaderTemp.next = 0;
        end;

        //If not consumed
        if PalletsNotConsumed then
            pContent := 'Pallets cannot be consumed'
        else
            pContent := 'Pallets Added Succesfully';
    end;

    //Update Purchase Header -UpdatePurchaseHeader [9344]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure UpdatePurchaseHeader(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        PurchaseNumber: Code[20];
        PurchaseType: Text;
        RM_Bins: Integer;
        HarvestDate_Json: Text;
        HarvestDate_Eval: date;
        PurchaseHeader: Record "Purchase Header";
        ResultText: Text;
        JsonObjResult: JsonObject;

    begin
        IF pFunction <> 'UpdatePurchaseHeader' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        JsonObj.SelectToken('PONumber', JsonTkn);
        PurchaseNumber := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('Type', JsonTkn);
        PurchaseType := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('Bins', JsonTkn);
        RM_Bins := JsonTkn.AsValue().AsInteger();

        JsonObj.SelectToken('HarvestDate', JsonTkn);
        HarvestDate_Json := JsonTkn.AsValue().AsText();
        Evaluate(HarvestDate_Eval, HarvestDate_json);

        if PurchaseHeader.get(PurchaseHeader."Document Type"::Order, PurchaseNumber) then begin
            PurchaseHeader."Number Of Raw Material Bins" := RM_Bins;
            PurchaseHeader."Harvest Date" := HarvestDate_Eval;
            IF PurchaseHeader.MODIFY then
                ResultText := 'Success' else
                ResultText := 'Error : ' + GetLastErrorText;
        end;

        JsonObjResult.add('Result', ResultText);
        JsonObjResult.WriteTo(pContent);
    end;

    var
    procedure GetCurrTime(): date;
    var
        lLocalTime: Time;
        lDateTimeTxt: Text;
        lTimeTxt: Text;
        IntHour: Integer;
        GMTplus: date;

    BEGIN
        EVALUATE(lLocalTime, '17:00:00');
        lDateTimeTxt := FORMAT(CREATEDATETIME(TODAY, time), 0, 9);
        lTimeTxt := COPYSTR(lDateTimeTxt, STRPOS(lDateTimeTxt, 'T') + 1);
        lTimeTxt := COPYSTR(lTimeTxt, 1, STRPOS(lTimeTxt, ':') - 1);
        evaluate(IntHour, lTimeTxt);
        if IntHour > 13 then
            GMTplus := CalcDate('+1D', Today)
        else
            GMTplus := Today;
        exit(GMTplus);
    END;

}