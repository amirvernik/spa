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
            StickerNoteFunctions.CreateSSCCStickernote(ShipmentHeader); //SSCC Label Sticker note
            StickerNoteFunctions.CreateDispatchStickerNote(ShipmentHeader); //Dispatch Label Sticker note
            StickerNoteFunctions.CreateItemLabelStickerNote(ShipmentHeader); //Item Label Sticker Note
            pContent := 'Warehouse Stickers sent to Printer';
        end
        else
            pContent := 'Error, cannot find Shipment';


    end;

    //Print Sticker Note - Shipment Sticker Notes From UI
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure PrintShipmentSpecificSticker(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        ShipmentHeader: Record "Warehouse Shipment Header";
        PalletHeader: Record "Pallet Header";
        LCustomer: Record Customer;
        ShipmentNumber: code[20];
        PalletNumber: Code[20];
        StickerType: text;
        StickerNoteFunctions: Codeunit "Sticker note functions";

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
                        StickerNoteFunctions.CreateSSCCStickernote(ShipmentHeader); //SSCC Label Sticker note
                        pContent := 'SSCC Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Shipment';
                end;
            'Pallet':
                begin
                    if PalletHeader.Get(PalletHeader) then begin
                        StickerNoteFunctions.CreatePalletStickerNoteFromPallet(PalletHeader);
                        pContent := 'Pallet Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Pallet';
                end;
            'Dispatch':
                begin
                    if ShipmentHeader.get(ShipmentNumber) then begin
                        StickerNoteFunctions.CreateDispatchStickerNote(ShipmentHeader); //Dispatch Label Sticker note
                        pContent := 'Dispatch Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Shipment';
                end;
            'Item':
                begin
                    if ShipmentHeader.get(ShipmentNumber) then begin
                        StickerNoteFunctions.CreateItemLabelStickerNote(ShipmentHeader); //Item Label Sticker Note
                        pContent := 'Item Sticker sent to Printer';
                    end else
                        pContent := 'Error, cannot find Shipment';
                end;
        end;


    end;


}