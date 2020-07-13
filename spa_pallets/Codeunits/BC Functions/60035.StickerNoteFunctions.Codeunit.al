codeunit 60035 "Sticker note functions"
{
    procedure CreatePalletStickerNoteFromPallet(var PalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";
        Err001: label 'You cannot print a sticker note for an open pallet';
        OneDriveFunctions: Codeunit "OneDrive Functions";
        PalletProcessSetup: Record "Pallet Process Setup";
        PalletHeaderText: Text;
        PalletLineText: Text;
        FooterText: Text;
        PackDate_Line5: Date;
        PackDate_Text: text;
        BearerToken: Text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        StickerPrinter: Record "Sticker note Printer";
    begin
        PalletProcessSetup.Get();
        TempBlob.CreateOutStream(OutStr);

        PalletHeaderText := '';
        PalletLineText := '';
        if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::open then
            Error(Err001);

        StickerPrinter.reset;
        StickerPrinter.setrange("User Code", UserId);
        StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Pallet Label Type Code");
        StickerPrinter.setrange("Location Code", PalletHeader."Location Code");
        if StickerPrinter.findfirst then
            FileName := StickerPrinter."Printer Path" + 'Pallet_Label.txt';

        PalletHeaderText += PalletHeader."Pallet ID" + '|' +
                            format(PalletHeader."Pallet Status") + '|' +
                            PalletHeader."Location Code" + '|' +
                            format(PalletHeader."Creation Date") + '|' +
                            PalletHeader."User Created" + '|' +
                            format(PalletHeader."Exist in warehouse shipment") + '|' +
                            format(PalletHeader."Raw Material Pallet") + '|' +
                            PalletHeader."Pallet Type" + '|' +
                            format(PalletHeader."Disposal Status");
        OutStr.WriteText(PalletHeaderText);
        OutStr.WriteText();

        PalletLine.reset;
        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                PalletLineText += format(PalletLine."Line No.") + '|' +
                                    PalletLine."Item No." + '|' +
                                    PalletLine."Variant Code" + '|' +
                                    PalletLine.Description + '|' +
                                    PalletLine."Lot Number" + '|' +
                                    PalletLine."Unit of Measure" + '|' +
                                    format(PalletLine.Quantity) + '|' +
                                    format(PalletLine."QTY Consumed") + '|' +
                                    format(PalletLine."Remaining Qty") + '|' +
                                    format(PalletLine."Expiration Date");
                OutStr.WriteText(PalletLineText);
                OutStr.WriteText();
            until PalletLine.next = 0;
        FooterText := format(PalletProcessSetup."Pallet Label No. of Copies");
        OutStr.WriteText(FooterText);

        //BearerToken := OneDriveFunctions.GetBearerToken;
        //message(BearerToken);
        //message(OneDriveFunctions.CreateUploadURL('1234.txt', BearerToken));
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, '', '', '', fileName);

    end;

    procedure CreatePalletStickerNoteFromShipment(var ShipmentHeader: Record "Warehouse Shipment Header")
    var
        TypeOfPO: Label 'All,SSCC Label,Dispatch Label,Item Label';
        Selection: integer;
    begin
        Selection := STRMENU(TypeOfPO, 1);
        if selection = 1 then begin
            CreateSSCCStickernote(ShipmentHeader); //SSCC Label Sticker note
            CreateDispatchStickerNote(ShipmentHeader); //Dispatch Label Sticker note
            CreateItemLabelStickerNote(ShipmentHeader); //Item Label Sticker Note
        end;
        if selection = 2 then
            CreateSSCCStickernote(ShipmentHeader); //SSCC Label Sticker note
        if selection = 3 then
            CreateDispatchStickerNote(ShipmentHeader); //Dispatch Label Sticker note
        if selection = 4 then
            CreateItemLabelStickerNote(ShipmentHeader); //Item Label Sticker Note

    end;

    //Dispatch Label Sticker note
    procedure CreateDispatchStickerNote(pShipmentHeader: Record "Warehouse Shipment Header")
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        SalesHeader: Record "Sales Header";
        CustomerRec: Record customer;
        StickerPrinter: Record "Sticker note Printer";
        FileName: Text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        FileName := '';
        PalletProcessSetup.get;
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", pShipmentHeader."No.");
        if WarehouseShipmentLine.findset then
            repeat
                WarehousePallet.reset;
                WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentLine."No.");
                WarehousePallet.setrange("Whse Shipment Line No.", WarehouseShipmentLine."Line No.");
                if WarehousePallet.findset then
                    repeat
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then begin
                                //if CustomerRec."SSCC Sticker Note" then begin
                                StickerPrinter.reset;
                                StickerPrinter.setrange("User Code", UserId);
                                StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Dispatch Type Code");
                                StickerPrinter.setrange("Sticker Note Format", CustomerRec."Dispatch Format Code");
                                StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                if StickerPrinter.findfirst then
                                    FileName := StickerPrinter."Printer Path" + '_Dispatch_' + WarehouseShipmentLine."No." +
                                        '_' + format(WarehouseShipmentLine."Line No.") +
                                        '_' + WarehousePallet."Lot No." + '.txt';
                                TempBlob.CreateOutStream(OutStr);
                                OutStr.WriteText(WarehousePallet."Lot No.");
                            end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, '', '', '', fileName);
    end;

    //SSCC Label Sticker note
    procedure CreateSSCCStickernote(pShipmentHeader: Record "Warehouse Shipment Header")
    var
        CompanyInformation: Record "Company Information";
        ItemRec: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        GTINText_Line2: Text;
        NumberOfCrates_Line3: Text;
        BatchNumber_Line4: Text;
        PackDate_Line5: Date;
        Packdate_Text: Text;
        SSCC_Text_Line6: Text;
        Barcode_Line1: Text;
        Barcode_Line11: Text;
        Barcode_Line2: Text;
        Barcode_Line21: Text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        PalletProcessSetup: Record "Pallet Process Setup";
        CustomerRec: Record Customer;
        StickerPrinter: Record "Sticker note Printer";
    begin
        PalletProcessSetup.get;
        CompanyInformation.get;

        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", pShipmentHeader."No.");
        if WarehouseShipmentLine.findset then
            repeat
                WarehousePallet.reset;
                WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentLine."No.");
                WarehousePallet.setrange("Whse Shipment Line No.", WarehouseShipmentLine."Line No.");
                if WarehousePallet.findset then
                    repeat
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then
                                if CustomerRec."SSCC Sticker Note" then begin
                                    StickerPrinter.reset;
                                    StickerPrinter.setrange("User Code", UserId);
                                    StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."SSCC Label Type Code");
                                    StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                    if StickerPrinter.findfirst then
                                        FileName := StickerPrinter."Printer Path" + 'SSCC_' + WarehouseShipmentLine."No." +
                                            '_' + format(WarehouseShipmentLine."Line No.") +
                                            '_' + WarehousePallet."Lot No." + '.txt';
                                    TempBlob.CreateOutStream(OutStr);

                                    OutStr.WriteText(CompanyInformation.Name + '|' + CompanyInformation.Address); //Line 1
                                    OutStr.WriteText();

                                    if ItemRec.get(WarehouseShipmentLine."Item No.") then
                                        OutStr.WriteText(ItemRec.GTIN);
                                    GTINText_Line2 := ItemRec.GTIN;
                                    OutStr.WriteText();

                                    NumberOfCrates_Line3 := '99'; //Line 3
                                    OutStr.WriteText(NumberOfCrates_Line3);
                                    OutStr.WriteText();

                                    PackDate_Line5 := DMY2Date(31, 12, 3999); //Line 5

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
                                    OutStr.WriteText(format(PackDate_Line5));
                                    OutStr.WriteText();

                                    OutStr.WriteText(WarehousePallet."Lot No.");
                                    OutStr.WriteText();

                                    SSCC_Text_Line6 := GenerateSSCC();
                                    OutStr.WriteText(SSCC_Text_Line6);
                                    OutStr.WriteText();

                                    Barcode_Line1 := '02' + GTINText_Line2 + '15' + Packdate_Text + '37' + format(NumberOfCrates_Line3);
                                    Barcode_Line11 := '(02)' + GTINText_Line2 + '(15)' + Packdate_Text + '(37)' + format(NumberOfCrates_Line3);
                                    OutStr.WriteText(Barcode_Line1);
                                    OutStr.WriteText();
                                    OutStr.WriteText(Barcode_Line11);
                                    OutStr.WriteText();

                                    Barcode_Line2 := '00' + SSCC_Text_Line6;
                                    Barcode_Line21 := '(00)' + SSCC_Text_Line6;
                                    OutStr.WriteText(Barcode_Line2);
                                    OutStr.WriteText();
                                    OutStr.WriteText(Barcode_Line21);
                                    OutStr.WriteText();

                                    OutStr.WriteText(format(PalletProcessSetup."SSCC Label No. of Copies"));
                                    OutStr.WriteText();

                                    TempBlob.CreateInStream(InStr);
                                    DownloadFromStream(InStr, '', '', '', fileName);
                                end;

                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
    end;

    //Item Label Sticker Note
    procedure CreateItemLabelStickerNote(pShipmentHeader: Record "Warehouse Shipment Header")
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        SalesHeader: Record "Sales Header";
        CustomerRec: Record customer;
        StickerPrinter: Record "Sticker note Printer";
        FileName: Text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        FileName := '';
        PalletProcessSetup.get;
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", pShipmentHeader."No.");
        if WarehouseShipmentLine.findset then
            repeat
                WarehousePallet.reset;
                WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentLine."No.");
                WarehousePallet.setrange("Whse Shipment Line No.", WarehouseShipmentLine."Line No.");
                if WarehousePallet.findset then
                    repeat
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then begin
                                //if CustomerRec."SSCC Sticker Note" then begin
                                StickerPrinter.reset;
                                StickerPrinter.setrange("User Code", UserId);
                                StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Item Label Type Code");
                                StickerPrinter.setrange("Sticker Note Format", CustomerRec."Item Label Format Code");
                                StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                if StickerPrinter.findfirst then
                                    FileName := StickerPrinter."Printer Path" + '_ItemLabel_' + WarehouseShipmentLine."No." +
                                        '_' + format(WarehouseShipmentLine."Line No.") +
                                        '_' + WarehousePallet."Lot No." + '.txt';
                                TempBlob.CreateOutStream(OutStr);
                                OutStr.WriteText(WarehousePallet."Lot No.");
                            end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, '', '', '', fileName);
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