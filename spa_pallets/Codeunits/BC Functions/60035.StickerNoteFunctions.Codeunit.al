codeunit 60035 "Sticker note functions"
{
    //Pallet Label - Sticker Note
    procedure CreatePalletStickerNoteFromPallet(var PalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";
        Err001: label 'You cannot print a sticker note for an open pallet';
        PalletProcessSetup: Record "Pallet Process Setup";
        PalletHeaderText: Text;
        PalletLineText: Text;
        FooterText: Text;
        PackDate_Line5: Date;
        PackDate_Text: text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
        StickerPrinter: Record "Sticker note Printer";
        PrinterPath: Text;
        LabelFormat: Text;
        Base64Functions: Codeunit "Base64 Convert";
        JsonAsText: Text;
        uri: Text;
        OneDriveFunctions: Codeunit "OneDrive Functions";
        BearerToken: text;
        UploadURL: text;
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
        if StickerPrinter.findfirst then begin
            PrinterPath := StickerPrinter."Printer Path";
            LabelFormat := StickerPrinter."Sticker Note type";
        end;

        FileName := 'Pallet_Label_' + PalletHeader."Pallet ID" + '.txt';
        OutStr.WriteText(LabelFormat);
        OutStr.WriteText();
        OutStr.WriteText(PrinterPath);
        OutStr.WriteText();

        PalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                            format(PalletHeader."Pallet Status") + Splitter +
                            PalletHeader."Location Code" + Splitter +
                            format(PalletHeader."Creation Date") + Splitter +
                            PalletHeader."User Created" + Splitter +
                            format(PalletHeader."Exist in warehouse shipment") + Splitter +
                            format(PalletHeader."Raw Material Pallet") + Splitter +
                            PalletHeader."Pallet Type" + Splitter +
                            format(PalletHeader."Disposal Status") + Splitter +
                            format(PalletProcessSetup."Pallet Label No. of Copies");
        OutStr.WriteText(PalletHeaderText);
        OutStr.WriteText();

        PalletLine.reset;
        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                PalletLineText += format(PalletLine."Line No.") + Splitter +
                                    PalletLine."Item No." + Splitter +
                                    PalletLine."Variant Code" + Splitter +
                                    PalletLine.Description + Splitter +
                                    PalletLine."Lot Number" + Splitter +
                                    PalletLine."Unit of Measure" + Splitter +
                                    format(PalletLine.Quantity) + Splitter +
                                    format(PalletLine."QTY Consumed") + Splitter +
                                    format(PalletLine."Remaining Qty") + Splitter +
                                    format(PalletLine."Expiration Date");
                OutStr.WriteText(PalletLineText);
                OutStr.WriteText();
            until PalletLine.next = 0;
        TempBlob.CreateInStream(InStr);
        BearerToken := OneDriveFunctions.GetBearerToken();
        OneDriveFunctions.UploadFile(FileName, BearerToken, InStr);       
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

    //Dispatch Label - Sticker note
    procedure CreateDispatchStickerNote(pShipmentHeader: Record "Warehouse Shipment Header")
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        PalletHeader: Record "Pallet Header";
        PalletHeaderText: text;
        PalletLine: Record "Pallet Line";
        PalletlineText: Text;
        SalesHeader: Record "Sales Header";
        CustomerRec: Record customer;
        StickerPrinter: Record "Sticker note Printer";
        FileName: Text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        PrinterPath: Text;
        LabelFormat: Text;
        ItemAttributesMapping: Record "Item Attribute Value mapping";
        ItemAttrText: text;
        SalesHeaderText: Text;
        CompanyInformation: Record "Company Information";
        CompanyText: Text;
        PurchaseHeader: Record "Purchase Header";
        Base64Functions: Codeunit "Base64 Convert";
        JsonAsText: Text;
        uri: text;
        BearerToken: text;
        OneDriveFunctions: Codeunit "OneDrive Functions";
    begin
        CompanyInformation.get;
        CompanyText := CompanyInformation.name + Splitter +
                     CompanyInformation.address + Splitter +
                     CompanyInformation."E-Mail" + splitter +
                     CompanyInformation."Phone No.";
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
                                StickerPrinter.setrange("Sticker Note Format", CustomerRec."Dispatch Format Code");
                                StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                if StickerPrinter.findfirst then begin
                                    PrinterPath := StickerPrinter."Printer Path";
                                    LabelFormat := CustomerRec."Dispatch Format Description";
                                end;

                                FileName := 'DispatchLabel_' + WarehouseShipmentLine."No." +
                                    '_' + format(WarehouseShipmentLine."Line No.") +
                                    '_' + WarehousePallet."Lot No." + '.txt';

                                TempBlob.CreateOutStream(OutStr);

                                PalletHeader.get(WarehousePallet."Pallet ID");

                                OutStr.WriteText(LabelFormat);
                                OutStr.WriteText();
                                OutStr.WriteText(PrinterPath);
                                OutStr.WriteText();

                                PalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                    format(PalletHeader."Pallet Status") + Splitter +
                                                    PalletHeader."Location Code" + Splitter +
                                                    format(PalletHeader."Creation Date") + Splitter +
                                                    PalletHeader."User Created" + Splitter +
                                                    format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                    format(PalletHeader."Raw Material Pallet") + Splitter +
                                                    PalletHeader."Pallet Type" + Splitter +
                                                    format(PalletHeader."Disposal Status") + Splitter +
                                                    format(PalletProcessSetup."Pallet Label No. of Copies");
                                OutStr.WriteText(PalletHeaderText);
                                OutStr.WriteText();
                            end;

                        PalletLine.reset;
                        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                        if PalletLine.findset then
                            repeat
                                PalletLineText := format(PalletLine."Line No.") + Splitter +
                                                    PalletLine."Item No." + Splitter +
                                                    PalletLine."Variant Code" + Splitter +
                                                    PalletLine.Description + Splitter +
                                                    PalletLine."Lot Number" + Splitter +
                                                    PalletLine."Unit of Measure" + Splitter +
                                                    format(PalletLine.Quantity) + Splitter +
                                                    format(PalletLine."QTY Consumed") + Splitter +
                                                    format(PalletLine."Remaining Qty") + Splitter +
                                                    format(PalletLine."Expiration Date");
                                if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                    PalletLine."Purchase Order No.") then begin
                                    PalletLineText += Splitter +
                                                      PurchaseHeader."Buy-from Vendor No." + splitter +
                                                      GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                      format(PurchaseHeader."Harvest Date");
                                    PalletLineText += splitter + Format(CustomerRec."Dispatch Format No. of Copies");
                                end;
                                OutStr.WriteText(PalletLineText);
                                OutStr.WriteText();
                            until PalletLine.next = 0;

                        ItemAttrText := '';
                        ItemAttributesMapping.reset;
                        ItemAttributesMapping.setrange("Table ID", 27);
                        ItemAttributesMapping.setrange("No.", WarehouseShipmentLine."Item No.");
                        if ItemAttributesMapping.findset then
                            repeat
                                ItemAttrText += GetAttributeName(ItemAttributesMapping."Item Attribute ID") + ':' +
                                GetAttributeValue(ItemAttributesMapping."Item Attribute ID", ItemAttributesMapping."Item Attribute Value ID") + Splitter;
                            until ItemAttributesMapping.next = 0;

                        if ItemAttrText <> '' then begin
                            ItemAttrText := copystr(ItemAttrText, 1, strlen(ItemAttrText) - 1);
                            OutStr.WriteText(ItemAttrText);
                            OutStr.WriteText();
                        end;

                        SalesHeaderText := SalesHeader."Sell-to Customer No." + Splitter +
                                        SalesHeader."Sell-to Customer Name" + Splitter +
                                        SalesHeader."No." + Splitter +
                                        format(SalesHeader."Requested Delivery Date") + Splitter +
                                        format(SalesHeader."document Date") + Splitter +
                                        format(SalesHeader."Pack-out Date") + Splitter +
                                        format(SalesHeader."Dispatch Date") + Splitter +
                                        format(SalesHeader."Promised Delivery Date") + Splitter +
                                        format(SalesHeader."due Date") + Splitter +
                                        format(SalesHeader."order Date") + Splitter +
                                        format(SalesHeader."Work Description");
                        OutStr.WriteText(SalesHeaderText);
                        OutStr.WriteText();

                        OutStr.WriteText(CompanyText);
                        OutStr.WriteText();

                        TempBlob.CreateInStream(InStr);
                        BearerToken := OneDriveFunctions.GetBearerToken();
                        OneDriveFunctions.UploadFile(FileName, BearerToken, InStr);                        

                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
    end;

    //SSCC Label Sticker note
    procedure CreateSSCCStickerNote(pShipmentHeader: Record "Warehouse Shipment Header")
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
        PrinterPath: Text;
        LabelFormat: Text;
        Base64Functions: Codeunit "Base64 convert";
        JsonAsText: Text;
        uri: text;
        BearerToken: text;
        OneDriveFunctions: Codeunit "OneDrive Functions";

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
                                    if StickerPrinter.findfirst then begin
                                        PrinterPath := StickerPrinter."Printer Path";
                                        LabelFormat := StickerPrinter."Sticker Note type";
                                    end;
                                    FileName := 'SSCC_' + WarehouseShipmentLine."No." +
                                        '_' + format(WarehouseShipmentLine."Line No.") +
                                        '_' + WarehousePallet."Lot No." + '.txt';

                                    TempBlob.CreateOutStream(OutStr);

                                    OutStr.WriteText(LabelFormat);
                                    OutStr.WriteText();
                                    OutStr.WriteText(PrinterPath);
                                    OutStr.WriteText();

                                    OutStr.WriteText(CompanyInformation.Name + Splitter + CompanyInformation.Address); //Line 1
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
                                    BearerToken := OneDriveFunctions.GetBearerToken();
                                    OneDriveFunctions.UploadFile(FileName, BearerToken, InStr);                                    

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
        PalletHeader: Record "Pallet Header";
        PalletHeaderText: text;
        PalletLine: Record "Pallet Line";
        PalletlineText: Text;
        SalesHeader: Record "Sales Header";
        CustomerRec: Record customer;
        StickerPrinter: Record "Sticker note Printer";
        FileName: Text;
        TempBlob: codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        PrinterPath: Text;
        LabelFormat: Text;
        ItemAttributesMapping: Record "Item Attribute Value mapping";
        ItemAttrText: text;
        SalesHeaderText: Text;
        CompanyInformation: Record "Company Information";
        CompanyText: Text;
        PurchaseHeader: Record "Purchase Header";
        Base64Functions: Codeunit "Base64 convert";
        JsonAsText: Text;
        uri: text;
        BearerToken: text;
        OneDriveFunctions: Codeunit "OneDrive Functions";

    begin
        CompanyInformation.get;
        CompanyText := CompanyInformation.name + Splitter +
                     CompanyInformation.address + Splitter +
                     CompanyInformation."E-Mail" + splitter +
                     CompanyInformation."Phone No.";
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
                                if StickerPrinter.findfirst then begin
                                    PrinterPath := StickerPrinter."Printer Path";
                                    LabelFormat := CustomerRec."Item Label Format Description";
                                end;

                                FileName := 'ItemLabel_' + WarehouseShipmentLine."No." +
                                    '_' + format(WarehouseShipmentLine."Line No.") +
                                    '_' + WarehousePallet."Lot No." + '.txt';

                                TempBlob.CreateOutStream(OutStr);

                                PalletHeader.get(WarehousePallet."Pallet ID");

                                OutStr.WriteText(LabelFormat);
                                OutStr.WriteText();
                                OutStr.WriteText(PrinterPath);
                                OutStr.WriteText();

                                PalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                    format(PalletHeader."Pallet Status") + Splitter +
                                                    PalletHeader."Location Code" + Splitter +
                                                    format(PalletHeader."Creation Date") + Splitter +
                                                    PalletHeader."User Created" + Splitter +
                                                    format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                    format(PalletHeader."Raw Material Pallet") + Splitter +
                                                    PalletHeader."Pallet Type" + Splitter +
                                                    format(PalletHeader."Disposal Status") + Splitter +
                                                    format(PalletProcessSetup."Pallet Label No. of Copies");
                                OutStr.WriteText(PalletHeaderText);
                                OutStr.WriteText();
                            end;

                        PalletLine.reset;
                        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                        if PalletLine.findset then
                            repeat
                                PalletLineText := format(PalletLine."Line No.") + Splitter +
                                                    PalletLine."Item No." + Splitter +
                                                    PalletLine."Variant Code" + Splitter +
                                                    PalletLine.Description + Splitter +
                                                    PalletLine."Lot Number" + Splitter +
                                                    PalletLine."Unit of Measure" + Splitter +
                                                    format(PalletLine.Quantity) + Splitter +
                                                    format(PalletLine."QTY Consumed") + Splitter +
                                                    format(PalletLine."Remaining Qty") + Splitter +
                                                    format(PalletLine."Expiration Date");
                                if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                    PalletLine."Purchase Order No.") then begin
                                    PalletLineText += Splitter +
                                                      PurchaseHeader."Buy-from Vendor No." + splitter +
                                                      GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                      format(PurchaseHeader."Harvest Date");
                                    PalletLineText += splitter + Format(PalletLine."Item Label No. of Copies")
                                end;
                                OutStr.WriteText(PalletLineText);
                                OutStr.WriteText();
                            until PalletLine.next = 0;

                        ItemAttrText := '';
                        ItemAttributesMapping.reset;
                        ItemAttributesMapping.setrange("Table ID", 27);
                        ItemAttributesMapping.setrange("No.", WarehouseShipmentLine."Item No.");
                        if ItemAttributesMapping.findset then
                            repeat
                                ItemAttrText += GetAttributeName(ItemAttributesMapping."Item Attribute ID") + ':' +
                                GetAttributeValue(ItemAttributesMapping."Item Attribute ID", ItemAttributesMapping."Item Attribute Value ID") + Splitter;
                            until ItemAttributesMapping.next = 0;

                        if ItemAttrText <> '' then begin
                            ItemAttrText := copystr(ItemAttrText, 1, strlen(ItemAttrText) - 1);
                            OutStr.WriteText(ItemAttrText);
                            OutStr.WriteText();
                        end;

                        SalesHeaderText := SalesHeader."Sell-to Customer No." + Splitter +
                                        SalesHeader."Sell-to Customer Name" + Splitter +
                                        SalesHeader."No." + Splitter +
                                        format(SalesHeader."Requested Delivery Date") + Splitter +
                                        format(SalesHeader."document Date") + Splitter +
                                        format(SalesHeader."Pack-out Date") + Splitter +
                                        format(SalesHeader."Dispatch Date") + Splitter +
                                        format(SalesHeader."Promised Delivery Date") + Splitter +
                                        format(SalesHeader."due Date") + Splitter +
                                        format(SalesHeader."order Date") + Splitter +
                                        format(SalesHeader."Work Description");
                        OutStr.WriteText(SalesHeaderText);
                        OutStr.WriteText();

                        OutStr.WriteText(CompanyText);
                        OutStr.WriteText();

                        TempBlob.CreateInStream(InStr);
                        BearerToken := OneDriveFunctions.GetBearerToken();
                        OneDriveFunctions.UploadFile(FileName, BearerToken, InStr);                        

                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
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

    procedure GetAttributeName(AttrID: Integer): Text
    var
        ItemAttribute: Record "Item Attribute";
    begin
        if ItemAttribute.get(AttrID) then
            exit(ItemAttribute.Name);
    end;

    procedure GetAttributeValue(AttrID: integer; AttrValueID: Integer): Text
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if ItemAttributeValue.get(AttrID, AttrValueID) then
            exit(ItemAttributeValue.value);
    end;

    procedure GetVendorAddress(pVendorNo: code[20]): Text
    var
        VendorRec: Record vendor;
    begin
        if VendorRec.get(pVendorNo) then
            exit(VendorRec.Address);
    end;

    var
        Splitter: label '|';

    Procedure ConvertFileToJson(pFileName: Text; Base64Content: text): Text
    var
        JsonText: Text;
        JsonObj: JsonObject;
    begin
        JsonObj.Add('FileName', pFileName);
        JsonObj.Add('Content', Base64Content);
        JsonObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure MakeRequest(uri: Text; payload: Text) responseText: Text;
    var
        TempBlob: Codeunit "Temp Blob";
        REsponseBlob: Codeunit "Temp Blob";
        client: HttpClient;
        request: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        contentHeaders: HttpHeaders;
        content: HttpContent;
        Instr: InStream;
        ResponseInstr: InStream;
        Outstr: OutStream;
        StartDateTime: DateTime;
        TotalDuration: Duration;

    begin
        // Add the payload to the content 
        content.WriteFrom(payload);
        // Retrieve the contentHeaders associated with the content 
        content.GetHeaders(contentHeaders);
        contentHeaders.Clear();
        contentHeaders.Add('Content-Type', 'application/json');
        contentHeaders.Add('Content-Length', format(StrLen(payload)));
        // Assigning content to request.Content will actually create a copy of the content and assign it. 
        // After this line, modifying the content variable or its associated headers will not reflect in 
        // the content associated with the request message 
        request.Content := content;
        request.SetRequestUri(uri);
        request.Method := 'POST';
        StartDateTime := CurrentDateTime();
        client.Send(request, WebResponse);
        TotalDuration := CurrentDateTime() - StartDateTime;
        //>>LOG
        tempblob.CreateInStream(Instr);
        content.ReadAs(Instr);
        ResponseBlob.CreateInStream(ResponseInstr);
        WebResponse.Content().ReadAs(ResponseInstr);

        // Read the response content as XML. 
        WebResponse.Content().ReadAs(responseText);
    end;
}