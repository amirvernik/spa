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
        PackDate_Line5: Date;
        PackDate_Text: text;
        BearerToken: Text;
    begin
        /*PalletHeaderText := '';
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
            until PalletLine.next = 0;*/
        BearerToken := OneDriveFunctions.GetBearerToken;
        message(BearerToken);
        message(OneDriveFunctions.CreateUploadURL('1234.txt', BearerToken));

    end;

    procedure CreatePalletStickerNoteFromShipment(var ShipmentHeader: Record "Warehouse Shipment Header")
    var
    begin
        CreateDispatchStickerNote; //Dispatch Label Sticker note
        CreateSSCCStickernote(ShipmentHeader); //SSCC Label Sticker note
        CreateItemLabelStickerNote; //Item Label Sticker Note
    end;

    //Dispatch Label Sticker note
    procedure CreateDispatchStickerNote()
    var
    begin

    end;

    //SSCC Label Sticker note
    procedure CreateSSCCStickernote(pShipmentHeader: Record "Warehouse Shipment Header")
    var
        CompanyInformation: Record "Company Information";
        ItemRec: Record Item;
        SalesHeader: Record "Sales Header";
        NameAndAddress_Line1: Text;
        GTINText_Line2: Text;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        NumberOfCrates_Line3: Text;
        BatchNumber_Line4: Text;
        PackDate_Line5: Date;
        Packdate_Text: Text;
        SSCC_Text_Line6: Text;
        Barcode_Line1: Text;
        Barcode_Line2: Text;

    begin
        CompanyInformation.get;
        NameAndAddress_Line1 := CompanyInformation.Name + '|' + CompanyInformation.Address; //Line 1
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", pShipmentHeader."No.");
        if WarehouseShipmentLine.findset then
            repeat
                if ItemRec.get(WarehouseShipmentLine."Item No.") then
                    GTINText_Line2 := itemrec.GTIN; //Line 2

                NumberOfCrates_Line3 := ''; //Line 3

                WarehousePallet.reset;
                WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentLine."No.");
                WarehousePallet.setrange("Whse Shipment Line No.", WarehouseShipmentLine."Line No.");
                if WarehousePallet.findset then
                    repeat
                        BatchNumber_Line4 := WarehousePallet."Lot No."; //Line 4
                    until warehousepallet.next = 0;

                PackDate_Line5 := DMY2Date(31, 12, 3999); //Line 5
                if SalesHeader.get(WarehouseShipmentLine."Source No.") then begin
                    if SalesHeader."Posting Date" < PackDate_Line5 then
                        PackDate_Line5 := SalesHeader."Posting Date";
                    if SalesHeader."Pack-out Date" < PackDate_Line5 then
                        PackDate_Line5 := SalesHeader."Pack-out Date";
                    if SalesHeader."Document Date" < PackDate_Line5 then
                        PackDate_Line5 := SalesHeader."Document Date";
                    if SalesHeader."Dispatch Date" < PackDate_Line5 then
                        PackDate_Line5 := SalesHeader."Dispatch Date";

                    Packdate_Text := format(Date2DMY(PackDate_Line5, 3) - 2000) +
                                    PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                    PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 2));
                end;
            until WarehouseShipmentLine.next = 0;
        SSCC_Text_Line6 := GenerateSSCC();
        Barcode_Line1 := '02' + GTINText_Line2 + '15' + Packdate_Text + '37' + format(NumberOfCrates_Line3);
        Barcode_Line2 := '00' + SSCC_Text_Line6;
    end;

    //Item Label Sticker Note
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