codeunit 60016 "UI Whse Shipments Functions"
{
    //Get List of Sales Order Lines
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfWhseShipmentLines(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Obj_JsonText: Text;

    begin
        IF pFunction <> 'GetListOfWhseShipmentLines' THEN
            EXIT;
        Obj_JsonText := '[';
        WarehouseShipmentHeader.reset;
        if WarehouseShipmentHeader.findset then begin
            repeat
                WarehouseShipmentLine.reset;
                WarehouseShipmentLine.setrange(WarehouseShipmentLine."No.", WarehouseShipmentHeader."No.");
                if WarehouseShipmentline.findset then begin
                    Obj_JsonText += '{"Shipment No.": ' +
                                    '"' + WarehouseShipmentHeader."No." + '"' +
                                    ',' +
                                    '"Shipment Date": ' +
                                    '"' + format(WarehouseShipmentHeader."Shipment Date") + '"' +
                                    ',' +
                                    '"Location Code": "' +
                                    format(WarehouseShipmentHeader."Location Code") +
                                    '","Item List":[';
                    repeat
                        Obj_JsonText += '{"Item No" :"' + WarehouseShipmentLine."Item No." + '",' +
                                        '"Line Number" :"' + format(WarehouseShipmentLine."Line No.") + '",' +
                                        '"Description" :"' + WarehouseShipmentLine.Description + '",' +
                                        '"Quantity" :"' + format(WarehouseShipmentLine.Quantity) + '",' +
                                        '"Qty. to Ship" :"' + format(WarehouseShipmentLine."Qty. to Ship") + '",' +
                                        '"Remaining Qty" :"' + format(WarehouseShipmentLine."Remaining Quantity") + '",' +
                                      '"Qty. Shipped" :"' + format(WarehouseShipmentLine."Qty. Shipped") + '"},';

                    until WarehouseShipmentLine.next = 0;

                end;
                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']},';

            until WarehouseShipmentHeader.next = 0;
        end;

        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 2);
        Obj_JsonText += '}]';
        pContent := Obj_JsonText;
    end;


    //Create Warehouse Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreateWhseShipment(VAR pFunction: Text[50]; VAR
                                                                    pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        SalesOrdersTempHeaders: Record "Sales Line" temporary;
        SalesOrdersTempLines: Record "Sales Line" temporary;
        lSalesHeader: Record "Sales Header";
        SalesLineCheck: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentLineCheck: Record "Warehouse Shipment Line";
        SalesHeaderCheck: Record "sales header";
        ShipLine: Integer;
        ShipmentNo: code[20];
        WarehouseSetup: Record "Warehouse Setup";
        NoSeriesMgmt: Codeunit NoSeriesManagement;
        LastLine: Integer;
        ManipulateText: text;
        Pos: integer;
        ResultText: Text;
        SalesOrdersCountText: Text;
        SalesOrdersCount: Integer;
        iCount: Integer;
        SalesOrderNumber: code[20];
        LocationCode: code[20];
        SalesOrderLocation: code[20];
        Json_Text: text;
        LineNumber: Integer;
        ItemNumber: code[20];
        LineOrderText: Text;
        LineOrder: Integer;
        ItemRec: Record Item;

    begin
        IF pFunction <> 'CreateWhseShipment' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        if JsonBuffer.findlast then begin
            ManipulateText := copystr(jsonbuffer.path, 2, strlen(jsonbuffer.path) - 1);
            pos := strpos(ManipulateText, ']');
            SalesOrdersCountText := copystr(ManipulateText, 1, pos - 1);
            evaluate(SalesOrdersCount, SalesOrdersCountText);

            Json_Text := '';

            //Creating Temp table with sales order numbers
            icount := 0;
            while iCount <= SalesOrdersCount do begin
                JsonBuffer.reset;
                JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
                JsonBuffer.setrange(JsonBuffer.depth, 2);
                if jsonbuffer.findset then
                    repeat
                        if JsonBuffer.path = '[' + format(icount) + '].salesorder' then
                            SalesOrderNumber := JsonBuffer.value;
                        if JsonBuffer.path = '[' + format(icount) + '].location' then
                            LocationCode := JsonBuffer.value;
                    until jsonbuffer.next = 0;

                if not SalesOrdersTempHeaders.get(SalesOrdersTempHeaders."Document Type"::Order,
                    SalesOrderNumber, icount + 1) then begin
                    SalesOrdersTempHeaders.init;
                    SalesOrdersTempHeaders."Document Type" := SalesOrdersTempHeaders."Document Type"::Order;
                    SalesOrdersTempHeaders."Document No." := SalesOrderNumber;
                    SalesOrdersTempHeaders."Location Code" := LocationCode;
                    SalesOrdersTempHeaders."Line No." := icount + 1;
                    SalesOrdersTempHeaders.insert;
                    icount += 1;
                end;
            end;

            //Createing temp table for lines
            icount := 0;
            JsonBuffer.reset;
            JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
            JsonBuffer.setrange(JsonBuffer.depth, 4);
            if jsonbuffer.findset then
                repeat
                    if strpos(jsonbuffer.path, '.line') > 0 then begin
                        ManipulateText := copystr(jsonbuffer.path, 2, strlen(jsonbuffer.path) - 1);
                        pos := strpos(ManipulateText, ']');
                        LineOrderText := copystr(ManipulateText, 1, pos - 1);
                        evaluate(LineOrder, LineOrderText);

                        SalesOrdersTempHeaders.reset;
                        SalesOrdersTempHeaders.setfilter("Line No.", format(LineOrder + 1));
                        if SalesOrdersTempHeaders.findfirst then begin
                            SalesOrdersTempLines.init;
                            SalesOrdersTempLines."Document Type" := SalesOrdersTempLines."Document Type"::order;
                            SalesOrdersTempLines."Document No." := SalesOrdersTempHeaders."Document No.";
                            evaluate(SalesOrdersTempLines."Line No.", JsonBuffer.value);
                            SalesOrdersTempLines.insert;
                        end;
                    end;
                until JsonBuffer.next = 0;
        end;

        //Create warehouse Shipment Header
        WarehouseSetup.get;
        ShipmentNo := NoSeriesMgmt.GetNextNo(WarehouseSetup."Whse. Ship Nos.", today, true);
        WarehouseShipmentHeader.init;
        WarehouseShipmentHeader."No." := ShipmentNo;
        WarehouseShipmentHeader."No. Series" := WarehouseSetup."Whse. Ship Nos.";
        WarehouseShipmentHeader.Status := WarehouseShipmentHeader.Status::Open;
        WarehouseShipmentHeader."Location Code" := LocationCode;
        WarehouseShipmentHeader."Posting Date" := today;
        WarehouseShipmentHeader."Shipment Date" := today;
        WarehouseShipmentHeader."Shipping No. Series" := WarehouseSetup."Posted Whse. Shipment Nos.";
        WarehouseShipmentHeader.insert;

        //Creating warehouse shipment lines
        SalesOrdersTempLines.reset;
        if SalesOrdersTempLines.findset then
            repeat
                WarehouseShipmentLineCheck.reset;
                WarehouseShipmentLineCheck.setrange("No.", WarehouseShipmentHeader."No.");
                if WarehouseShipmentLineCheck.findlast then
                    ShipLine := WarehouseShipmentLineCheck."Line No." + 10000
                else
                    ShipLine := 10000;

                SalesLineCheck.get(SalesOrdersTempLines."Document Type"::order, SalesOrdersTempLines."Document No.",
                    SalesOrdersTempLines."Line No.");

                SalesHeaderCheck.get(SalesOrdersTempLines."Document Type"::Order, SalesOrdersTempLines."Document No.");
                WarehouseShipmentLine.init;
                WarehouseShipmentLine."No." := ShipmentNo;
                WarehouseShipmentLine."Line No." := ShipLine;
                WarehouseShipmentLine."source Line No." := SalesOrdersTempLines."Line No.";
                WarehouseShipmentLine."Source Type" := 37;
                WarehouseShipmentLine."Source Subtype" := 1;
                WarehouseShipmentLine."Source Document" := WarehouseShipmentLine."Source Document"::"Sales Order";
                WarehouseShipmentLine."Source No." := SalesLineCheck."Document No.";
                WarehouseShipmentLine.insert;

                SalesLineCheck.reset;
                SalesLineCheck.setrange(SalesLineCheck."Document Type", SalesLineCheck."Document Type"::Order);
                SalesLineCheck.setrange(SalesLineCheck."Document No.", SalesOrdersTempLines."Document No.");
                SalesLineCheck.setrange(SalesLineCheck."Line No.", SalesOrdersTempLines."Line No.");
                if SalesLineCheck.findfirst then begin
                    WarehouseShipmentLine.validate("Item No.", SalesLineCheck."No.");
                    WarehouseShipmentLine.Description := SalesLineCheck.Description;
                    WarehouseShipmentLine.Quantity := SalesLineCheck.Quantity;
                    WarehouseShipmentLine."Qty. to Ship" := SalesLineCheck.quantity;
                    WarehouseShipmentLine."Qty. to Ship (Base)" := SalesLineCheck.quantity;
                    WarehouseShipmentLine."Qty. Outstanding" := SalesLineCheck.quantity;
                    WarehouseShipmentLine."Qty. Outstanding (Base)" := SalesLineCheck.quantity;
                    WarehouseShipmentLine."Remaining Quantity" := SalesLineCheck.quantity;
                    WarehouseShipmentLine."Qty. (Base)" := SalesLineCheck.quantity;
                    WarehouseShipmentLine."Qty. per Unit of Measure" := 1;
                    WarehouseShipmentLine."Unit of Measure Code" := SalesLineCheck."Unit of Measure Code";
                    WarehouseShipmentLine.validate("Location Code", SalesLineCheck."Location Code");
                    WarehouseShipmentLine."Sorting Sequence No." := SalesOrdersTempLines."Line No.";
                    WarehouseShipmentLine."Destination Type" := WarehouseShipmentLine."Destination Type"::Customer;
                    WarehouseShipmentLine."Destination No." := SalesHeaderCheck."Sell-to Customer No.";
                    if ItemRec.get(SalesLineCheck."No.") then
                        WarehouseShipmentLine."Shelf No." := itemrec."Shelf No.";
                    WarehouseShipmentLine.modify;
                end;
            until SalesOrdersTempLines.next = 0;
        pContent := '{"ShipmentNo": "' + ShipmentNo + '"}';
    end;

    //Add Pallet to Whse Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure AddPalletToWhseShipment(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        MaxEntry: integer;
        Json_Text: Text;
        PalletHeaderTemp: Record "Pallet Header" temporary;
        WarehousePallet: Record "Warehouse Pallet";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LineNumber: Integer;
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        QuantityToUpdateShip: Integer;
        QuantityRemain: Integer;
        ShipmentNumnber: Code[20];
        PalletID: code[20];

    begin
        IF pFunction <> 'AddPalletToWhseShipment' THEN
            EXIT;

        if PalletHeaderTemp.findset then
            PalletHeaderTemp.deleteall;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        if JsonBuffer.findfirst then
            ShipmentNumnber := JsonBuffer.value;

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 4);
        JsonBuffer.setrange(JsonBuffer."Token type", JsonBuffer."Token type"::String);
        if JsonBuffer.findset then
            repeat
                if not PalletHeaderTemp.get(JsonBuffer.value) then begin
                    PalletHeaderTemp.init;
                    PalletHeaderTemp."Pallet ID" := JsonBuffer.value;
                    PalletHeaderTemp.insert;
                end;
            until JsonBuffer.next = 0;

        PalletHeaderTemp.reset;
        if PalletHeaderTemp.findset then begin
            LineNumber := 10000;
            repeat
                PalletLine.reset;
                PalletLine.setrange("Pallet ID", PalletHeaderTemp."Pallet ID");
                if palletline.findset then
                    repeat
                        QuantityToUpdateShip := PalletLine.Quantity;
                        while QuantityToUpdateShip > 0 do begin
                            WarehouseShipmentLine.reset;
                            WarehouseShipmentLine.setrange("No.", ShipmentNumnber);
                            WarehouseShipmentLine.setrange("Item No.", PalletLine."Item No.");
                            WarehouseShipmentLine.setrange("Unit of Measure Code", PalletLine."Unit of Measure");
                            WarehouseShipmentLine.setrange("Location Code", PalletLine."Location Code");
                            WarehouseShipmentLine.setfilter(WarehouseShipmentLine."Remaining Quantity", '>%1', 0);
                            if WarehouseShipmentLine.findfirst then begin
                                if WarehouseShipmentLine."Remaining Quantity" >= QuantityToUpdateShip then begin
                                    WarehousePallet.init;
                                    WarehousePallet."Whse Shipment No." := WarehouseShipmentLine."No.";
                                    WarehousePallet."Whse Shipment Line No." := WarehouseShipmentLine."Line No.";
                                    WarehousePallet."Pallet Line No." := PalletLine."Line No.";
                                    WarehousePallet."Pallet ID" := palletline."Pallet ID";
                                    WarehousePallet."Sales Order No." := WarehouseShipmentLine."Source No.";
                                    WarehousePallet."Sales Order Line No." := WarehouseShipmentLine."Source Line No.";
                                    WarehousePallet."Lot No." := PalletLine."Lot Number";
                                    WarehousePallet.Quantity := QuantityToUpdateShip;
                                    if WarehousePallet.insert then begin
                                        if PalletHeader.get(palletline."Pallet ID") then begin
                                            PalletHeader."Exist in warehouse shipment" := true;
                                            PalletHeader.modify;
                                        end;
                                    end;
                                    QuantityToUpdateShip -= PalletLine.Quantity;
                                end;
                                if WarehouseShipmentLine."Remaining Quantity" <= QuantityToUpdateShip then begin
                                    WarehousePallet.init;
                                    WarehousePallet."Whse Shipment No." := WarehouseShipmentLine."No.";
                                    WarehousePallet."Whse Shipment Line No." := WarehouseShipmentLine."Line No.";
                                    WarehousePallet."Pallet Line No." := PalletLine."Line No.";
                                    WarehousePallet."Pallet ID" := palletline."Pallet ID";
                                    WarehousePallet."Sales Order No." := WarehouseShipmentLine."Source No.";
                                    WarehousePallet."Sales Order Line No." := WarehouseShipmentLine."Source Line No.";
                                    WarehousePallet."Lot No." := PalletLine."Lot Number";
                                    WarehousePallet.Quantity := WarehouseShipmentLine."Remaining Quantity";
                                    if WarehousePallet.insert then begin
                                        if PalletHeader.get(palletline."Pallet ID") then begin
                                            PalletHeader."Exist in warehouse shipment" := true;
                                            PalletHeader.modify;
                                        end;
                                    end;
                                    QuantityToUpdateShip -= WarehouseShipmentLine."Remaining Quantity";
                                end;
                            end;

                        end;

                    until palletline.next = 0;
            until PalletHeaderTemp.next = 0;
        end;
        pContent := 'Pallets Added';
    end;

    //Get List of Sales Orders
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure RemovePalletFromWhseShip(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        ShipmentNo: code[20];
        PalletID: code[20];
        Obj_JsonText: Text;
        WarehousePallet: Record "Warehouse Pallet";
        PalletHeader: Record "Pallet Header";
        RecGReservationEntry: Record "Reservation Entry";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";

    begin
        IF pFunction <> 'RemovePalletFromWhseShip' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        //JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'shipmentno') > 0 THEN
                        ShipmentNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'palletid') > 0 THEN
                        PalletID := JSONBuffer.Value;

            UNTIL JSONBuffer.NEXT = 0;

            if (ShipmentNo <> '') and (PalletID <> '') then begin
                WarehousePallet.reset;
                WarehousePallet.setrange(WarehousePallet."Whse Shipment No.", ShipmentNo);
                WarehousePallet.setrange("Pallet ID", PalletID);
                if WarehousePallet.findset then begin
                    repeat
                        if RecGReservationEntry.get(WarehousePallet."Reserve. Entry No.") then
                            RecGReservationEntry.Delete();
                        if WarehouseShipmentLine.get(WarehousePallet."Whse Shipment No.", WarehousePallet."Whse Shipment Line No.") then begin
                            WarehouseShipmentLine."Remaining Quantity" += WarehousePallet.quantity;
                            WarehouseShipmentLine.modify;
                        end;
                        WarehousePallet.Delete();
                    until WarehousePallet.next = 0;
                    if PalletHeader.get(WarehousePallet."Pallet ID") then begin
                        PalletHeader."Exist in warehouse shipment" := false;
                        PalletHeader.modify;
                    end;
                    pContent := 'Pallet ' + PalletID + ' Removed from Shipment ' + ShipmentNo;
                end
                else
                    pContent := 'Pallet ' + PalletID + ' does not exist on Shipment ' + ShipmentNo;

            end
            else
                pContent := 'Error, shipment or Pallet doesnot exist' + ShipmentNo + PalletID;
        end;
    end;

    //Get List of Pallet in Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPalletsInShipment(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR

        JsonBuffer: Record "JSON Buffer" temporary;
        Obj_JsonText: Text;
        ShipmentNo: code[20];
        WarehouseShipmentHeader: Record "warehouse Shipment Header";
        ItemRecTemp: Record item temporary;
        WarehousePallet: Record "Warehouse Pallet";

    begin
        IF pFunction <> 'GetListOfPalletsInShipment' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'shipmentno') > 0 THEN
                        ShipmentNo := JSONBuffer.Value;
            UNTIL JSONBuffer.NEXT = 0;

        Obj_JsonText := '[';

        if WarehouseShipmentHeader.get(ShipmentNo) then begin
            WarehousePallet.reset;
            WarehousePallet.setrange("Whse Shipment No.", ShipmentNo);
            if WarehousePallet.findset then begin
                Obj_JsonText += '{"ShipmentNo": ' +
                        '"' + ShipmentNo +
                        '","PalletList":[';
                repeat
                    if not ItemRecTemp.get(WarehousePallet."Pallet ID") then begin
                        ItemRecTemp.init;
                        ItemRecTemp."No." := WarehousePallet."Pallet ID";
                        ItemRecTemp.insert;
                    end;
                until WarehousePallet.next = 0;

                ItemRecTemp.reset;
                if ItemRecTemp.findset then
                    repeat
                        Obj_JsonText += '{"PalletID" :"' + ItemRecTemp."No." + '"},';

                    until ItemRecTemp.next = 0;

            end;
        end;
        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
        Obj_JsonText += ']}]';
        if Obj_JsonText = ']}]' then
            pContent := 'No Pallets in Shipment'
        else
            pContent := Obj_JsonText;
    end;

    //Get List of Pallet in Shipment Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPalletsInShipmentLine(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR

        JsonBuffer: Record "JSON Buffer" temporary;
        Obj_JsonText: Text;
        ShipmentNo: code[20];
        LineNo: Integer;
        WarehouseShipmentHeader: Record "warehouse Shipment Header";
        ItemRecTemp: Record item temporary;
        WarehousePallet: Record "Warehouse Pallet";

    begin
        IF pFunction <> 'GetListOfPalletsInShipmentLine' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'shipmentno') > 0 THEN
                        ShipmentNo := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'lineno') > 0 THEN
                        evaluate(LineNo, JSONBuffer.Value);

            UNTIL JSONBuffer.NEXT = 0;

        Obj_JsonText := '[';

        if WarehouseShipmentHeader.get(ShipmentNo) then begin
            WarehousePallet.reset;
            WarehousePallet.setrange("Whse Shipment No.", ShipmentNo);
            WarehousePallet.setrange("Whse Shipment line No.", LineNo);
            if WarehousePallet.findset then begin
                Obj_JsonText += '{"ShipmentNo": ' +
                        '"' + ShipmentNo +
                        '","PalletList":[';
                repeat
                    if not ItemRecTemp.get(WarehousePallet."Pallet ID") then begin
                        ItemRecTemp.init;
                        ItemRecTemp."No." := WarehousePallet."Pallet ID";
                        ItemRecTemp.insert;
                    end;
                until WarehousePallet.next = 0;

                ItemRecTemp.reset;
                if ItemRecTemp.findset then
                    repeat
                        Obj_JsonText += '{"PalletID" :"' + ItemRecTemp."No." + '"},';

                    until ItemRecTemp.next = 0;

            end;
        end;
        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
        Obj_JsonText += ']}]';
        if Obj_JsonText = ']}]' then
            pContent := 'No Pallets in Shipment Line'
        else
            pContent := Obj_JsonText;
    end;

    //Get List of Pallet to select in Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPalletToSelect(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR

        JsonBuffer: Record "JSON Buffer" temporary;
        Obj_JsonText: Text;
        ShipmentNo: code[20];
        WarehouseShipmentHeader: Record "warehouse Shipment Header";
        ItemRecTemp: Record item temporary;
        WarehousePallet: Record "Warehouse Pallet";
        PalletListSelect: Record "Pallet List Select" temporary;
        PalletItemTemp: Record Item temporary;
        BoolPallet: Boolean;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "pallet line";
        Lbl002: label 'The chosen pallet cant be added because it holds items that do not exist in the warehouse shipment';


    begin
        IF pFunction <> 'GetListOfPalletToSelect' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'shipmentno') > 0 THEN
                        ShipmentNo := JSONBuffer.Value;
            UNTIL JSONBuffer.NEXT = 0;

        if PalletItemTemp.findset then
            PalletItemTemp.deleteall;

        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", ShipmentNo);
        if not WarehouseShipmentLine.findset then
            pContent := Lbl002
        else begin
            //Getting List of items in Shipment
            WarehouseShipmentLine.reset;
            WarehouseShipmentLine.setrange("No.", ShipmentNo);
            if WarehouseShipmentLine.findset then
                repeat
                    if not PalletItemTemp.get(WarehouseShipmentLine."Item No.") then begin
                        PalletItemTemp.init;
                        PalletItemTemp."No." := WarehouseShipmentLine."Item No.";
                        PalletItemTemp.Insert;
                    end;
                until WarehouseShipmentLine.next = 0;

            if PalletListSelect.findset then
                PalletListSelect.Deleteall;

            WarehouseShipmentHeader.get(ShipmentNo);
            palletheader.reset;
            palletheader.setrange(palletheader."Pallet Status", palletheader."Pallet Status"::Closed);
            palletheader.setrange(palletheader."Location Code", WarehouseShipmentHeader."Location Code");
            palletheader.setrange(palletheader."Exist in warehouse shipment", false);
            PalletHeader.setrange(PalletHeader."Raw Material Pallet", false);
            if palletheader.findset then begin
                BoolPallet := false;
                repeat
                    PalletLine.reset;
                    PalletLine.setrange("Pallet ID", Palletheader."Pallet ID");
                    if PalletLine.findset then
                        repeat
                            if PalletItemTemp.get(palletline."Item No.") then
                                BoolPallet := true;
                        until palletline.next = 0;

                    if BoolPallet then begin
                        PalletListSelect.init;
                        PalletListSelect."Pallet ID" := palletheader."Pallet ID";
                        PalletListSelect."Source Document" := ShipmentNo;
                        PalletListSelect.insert;
                    end;
                until palletheader.next = 0;

                Obj_JsonText := '[';

                if WarehouseShipmentHeader.get(ShipmentNo) then begin
                    PalletListSelect.reset;
                    if PalletListSelect.findset then begin
                        Obj_JsonText += '{"ShipmentNo": ' +
                                '"' + ShipmentNo +
                                '","PalletList":[';


                        repeat
                            palletheader.get(PalletListSelect."Pallet ID");
                            palletheader.CalcFields(palletheader."Total Qty");
                            Obj_JsonText += '{"PalletID" :"' + PalletListSelect."Pallet ID" + '"' +
                            ',"total Qty":"' + format(palletheader."Total Qty") +
                            '"},';

                        until PalletListSelect.next = 0;

                    end;
                end;
                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']}]';
                if Obj_JsonText = ']}]' then
                    pContent := 'No Pallets in Shipment'
                else
                    pContent := Obj_JsonText;
            end;
        end;
    end;

    //Remove Warehouse Shipment Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure RemoveWhseShipmentLine(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        ShipmentNo: code[20];
        LineNo: Integer;
        Obj_JsonText: Text;
        WarehousePallet: Record "Warehouse Pallet";
        RecGReservationEntry: Record "Reservation Entry";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";

    begin
        IF pFunction <> 'RemoveWhseShipmentLine' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        //JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'shipmentno') > 0 THEN
                        ShipmentNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'lineno') > 0 THEN
                        evaluate(LineNo, JSONBuffer.Value);
            UNTIL JSONBuffer.NEXT = 0;

            if (ShipmentNo <> '') and (LineNo <> 0) then begin
                if not WarehouseShipmentLine.get(ShipmentNo, LineNo) then
                    pContent := 'Error, shipment ' + ShipmentNo + ' Line ' + format(LineNo) + ' does not exist';

                WarehousePallet.reset;
                WarehousePallet.setrange(WarehousePallet."Whse Shipment No.", ShipmentNo);
                WarehousePallet.setrange(WarehousePallet."Whse Shipment Line No.", LineNo);

                if not WarehousePallet.FindFirst() then begin
                    if WarehouseShipmentLine.get(ShipmentNo, LineNo) then begin
                        WarehouseShipmentLine.delete;
                        pContent := 'Whse. Shipment ' + ShipmentNo + ' Line ' + format(LineNo) + ' Deleted';
                    end
                end
                else
                    pContent := 'error, cannot delete, Pallets Exist ';
            end;
        end;
    end;
}