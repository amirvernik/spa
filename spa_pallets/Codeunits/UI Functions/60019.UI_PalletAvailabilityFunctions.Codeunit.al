codeunit 60019 "UI Pallet Availability"
{

    //Post Warehouse Shipment - PostWarehouseShipment [8798]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure PostWarehouseShipment(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonBuffer: Record "JSON Buffer" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WareHpouseShipmentLine: Record "Warehouse Shipment Line";
        ShipmentNumnber: code[20];
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        LastError: Text;

    begin
        IF pFunction <> 'PostWarehouseShipment' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        //JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);

        if JsonBuffer.findfirst then
            ShipmentNumnber := JsonBuffer.value;

        LastError := '';
        if WarehouseShipmentHeader.get(ShipmentNumnber) then begin
            WareHpouseShipmentLine.reset;
            WareHpouseShipmentLine.setrange(WareHpouseShipmentLine."No.", ShipmentNumnber);
            if WareHpouseShipmentLine.findset then begin
                repeat
                    if not WhsePostShipment.run(WareHpouseShipmentLine) then
                        LastError := GetLastErrorText;
                until WareHpouseShipmentLine.next = 0;
                if LastError <> '' then
                    pContent := LastError else
                    pContent := 'Success';
            end;
        end
        else
            pContent := ' Error, Shipment does not exist';
    end;

    //Check Pallet Availability
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CheckPalletAvailability(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        PalletHeaderTemp: Record "Pallet Header" temporary;
        JsonBuffer: Record "JSON Buffer" temporary;
        ShipmentNumnber: code[20];
        PalletListSelect: Record "Pallet List Select" temporary;
        PalletAvailabilityFunctions: Codeunit "Pallet Availability Functions";
        PalletAvailError: Record "Pallet Avail Error" temporary;

    begin
        IF pFunction <> 'CheckPalletAvailability' THEN
            EXIT;

        if PalletHeaderTemp.findset then
            PalletHeaderTemp.deleteall;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        if JsonBuffer.findfirst then
            ShipmentNumnber := JsonBuffer.value;

        pcontent := ShipmentNumnber;

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 4);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        if JsonBuffer.findset then
            repeat
                if not PalletHeaderTemp.get(JsonBuffer.value) then begin
                    PalletHeaderTemp.init;
                    PalletHeaderTemp."Pallet ID" := JsonBuffer.value;
                    PalletHeaderTemp.insert;
                    pContent += JsonBuffer.value;
                end;
            until JsonBuffer.next = 0;

        PalletHeaderTemp.reset;
        if PalletHeaderTemp.findset then
            repeat
                PalletListSelect.init;
                PalletListSelect."Pallet ID" := PalletHeaderTemp."Pallet ID";
                PalletListSelect.Select := true;
                PalletListSelect."Source Document" := ShipmentNumnber;
                PalletListSelect.insert;
            until PalletHeaderTemp.next = 0;

        PalletListSelect.reset;
        if PalletListSelect.findset then
            pContent := PalletAvailabilityFunctions.FctCheckSelectedPallets(PalletListSelect, 'UI');
        if pContent = '' then
            pContent := 'Success';
    end;

    //Check Pallet Availability - CheckPalletAvailability [8795]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListForMWPallets(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        PalletHeaderTemp: Record "Pallet Header" temporary;
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        JsonBuffer: Record "JSON Buffer" temporary;
        ItemNumber: code[20];
        BatchNumber: code[20];
        VariantCode: code[20];
    begin
        IF pFunction <> 'GetListForMWPallets' THEN
            EXIT;

        if PalletHeaderTemp.findset then
            PalletHeaderTemp.deleteall;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        JsonBuffer.setrange(JsonBuffer.path, 'item');
        if JsonBuffer.findfirst then
            ItemNumber := JsonBuffer.value;

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        JsonBuffer.setrange(JsonBuffer.path, 'varietycode');
        if JsonBuffer.findfirst then
            VariantCode := JsonBuffer.value;

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        JsonBuffer.setrange(JsonBuffer.path, 'batch');
        if JsonBuffer.findfirst then
            BatchNumber := JsonBuffer.value;

        PalletLine.reset;
        PalletLine.setrange("Item No.", ItemNumber);
        PalletLine.SetRange("Variant Code", VariantCode);
        PalletLine.setrange("Lot Number", BatchNumber);
        if PalletLine.findset then begin
            repeat
                if PalletHeader.get(PalletLine."Pallet ID") then
                    if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::closed then
                        if PalletHeader."Raw Material Pallet" = true then begin
                            JsonObj.add('palletId', PalletLine."Pallet ID");
                            JsonObj.add('qty', format(PalletLine.Quantity));
                            JsonArr.Add(JsonObj);
                            clear(JsonObj);
                        end;
            until PalletLine.next = 0;
        end;
        if JsonArr.Count > 0 then
            JsonArr.WriteTo(pContent)
        else
            pContent := 'error,could not find pallets';
    end;
}

