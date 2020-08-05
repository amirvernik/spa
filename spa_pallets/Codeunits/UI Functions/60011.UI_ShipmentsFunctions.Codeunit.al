codeunit 60011 "UI Shipments Functions"
{

    //Get List Of Items - GetListOfItems [8295]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfItems(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        DescText: Text;
        QtyPerPallet: Decimal;
        DefaultUOM: code[20];

    begin
        IF pFunction <> 'GetListOfItems' THEN
            EXIT;
        Item.reset;
        if Item.findset then
            repeat
                QtyPerPallet := 0;
                if ItemUOM.get(item."No.", 'PALLET') then
                    QtyPerPallet := ItemUOM."Qty. per Unit of Measure";
                if strpos(item.Description, '"') > 0 then
                    DescText := ConvertStr(item.Description, '"', ' ')
                else
                    DescText := item.Description;
                ItemUOM.reset;
                ItemUOM.setrange("Item No.", Item."No.");
                ItemUOM.setrange("Default Unit Of Measure", true);
                if itemuom.findfirst then
                    DefaultUOM := ItemUOM.Code else
                    DefaultUOM := '';
                JsonObj.add('Item No.', item."No.");
                JsonObj.add('Description', DescText);
                JsonObj.add('ItemCategory', Item."Item Category Code");
                JsonObj.add('BaseUnitOfMeasure', Item."Base Unit of Measure");
                Jsonobj.add('DefaultUnitOfMeasure', DefaultUOM);
                JsonObj.add('QtyPerPallet', format(QtyPerPallet));
                JsonObj.Add('MaxQtyPerPallet', format(Item."Max Qty Per Pallet"));
                JsonArr.Add(JsonObj);
                clear(JsonObj);

            until item.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Get Item Description - by Item - GetItemName [8497]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetItemName(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemRec: Record Item;
        JsonBuffer: Record "JSON Buffer" temporary;
        ItemNo: code[20];
        JsonObj: JsonObject;
    begin
        IF pFunction <> 'GetItemName' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'itemno') > 0 THEN
                        ItemNo := JSONBuffer.Value;
            until JsonBuffer.next = 0;
        if ItemRec.GET(ItemNo) then begin
            JsonObj.add('Item Name', ItemRec.Description);
            JsonObj.WriteTo(pContent);
        end
        else
            pContent := 'Error: Item does not exist';

    end;

    //Get All Customers - GetAllCustomers [8512]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllCustomers(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        CustomerRec: Record Customer;
        JsonObj: JsonObject;
        JsonArr: JsonArray;
    begin
        IF pFunction <> 'GetAllCustomers' THEN
            EXIT;
        CustomerRec.reset;
        if CustomerRec.findset then
            repeat
                JsonObj.add('Customer No.', CustomerRec."No.");
                JsonObj.add('Name', CustomerRec.Name);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until CustomerRec.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Get All Vendors - GetAllVendors [8513]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllVendors(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        VendorRec: Record Vendor;
        JsonObj: JsonObject;
        JsonArr: JsonArray;

    begin
        IF pFunction <> 'GetAllVendors' THEN
            EXIT;
        VendorRec.reset;
        if VendorRec.findset then
            repeat
                JsonObj.add('Vendor No.', VendorRec."No.");
                JsonObj.add('PostingGroup', VendorRec."Vendor Posting Group");
                JsonObj.add('Name', VendorRec.name);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until VendorRec.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Get List of Sales Orders - GetListOfSalesOrders [8515]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfSalesOrders(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemRec: Record Item;
        JsonBuffer: Record "JSON Buffer" temporary;
        CustomerNo: code[20];
        LocationCode: code[20];
        FromDate: date;
        toDate: date;
        Salesheader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Obj_JsonText: Text;

    begin
        IF pFunction <> 'GetListOfSalesOrders' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'customerno') > 0 THEN
                        CustomerNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'location') > 0 THEN
                        LocationCode := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'fromdate') > 0 THEN
                        evaluate(FromDate, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'todate') > 0 THEN
                        evaluate(ToDate, JSONBuffer.Value)
            UNTIL JSONBuffer.NEXT = 0;

            Salesheader.reset;
            salesheader.SetRange(Salesheader."Document Type", Salesheader."Document Type"::order);
            salesheader.setrange(Salesheader."Bill-to Customer No.", CustomerNo);
            Salesheader.setrange(Salesheader."Order Date", FromDate, ToDate);
            //if ShipToCode <> '' then
            //    Salesheader.SetRange(Salesheader."Ship-to Code", ShipToCode);
            if Salesheader.findset then begin
                Obj_JsonText := '[';
                repeat
                    SalesLine.reset;
                    SalesLine.setrange("Document No.", Salesheader."No.");
                    SalesLine.setrange("Document Type", Salesheader."Document Type");
                    SalesLine.setrange("Location Code", LocationCode);
                    if SalesLine.findfirst then begin
                        Obj_JsonText += '{' +
                                    '"Sales Order No": ' +
                                    '"' + Salesheader."No." + '"' +
                                    ',' +
                                    '"Order Date": "' +
                                    format(salesheader."Order Date") +
                                    '"},';
                    end;
                until Salesheader.next = 0;
                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']';
                pContent := Obj_JsonText;
                if pContent = ']' then
                    pContent := 'No Sales Orders Exist';
            end
            else
                pContent := 'No Sales Orders Exist';

        end;
    end;

    //Get List of Sales Order Lines - GetListOfSalesOrderLines [8588]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfSalesOrderLines(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemRec: Record Item;
        VariantRec: Record "Item Variant";
        JsonBuffer: Record "JSON Buffer" temporary;
        CustomerNo: code[20];
        LocationCode: code[20];
        FromDate: date;
        toDate: date;
        Salesheader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        BoolExistsInWhseShip: Boolean;
        JsonObj: JsonObject;
        JsonObjLines: JsonObject;
        JsonArr: JsonArray;
        JsonArrLines: JsonArray;


    begin
        IF pFunction <> 'GetListOfSalesOrderLines' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'customerno') > 0 THEN
                        CustomerNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'location') > 0 THEN
                        LocationCode := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'fromdate') > 0 THEN
                        evaluate(FromDate, JSONBuffer.Value);

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'todate') > 0 THEN
                        evaluate(ToDate, JSONBuffer.Value)
            UNTIL JSONBuffer.NEXT = 0;

            Salesheader.reset;
            salesheader.SetRange(Salesheader."Document Type", Salesheader."Document Type"::order);
            Salesheader.setfilter("SPA Location", '%1|%2', 'MIX', LocationCode);
            Salesheader.setrange(Salesheader."Order Date", FromDate, ToDate);
            Salesheader.SetRange(Salesheader.Status, Salesheader.Status::Released);

            if Salesheader.findset then begin
                repeat
                    SalesLine.reset;
                    salesline.setrange("Document Type", Salesheader."Document Type");
                    SalesLine.setrange("Document No.", Salesheader."No.");
                    SalesLine.setrange("Location Code", LocationCode);
                    if SalesLine.findset then begin
                        WarehouseShipmentLine.reset;
                        WarehouseShipmentLine.setrange("Source Type", 37);
                        WarehouseShipmentLine.setrange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
                        WarehouseShipmentLine.setrange("Source No.", Salesheader."No.");
                        if WarehouseShipmentLine.findfirst then
                            BoolExistsInWhseShip := true
                        else
                            BoolExistsInWhseShip := false;

                        JsonObj.add('Sales Order No', Salesheader."No.");
                        JsonObj.add('Locaion Code', SalesHeader."SPA Location");
                        JsonObj.add('Customer', SalesHeader."Sell-to Customer No.");
                        JsonObj.add('Customer Name', SalesHeader."Sell-to Customer name");
                        JsonObj.add('Ship-to Address', SalesHeader."Ship-to Address");
                        JsonObj.add('Order Date', format(salesheader."Dispatch Date"));
                        JsonObj.add('ExternalDocNum', Salesheader."External Document No.");
                        JsonObj.add('ReqDeliveryDate', Salesheader."Requested Delivery Date");
                        JsonObj.add('ExistInWhseShip', BoolExistsInWhseShip);
                        SalesLine.reset;
                        salesline.setrange("Document Type", Salesheader."Document Type");
                        SalesLine.setrange("Document No.", Salesheader."No.");
                        SalesLine.setrange("Location Code", LocationCode);
                        if salesline.findset then
                            repeat
                                Clear(JsonObjLines);
                                JsonObjLines.add('Line No.', format(SalesLine."Line No."));
                                JsonObjLines.add('Item No', SalesLine."No.");
                                if VariantRec.get(SalesLine."No.", SalesLine."Variant Code") then
                                    JsonObjLines.add('Variety', VariantRec.Description)
                                else
                                    JsonObjLines.add('Variety', '');
                                JsonObjLines.add('Description', salesline.Description);
                                JsonObjLines.add('Location', salesline."Location Code");
                                JsonObjLines.add('Quantity', format(salesline.Quantity));
                                JsonObjLines.add('Qty. to Ship', format(SalesLine."Qty. to Ship"));
                                JsonObjLines.add('Qty. to Ship (Base)', format(SalesLine."Qty. to Ship (base)"));
                                JsonArrLines.Add(JsonObjLines);
                            until SalesLine.next = 0;
                        if JsonArrLines.Count > 0 then
                            JsonObj.add('Item List', JsonArrLines);
                        clear(JsonArrLines);
                        JsonArr.Add(JsonObj);
                        clear(JsonObj);
                    end;
                until Salesheader.next = 0;

                if JsonArr.Count > 0 then
                    JsonArr.WriteTo(pContent)
                else
                    pContent := 'No Lines found';
            end;

        end;
    end;

    //Get Customer Ship-to Addresses - GetCustomerShipToAddresses [8589]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetCustomerShipToAddresses(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ShipToAddress: Record "Ship-to Address";
        CustomerRec: Record Customer;
        JsonBuffer: Record "JSON Buffer" temporary;
        CustomerNo: code[20];
        JsonObj: JsonObject;
        JsonArr: JsonArray;

    begin
        IF pFunction <> 'GetCustomerShipToAddresses' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'customerno') > 0 THEN
                        CustomerNo := JSONBuffer.Value;

            UNTIL JSONBuffer.NEXT = 0;

            if CustomerRec.get(customerno) then begin
                ShipToAddress.reset;
                ShipToAddress.SetRange("Customer No.", CustomerNo);
                if ShipToAddress.findset then
                    repeat
                        JsonObj.add('Customer No', ShipToAddress."Customer No.");
                        JsonObj.add('Ship-To Address Code', ShipToAddress.Code);
                        JsonObj.add('Name', ShipToAddress.Name);
                        JsonObj.add('Name 2', ShipToAddress."Name 2");
                        JsonObj.add('Address', ShipToAddress.Address);
                        JsonObj.add('Address 2', ShipToAddress."Address 2");
                        JsonObj.add('City', ShipToAddress.City);
                        JsonArr.Add(JsonObj);
                        clear(JsonObj);
                    until ShipToAddress.next = 0;
                if JsonArr.count > 0 then
                    JsonArr.WriteTo(pContent)
                else
                    pContent := 'No Customer Ship to Addresses';
            end;
        end;
    end;

    //Get List of Sales Order Lines - GetListOfOpenPurchaseOrders [8754]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfOpenPurchaseOrders(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        purchaseHeader: Record "Purchase Header";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        PurchaseType: text;
        OrderType: Text;
        ItemVariant: Record "item variant";
    begin
        IF pFunction <> 'GetListOfOpenPurchaseOrders' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'type') > 0 THEN
                        PurchaseType := JSONBuffer.Value;
            UNTIL JSONBuffer.NEXT = 0;

            purchaseHeader.reset;
            purchaseHeader.SetRange(purchaseHeader."Document Type", purchaseHeader."Document Type"::order);
            if PurchaseType = 'grade' then
                purchaseHeader.SetRange("Grading Result PO", true);
            if PurchaseType = 'microwave' then
                purchaseHeader.SetRange("Microwave Process PO", true);

            if purchaseHeader.findset then begin
                repeat
                    //Removed by oren's request - 26/07/2020
                    //purchaseHeader.CalcFields("Completely Received");
                    //if (NOT purchaseHeader."Completely Received") and
                    if
                        ((purchaseHeader.Status = purchaseHeader.status::Open) or
                        (purchaseHeader.Status = purchaseHeader.status::released)) and
                        (purchaseHeader."Grading Result PO" or purchaseHeader."Microwave Process PO") then begin
                        //and (GetQtyInvoiced(purchaseHeader) = 0) then begin

                        if purchaseHeader."Grading Result PO" then
                            OrderType := 'GradingPO';
                        if purchaseHeader."Microwave Process PO" then
                            OrderType := 'MicrowavePO';
                        JsonObj.add('Purchase Order No', purchaseHeader."No.");
                        JsonObj.add('Batch Number', purchaseHeader."Batch Number");
                        JsonObj.add('VarietyCode', purchaseHeader."Variety Code");
                        ItemVariant.reset;
                        ItemVariant.setrange(code, purchaseHeader."Variety Code");
                        if ItemVariant.findfirst then
                            JsonObj.add('VarietyDescription', ItemVariant.Description);
                        JsonObj.add('Type', OrderType);
                        JsonObj.add('Vendor', format(purchaseHeader."Buy-from Vendor No."));
                        JsonObj.add('HarvestDate', format(purchaseHeader."Harvest Date"));
                        JsonObj.add('BinQuantity', format(purchaseHeader."Number Of Raw Material Bins"));
                        JsonObj.add('SupplierPackingSlip', purchaseheader."Vendor Shipment No.");
                        JsonObj.add('Location Code', purchaseHeader."Location Code");
                        JsonObj.add('RM Location', purchaseHeader."RM Location");
                        JsonObj.add('RawMaterialItem', purchaseHeader."Raw Material Item");
                        JsonObj.add('RawMaterialBatch', purchaseHeader."Item LOT Number");
                        JsonObj.add('RawMaterialQuantity', purchaseHeader."RM Qty");
                        JsonArr.Add(JsonObj);
                        clear(JsonObj);
                    end;
                until purchaseHeader.next = 0;
                if JsonArr.Count = 0 then
                    pContent := 'No Orders found' else
                    JsonArr.WriteTo(pContent);
            end;

        end;
    end;

    procedure GetQtyInvoiced(var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        TotalQtyInvoiced: Decimal;
    begin
        TotalQtyInvoiced := 0;
        PurchaseLine.reset;
        PurchaseLine.setrange(PurchaseLine."Document Type", PurchaseLine."Document Type");
        PurchaseLine.setrange(PurchaseLine."Document No.", PurchaseLine."No.");
        if PurchaseLine.findset then
            repeat
                TotalQtyInvoiced += PurchaseLine."Quantity Invoiced";
            until PurchaseLine.next = 0;
        exit(TotalQtyInvoiced);
    end;


    //CreateItemsByPurchasePrice [9276]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreateItemsByPurchasePrice(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemRec: Record Item;
        JsonBuffer: Record "JSON Buffer" temporary;
        PurchasePriceRec: Record "Purchase Price";
        VendorNo: code[20];
        VariantCode: Code[10];
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        boolExist: Boolean;
    begin
        IF pFunction <> 'CreateItemsByPurchasePrice' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);
        boolExist := false;

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN begin
                    IF STRPOS(JSONBuffer.Path, 'vendorno') > 0 THEN
                        VendorNo := JSONBuffer.Value;
                    IF STRPOS(JSONBuffer.Path, 'variantcode') > 0 THEN
                        VariantCode := JSONBuffer.Value;
                end;
            until JsonBuffer.next = 0;

        Clear(JsonArr);
        pContent := '';

        PurchasePriceRec.Reset();
        PurchasePriceRec.SetRange("Vendor No.", VendorNo);
        PurchasePriceRec.SetRange("Variant Code", VariantCode);
        if PurchasePriceRec.FindSet() then begin

            repeat
                if (PurchasePriceRec."Starting Date" <> 0D) and (PurchasePriceRec."Ending Date" <> 0D)
                    and ((PurchasePriceRec."Starting Date" <= Today()) and (PurchasePriceRec."Ending Date" >= Today)) then
                    if CheckItemPurchaseUnitofMeasure(PurchasePriceRec."Item No.", PurchasePriceRec."Unit of Measure Code") then begin
                        boolExist := true;
                        JsonArr.Add(PurchasePriceRec."Item No.");
                    end;

                if (PurchasePriceRec."Starting Date" <> 0D) and (PurchasePriceRec."Ending Date" = 0D)
                    and (PurchasePriceRec."Starting Date" <= Today()) then
                    if CheckItemPurchaseUnitofMeasure(PurchasePriceRec."Item No.", PurchasePriceRec."Unit of Measure Code") then begin
                        boolExist := true;
                        JsonArr.Add(PurchasePriceRec."Item No.");
                    end;

                if (PurchasePriceRec."Starting Date" = 0D) and (PurchasePriceRec."Ending Date" <> 0D)
                    and (PurchasePriceRec."Ending Date" >= Today()) then
                    if CheckItemPurchaseUnitofMeasure(PurchasePriceRec."Item No.", PurchasePriceRec."Unit of Measure Code") then begin
                        boolExist := true;
                        JsonArr.Add(PurchasePriceRec."Item No.");
                    end;

                if (PurchasePriceRec."Starting Date" = 0D) and (PurchasePriceRec."Ending Date" = 0D) then
                    if CheckItemPurchaseUnitofMeasure(PurchasePriceRec."Item No.", PurchasePriceRec."Unit of Measure Code") then begin
                        boolExist := true;
                        JsonArr.Add(PurchasePriceRec."Item No.");
                    end;

            until PurchasePriceRec.Next() = 0;
            if boolExist then begin
                Clear(JsonObj);
                JsonObj.add('Items', JsonArr);
                JsonObj.WriteTo(pContent);
            end else
                pContent := 'Purchase Price does not found';
        end else
            pContent := 'Purchase Price does not exist';

    end;

    local procedure CheckItemPurchaseUnitofMeasure(ItemNo: code[20]; PurchasePriceUnitofMeasure: code[20]): Boolean;
    var
        ItemRec: Record Item;
    begin
        if ItemRec.Get(ItemNo) then begin
            if ItemRec."Purch. Unit of Measure" = PurchasePriceUnitofMeasure then
                exit(true);
        end;
        exit(false);
    end;

}


