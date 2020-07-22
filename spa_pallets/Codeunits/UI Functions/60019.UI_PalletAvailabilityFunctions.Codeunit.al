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
        PalletLineTemp: Record "Pallet Line" temporary;
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        ItemNumber: code[20];
        BatchNumber: code[20];
        VariantCode: code[10];
        JsonObjRead: JsonObject;
        JsonTokenRead: JsonToken;
        JsonObjectAll: JsonObject;
        JsonArrayPallets: JsonArray;
        JsonArrayLines: JsonArray;
        JsonObjPallet: JsonObject;
        JsonObjLines: JsonObject;
        jarr: JsonArray;
        jobj: JsonObject;

    begin
        IF pFunction <> 'GetListForMWPallets' THEN
            EXIT;

        JsonObjRead.ReadFrom(pContent);

        //Get Item Number
        JsonObjRead.SelectToken('item', JsonTokenRead);
        ItemNumber := JsonTokenRead.AsValue().AsText();

        //Get Batch Number
        JsonObjRead.SelectToken('batch', JsonTokenRead);
        BatchNumber := JsonTokenRead.AsValue().AsText();

        //Get Variety Code
        JsonObjRead.SelectToken('varietycode', JsonTokenRead);
        VariantCode := JsonTokenRead.AsValue().AsText();

        pContent := '';

        PalletLine.reset;
        PalletLine.setrange("Item No.", ItemNumber);
        PalletLine.SetRange("Variant Code", VariantCode);
        PalletLine.setrange("Lot Number", BatchNumber);
        if PalletLine.findset then begin
            repeat
                if not PalletHeaderTemp.get(PalletLine."Pallet ID") then begin
                    PalletHeaderTemp.init;
                    PalletHeaderTemp."Pallet ID" := PalletLine."Pallet ID";
                    PalletHeaderTemp.insert;
                    PalletLineTemp.init;
                    PalletLineTemp.TransferFields(PalletLine);
                    PalletLineTemp.insert;
                end;
            until PalletLine.next = 0;
        end;

        clear(JsonObjectAll);

        PalletHeaderTemp.reset;
        if PalletHeaderTemp.findset then
            repeat
                JsonObjPallet.add('palletid', PalletHeaderTemp."Pallet ID");

                PalletLineTemp.reset;
                PalletLineTemp.setrange("Pallet ID", PalletHeaderTemp."Pallet ID");
                if PalletLineTemp.findset then
                    repeat
                        clear(JsonObjLines);
                        JsonObjLines.add('palletid', PalletLineTemp."Pallet ID");
                        JsonObjLines.Add('itemId', PalletLineTemp."Item No.");
                        JsonObjLines.add('variety', PalletLineTemp."Variant Code");
                        JsonObjLines.add('remainingQty', PalletLineTemp."Remaining Qty");
                        jarr.Add(JsonObjLines);
                        JsonObjPallet.add('palletLines', jarr);

                        Clear(jarr);
                    until palletlinetemp.next = 0;

                JsonArrayPallets.add(JsonObjPallet);
                // JsonArrayPallets.Add(jobj);
                clear(JsonObjPallet);

                clear(jobj);
            until PalletHeaderTemp.next = 0;

        if JsonArrayPallets.Count > 0 then
            JsonArrayPallets.WriteTo(pContent)
        else
            pContent := 'error,could not find pallets';
    end;
}

