codeunit 60018 "Pallet Availability Functions"
{

    //Check Selected Pallets - Global Function
    procedure FctCheckSelectedPallets(var PalletListSelect: Record "Pallet List Select"; ReqType: Text): Text
    var
        ShipmentNo: code[20];
        TotalQtyOnPallets: Integer;
        TotalQtyOnShipment: Integer;
        PalletLine: Record "Pallet Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Err001: Label 'Quantities on Selected pallets are Greater then Quantities on Warehouse shipment, Please Select Again';
        ErrorText: Array[10] of Text;
        ItemNoToShow: code[20];
        CharBR: char;
        PalletError: Record "Pallet Avail Error" temporary;
        JsonText: Text;

    begin
        clear(ErrorText);
        CharBR := 13;
        PalletListSelect.reset;
        PalletListSelect.setrange(PalletListSelect.Select, true);
        if PalletListSelect.findfirst then
            ShipmentNo := PalletListSelect."Source Document";

        //01:: Check Quantities
        TotalQtyOnPallets := 0;
        PalletListSelect.reset;
        PalletListSelect.setrange(PalletListSelect.Select, true);
        if PalletListSelect.findset then
            repeat
                PalletLine.setrange("Pallet ID", PalletListSelect."Pallet ID");
                if PalletLine.findset then
                    repeat
                        TotalQtyOnPallets += PalletLine.Quantity;
                    until palletline.next = 0;
            until PalletListSelect.next = 0;


        if WarehouseShipmentLine.findset then
            WarehouseShipmentLine.setrange("No.", ShipmentNo);
        if WarehouseShipmentLine.findset then
            repeat
                //TotalQtyOnShipment += WarehouseShipmentLine."QTY. to ship";
                TotalQtyOnShipment += WarehouseShipmentLine."Remaining Quantity";
            until WarehouseShipmentLine.next = 0;

        if TotalQtyOnShipment < TotalQtyOnPallets then begin
            ErrorText[1] := Err001;
            PalletError.init;
            PalletError."Error No." := 1;
            PalletError."Error Description" := ErrorText[1];
            PalletError."Shipment No." := ShipmentNo;
            PalletError.insert;
        end;

        //02:: Check Items
        ErrorText[2] := 'Items : ';
        PalletListSelect.reset;
        PalletListSelect.setrange(PalletListSelect.Select, true);
        if PalletListSelect.findset then
            repeat
                PalletLine.setrange("Pallet ID", PalletListSelect."Pallet ID");
                if PalletLine.findset then
                    repeat
                        WarehouseShipmentLine.reset;
                        WarehouseShipmentLine.setrange("No.", ShipmentNo);
                        WarehouseShipmentLine.SetRange("Item No.", PalletLine."Item No.");
                        if not WarehouseShipmentLine.FindFirst then
                            ErrorText[2] += PalletLine."Item No." + ', '
                    until palletline.next = 0;
            until PalletListSelect.next = 0;
        if ErrorText[2] = 'Items : ' then
            ErrorText[2] := ''
        else begin
            ErrorText[2] := CopyStr(ErrorText[2], 1, StrLen(ErrorText[2]) - 2);
            ErrorText[2] += ' Does not exist on warehouse Shipment';
        end;

        if ErrorText[2] <> '' then begin
            PalletError.init;
            PalletError."Error No." := 2;
            PalletError."Error Description" := ErrorText[2];
            PalletError."Shipment No." := ShipmentNo;
            PalletError.insert;
        end;

        PalletError.reset;
        if PalletError.findset then begin
            JsonText := '[';
            if ReqType = 'BC' then
                page.run(page::"Pallet Avail Error List", PalletError);

            repeat
                JsonText += '{"Error":"' + PalletError."Error Description" + '"},';
            until PalletError.next = 0;

            JsonText := copystr(JsonText, 1, strlen(JsonText) - 1);
            JsonText += ']';
        end;

        exit(JsonText);
    end;
}