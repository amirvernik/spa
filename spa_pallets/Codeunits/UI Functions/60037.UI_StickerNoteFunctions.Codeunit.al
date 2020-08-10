codeunit 60036 "UI Sticker Note Functions"
{
    //Print Sticker Note - Pallet Sticker Note From UI
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure PrintPalletSticker(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        PalletHeader: Record "Pallet Header";
        PalletID: code[20];
        StickerNoteFunctions: Codeunit "Sticker note functions";

    begin
        IF pFunction <> 'PrintPalletSticker' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        JsonObj.SelectToken('palletid', JsonTkn);
        PalletID := JsonTkn.AsValue().AsText();


        if PalletHeader.get(PalletID) then begin
            StickerNoteFunctions.CreatePalletStickerNoteFromPallet(PalletHeader);
            pContent := 'Pallet Sticker Note sent to Printer';
        end
        else
            pContent := 'Error, cannot find pallet';
    end;

    //Print Sticker Note - Shipment Sticker Notes From UI
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure PrintShipmentStickers(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        ShipmentHeader: Record "Warehouse Shipment Header";
        ShipmentNumber: code[20];
        StickerNoteFunctions: Codeunit "Sticker note functions";

    begin
        IF pFunction <> 'PrintShipmentStickers' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        JsonObj.SelectToken('shipmentNum', JsonTkn);
        ShipmentNumber := JsonTkn.AsValue().AsText();


        if ShipmentHeader.get(ShipmentNumber) then begin
            StickerNoteFunctions.CreateSSCCStickernote(ShipmentHeader, '', false); //SSCC Label Sticker note
            StickerNoteFunctions.CreateDispatchStickerNote(ShipmentHeader, '', false); //Dispatch Label Sticker note
            StickerNoteFunctions.CreateItemLabelStickerNote(ShipmentHeader, '', false); //Item Label Sticker Note
            pContent := 'Warehouse Stickers sent to Printer';
        end
        else
            pContent := 'Error, cannot find Shipment';


    end;

    //9284 -Add a new function to print a label for a specific sticker From UI
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure PrintShipmentSpecificSticker(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        ShipmentHeader: Record "Warehouse Shipment Header";
        ShipmentLine: Record "Warehouse Shipment Line";
        PalletHeader: Record "Pallet Header";
        LCustomer: Record Customer;
        ShipmentNumber: code[20];
        PalletNumber: Code[20];
        StickerType: text;
        StickerNoteFunctions: Codeunit "Sticker note functions";
        LSalesOrder: Record "Sales Header";
        LSalesOrderArchive: Record "Sales Header Archive";
    begin
        IF pFunction <> 'PrintShipmentSpecificSticker' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        JsonObj.SelectToken('shipmentnumber', JsonTkn);
        ShipmentNumber := JsonTkn.AsValue().AsText();
        JsonObj.SelectToken('palletnumber', JsonTkn);
        PalletNumber := JsonTkn.AsValue().AsText();
        JsonObj.SelectToken('stickertype', JsonTkn);
        StickerType := JsonTkn.AsValue().AsText();

        case StickerType of
            'SSCC':
                begin
                    if ShipmentHeader.get(ShipmentNumber) then begin
                        ShipmentLine.Reset();
                        ShipmentLine.SetRange("No.", ShipmentNumber);
                        if ShipmentLine.FindFirst() then begin
                            LSalesOrder.Reset();
                            LSalesOrder.SetRange("Document Type", LSalesOrder."Document Type"::Order);
                            LSalesOrder.SetRange("No.", ShipmentLine."Source No.");
                            if LSalesOrder.FindFirst() then begin
                                LCustomer.Get(LSalesOrder."Sell-to Customer No.");
                                if LCustomer."SSCC Sticker Note" then begin
                                    StickerNoteFunctions.CreateSSCCStickernote(ShipmentHeader, PalletNumber, true); //SSCC Label Sticker note
                                    pContent := 'SSCC Sticker sent to Printer';
                                    exit;
                                end;
                            end else begin
                                LSalesOrderArchive.Reset();
                                LSalesOrderArchive.SetRange("Document Type", LSalesOrder."Document Type"::Order);
                                LSalesOrderArchive.SetRange("No.", ShipmentLine."Source No.");
                                if LSalesOrderArchive.FindFirst() then begin
                                    LCustomer.Get(LSalesOrder."Sell-to Customer No.");
                                    if LCustomer."SSCC Sticker Note" then begin
                                        StickerNoteFunctions.CreateSSCCStickernote(ShipmentHeader, PalletNumber, true); //SSCC Label Sticker note
                                        pContent := 'SSCC Sticker sent to Printer';
                                        exit;
                                    end else begin
                                        pContent := StrSubstNo('Error, field "SSCC Sticker Note" must be marked in customer %1', LCustomer."No.");
                                        exit;
                                    end;

                                end else begin
                                    pContent := 'Error, cannot find sales order';
                                    exit;
                                end;
                            end;
                        end else
                            pContent := 'Error, cannot find warehouse shipment line';
                    end else
                        pContent := 'Error, cannot find Shipment';
                    exit;
                end;
            'Pallet':
                begin
                    if PalletHeader.Get(PalletHeader) then begin
                        StickerNoteFunctions.CreatePalletStickerNoteFromPallet(PalletHeader);
                        pContent := 'Pallet Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Pallet';
                    exit;
                end;
            'Dispatch':
                begin
                    if ShipmentHeader.get(ShipmentNumber) then begin
                        StickerNoteFunctions.CreateDispatchStickerNote(ShipmentHeader, PalletNumber, true); //Dispatch Label Sticker note
                        pContent := 'Dispatch Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Shipment';
                    exit;
                end;
            'Item':
                begin
                    if ShipmentHeader.get(ShipmentNumber) then begin
                        StickerNoteFunctions.CreateItemLabelStickerNote(ShipmentHeader, PalletNumber, true); //Item Label Sticker Note
                        pContent := 'Item Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Shipment';
                    exit;
                end;
        end;
        pContent := 'Error, cannot find Sticker';
    end;


}