codeunit 60035 "Sticker note functions"
{
    procedure CreatePalletStickerNoteFromPallet(var PalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";
        Err001: label 'You cannot print a sticker note for an open pallet';
        OneDriveFunctions: Codeunit "OneDrive Functions";
        PalletHeaderText: Text;
        PalletLineText: Text;
        FooterText: Text;

    begin
        PalletHeaderText := '';
        PalletLineText := '';
        if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::open then
            Error(Err001);

        PalletHeaderText += PalletHeader."Pallet ID" +
                            format(PalletHeader."Pallet Status") +
                            PalletHeader."Location Code" +
                            format(PalletHeader."Creation Date") +
                            PalletHeader."User Created" +
                            format(PalletHeader."Exist in warehouse shipment") +
                            format(PalletHeader."Raw Material Pallet") +
                            PalletHeader."Pallet Type" +
                            format(PalletHeader."Disposal Status");
        PalletLine.reset;
        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                PalletLineText += format(PalletLine."Line No.") +
                                    PalletLine."Item No." +
                                    PalletLine."Variant Code" +
                                    PalletLine.Description +
                                    PalletLine."Lot Number" +
                                    PalletLine."Unit of Measure" +
                                    format(PalletLine.Quantity) +
                                    format(PalletLine."QTY Consumed") +
                                    format(PalletLine."Remaining Qty") +
                                    format(PalletLine."Expiration Date");
                FooterText := format(PalletLine."Item Label No. of Copies");
            until PalletLine.next = 0;
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

    procedure GenerateSSCC(): Text
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        SSCCNumber: Text[20];
        NoSeriesManagement: Codeunit NoSeriesManagement;
        SSCC_Seq: Text;
        SSCC_Seq2: Text;
    begin
        PalletProcessSetup.get;
        SSCC_Seq := NoSeriesManagement.GetNextNo(PalletProcessSetup."SSCC No. Series", today, true);
        SSCC_Seq2 := PADSTR('', 10 - strlen(SSCC_Seq), '0') + SSCC_Seq;
        SSCCNumber := '3' + PalletProcessSetup."Company Prefix" + SSCC_Seq2;
        exit(SSCCNumber);
    end;
}