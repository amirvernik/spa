codeunit 60035 "Sticker note functions"
{
    //Pallet Label - Sticker Note
    procedure CreatePalletStickerNoteFromPallet(var PalletHeader: Record "Pallet Header")
    var
        PalletFunctions: Codeunit "Pallet Functions";
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
            // end else
            //    Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

            FileName := 'Pallet_Label_' + PalletHeader."Pallet ID" + '.txt';
            OutStr.WriteText(Firstline);
            OutStr.WriteText();
            OutStr.WriteText(SecondLine);
            OutStr.WriteText();

            PalletText := PalletHeader."Pallet ID" + Splitter +
                                format(PalletHeader."Pallet Status") + Splitter +
                                PalletHeader."Location Code" + Splitter +
                                format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
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
                                        format(PalletLine."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                        PalletFunctions.GetFirstPO(PalletHeader) + splitter +
                                        PalletFunctions.GetVendorShipmentNoFromPalletLine(PalletLine) + splitter;

                until PalletLine.next = 0;
            OutStr.WriteText(PalletText);
            TempBlob.CreateInStream(InStr);
            BearerToken := OneDriveFunctions.GetBearerToken();
            OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
        end;
    end;

    procedure CreatePalletStickerNoteFromShipment(var ShipmentHeader: Record "Warehouse Shipment Header"; BCorUI: text[2])
    var
        TypeOfPO: Label 'All,SSCC Label,Dispatch Label,Item Label';
        Selection: integer;
    begin
        Selection := STRMENU(TypeOfPO, 1, 'Please select the Desired format');
        if selection = 1 then begin
            CreateSSCCStickernote(ShipmentHeader, '', false, BCorUI); //SSCC Label Sticker note
            CreateDispatchStickerNote(ShipmentHeader, '', false, BCorUI); //Dispatch Label Sticker note
            CreateItemLabelStickerNote(ShipmentHeader, '', false, BCorUI); //Item Label Sticker Note
            message('All Warehouse Shipment Sticker notes sent to Printer');
        end;
        if selection = 2 then begin
            CreateSSCCStickernote(ShipmentHeader, '', false, BCorUI); //SSCC Label Sticker note
            message('SSCC Label Sticker note sent to Printer');
        end;

        if selection = 3 then begin
            CreateDispatchStickerNote(ShipmentHeader, '', false, BCorUI); //Dispatch Label Sticker note
            message('Dispatch Label Sticker note sent to Printer');
        end;

        if selection = 4 then begin
            CreateItemLabelStickerNote(ShipmentHeader, '', false, BCorUI); //Item Label Sticker Note
            message('Item Label Sticker note sent to Printer');
        end;


    end;


    procedure CreatePalletStickerNoteFromShipmentNEW(var ShipmentHeader: Record "Warehouse Shipment Header"; pPalletText: Text; BCorUI: text[2])
    var
        TypeOfPO: Label 'All,SSCC Label,Dispatch Label,Item Label';
        Selection: integer;
    begin
        Selection := STRMENU(TypeOfPO, 1, 'Please select the Desired format');
        if selection = 1 then begin
            CreateSSCCStickernote(ShipmentHeader, pPalletText, true, BCorUI); //SSCC Label Sticker note
            CreateDispatchStickerNote(ShipmentHeader, pPalletText, true, BCorUI); //Dispatch Label Sticker note
            CreateItemLabelStickerNote(ShipmentHeader, pPalletText, true, BCorUI); //Item Label Sticker Note
            message('All Warehouse Shipment Sticker notes sent to Printer');
        end;
        if selection = 2 then begin
            CreateSSCCStickernote(ShipmentHeader, pPalletText, true, BCorUI); //SSCC Label Sticker note
            message('SSCC Label Sticker note sent to Printer');
        end;

        if selection = 3 then begin
            CreateDispatchStickerNote(ShipmentHeader, pPalletText, true, BCorUI); //Dispatch Label Sticker note
            message('Dispatch Label Sticker note sent to Printer');
        end;

        if selection = 4 then begin
            CreateItemLabelStickerNote(ShipmentHeader, pPalletText, true, BCorUI); //Item Label Sticker Note
            message('Item Label Sticker note sent to Printer');
        end;


    end;

    procedure CreatePalletStickerNoteFromPostedShipment(var ShipmentHeader: Record "Posted Whse. Shipment Header"; BCorUI: text[2])
    var
        TypeOfPO: Label 'All,SSCC Label,Dispatch Label,Item Label';
        Selection: integer;
    begin
        Selection := STRMENU(TypeOfPO, 1, 'Please select the Desired format');
        if selection = 1 then begin
            CreatePostedSSCCStickernote(ShipmentHeader, '', false, BCorUI); //SSCC Label Sticker note
            CreatePostedDispatchStickerNote(ShipmentHeader, '', false); //Dispatch Label Sticker note
            CreatePostedItemLabelStickerNote(ShipmentHeader, '', false); //Item Label Sticker Note
            message('All Warehouse Shipment Sticker notes sent to Printer');
        end;
        if selection = 2 then begin
            CreatePostedSSCCStickernote(ShipmentHeader, '', false, BCorUI); //SSCC Label Sticker note
            message('SSCC Label Sticker note sent to Printer');
        end;

        if selection = 3 then begin
            CreatePostedDispatchStickerNote(ShipmentHeader, '', false); //Dispatch Label Sticker note
            message('Dispatch Label Sticker note sent to Printer');
        end;

        if selection = 4 then begin
            CreatePostedItemLabelStickerNote(ShipmentHeader, '', false); //Item Label Sticker Note
            message('Item Label Sticker note sent to Printer');
        end;


    end;


    procedure CreatePalletStickerNoteFromPostedShipmentNEW(var ShipmentHeader: Record "Posted Whse. Shipment Header"; PalletText: Text; BCorUI: text[2])
    var
        TypeOfPO: Label 'All,SSCC Label,Dispatch Label,Item Label';
        Selection: integer;
    begin
        Selection := STRMENU(TypeOfPO, 1, 'Please select the Desired format');
        if selection = 1 then begin
            CreatePostedSSCCStickernote(ShipmentHeader, PalletText, true, BCorUI); //SSCC Label Sticker note
            CreatePostedDispatchStickerNote(ShipmentHeader, PalletText, true); //Dispatch Label Sticker note
            CreatePostedItemLabelStickerNote(ShipmentHeader, PalletText, true); //Item Label Sticker Note
            message('All Warehouse Shipment Sticker notes sent to Printer');
        end;
        if selection = 2 then begin
            CreatePostedSSCCStickernote(ShipmentHeader, PalletText, true, BCorUI); //SSCC Label Sticker note
            message('SSCC Label Sticker note sent to Printer');
        end;

        if selection = 3 then begin
            CreatePostedDispatchStickerNote(ShipmentHeader, PalletText, true); //Dispatch Label Sticker note
            message('Dispatch Label Sticker note sent to Printer');
        end;

        if selection = 4 then begin
            CreatePostedItemLabelStickerNote(ShipmentHeader, PalletText, true); //Item Label Sticker Note
            message('Item Label Sticker note sent to Printer');
        end;


    end;


    //Dispatch Label - Sticker note - WarehouseShipmentLine
    procedure CreateDispatchStickerNote(pShipmentHeader: Record "Warehouse Shipment Header"; PalletNumber: Text; boolFilterPallet: Boolean; BCorUI: text[2])
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
        ItemCrossRef: Record "Item Cross Reference";
        LPalletHeaderText: Text;
        LFooterText: Text;
        PalletLineTemp: Record "Pallet Line" temporary;
        LPalletsText: Text;
        SumQty: Text;
        StringCross: Text;
    begin
        CompanyInformation.get;
        CompanyText := CompanyInformation.name + Splitter +
                     CompanyInformation.address + Splitter +
                     CompanyInformation."E-Mail" + splitter +
                     CompanyInformation."Phone No." + Splitter;
        FileName := '';
        PalletProcessSetup.get;
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", pShipmentHeader."No.");
        if WarehouseShipmentLine.findset then
            repeat
                WarehousePallet.reset;
                WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentLine."No.");
                WarehousePallet.setrange("Whse Shipment Line No.", WarehouseShipmentLine."Line No.");
                // WarehousePallet.setrange(Printed, false);
                if boolFilterPallet then
                    WarehousePallet.SetFilter("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat


                        if not ((WarehousePallet.Printed) and (BCorUI = 'UI')) then begin
                            DispatchText := '';
                            if not (StrPos(LPalletsText, WarehousePallet."Pallet ID") > 0) then begin
                                LPalletsText += WarehousePallet."Pallet ID" + '|';
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
                                            // end else
                                            //    Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                            FileName := 'DispatchLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(WarehousePallet."Pallet Line No.") + '.txt';

                                            TempBlob.CreateOutStream(OutStr);

                                            PalletHeader.get(WarehousePallet."Pallet ID");

                                            OutStr.WriteText(FirstLine);
                                            OutStr.WriteText();
                                            OutStr.WriteText(SecondLine);
                                            OutStr.WriteText();


                                            LPalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                    format(PalletHeader."Pallet Status") + Splitter +
                                                    PalletHeader."Location Code" + Splitter +
                                                    format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    PalletHeader."User Created" + Splitter +
                                                    format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                    format(PalletHeader."Raw Material Pallet") + Splitter +
                                                    PalletHeader."Pallet Type" + Splitter +
                                                    format(PalletHeader."Disposal Status") + Splitter;

                                            SumQty := '';
                                            StringCross := '';

                                            PalletLineTemp.Reset();
                                            if PalletLineTemp.FindSet() then
                                                PalletLineTemp.DeleteAll(false);

                                            PalletLine.reset;
                                            PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                                            if PalletLine.findset then
                                                repeat
                                                    PalletLineTemp.reset;
                                                    PalletLineTemp.setrange("Pallet ID", PalletHeader."Pallet ID");
                                                    PalletLineTemp.setrange("Item No.", PalletLine."Item No.");
                                                    PalletLineTemp.setrange("Variant Code", PalletLine."Variant Code");
                                                    PalletLineTemp.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                                    if not PalletLineTemp.findfirst then begin
                                                        ItemCrossRef.reset;
                                                        ItemCrossRef.setrange("Item No.", PalletLine."Item No.");
                                                        ItemCrossRef.setrange("Variant Code", PalletLine."Variant Code");
                                                        ItemCrossRef.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                                        ItemCrossRef.SetRange(ItemCrossRef."Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::Customer);
                                                        ItemCrossRef.SetRange("Cross-Reference type No.", salesheader."Sell-to Customer No.");
                                                        if ItemCrossRef.findfirst then
                                                            if StringCross = '' then
                                                                StringCross += ItemCrossRef.Description
                                                            else
                                                                StringCross += ',' + ItemCrossRef.Description;
                                                        PalletLineTemp.init;
                                                        palletlinetemp.TransferFields(PalletLine);
                                                        PalletLineTemp.insert;
                                                    end else begin
                                                        PalletLineTemp.Quantity += PalletLine.Quantity;
                                                        PalletLineTemp.Modify();
                                                    end;
                                                until PalletLine.next = 0;

                                            PalletLineTemp.reset;
                                            PalletLineTemp.setrange(PalletLineTemp."Pallet ID", PalletHeader."Pallet ID");
                                            if PalletLineTemp.FindSet() then
                                                repeat
                                                    if SumQty = '' then
                                                        SumQty += format(PalletLineTemp.Quantity)
                                                    else
                                                        SumQty += ',' + format(PalletLineTemp.Quantity);
                                                until PalletLineTemp.Next() = 0;

                                            LFooterText := '';
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
                                                LFooterText += ItemAttrText + Splitter;
                                            end
                                            else
                                                LFooterText += Splitter;

                                            LFooterText += SalesHeader."Sell-to Customer No." + Splitter +
                                                            SalesHeader."Sell-to Customer Name" + Splitter +
                                                            SalesHeader."No." + Splitter +
                                                            format(SalesHeader."Requested Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."document Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."Pack-out Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."Dispatch Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."Promised Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."due Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."order Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                            format(SalesHeader."Work Description") + Splitter +
                                                            salesheader."External Document No." + splitter +
                                                            GetVendorShipmentNo(WarehousePallet) + splitter;
                                            LFooterText += StringCross + Splitter;
                                            LFooterText += CompanyText;


                                            OutStr.WriteText('');
                                            DispatchText := LPalletHeaderText;
                                            PalletLineTemp.reset;
                                            PalletLineTemp.setrange(PalletLineTemp."Pallet ID", PalletHeader."Pallet ID");
                                            if PalletLineTemp.FindFirst() then begin
                                                DispatchText += format(PalletLineTemp."Line No.") + Splitter +
                                                                    PalletLineTemp."Item No." + Splitter +
                                                                    PalletLineTemp."Variant Code" + Splitter +
                                                                    PalletLineTemp.Description + Splitter +
                                                                    PalletLineTemp."Lot Number" + Splitter +
                                                                    PalletLineTemp."Unit of Measure" + Splitter +
                                                                    SumQty + Splitter +
                                                                    format(PalletLineTemp."QTY Consumed") + Splitter +
                                                                    format(PalletLineTemp."Remaining Qty") + Splitter +
                                                                    format(PalletLineTemp."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter;
                                                if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                                    PalletLineTemp."Purchase Order No.") then begin
                                                    DispatchText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                                      GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                                      format(PurchaseHeader."Harvest Date") + splitter;
                                                end;
                                            end;
                                            DispatchText += LFooterText;
                                            OutStr.WriteText(DispatchText);
                                            TempBlob.CreateInStream(InStr);
                                            BearerToken := OneDriveFunctions.GetBearerToken();
                                            OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                        end;
                                    end;
                            end;
                        end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;


    end;


    //Dispatch Label - Sticker note -Posted WarehouseShipmentLine
    procedure CreatePostedDispatchStickerNote(pShipmentHeader: Record "Posted Whse. Shipment Header";
                PalletNumber: Text;
                boolFilterPallet: Boolean)
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Posted Whse. Shipment Line";
        WarehousePallet: Record "Posted Warehouse Pallet";
        PalletHeader: Record "Pallet Header";
        DispatchText: Text;
        PalletLine: Record "Pallet Line";
        SalesHeader: Record "Sales Header";
        SalesArchiveHeader: Record "Sales Header Archive";
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
        SumQty: Text;
        StringCross: text;
        BearerToken: text;
        OneDriveFunctions: Codeunit "OneDrive Functions";
        FirstLine: text;
        SecondLine: Text;
        ItemCrossRef: Record "Item Cross Reference";
        LPalletHeaderText: Text;
        LFooterText: Text;
        PalletLineTemp: Record "Pallet Line" temporary;
        LPalletsText: Text;
    begin
        CompanyInformation.get;
        CompanyText := CompanyInformation.name + Splitter +
                     CompanyInformation.address + Splitter +
                     CompanyInformation."E-Mail" + splitter +
                     CompanyInformation."Phone No." + Splitter;
        FileName := '';
        PalletProcessSetup.get;
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", pShipmentHeader."No.");
        if WarehouseShipmentLine.findset then
            repeat
                LPalletsText := '';
                WarehousePallet.reset;
                WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentLine."No.");
                WarehousePallet.setrange("Whse Shipment Line No.", WarehouseShipmentLine."Line No.");
                if boolFilterPallet then
                    WarehousePallet.SetFilter("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        if not (StrPos(LPalletsText, WarehousePallet."Pallet ID") > 0) then begin
                            LPalletsText += WarehousePallet."Pallet ID" + '|';
                            DispatchText := '';
                            if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then begin
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
                                        // end else
                                        //    Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                        FileName := 'DispatchLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(WarehousePallet."Pallet Line No.") + '.txt';


                                        TempBlob.CreateOutStream(OutStr);

                                        PalletHeader.get(WarehousePallet."Pallet ID");

                                        OutStr.WriteText(FirstLine);
                                        OutStr.WriteText();
                                        OutStr.WriteText(SecondLine);
                                        OutStr.WriteText();


                                        LPalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                format(PalletHeader."Pallet Status") + Splitter +
                                                PalletHeader."Location Code" + Splitter +
                                                format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                PalletHeader."User Created" + Splitter +
                                                format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                format(PalletHeader."Raw Material Pallet") + Splitter +
                                                PalletHeader."Pallet Type" + Splitter +
                                                format(PalletHeader."Disposal Status") + Splitter;

                                        SumQty := '';
                                        StringCross := '';

                                        PalletLineTemp.Reset();
                                        if PalletLineTemp.FindSet() then
                                            PalletLineTemp.DeleteAll(false);

                                        PalletLine.reset;
                                        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                                        if PalletLine.findset then
                                            repeat
                                                PalletLineTemp.reset;
                                                PalletLineTemp.setrange("Pallet ID", PalletHeader."Pallet ID");
                                                PalletLineTemp.setrange("Item No.", PalletLine."Item No.");
                                                PalletLineTemp.setrange("Variant Code", PalletLine."Variant Code");
                                                PalletLineTemp.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                                if not PalletLineTemp.findfirst then begin
                                                    ItemCrossRef.reset;
                                                    ItemCrossRef.setrange("Item No.", PalletLine."Item No.");
                                                    ItemCrossRef.setrange("Variant Code", PalletLine."Variant Code");
                                                    ItemCrossRef.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                                    ItemCrossRef.SetRange(ItemCrossRef."Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::Customer);
                                                    ItemCrossRef.SetRange("Cross-Reference type No.", salesheader."Sell-to Customer No.");
                                                    if ItemCrossRef.findfirst then
                                                        if StringCross = '' then
                                                            StringCross += ItemCrossRef.Description
                                                        else
                                                            StringCross += ',' + ItemCrossRef.Description;
                                                    PalletLineTemp.init;
                                                    palletlinetemp.TransferFields(PalletLine);
                                                    PalletLineTemp.insert;
                                                end else begin
                                                    PalletLineTemp.Quantity += PalletLine.Quantity;
                                                    PalletLineTemp.Modify();
                                                end;
                                            until PalletLine.next = 0;

                                        PalletLineTemp.reset;
                                        PalletLineTemp.setrange(PalletLineTemp."Pallet ID", PalletHeader."Pallet ID");
                                        if PalletLineTemp.FindSet() then
                                            repeat
                                                if SumQty = '' then
                                                    SumQty += format(PalletLineTemp.Quantity)
                                                else
                                                    SumQty += ',' + format(PalletLineTemp.Quantity);
                                            until PalletLineTemp.Next() = 0;

                                        LFooterText := '';
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
                                            LFooterText += ItemAttrText + Splitter;
                                        end
                                        else
                                            LFooterText += Splitter;

                                        LFooterText += SalesHeader."Sell-to Customer No." + Splitter +
                                                        SalesHeader."Sell-to Customer Name" + Splitter +
                                                        SalesHeader."No." + Splitter +
                                                        format(SalesHeader."Requested Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."document Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Pack-out Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Dispatch Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Promised Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."due Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."order Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Work Description") + Splitter +
                                                        salesheader."External Document No." + splitter +
                                                        GetVendorShipmentNo_Posted(WarehousePallet) + splitter;
                                        LFooterText += StringCross + Splitter;
                                        LFooterText += CompanyText;


                                        OutStr.WriteText('');
                                        DispatchText := LPalletHeaderText;
                                        PalletLineTemp.reset;
                                        PalletLineTemp.setrange(PalletLineTemp."Pallet ID", PalletHeader."Pallet ID");
                                        if PalletLineTemp.FindFirst() then begin
                                            DispatchText += format(PalletLineTemp."Line No.") + Splitter +
                                                                PalletLineTemp."Item No." + Splitter +
                                                                PalletLineTemp."Variant Code" + Splitter +
                                                                PalletLineTemp.Description + Splitter +
                                                                PalletLineTemp."Lot Number" + Splitter +
                                                                PalletLineTemp."Unit of Measure" + Splitter +
                                                                SumQty + Splitter +
                                                                format(PalletLineTemp."QTY Consumed") + Splitter +
                                                                format(PalletLineTemp."Remaining Qty") + Splitter +
                                                                format(PalletLineTemp."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter;
                                            if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                                PalletLineTemp."Purchase Order No.") then begin
                                                DispatchText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                                  GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                                  format(PurchaseHeader."Harvest Date") + splitter;
                                            end;
                                        end;
                                        DispatchText += LFooterText;
                                        OutStr.WriteText(DispatchText);
                                        TempBlob.CreateInStream(InStr);
                                        BearerToken := OneDriveFunctions.GetBearerToken();
                                        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                    end;
                                end;
                            end else begin
                                if SalesArchiveHeader.get(SalesArchiveHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then begin
                                    if CustomerRec.get(SalesArchiveHeader."Sell-to Customer No.") then begin
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
                                            //end else
                                            //   Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                            FileName := 'DispatchLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(WarehousePallet."Pallet Line No.") + '.txt';


                                            TempBlob.CreateOutStream(OutStr);

                                            PalletHeader.get(WarehousePallet."Pallet ID");

                                            OutStr.WriteText(FirstLine);
                                            OutStr.WriteText();
                                            OutStr.WriteText(SecondLine);
                                            OutStr.WriteText();

                                        end;
                                        LPalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                format(PalletHeader."Pallet Status") + Splitter +
                                                PalletHeader."Location Code" + Splitter +
                                                format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                PalletHeader."User Created" + Splitter +
                                                format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                format(PalletHeader."Raw Material Pallet") + Splitter +
                                                PalletHeader."Pallet Type" + Splitter +
                                                format(PalletHeader."Disposal Status") + Splitter;

                                        SumQty := '';
                                        StringCross := '';

                                        PalletLineTemp.Reset();
                                        if PalletLineTemp.FindSet() then
                                            PalletLineTemp.DeleteAll(false);

                                        PalletLine.reset;
                                        PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
                                        if PalletLine.findset then
                                            repeat
                                                PalletLineTemp.reset;
                                                PalletLineTemp.setrange("Pallet ID", PalletHeader."Pallet ID");
                                                PalletLineTemp.setrange("Item No.", PalletLine."Item No.");
                                                PalletLineTemp.setrange("Variant Code", PalletLine."Variant Code");
                                                PalletLineTemp.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                                if not PalletLineTemp.findfirst then begin
                                                    ItemCrossRef.reset;
                                                    ItemCrossRef.setrange("Item No.", PalletLine."Item No.");
                                                    ItemCrossRef.setrange("Variant Code", PalletLine."Variant Code");
                                                    ItemCrossRef.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                                    ItemCrossRef.SetRange(ItemCrossRef."Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::Customer);
                                                    ItemCrossRef.SetRange("Cross-Reference type No.", SalesArchiveHeader."Sell-to Customer No.");
                                                    if ItemCrossRef.findfirst then
                                                        if StringCross = '' then
                                                            StringCross += ItemCrossRef.Description
                                                        else
                                                            StringCross += ',' + ItemCrossRef.Description;
                                                    PalletLineTemp.init;
                                                    palletlinetemp.TransferFields(PalletLine);
                                                    PalletLineTemp.insert;
                                                end else begin
                                                    PalletLineTemp.Quantity += PalletLine.Quantity;
                                                    PalletLineTemp.Modify();
                                                end;
                                            until PalletLine.next = 0;

                                        PalletLineTemp.reset;
                                        PalletLineTemp.setrange(PalletLineTemp."Pallet ID", PalletHeader."Pallet ID");
                                        if PalletLineTemp.FindSet() then
                                            repeat
                                                if SumQty = '' then
                                                    SumQty += format(PalletLineTemp.Quantity)
                                                else
                                                    SumQty += ',' + format(PalletLineTemp.Quantity);
                                            until PalletLineTemp.Next() = 0;

                                        LFooterText := '';
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
                                            LFooterText += ItemAttrText + Splitter;
                                        end
                                        else
                                            LFooterText += Splitter;

                                        LFooterText += SalesArchiveHeader."Sell-to Customer No." + Splitter +
                                                        SalesArchiveHeader."Sell-to Customer Name" + Splitter +
                                                        SalesArchiveHeader."No." + Splitter +
                                                        format(SalesArchiveHeader."Requested Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."document Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Pack-out Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Dispatch Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Promised Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."due Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."order Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Work Description") + Splitter +
                                                        SalesArchiveHeader."External Document No." + splitter +
                                                        GetVendorShipmentNo_Posted(WarehousePallet) + splitter;
                                        LFooterText += StringCross + Splitter;
                                        LFooterText += CompanyText;


                                        OutStr.WriteText('');
                                        DispatchText := LPalletHeaderText;
                                        PalletLineTemp.reset;
                                        PalletLineTemp.setrange(PalletLineTemp."Pallet ID", PalletHeader."Pallet ID");
                                        if PalletLineTemp.FindFirst() then
                                            DispatchText += format(PalletLineTemp."Line No.") + Splitter +
                                                                PalletLineTemp."Item No." + Splitter +
                                                                PalletLineTemp."Variant Code" + Splitter +
                                                                PalletLineTemp.Description + Splitter +
                                                                PalletLineTemp."Lot Number" + Splitter +
                                                                PalletLineTemp."Unit of Measure" + Splitter +
                                                                SumQty + Splitter +
                                                                format(PalletLineTemp."QTY Consumed") + Splitter +
                                                                format(PalletLineTemp."Remaining Qty") + Splitter +
                                                                format(PalletLineTemp."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter;
                                        if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                            PalletLineTemp."Purchase Order No.") then begin
                                            DispatchText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                              GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                              format(PurchaseHeader."Harvest Date") + splitter;
                                        end;

                                        DispatchText += LFooterText;
                                        OutStr.WriteText(DispatchText);
                                        TempBlob.CreateInStream(InStr);
                                        BearerToken := OneDriveFunctions.GetBearerToken();
                                        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                    end;
                                end;
                            end;
                        end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;


    end;


    //SSCC Label Sticker note
    procedure CreateSSCCStickerNote(pShipmentHeader: Record "Warehouse Shipment Header";
                PalletNumber: Text;
                boolFilterPallet: Boolean;
                BCorUI: Text[2])
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
        PalletLine: Record "Pallet Line";
        PalletHeader: Record "Pallet Header";
        LLabelDate: date;
        LPalletsText: Text;
        TotalQty: Decimal;
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
                // WarehousePallet.setrange(Printed, false);
                if boolFilterPallet then
                    WarehousePallet.SetFilter("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        if not ((WarehousePallet.Printed) and (BCorUI = 'UI')) then begin
                            if not (StrPos(LPalletsText, WarehousePallet."Pallet ID") > 0) then begin
                                LPalletsText += WarehousePallet."Pallet ID" + '|';
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
                                                // end else
                                                //    Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                                FileName := 'SSCCLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(WarehousePallet."Pallet Line No.") + '.txt';

                                                TempBlob.CreateOutStream(OutStr);

                                                OutStr.WriteText(FirstLine);
                                                OutStr.WriteText();
                                                OutStr.WriteText(SecondLine);
                                                OutStr.WriteText();

                                                SSCCText += CompanyInformation.Name + Splitter + CompanyInformation.Address + Splitter;

                                                if ItemRec.get(WarehouseShipmentLine."Item No.") then
                                                    //GTIN_Text := PADSTR('', 14 - strlen(ItemRec.GTIN), '0') + ItemRec.GTIN; removed by Braden
                                                    GTIN_Text := ItemRec.GTIN;

                                                SSCCText += GTIN_Text + Splitter;
                                                GTINText_Line2 := GTIN_Text;

                                                //NumberOfCrates_Line3 := '99'; //Line 3
                                                //no of crates changed to quantity on the pallet line
                                                //if PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.") then
                                                PalletHeader.get(WarehousePallet."Pallet ID");
                                                TotalQty := 0;
                                                PalletLine.reset;
                                                PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                                if PalletLine.findset then
                                                    repeat
                                                        TotalQty += PalletLine.Quantity;
                                                    until PalletLine.Next() = 0;

                                                PalletLine.reset;
                                                PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                                if not PalletLine.FindFirst() then;
                                                NumberOfCrates_Line3 := format(TotalQty);
                                                SSCCText += NumberOfCrates_Line3 + splitter;

                                                //Removed by ask of braden
                                                /*PackDate_Line5 := DMY2Date(31, 12, 3999); //Line 5

                                                if SalesHeader."Posting Date" < PackDate_Line5 then
                                                    PackDate_Line5 := SalesHeader."Posting Date";
                                                if SalesHeader."Pack-out Date" < PackDate_Line5 then
                                                    PackDate_Line5 := SalesHeader."Pack-out Date";
                                                if SalesHeader."Document Date" < PackDate_Line5 then
                                                    PackDate_Line5 := SalesHeader."Document Date";
                                                if SalesHeader."Dispatch Date" < PackDate_Line5 then
                                                    PackDate_Line5 := SalesHeader."Dispatch Date";*/

                                                if SalesHeader."Pack-out Date" <= PalletHeader."Creation Date" then
                                                    LLabelDate := PalletHeader."Creation Date"
                                                else
                                                    LLabelDate := SalesHeader."Pack-out Date";

                                                PackDate_Line5 := LLabelDate;

                                                Packdate_Text := format(Date2DMY(PackDate_Line5, 3) - 2000) +
                                                                PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                                                PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 1));
                                                /*Packdate_Text := PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 1)) +
                                                                PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                                                format(Date2DMY(PackDate_Line5, 3) - 2000);*/

                                                //SSCCText += format(PackDate_Line5) + Splitter;
                                                SSCCText += format(Packdate_Text) + Splitter;


                                                SSCC_Text_Line6 := GenerateSSCC();
                                                SSCCText += SSCC_Text_Line6 + splitter;

                                                Barcode_Line1 := '02' + GTINText_Line2 + '13' + Packdate_Text + '37' + format(NumberOfCrates_Line3);
                                                Barcode_Line11 := '(02)' + GTINText_Line2 + '(13)' + Packdate_Text + '(37)' + format(NumberOfCrates_Line3);
                                                SSCCText += Barcode_Line1 + splitter;
                                                SSCCText += Barcode_Line11 + splitter;

                                                Barcode_Line2 := '00' + SSCC_Text_Line6;
                                                Barcode_Line21 := '(00)' + SSCC_Text_Line6;
                                                SSCCText += Barcode_Line2 + splitter;
                                                SSCCText += Barcode_Line21 + splitter;

                                                SSCCText += PalletLine."Item No." + splitter +
                                                            PalletLine."Variant Code" + Splitter +
                                                            format(LLabelDate, 0, '<Day,2>/<Month,2>/<Year,2>') + splitter +
                                                            format(TotalQty) + splitter;

                                                OutStr.WriteText(SSCCTExt);

                                                TempBlob.CreateInStream(InStr);
                                                BearerToken := OneDriveFunctions.GetBearerToken();
                                                OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);

                                            end;
                                        end;
                            end;
                        end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
    end;


    //SSCC Label Sticker note - Posted
    procedure CreatePostedSSCCStickerNote(pShipmentHeader: Record "Posted Whse. Shipment Header";
                PalletNumber: Text;
                boolFilterPallet: Boolean;
                BCorUI: Text[2])
    var
        CompanyInformation: Record "Company Information";
        ItemRec: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        WarehouseShipmentLine: Record "Posted Whse. Shipment Line";
        WarehousePallet: Record "Posted Warehouse Pallet";
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
        PalletLine: Record "Pallet Line";
        PalletHeader: Record "Pallet Header";
        LLabelDate: Date;
        TotalQty: Decimal;
        LPalletsText: Text;
        ErrCustomerSetting: Label 'The SSCC label is not set to be printed for the specific customer';
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
                    WarehousePallet.SetFilter("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat

                        if not (StrPos(LPalletsText, WarehousePallet."Pallet ID") > 0) then begin
                            LPalletsText += WarehousePallet."Pallet ID" + '|';
                            SSCCText := '';
                            if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then begin
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
                                            // end else
                                            //    Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                            FileName := 'SSCCLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(WarehousePallet."Pallet Line No.") + '.txt';

                                            TempBlob.CreateOutStream(OutStr);

                                            OutStr.WriteText(FirstLine);
                                            OutStr.WriteText();
                                            OutStr.WriteText(SecondLine);
                                            OutStr.WriteText();

                                            SSCCText += CompanyInformation.Name + Splitter + CompanyInformation.Address + Splitter;

                                            if ItemRec.get(WarehouseShipmentLine."Item No.") then
                                                //GTIN_Text := PADSTR('', 14 - strlen(ItemRec.GTIN), '0') + ItemRec.GTIN; removed by Braden
                                                GTIN_Text := ItemRec.GTIN;

                                            SSCCText += GTIN_Text + Splitter;
                                            GTINText_Line2 := GTIN_Text;

                                            //NumberOfCrates_Line3 := '99'; //Line 3
                                            //no of crates changed to quantity on the pallet line
                                            //if PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.") then
                                            PalletHeader.get(WarehousePallet."Pallet ID");
                                            TotalQty := 0;
                                            PalletLine.reset;
                                            PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                            if PalletLine.findset then
                                                repeat
                                                    TotalQty += PalletLine.Quantity;
                                                until PalletLine.Next() = 0;

                                            PalletLine.reset;
                                            PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                            if not PalletLine.FindFirst() then
                                                NumberOfCrates_Line3 := format(TotalQty);
                                            SSCCText += NumberOfCrates_Line3 + splitter;

                                            //Removed by ask of braden
                                            /*PackDate_Line5 := DMY2Date(31, 12, 3999); //Line 5

                                            if SalesHeader."Posting Date" < PackDate_Line5 then
                                                PackDate_Line5 := SalesHeader."Posting Date";
                                            if SalesHeader."Pack-out Date" < PackDate_Line5 then
                                                PackDate_Line5 := SalesHeader."Pack-out Date";
                                            if SalesHeader."Document Date" < PackDate_Line5 then
                                                PackDate_Line5 := SalesHeader."Document Date";
                                            if SalesHeader."Dispatch Date" < PackDate_Line5 then
                                                PackDate_Line5 := SalesHeader."Dispatch Date";*/

                                            if SalesHeader."Pack-out Date" <= PalletHeader."Creation Date" then
                                                LLabelDate := PalletHeader."Creation Date"
                                            else
                                                LLabelDate := SalesHeader."Pack-out Date";

                                            PackDate_Line5 := LLabelDate;

                                            Packdate_Text := format(Date2DMY(PackDate_Line5, 3) - 2000) +
                                                            PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                                            PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 1));
                                            /*Packdate_Text := PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 1)) +
                                                            PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                                            format(Date2DMY(PackDate_Line5, 3) - 2000);*/

                                            //SSCCText += format(PackDate_Line5) + Splitter;
                                            SSCCText += format(Packdate_Text) + Splitter;


                                            SSCC_Text_Line6 := GenerateSSCC();
                                            SSCCText += SSCC_Text_Line6 + splitter;

                                            Barcode_Line1 := '02' + GTINText_Line2 + '13' + Packdate_Text + '37' + format(NumberOfCrates_Line3);
                                            Barcode_Line11 := '(02)' + GTINText_Line2 + '(13)' + Packdate_Text + '(37)' + format(NumberOfCrates_Line3);
                                            SSCCText += Barcode_Line1 + splitter;
                                            SSCCText += Barcode_Line11 + splitter;

                                            Barcode_Line2 := '00' + SSCC_Text_Line6;
                                            Barcode_Line21 := '(00)' + SSCC_Text_Line6;
                                            SSCCText += Barcode_Line2 + splitter;
                                            SSCCText += Barcode_Line21 + splitter;


                                            SSCCText += PalletLine."Item No." + splitter +
                                                        PalletLine."Variant Code" + Splitter +
                                                        format(LLabelDate, 0, '<Day,2>/<Month,2>/<Year,2>') + splitter +
                                                        format(TotalQty) + splitter;

                                            OutStr.WriteText(SSCCTExt);

                                            TempBlob.CreateInStream(InStr);
                                            BearerToken := OneDriveFunctions.GetBearerToken();
                                            OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                        end;
                                    end;// else
                                        //  if BCorUI = 'BC' then
                                        //    Message(ErrCustomerSetting);

                            end else begin
                                if SalesHeaderArchive.get(SalesHeaderArchive."Document Type"::Order, WarehouseShipmentLine."Source No.") then begin
                                    if CustomerRec.get(SalesHeaderArchive."Sell-to Customer No.") then
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
                                                //end else
                                                //    Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                                FileName := 'SSCCLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(WarehousePallet."Pallet Line No.") + '.txt';

                                                TempBlob.CreateOutStream(OutStr);

                                                OutStr.WriteText(FirstLine);
                                                OutStr.WriteText();
                                                OutStr.WriteText(SecondLine);
                                                OutStr.WriteText();

                                                SSCCText += CompanyInformation.Name + Splitter + CompanyInformation.Address + Splitter;

                                                if ItemRec.get(WarehouseShipmentLine."Item No.") then
                                                    //GTIN_Text := PADSTR('', 14 - strlen(ItemRec.GTIN), '0') + ItemRec.GTIN; removed by Braden
                                                    GTIN_Text := ItemRec.GTIN;

                                                SSCCText += GTIN_Text + Splitter;
                                                GTINText_Line2 := GTIN_Text;

                                                //NumberOfCrates_Line3 := '99'; //Line 3
                                                //no of crates changed to quantity on the pallet line
                                                //if PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.") then
                                                PalletHeader.get(WarehousePallet."Pallet ID");
                                                TotalQty := 0;
                                                PalletLine.reset;
                                                PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                                if PalletLine.findset then
                                                    repeat
                                                        TotalQty += PalletLine.Quantity;
                                                    until PalletLine.Next() = 0;

                                                PalletLine.reset;
                                                PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                                if not PalletLine.FindFirst() then;
                                                NumberOfCrates_Line3 := format(TotalQty);
                                                SSCCText += NumberOfCrates_Line3 + splitter;

                                                if SalesHeaderArchive."Pack-out Date" <= PalletHeader."Creation Date" then
                                                    LLabelDate := PalletHeader."Creation Date"
                                                else
                                                    LLabelDate := SalesHeaderArchive."Pack-out Date";

                                                PackDate_Line5 := LLabelDate;

                                                Packdate_Text := format(Date2DMY(PackDate_Line5, 3) - 2000) +
                                                                PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                                                PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 1));
                                                /*Packdate_Text := PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 1))), '0') + format(Date2DMY(PackDate_Line5, 1)) +
                                                                PADSTR('', 2 - strlen(format(Date2DMY(PackDate_Line5, 2))), '0') + format(Date2DMY(PackDate_Line5, 2)) +
                                                                format(Date2DMY(PackDate_Line5, 3) - 2000);*/

                                                //SSCCText += format(PackDate_Line5) + Splitter;
                                                SSCCText += format(Packdate_Text) + Splitter;


                                                SSCC_Text_Line6 := GenerateSSCC();
                                                SSCCText += SSCC_Text_Line6 + splitter;

                                                Barcode_Line1 := '02' + GTINText_Line2 + '13' + Packdate_Text + '37' + format(NumberOfCrates_Line3);
                                                Barcode_Line11 := '(02)' + GTINText_Line2 + '(13)' + Packdate_Text + '(37)' + format(NumberOfCrates_Line3);
                                                SSCCText += Barcode_Line1 + splitter;
                                                SSCCText += Barcode_Line11 + splitter;

                                                Barcode_Line2 := '00' + SSCC_Text_Line6;
                                                Barcode_Line21 := '(00)' + SSCC_Text_Line6;
                                                SSCCText += Barcode_Line2 + splitter;
                                                SSCCText += Barcode_Line21 + splitter;


                                                SSCCText += PalletLine."Item No." + splitter +
                                                            PalletLine."Variant Code" + Splitter +
                                                            format(LLabelDate, 0, '<Day,2>/<Month,2>/<Year,2>') + splitter +
                                                            format(TotalQty) + splitter;

                                                OutStr.WriteText(SSCCTExt);

                                                TempBlob.CreateInStream(InStr);
                                                BearerToken := OneDriveFunctions.GetBearerToken();
                                                OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                            end;// else
                                                // if BCorUI = 'BC' then
                                                //    Message(ErrCustomerSetting);
                                        end;
                                end;
                            end;
                        end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;
    end;


    //Item Label Sticker Note +
    procedure CreateItemLabelStickerNote(pShipmentHeader: Record "Warehouse Shipment Header";
                PalletNumber: Text;
                boolFilterPallet: Boolean;
                BCorUI: text[2])
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
        ItemCrossRef: Record "Item Cross Reference";
        LPalletHeaderText: Text;
        LFooterText: Text;
        LLabelDate: Date;
        // PalletLineTemp: Record "Pallet Line" temporary;
        LPalletsText: text;
        ErrCustomerSetting: Label 'The SSCC label is not set to be printed for the specific customer';
    begin
        CompanyInformation.get;
        CompanyText := CompanyInformation.name + Splitter +
                     CompanyInformation.address + Splitter +
                     CompanyInformation."E-Mail" + Splitter +
                     CompanyInformation."Phone No." + Splitter;
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
                    WarehousePallet.SetFilter("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        if not ((WarehousePallet.Printed) and (BCorUI = 'UI')) then begin
                            PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.");
                            ItemText := '';
                            if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then
                                if CustomerRec.get(SalesHeader."Sell-to Customer No.") then begin
                                    StickerPrinter.reset;
                                    StickerPrinter.setrange("User Code", UserId);
                                    StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Item Label Type Code");
                                    StickerPrinter.setrange("Sticker Note Format", CustomerRec."Item Label Format Code");
                                    StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                    if StickerPrinter.findfirst then begin
                                        PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";
                                        LabelFormat := CustomerRec."Item Label Format Description";
                                        // end else
                                        //     Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');
                                        // end;
                                        PalletHeader.get(WarehousePallet."Pallet ID");
                                        LPalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                                                               format(PalletHeader."Pallet Status") + Splitter +
                                                                                               PalletHeader."Location Code" + Splitter +
                                                                                               format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                                                               PalletHeader."User Created" + Splitter +
                                                                                               format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                                                               format(PalletHeader."Raw Material Pallet") + Splitter +
                                                                                               PalletHeader."Pallet Type" + Splitter +
                                                                                               format(PalletHeader."Disposal Status") + Splitter;

                                        LFooterText := '';
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
                                            LFooterText += ItemAttrText + Splitter;
                                        end
                                        else
                                            LFooterText += splitter;
                                        if SalesHeader."Pack-out Date" <= PalletHeader."Creation Date" then
                                            LLabelDate := PalletHeader."Creation Date"
                                        else
                                            LLabelDate := SalesHeader."Pack-out Date";
                                        LFooterText += SalesHeader."Sell-to Customer No." + Splitter +
                                                        SalesHeader."Sell-to Customer Name" + Splitter +
                                                        SalesHeader."No." + Splitter +
                                                        format(SalesHeader."Requested Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."document Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Pack-out Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(LLabelDate, 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(calcdate('+14D', LLabelDate), 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Dispatch Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Promised Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."due Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."order Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesHeader."Work Description") + splitter;

                                        LFooterText += GetVendorShipmentNo(WarehousePallet) + splitter;

                                        PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.");
                                        ItemCrossRef.reset;
                                        ItemCrossRef.setrange("Item No.", PalletLine."Item No.");
                                        ItemCrossRef.setrange("Variant Code", PalletLine."Variant Code");
                                        ItemCrossRef.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                        ItemCrossRef.SetRange(ItemCrossRef."Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::Customer);
                                        ItemCrossRef.SetRange("Cross-Reference type No.", salesheader."Sell-to Customer No.");
                                        if ItemCrossRef.findfirst then
                                            LFooterText += ItemCrossRef."Cross-Reference No." + Splitter + ItemCrossRef.Description + splitter;



                                        FileName := 'ItemLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(PalletLine."Line No.") + '.txt';
                                        TempBlob.CreateOutStream(OutStr);
                                        FirstLine := '%BTW% /AF="' +
                                                        StickerPrinter."Sticker Format Name(BTW)" +
                                                        '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                                                        format(PalletLine."Item Label No. of Copies");
                                        SecondLine := '%END%';
                                        OutStr.WriteText(FirstLine);
                                        OutStr.WriteText();
                                        OutStr.WriteText(SecondLine);
                                        OutStr.WriteText();
                                        ItemText := LPalletHeaderText;
                                        ItemText += format(PalletLine."Line No.") + Splitter +
                                                            PalletLine."Item No." + Splitter +
                                                            PalletLine."Variant Code" + Splitter +
                                                            PalletLine.Description + Splitter +
                                                            PalletLine."Lot Number" + Splitter +
                                                            PalletLine."Unit of Measure" + Splitter +
                                                            format(PalletLine.Quantity) + Splitter +
                                                            format(PalletLine."QTY Consumed") + Splitter +
                                                            format(PalletLine."Remaining Qty") + Splitter +
                                                            format(PalletLine."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + splitter;
                                        if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                            PalletLine."Purchase Order No.") then begin
                                            ItemText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                              GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                              format(PurchaseHeader."Harvest Date") + Splitter;
                                        end;

                                        ItemText += LFooterText;
                                        OutStr.WriteText(ItemText);

                                        TempBlob.CreateInStream(InStr);
                                        BearerToken := OneDriveFunctions.GetBearerToken();
                                        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);

                                        WarehousePallet.Printed := true;
                                        WarehousePallet.Modify(false);
                                    end;// else
                                        //  if BCorUI = 'BC' then
                                        //     Message(ErrCustomerSetting);
                                end;
                        end;
                    until WarehousePallet.next = 0;
            until WarehouseShipmentLine.next = 0;

    end;


    //Item Label Sticker Note - Posted
    procedure CreatePostedItemLabelStickerNote(pShipmentHeader: Record "Posted Whse. Shipment Header";
                PalletNumber: Text;
                boolFilterPallet: Boolean)
    var
        PalletProcessSetup: Record "Pallet Process Setup";
        WarehouseShipmentLine: Record "Posted Whse. Shipment Line";
        WarehousePallet: Record "Posted Warehouse Pallet";
        PalletHeader: Record "Pallet Header";
        ItemText: Text;
        PalletLine: Record "Pallet Line";
        SalesHeader: Record "Sales Header";
        SalesArchiveHeader: Record "Sales Header Archive";
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
        ItemCrossRef: Record "Item Cross Reference";
        LPalletHeaderText: Text;
        LFooterText: Text;
        LLabelDate: Date;
        //PalletLineTemp: Record "Pallet Line" temporary;
        LPalletsText: Text;
    begin
        CompanyInformation.get;
        CompanyText := CompanyInformation.name + Splitter +
                     CompanyInformation.address + Splitter +
                     CompanyInformation."E-Mail" + Splitter +
                     CompanyInformation."Phone No." + Splitter;
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
                    WarehousePallet.SetFilter("Pallet ID", PalletNumber);
                if WarehousePallet.findset then
                    repeat
                        PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.");
                        ItemText := '';
                        if SalesHeader.get(SalesHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then begin
                            if CustomerRec.get(SalesHeader."Sell-to Customer No.") then begin
                                StickerPrinter.reset;
                                StickerPrinter.setrange("User Code", UserId);
                                StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Item Label Type Code");
                                StickerPrinter.setrange("Sticker Note Format", CustomerRec."Item Label Format Code");
                                StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                if StickerPrinter.findfirst then begin
                                    PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";
                                    LabelFormat := CustomerRec."Item Label Format Description";
                                    //end else
                                    //   Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');

                                    //end;
                                    PalletHeader.get(WarehousePallet."Pallet ID");
                                    LPalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                                                           format(PalletHeader."Pallet Status") + Splitter +
                                                                                           PalletHeader."Location Code" + Splitter +
                                                                                           format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                                                           PalletHeader."User Created" + Splitter +
                                                                                           format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                                                           format(PalletHeader."Raw Material Pallet") + Splitter +
                                                                                           PalletHeader."Pallet Type" + Splitter +
                                                                                           format(PalletHeader."Disposal Status") + Splitter;

                                    LFooterText := '';
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
                                        LFooterText += ItemAttrText + Splitter;
                                    end
                                    else
                                        LFooterText += splitter;
                                    if SalesHeader."Pack-out Date" <= PalletHeader."Creation Date" then
                                        LLabelDate := PalletHeader."Creation Date"
                                    else
                                        LLabelDate := SalesHeader."Pack-out Date";
                                    LFooterText += SalesHeader."Sell-to Customer No." + Splitter +
                                                    SalesHeader."Sell-to Customer Name" + Splitter +
                                                    SalesHeader."No." + Splitter +
                                                    format(SalesHeader."Requested Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."document Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."Pack-out Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(LLabelDate, 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(calcdate('+14D', LLabelDate), 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."Dispatch Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."Promised Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."due Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."order Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                    format(SalesHeader."Work Description") + splitter;

                                    LFooterText += GetVendorShipmentNo_Posted(WarehousePallet) + splitter;

                                    PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.");// then begin
                                    ItemCrossRef.reset;
                                    ItemCrossRef.setrange("Item No.", PalletLine."Item No.");
                                    ItemCrossRef.setrange("Variant Code", PalletLine."Variant Code");
                                    ItemCrossRef.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                    ItemCrossRef.SetRange(ItemCrossRef."Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::Customer);
                                    ItemCrossRef.SetRange("Cross-Reference type No.", salesheader."Sell-to Customer No.");
                                    if ItemCrossRef.findfirst then
                                        LFooterText += ItemCrossRef."Cross-Reference No." + Splitter + ItemCrossRef.Description + splitter;
                                    //end;
                                    LFooterText += CompanyText;

                                    /*PalletLine.reset;
                                    PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                    PalletLine.SetRange("Line No.", WarehousePallet."Pallet Line No.");
                                    if PalletLine.FindFirst() then begin*/

                                    FileName := 'ItemLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(PalletLine."Line No.") + '.txt';
                                    TempBlob.CreateOutStream(OutStr);
                                    FirstLine := '%BTW% /AF="' +
                                                    StickerPrinter."Sticker Format Name(BTW)" +
                                                    '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                                                    format(PalletLine."Item Label No. of Copies");
                                    SecondLine := '%END%';
                                    OutStr.WriteText(FirstLine);
                                    OutStr.WriteText();
                                    OutStr.WriteText(SecondLine);
                                    OutStr.WriteText();
                                    ItemText := LPalletHeaderText;
                                    ItemText += format(PalletLine."Line No.") + Splitter +
                                                        PalletLine."Item No." + Splitter +
                                                        PalletLine."Variant Code" + Splitter +
                                                        PalletLine.Description + Splitter +
                                                        PalletLine."Lot Number" + Splitter +
                                                        PalletLine."Unit of Measure" + Splitter +
                                                        format(PalletLine.Quantity) + Splitter +
                                                        format(PalletLine."QTY Consumed") + Splitter +
                                                        format(PalletLine."Remaining Qty") + Splitter +
                                                        format(PalletLine."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + splitter;
                                    if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                        PalletLine."Purchase Order No.") then begin
                                        ItemText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                          GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                          format(PurchaseHeader."Harvest Date") + Splitter;
                                    end;

                                    ItemText += LFooterText;
                                    OutStr.WriteText(ItemText);

                                    TempBlob.CreateInStream(InStr);
                                    BearerToken := OneDriveFunctions.GetBearerToken();
                                    OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                end;
                            end;
                        end else begin
                            if SalesArchiveHeader.get(SalesArchiveHeader."Document Type"::Order, WarehouseShipmentLine."Source No.") then begin
                                if CustomerRec.get(SalesArchiveHeader."Sell-to Customer No.") then begin
                                    // if CustomerRec."SSCC Sticker Note" then begin
                                    StickerPrinter.reset;
                                    StickerPrinter.setrange("User Code", UserId);
                                    StickerPrinter.setrange("Sticker Note Type", PalletProcessSetup."Item Label Type Code");
                                    StickerPrinter.setrange("Sticker Note Format", CustomerRec."Item Label Format Code");
                                    StickerPrinter.setrange("Location Code", WarehouseShipmentLine."Location Code");
                                    if StickerPrinter.findfirst then begin
                                        PrinterPath := PalletProcessSetup."OneDrive Root Directory" + '/' + StickerPrinter."Printer Path";
                                        LabelFormat := CustomerRec."Item Label Format Description";
                                        // end else
                                        //Error('You do not have the right setup in the sticker note configuration table - Please contact your administrator');
                                        //end;
                                        PalletHeader.get(WarehousePallet."Pallet ID");
                                        LPalletHeaderText := PalletHeader."Pallet ID" + Splitter +
                                                                                               format(PalletHeader."Pallet Status") + Splitter +
                                                                                               PalletHeader."Location Code" + Splitter +
                                                                                               format(PalletHeader."Creation Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                                                               PalletHeader."User Created" + Splitter +
                                                                                               format(PalletHeader."Exist in warehouse shipment") + Splitter +
                                                                                               format(PalletHeader."Raw Material Pallet") + Splitter +
                                                                                               PalletHeader."Pallet Type" + Splitter +
                                                                                               format(PalletHeader."Disposal Status") + Splitter;

                                        LFooterText := '';
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
                                            LFooterText += ItemAttrText + Splitter;
                                        end
                                        else
                                            LFooterText += splitter;
                                        if SalesArchiveHeader."Pack-out Date" <= PalletHeader."Creation Date" then
                                            LLabelDate := PalletHeader."Creation Date"
                                        else
                                            LLabelDate := SalesArchiveHeader."Pack-out Date";
                                        LFooterText += SalesArchiveHeader."Sell-to Customer No." + Splitter +
                                                        SalesArchiveHeader."Sell-to Customer Name" + Splitter +
                                                        SalesArchiveHeader."No." + Splitter +
                                                        format(SalesArchiveHeader."Requested Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."document Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Pack-out Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(LLabelDate, 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(calcdate('+14D', LLabelDate), 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Dispatch Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Promised Delivery Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."due Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."order Date", 0, '<Day,2>/<Month,2>/<Year,2>') + Splitter +
                                                        format(SalesArchiveHeader."Work Description") + splitter;

                                        LFooterText += GetVendorShipmentNo_Posted(WarehousePallet) + splitter;

                                        PalletLine.get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.");// then begin
                                        ItemCrossRef.reset;
                                        ItemCrossRef.setrange("Item No.", PalletLine."Item No.");
                                        ItemCrossRef.setrange("Variant Code", PalletLine."Variant Code");
                                        ItemCrossRef.setrange("Unit of Measure", PalletLine."Unit of Measure");
                                        ItemCrossRef.SetRange(ItemCrossRef."Cross-Reference Type", ItemCrossRef."Cross-Reference Type"::Customer);
                                        ItemCrossRef.SetRange("Cross-Reference type No.", SalesArchiveHeader."Sell-to Customer No.");
                                        if ItemCrossRef.findfirst then
                                            LFooterText += ItemCrossRef."Cross-Reference No." + Splitter + ItemCrossRef.Description + splitter;
                                        //end;
                                        LFooterText += CompanyText;

                                        /*PalletLine.reset;
                                        PalletLine.setrange(PalletLine."Pallet ID", WarehousePallet."Pallet ID");
                                        PalletLine.SetRange("Line No.", WarehousePallet."Pallet Line No.");
                                        if PalletLine.FindFirst() then begin*/

                                        FileName := 'ItemLabel_' + WarehousePallet."Whse Shipment No." + '_' + format(WarehousePallet."Whse Shipment Line No.") + '_' + WarehousePallet."Pallet ID" + '_' + Format(PalletLine."Line No.") + '.txt';
                                        TempBlob.CreateOutStream(OutStr);
                                        FirstLine := '%BTW% /AF="' +
                                                        StickerPrinter."Sticker Format Name(BTW)" +
                                                        '" /D="%Trigger File Name%" /PRN="' + StickerPrinter."Printer Name" + '"   /R=3 /P /C=' +
                                                        format(PalletLine."Item Label No. of Copies");
                                        SecondLine := '%END%';
                                        OutStr.WriteText(FirstLine);
                                        OutStr.WriteText();
                                        OutStr.WriteText(SecondLine);
                                        OutStr.WriteText();
                                        ItemText := LPalletHeaderText;
                                        ItemText += format(PalletLine."Line No.") + Splitter +
                                                            PalletLine."Item No." + Splitter +
                                                            PalletLine."Variant Code" + Splitter +
                                                            PalletLine.Description + Splitter +
                                                            PalletLine."Lot Number" + Splitter +
                                                            PalletLine."Unit of Measure" + Splitter +
                                                            format(PalletLine.Quantity) + Splitter +
                                                            format(PalletLine."QTY Consumed") + Splitter +
                                                            format(PalletLine."Remaining Qty") + Splitter +
                                                            format(PalletLine."Expiration Date", 0, '<Day,2>/<Month,2>/<Year,2>') + splitter;
                                        if PurchaseHeader.get(PurchaseHeader."Document Type"::order,
                                            PalletLine."Purchase Order No.") then begin
                                            ItemText += PurchaseHeader."Buy-from Vendor No." + splitter +
                                                              GetVendorAddress(PurchaseHeader."Buy-from Vendor No.") + splitter +
                                                              format(PurchaseHeader."Harvest Date") + Splitter;
                                        end;

                                        ItemText += LFooterText;
                                        OutStr.WriteText(ItemText);

                                        TempBlob.CreateInStream(InStr);
                                        BearerToken := OneDriveFunctions.GetBearerToken();
                                        OneDriveFunctions.UploadFile(PrinterPath, FileName, BearerToken, InStr);
                                    end;
                                end;
                            end;
                        end;
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

    Procedure GetVendorShipmentNo_Posted(var pWarehousePallet: Record "Posted Warehouse Pallet"): code[35]
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