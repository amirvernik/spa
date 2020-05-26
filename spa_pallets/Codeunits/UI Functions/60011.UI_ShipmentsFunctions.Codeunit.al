codeunit 60011 "UI Shipments Functions"
{

    //Get List Of Items - GetListOfItems [8295]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfItems(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        Item: Record item;
        ItemUOM: Record "Item Unit of Measure";
        Obj_JsonText: Text;
        DescText: Text;
        QtyPerPallet: Decimal;

    begin
        IF pFunction <> 'GetListOfItems' THEN
            EXIT;
        Obj_JsonText := '[';
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
                Obj_JsonText += '{' +
                            '"Item No.": ' +
                            '"' + item."No." +
                            '",' +
                            '"Description": "' +
                            DescText +
                            '",' +
                            '"ItemCategory": "' +
                            Item."Item Category Code" +
                            '",' +
                            '"BaseUnitOfMeasure": "' +
                            Item."Base Unit of Measure" +
                            '",' +
                            '"QtyPerPallet": "' +
                           format(QtyPerPallet) +

                            '"},'
            until item.next = 0;
        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
        Obj_JsonText += ']';
        pContent := Obj_JsonText;

    end;

    //Get Item Description - by Item - GetItemName [8497]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetItemName(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemRec: Record Item;
        JsonBuffer: Record "JSON Buffer" temporary;
        ItemNo: code[20];
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
        if ItemRec.GET(ItemNo) then
            pContent := '{"Item Name":"' + ItemRec.Description + '"}'
        else
            pContent := 'Error: Item does not exist';

    end;

    //Get All Customers - GetAllCustomers [8512]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllCustomers(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        CustomerRec: Record Customer;
        Obj_JsonText: Text;
    begin
        IF pFunction <> 'GetAllCustomers' THEN
            EXIT;
        Obj_JsonText := '[';

        CustomerRec.reset;
        if CustomerRec.findset then
            repeat
                Obj_JsonText += '{' +
                            '"Customer No.": ' +
                            '"' + CustomerRec."No." + '"' +
                            ',' +
                            '"Name": "' +
                            CustomerRec.Name +
                            '"},'

            until CustomerRec.next = 0;

        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
        Obj_JsonText += ']';
        pContent := Obj_JsonText;
    end;

    //Get All Vendors - GetAllVendors [8513]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllVendors(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        VendorRec: Record Vendor;
        Obj_JsonText: Text;
    begin
        IF pFunction <> 'GetAllVendors' THEN
            EXIT;
        Obj_JsonText := '[';

        VendorRec.reset;
        if VendorRec.findset then
            repeat
                Obj_JsonText += '{' +
                            '"Vendor No.": ' +
                            '"' + VendorRec."No." + '"' +
                            ',' +
                            '"PostingGroup": ' +
                            '"' + vendorrec."Vendor Posting Group" + '"' +
                            ',' +
                            '"Name": "' +
                            VendorRec.Name +
                            '"},'

            until VendorRec.next = 0;

        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
        Obj_JsonText += ']';
        pContent := Obj_JsonText;
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
        JsonBuffer: Record "JSON Buffer" temporary;
        CustomerNo: code[20];
        LocationCode: code[20];
        FromDate: date;
        toDate: date;
        Salesheader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Obj_JsonText: Text;

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

            Obj_JsonText := '[';
            Salesheader.reset;
            salesheader.SetRange(Salesheader."Document Type", Salesheader."Document Type"::order);
            //salesheader.setrange(Salesheader."Sell-to Customer No.", CustomerNo);
            Salesheader.setfilter("SPA Location", '%1|%2', 'MIX', LocationCode);
            Salesheader.setrange(Salesheader."Order Date", FromDate, ToDate);
            Salesheader.SetRange(Salesheader.Status, Salesheader.Status::Released);

            //if ShipToCode <> '' then
            //    Salesheader.SetRange(Salesheader."Ship-to Code", ShipToCode);

            if Salesheader.findset then begin
                repeat
                    SalesLine.reset;
                    salesline.setrange("Document Type", Salesheader."Document Type");
                    SalesLine.setrange("Document No.", Salesheader."No.");
                    SalesLine.setrange("Location Code", LocationCode);
                    if SalesLine.findset then begin
                        Obj_JsonText += '{"Sales Order No": ' +
                                        '"' + Salesheader."No." + '"' +
                                        ',' +
                                        '"Locaion Code": ' +
                                        '"' + SalesHeader."SPA Location" + '"' +
                                        ',' +
                                        '"Customer": ' +
                                        '"' + SalesHeader."Sell-to Customer No." + '"' +
                                        ',' +
                                        '"Customer Name": ' +
                                        '"' + SalesHeader."Sell-to Customer name" + '"' +
                                        ',' +
                                        '"Ship-to Address": ' +
                                        '"' + SalesHeader."Ship-to Address" + '"' +
                                        ',' +
                                        '"Order Date": "' +
                                        format(salesheader."Order Date") +
                                        '","Item List":[';
                        SalesLine.reset;
                        salesline.setrange("Document Type", Salesheader."Document Type");
                        SalesLine.setrange("Document No.", Salesheader."No.");
                        SalesLine.setrange("Location Code", LocationCode);
                        if salesline.findset then
                            repeat
                                Obj_JsonText += '{"Item No" :"' + SalesLine."No." + '",' +
                                                '"Line No." :"' + format(SalesLine."Line No.") + '",' +
                                                '"Description" :"' + format(SalesLine.Description) + '",' +
                                                '"Location" :"' + format(SalesLine."Location Code") + '",' +
                                                '"Quantity" :"' + format(SalesLine.Quantity) + '",' +
                                                '"Qty. to Ship" :"' + format(SalesLine."Qty. to Ship") + '",' +
                                              '"Qty. to Ship (Base)" :"' + format(SalesLine."Qty. to Ship (Base)") + '"},';
                            until salesline.Next = 0;
                        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                        Obj_JsonText += ']},';
                    end;
                until Salesheader.next = 0;

                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']';
                pContent := Obj_JsonText;
                if pContent = ']' then
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
        Obj_JsonText: Text;

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

            Obj_JsonText := '[';
            if CustomerRec.get(customerno) then begin
                ShipToAddress.reset;
                ShipToAddress.SetRange("Customer No.", CustomerNo);
                if ShipToAddress.findset then
                    repeat
                        Obj_JsonText += '{"Customer No": "' +
                                        ShipToAddress."Customer No." +
                                        '",' +
                                        '"Ship-To Address Code":' +
                                        '"' + ShipToAddress.Code +
                                        '",' +
                                        '"Name": "' +
                                        ShipToAddress.Name +
                                        '",' +
                                        '"Name 2": "' +
                                        ShipToAddress."Name 2" +
                                        '",' +
                                        '"Address": "' +
                                        ShipToAddress.Address +
                                        '",' +
                                        '"Address 2": "' +
                                        ShipToAddress."Address 2" +
                                        '",' +
                                        '"City": "' +
                                        ShipToAddress.City +
                                        '"},';

                    until ShipToAddress.next = 0;

                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']';
                pContent := Obj_JsonText;
            end;
        end;
    end;

    //Get List of Sales Order Lines - GetListOfOpenPurchaseOrders [8754]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfOpenPurchaseOrders(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        purchaseHeader: Record "Purchase Header";
        Obj_JsonText: Text;
        PurchaseType: text;
        OrderType: Text;

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

            Obj_JsonText := '[';
            purchaseHeader.reset;
            purchaseHeader.SetRange(purchaseHeader."Document Type", purchaseHeader."Document Type"::order);
            if PurchaseType = 'grade' then
                purchaseHeader.SetRange("Grading Result PO", true);
            if PurchaseType = 'microwave' then
                purchaseHeader.SetRange("Microwave Process PO", true);

            if purchaseHeader.findset then begin
                repeat
                    purchaseHeader.CalcFields("Completely Received");
                    if (purchaseHeader."Completely Received")
                        and (purchaseHeader."Grading Result PO" or purchaseHeader."Microwave Process PO")
                        and (GetQtyInvoiced(purchaseHeader) = 0) then begin

                        if purchaseHeader."Grading Result PO" then
                            OrderType := 'GradingPO';
                        if purchaseHeader."Microwave Process PO" then
                            OrderType := 'MicrowavePO';

                        Obj_JsonText += '{"Purchase Order No": ' +
                                        '"' + purchaseHeader."No." + '"' +
                                        ',' +
                                        '"Batch Number": ' +
                                        '"' + purchaseHeader."Batch Number" + '"' +
                                        ',' +
                                        '"Type": ' +
                                        '"' + OrderType + '"' +
                                        ',' +
                                        '"Vendor": "' +
                                        format(purchaseHeader."Buy-from Vendor No.") + '"' +
                                        ',' +
                                        '"HarvestDate": ' +
                                        '"' + format(purchaseHeader."Harvest Date") + '"' +
                                        ',' +
                                        '"BinQuantity": ' +
                                        '"' + format(purchaseHeader."Number Of Raw Material Bins") + '"' +
                                        ',' +
                                        '"SupplierPackingSlip": ' +
                                        '"' + purchaseHeader."Vendor Shipment No." + '"' +
                                        ',' +
                                        '"Location Code": ' +
                                        '"' + purchaseheader."Location Code" + '"' +
                                        ',' +
                                        '"RM Location": ' +
                                        '"' + purchaseheader."RM Location" + '"' +
                                        ',' +
                                        '"RawMaterialItem": ' +
                                        '"' + purchaseHeader."Raw Material Item" + '"' +
                                        ',' +
                                        '"RawMaterialBatch": ' +
                                        '"' + purchaseHeader."Item LOT Number" + '"' +
                                        ',' +
                                        '"RawMaterialQuantity": ' +
                                        '"' + format(purchaseHeader."RM Qty") + '"' +
                                        '},';
                    end;
                until purchaseHeader.next = 0;

                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']';
                if Obj_JsonText = ']' then
                    pContent := 'No Orders found' else
                    pContent := Obj_JsonText;
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

}


