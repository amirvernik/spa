codeunit 60035 "Sticker note functions"
{
    //Pallet Label - Sticker Note
    procedure CreatePalletStickerNoteFromPallet(var PalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";
        Err001: label 'You cannot print a sticker note for an open pallet';
        PalletProcessSetup: Record "Pallet Process Setup";
        PalletText: Text;
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
        FirstLine: Text;
        SecondLine: text;
    begin
        PalletProcessSetup.Get();
        TempBlob.CreateOutStream(OutStr);

        PalletText := '';
        //if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::open then
        //    Error(Err001);

        StickerPrinter.reset;
        StickerPrinter.setrange("User Code", UserId);
        StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Pallet Label Type Code");
        StickerPrinter.setrange("Location Code", PalletHeader."Location Code");
        if StickerPrinter.findfirst then begin
            FirstLine := '%BTW% /AF="' +
                        StickerPrinter."Sticker Format Name(BTW)" +
                        '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                        format(PalletProcessSetup."Pallet Label No. of Copies");
            SecondLine := '%END%';
            PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";
            LabelFormat := StickerPrinter."Sticker Note type";
        end;

        FileName := 'Pallet_Label_' + PalletHeader."Pallet ID" + '.txt';
        OutStr.WriteText(Firstline);
        OutStr.WriteText();
        OutStr.WriteText(SecondLine);
        OutStr.WriteText();

        PalletText := PalletHeader."Pallet ID" + Splitter +
                            format(PalletHeader."Pallet Status") + Splitter +
                            PalletHeader."Location Code" + Splitter +
                            format(PalletHeader."Creation Date") + Splitter +
                            PalletHeader."User Created" + Splitter +
                            format(PalletHeader."Exist in warehouse shipment") + Splitter +
                            format(PalletHeader."Raw Material Pallet") + Splitter +
                            PalletHeader."Pallet Type" + Splitter +
                            format(PalletHeader."Disposal Status") + Splitter;
        //OutStr.WriteText(PalletHeaderText);
        //OutStr.WriteText();

        PalletLine.reset;
        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                PalletText += format(PalletLine."Line No.") + Splitter +
                                    PalletLine."Item No." + Splitter +
                                    PalletLine."Variant Code" + Splitter +
                                    PalletLine.Description + Splitter +
                                    PalletLine."Lot Number" + Splitter +
                                    PalletLine."Unit of Measure" + Splitter +
                                    format(PalletLine.Quantity) + Splitter +
                                    format(PalletLine."QTY Consumed") + Splitter +
                                    format(PalletLine."Remaining Qty") + Splitter +
                                    format(PalletLine."Expiration Date") + Splitter;
            //OutStr.WriteText(PalletLineText);
            until PalletLine.next = 0;

        OutStr.WriteText(PalletText);
        TempBlob.CreateInStream(InStr);
        BearerToken := OneDriveFunctions.GetBearerToken();
        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
    end;

    procedure CreatePalletStickerNoteFromShipment(var ShipmentHeader: Record "Warehouse Shipment Header")
    var
        TypeOfPO: Label 'All,SSCC Label,Dispatch Label,Item Label';
        Selection: integer;
    begin
        Selection := STRMENU(TypeOfPO, 1, 'Please select the Desired format');
        if selection = 1 then begin
            CreateSSCCStickernote(ShipmentHeader, '', false); //SSCC Label Sticker note
            CreateDispatchStickerNote(ShipmentHeader, '', false); //Dispatch Label Sticker note
            CreateItemLabelStickerNote(ShipmentHeader, '', false); //Item Label Sticker Note
            message('All Warehouse Shipment Sticker notes sent to Printer');
        end;
        if selection = 2 then begin
            CreateSSCCStickernote(ShipmentHeader, '', false); //SSCC Label Sticker note
            message('SSCC Label Sticker note sent to Printer');
        end;

        if selection = 3 then begin
            CreateDispatchStickerNote(ShipmentHeader, '', false); //Dispatch Label Sticker note
            message('Dispatch Label Sticker note sent to Printer');
        end;

        if selection = 4 then begin
            CreateItemLabelStickerNote(ShipmentHeader, '', false); //Item Label Sticker Note
            message('Item Label Sticker note sent to Printer');
        end;


    end;

    //Dispatch Label - Sticker note
    procedure CreateDispatchStickerNote(pShipmentHeader: Record "Warehouse Shipment Header"; PalletNumber: Code[20]; boolFilterPallet: Boolean)
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        PalletHeader: Record "Pallet Header";
        DispatchText: Text;
        PalletLine: Record "Pallet Line";
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
        FirstLine: text;
        SecondLine: Text;
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
                if boolFilterPallet then
                    WarehousePallet.SetRange("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        DispatchText := '';
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then begin
                                StickerPrinter.reset;
                                StickerPrinter.setrange("User Code", UserId);
                                StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Dispatch Type Code");
                                StickerPrinter.setrange("Sticker Note Format", CustomerRec."Dispatch Format Code");
                                StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                if StickerPrinter.findfirst then begin
                                    FirstLine := '%BTW% /AF="' +
                                                StickerPrinter."Sticker Format Name(BTW)" +
                                                '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                                                format(CustomerRec."Dispatch Format No. of Copies");
                                    SecondLine := '%END%';
                                    PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";
                                    LabelFormat := CustomerRec."Dispatch Format Description";
                                end;

                                FileName := 'DispatchLabel_' + WarehouseShipmentLine."No." +
                                    '_' + format(WarehouseShipmentLine."Line No.") +
                                    '_' + WarehousePallet."Lot No." + '.txt';

                                TempBlob.CreateOutStream(OutStr);

                                PalletHeader.get(WarehousePallet."Pallet ID");

                                OutStr.WriteText(FirstLine);
                                OutStr.WriteText();
                                OutStr.WriteText(SecondLine);
                                OutStr.WriteText();

                                DispatchText += PalletHeader."Pallet ID" + Splitter +
                                                    format(PalletHeader."Pallet Status") + Splitter +
                                                    PalletHeader."Location Code" + Splitter +
                                                    format(PalletHeader."Creation Date") + Splitter +
                                                    PalletHeader."User Created" + Splitter +
                                                    format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                    format(PalletHeader."Raw Material Pallet") + Splitter +
                                                    PalletHeader."Pallet Type" + Splitter +
                                                    format(PalletHeader."Disposal Status") + Splitter;
                            end;

                        PalletLine.reset;
                        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                        if PalletLine.findset then
                            repeat
                                DispatchText += format(PalletLine."Line No.") + Splitter +
                                                    PalletLine."Item No." + Splitter +
                                                    PalletLine."Variant Code" + Splitter +
                                                    PalletLine.Description + Splitter +
                                                    PalletLine."Lot Number" + Splitter +
                                                    PalletLine."Unit of Measure" + Splitter +
                                                    format(PalletLine.Quantity) + Splitter +
                                                    format(PalletLine."QTY Consumed") + Splitter +
                                                    format(PalletLine."Remaining Qty") + Splitter +
                                                    format(PalletLine."Expiration Date") + Splitter;
                                if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                    PalletLine."Purchase Order No.") then begin
                                    DispatchText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                      GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                      format(PurchaseHeader."Harvest Date") + splitter;
                                end;
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
                            DispatchText += ItemAttrText + Splitter;
                        end
                        else
                            DispatchTExt += Splitter;

                        DispatchText += SalesHeader."Sell-to Customer No." + Splitter +
                                        SalesHeader."Sell-to Customer Name" + Splitter +
                                        SalesHeader."No." + Splitter +
                                        format(SalesHeader."Requested Delivery Date") + Splitter +
                                        format(SalesHeader."document Date") + Splitter +
                                        format(SalesHeader."Pack-out Date") + Splitter +
                                        format(SalesHeader."Dispatch Date") + Splitter +
                                        format(SalesHeader."Promised Delivery Date") + Splitter +
                                        format(SalesHeader."due Date") + Splitter +
                                        format(SalesHeader."order Date") + Splitter +
                                        format(SalesHeader."Work Description") + Splitter;

                        DispatchText += CompanyText;
                        OutStr.WriteText(DispatchText);
                        Outstr.WriteText();
                        OutStr.WriteText(GetVendorShipmentNo(WarehousePallet));
                        TempBlob.CreateInStream(InStr);
                        BearerToken := OneDriveFunctions.GetBearerToken();
                        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);

                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
    end;

    //SSCC Label Sticker note
    procedure CreateSSCCStickerNote(pShipmentHeader: Record "Warehouse Shipment Header"; PalletNumber: Code[20]; boolFilterPallet: Boolean)
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
        GTIN_Text: Text;
        SSCCText: Text;
        FirstLine: Text;
        SecondLine: Text;

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
                if boolFilterPallet then
                    WarehousePallet.SetRange("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        SSCCText := '';
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then
                                if CustomerRec."SSCC Sticker Note" then begin
                                    StickerPrinter.reset;
                                    StickerPrinter.setrange("User Code", UserId);
                                    StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."SSCC Label Type Code");
                                    StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                    if StickerPrinter.findfirst then begin
                                        FirstLine := '%BTW% /AF="' +
                                                    StickerPrinter."Sticker Format Name(BTW)" +
                                                    '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                                                    format(PalletProcessSetup."SSCC Label No. of Copies");
                                        SecondLine := '%END%';
                                        PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";

                                        LabelFormat := StickerPrinter."Sticker Note type";
                                    end;
                                    FileName := 'SSCC_' + WarehouseShipmentLine."No." +
                                        '_' + format(WarehouseShipmentLine."Line No.") +
                                        '_' + WarehousePallet."Lot No." + '.txt';

                                    TempBlob.CreateOutStream(OutStr);

                                    OutStr.WriteText(FirstLine);
                                    OutStr.WriteText();
                                    OutStr.WriteText(SecondLine);
                                    OutStr.WriteText();

                                    SSCCText += CompanyInformation.Name + Splitter + CompanyInformation.Address + Splitter;

                                    if ItemRec.get(WarehouseShipmentLine."Item No.") then
                                        GTIN_Text := PADSTR('', 14 - strlen(ItemRec.GTIN), '0') + ItemRec.GTIN;

                                    SSCCText += GTIN_Text;
                                    GTINText_Line2 := GTIN_Text;

                                    NumberOfCrates_Line3 := '99'; //Line 3
                                    SSCCText += NumberOfCrates_Line3;

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
                                    SSCCText += format(PackDate_Line5) + Splitter;

                                    SSCC_Text_Line6 := GenerateSSCC();
                                    SSCCText += SSCC_Text_Line6 + splitter;

                                    Barcode_Line1 := '02' + GTINText_Line2 + '15' + Packdate_Text + '37' + format(NumberOfCrates_Line3);
                                    Barcode_Line11 := '(02)' + GTINText_Line2 + '(15)' + Packdate_Text + '(37)' + format(NumberOfCrates_Line3);
                                    SSCCText += Barcode_Line1 + splitter;
                                    SSCCText += Barcode_Line11 + splitter;

                                    Barcode_Line2 := '00' + SSCC_Text_Line6;
                                    Barcode_Line21 := '(00)' + SSCC_Text_Line6;
                                    SSCCText += Barcode_Line2 + splitter;
                                    SSCCText += Barcode_Line21 + splitter;

                                    OutStr.WriteText(SSCCTExt);

                                    TempBlob.CreateInStream(InStr);
                                    BearerToken := OneDriveFunctions.GetBearerToken();
                                    OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);

                                end;

                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
    end;

    //Item Label Sticker Note
    procedure CreateItemLabelStickerNote(pShipmentHeader: Record "Warehouse Shipment Header"; PalletNumber: Code[20]; boolFilterPallet: Boolean)
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehousePallet: Record "Warehouse Pallet";
        PalletHeader: Record "Pallet Header";
        ItemText: Text;
        PalletLine: Record "Pallet Line";
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
        FirstLine: Text;
        SecondLine: Text;

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
                if boolFilterPallet then
                    WarehousePallet.SetRange("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.");
                        ItemText := '';
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then begin
                                //if CustomerRec."SSCC Sticker Note" then begin
                                StickerPrinter.reset;
                                StickerPrinter.setrange("User Code", UserId);
                                StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Item Label Type Code");
                                StickerPrinter.setrange("Sticker Note Format", CustomerRec."Item Label Format Code");
                                StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                if StickerPrinter.findfirst then begin
                                    FirstLine := '%BTW% /AF="' +
                                                StickerPrinter."Sticker Format Name(BTW)" +
                                                '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                                                format(PalletLine."Item Label No. of Copies");
                                    SecondLine := '%END%';
                                    PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";
                                    LabelFormat := CustomerRec."Item Label Format Description";
                                end;

                                FileName := 'ItemLabel_' + WarehouseShipmentLine."No." +
                                    '_' + format(WarehouseShipmentLine."Line No.") +
                                    '_' + WarehousePallet."Lot No." + '.txt';

                                TempBlob.CreateOutStream(OutStr);

                                PalletHeader.get(WarehousePallet."Pallet ID");

                                OutStr.WriteText(FirstLine);
                                OutStr.WriteText();
                                OutStr.WriteText(SecondLine);
                                OutStr.WriteText();

                                ItemText += PalletHeader."Pallet ID" + Splitter +
                                                    format(PalletHeader."Pallet Status") + Splitter +
                                                    PalletHeader."Location Code" + Splitter +
                                                    format(PalletHeader."Creation Date") + Splitter +
                                                    PalletHeader."User Created" + Splitter +
                                                    format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                    format(PalletHeader."Raw Material Pallet") + Splitter +
                                                    PalletHeader."Pallet Type" + Splitter +
                                                    format(PalletHeader."Disposal Status") + Splitter;
                            end;

                        PalletLine.reset;
                        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                        if PalletLine.findset then
                            repeat
                                ItemText += format(PalletLine."Line No.") + Splitter +
                                                    PalletLine."Item No." + Splitter +
                                                    PalletLine."Variant Code" + Splitter +
                                                    PalletLine.Description + Splitter +
                                                    PalletLine."Lot Number" + Splitter +
                                                    PalletLine."Unit of Measure" + Splitter +
                                                    format(PalletLine.Quantity) + Splitter +
                                                    format(PalletLine."QTY Consumed") + Splitter +
                                                    format(PalletLine."Remaining Qty") + Splitter +
                                                    format(PalletLine."Expiration Date") + splitter;
                                if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                    PalletLine."Purchase Order No.") then begin
                                    ItemText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                      GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                      format(PurchaseHeader."Harvest Date");
                                end;
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
                            ItemText += ItemAttrText;
                        end
                        else
                            ItemText += splitter;

                        ItemText += SalesHeader."Sell-to Customer No." + Splitter +
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
                        ItemText += CompanyText;

                        OutStr.WriteText(ItemText);
                        Outstr.WriteText();
                        OutStr.WriteText(GetVendorShipmentNo(WarehousePallet));
                        TempBlob.CreateInStream(InStr);
                        BearerToken := OneDriveFunctions.GetBearerToken();
                        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);

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

    Procedure GetVendorShipmentNo(var pWarehousePallet: Record "Warehouse Pallet"): code[35]
    var
        PurchaseHeader: Record "Purchase Header";
        PalletLine: Record "Pallet Line";
    begin
        if PalletLine.get(pWarehousePallet."Pallet ID", pWarehousePallet."Pallet Line No.") then begin
            PurchaseHeader.reset;
            PurchaseHeader.setrange("Document Type", PurchaseHeader."Document Type"::Order);
            PurchaseHeader.setrange("Batch Number", PalletLine."Lot Number");
            if PurchaseHeader.findfirst then
                exit(PurchaseHeader."Vendor Shipment No.");
        end;
    end;
}