codeunit 60020 "UI Sales Return Orders"
{
    //Get Sales Shipments By Customer - GetSalesShipmentsByCustomer [8807]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetSalesShipmentsByCustomer(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonBuffer: Record "JSON Buffer" temporary;
        SalesShipmentHeader: Record "Sales Shipment Header";
        CustomerNo: code[20];
        Json_Text: Text;
        PalletLedgerEntry: Record "Pallet Ledger Entry";

    begin
        IF pFunction <> 'GetSalesShipmentsByCustomer' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        //Getting Customer from Json
        JSONBuffer.RESET;
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);

        if JsonBuffer.findfirst then
            CustomerNo := JsonBuffer.value;

        SalesShipmentHeader.reset;
        SalesShipmentHeader.setrange(SalesShipmentHeader."Sell-to Customer No.", CustomerNo);
        if SalesShipmentHeader.FindSet then begin
            Json_Text := '[{"customerno":"' + CustomerNo + '","shipments":[';
            repeat
                PalletLedgerEntry.reset;
                PalletLedgerEntry.setrange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Sales Shipment");
                PalletLedgerEntry.setrange(PalletLedgerEntry."Document No.", SalesShipmentHeader."No.");
                if PalletLedgerEntry.findfirst then
                    Json_Text += '{"shipmentno":"' + SalesShipmentHeader."No." + '"},';
            until SalesShipmentHeader.next = 0;
            Json_Text := copystr(Json_Text, 1, strlen(Json_Text) - 1);
            Json_Text += ']}]';
            pContent := Json_Text;
        end
        else
            pContent := 'No shipments for Customer or customer does not exist';
    end;

    //Post Return Order - PostReturnOrder [8808]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure PostReturnOrder(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonBuffer: Record "JSON Buffer" temporary;
        ReturnOrderNo: code[20];
        SalesPost: Codeunit "Sales-Post";
        SalesHeaderTemp: Record "Sales Header" temporary;
        SalesHeader: Record "Sales Header";

    begin
        IF pFunction <> 'PostReturnOrder' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        //Getting Customer from Json
        JSONBuffer.RESET;
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);

        if JsonBuffer.findfirst then
            ReturnOrderNo := JsonBuffer.value;

        if SalesHeader.get(SalesHeader."Document Type"::"Return Order", ReturnOrderNo) then begin
            SalesHeaderTemp.init;
            SalesHeaderTemp.Copy(SalesHeader);
            SalesHeaderTemp.Receive := true;
            SalesHeaderTemp.Invoice := false;
            SalesHeaderTemp.insert;
            SalesPost.run(SalesHeaderTemp);
            pContent := 'Return Order No. ' + ReturnOrderNo + ' Posted';
        end
        else
            pContent := 'error, Return Order does not exist';

    end;

    //Create Sales Return Order - CreateSalesReturnOrder [8806]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreateSalesReturnOrder(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        PalletProccessSetup: Record "Pallet Process Setup";
        JsonBuffer: Record "JSON Buffer" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ToSalesHeader: Record "Sales Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        SalesShipmentHeaderTemp: Record "Sales Shipment Header" temporary;
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        NextSalesreturnOrder: code[20];
        NoSeriesMgmt: Codeunit NoSeriesManagement;
        CustomerNo: code[20];
        Json_Text: text;
        PalletLedgerEntry: Record "Pallet Ledger Entry";

    begin
        IF pFunction <> 'CreateSalesReturnOrder' THEN
            EXIT;

        SalesAndReceivablesSetup.Get();
        PalletProccessSetup.get();

        if SalesShipmentHeaderTemp.findset then
            SalesShipmentHeaderTemp.deleteall;

        MissingExCostRevLink := false;
        LinesNotCopied := 0;
        JsonBuffer.ReadFromText(pContent);

        //Getting Customer from Json
        JSONBuffer.RESET;
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        JsonBuffer.setrange(Depth, 2);
        if JsonBuffer.findfirst then
            CustomerNo := JsonBuffer.value;

        //Getting Shipments
        JSONBuffer.RESET;
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        JsonBuffer.setrange(Depth, 4);
        if JsonBuffer.findset then
            repeat
                if not SalesShipmentHeaderTemp.get(JsonBuffer.Value) then begin
                    SalesShipmentHeaderTemp.init;
                    SalesShipmentHeaderTemp."No." := JsonBuffer.value;
                    SalesShipmentHeaderTemp.insert;
                end;
            until JsonBuffer.next = 0;

        NextSalesreturnOrder := NoSeriesMgmt.GetNextNo(SalesAndReceivablesSetup."Return Order Nos.", today, true);
        ToSalesHeader.init;
        ToSalesHeader."No." := NextSalesreturnOrder;
        ToSalesHeader."Document Type" := ToSalesHeader."Document Type"::"Return Order";
        ToSalesHeader."No. Series" := SalesAndReceivablesSetup."Return Order Nos.";
        ToSalesHeader.insert(true);
        ToSalesHeader.validate("Sell-to Customer No.", CustomerNo);
        ToSalesHeader.modify;

        if ToSalesHeader.get(ToSalesHeader."Document Type"::"Return Order", NextSalesreturnOrder) then begin
            SalesShipmentHeaderTemp.reset;
            if SalesShipmentHeaderTemp.findset then
                repeat
                    SalesShipmentLine.reset;
                    SalesShipmentLine.setrange("Document No.", SalesShipmentHeaderTemp."No.");
                    if SalesShipmentLine.findset then
                        repeat
                            CopyDocMgt.CopySalesShptLinesToDoc(ToSalesHeader, SalesShipmentLine, LinesNotCopied, MissingExCostRevLink);
                        until SalesShipmentLine.next = 0;
                until SalesShipmentHeaderTemp.next = 0;
            SalesLine.reset;
            SalesLine.setrange(SalesLine."Document Type", SalesLine."Document Type"::"Return Order");
            SalesLine.setrange(SalesLine."Document No.", NextSalesreturnOrder);
            if SalesLine.findset then
                repeat
                    if SalesLine.Quantity > 0 then begin
                        SalesLine.validate("Return Qty. to Receive", salesLine.Quantity);
                        SalesLine."Return Reason Code" := PalletProccessSetup."Cancel Reason Code";
                        SalesLine.modify;
                    end;
                until SalesLine.next = 0;
        end;

        //Create Return Json  

        //[{"returnorderno":"1030"},{"lines":[{"123":"456","567":"890"},{"123":"456","567":"890"}]}]
        if NextSalesreturnOrder <> '' then begin
            Json_Text := '[{"returnorderno":"' + NextSalesreturnOrder + '"}';
            SalesLine.reset;
            SalesLine.setrange(SalesLine."Document Type", SalesLine."Document Type"::"Return Order");
            SalesLine.setrange(SalesLine."Document No.", NextSalesreturnOrder);
            SalesLine.setfilter(SalesLine."SPA Order No.", '<>%1', '');
            if SalesLine.findset then begin
                Json_Text += ',{"lines":[';
                repeat
                    Json_Text += '{"SalesOrderNo":"' + SalesLine."SPA Order No." + '",' +
                                '"SalesOrderLineNo":"' + format(SalesLine."SPA Order Line No.") + '",' +
                                '"ItemNo":"' + SalesLine."No." + '",' +
                                '"Variety":"' + SalesLine."Variant Code" + '",' +
                                '"ItemName":"' + SalesLine.Description + '",';

                    PalletLedgerEntry.reset;
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Sales Shipment");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Order No.", SalesLine."SPA Order No.");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Order Line No.", SalesLine."SPA Order Line No.");
                    PalletLedgerEntry.setrange(PalletLedgerEntry."Order Type", 'Sales Order');
                    if PalletLedgerEntry.findset then begin
                        Json_Text += '"pallets":[';
                        repeat
                            Json_Text += '{"PalletNo":"' + PalletLedgerEntry."Pallet ID" + '",' +
                                        '"PalletLine":"' + format(PalletLedgerEntry."Pallet Line No.") + '",' +
                                        '"LotNo":"' + PalletLedgerEntry."Lot Number" + '",' +
                                        '"Location":"' + PalletLedgerEntry."Location Code" + '",' +
                                '"Quantity":"' + format(PalletLedgerEntry.Quantity) + '"},';

                        until PalletLedgerEntry.next = 0;
                        Json_Text := copystr(Json_Text, 1, strlen(Json_Text) - 1);
                        Json_Text += ']},';
                    end;
                until SalesLine.next = 0;

                Json_Text := copystr(Json_Text, 1, strlen(Json_Text) - 1);
                Json_Text += ']}]';
                pContent := Json_Text;
            end;
        end;
    end;
}