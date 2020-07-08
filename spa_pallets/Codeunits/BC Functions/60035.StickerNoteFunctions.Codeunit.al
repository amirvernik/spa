codeunit 60035 "Sticker note functions"
{
    procedure CreatePalletStickerNoteFromPallet(var PalletHeader: Record "Pallet Header")
    var
        Err001: label 'You cannot print a sticker note for an open pallet';
        VOutStream: OutStream;
    begin
        if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::open then
            Error(Err001);
    end;

    procedure CreatePalletStickerNoteFromShipment(var ShipmentHeader: Record "Warehouse Shipment Header")
    var
    begin

    end;

    procedure CreateDispatchStickerNote()
    var
    begin

    end;

    procedure CreateSSCCStickernote()
    var
    begin

    end;

    procedure CreateItemLabelStickerNote()
    var
    begin

    end;
}