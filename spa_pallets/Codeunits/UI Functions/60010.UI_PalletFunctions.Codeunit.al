codeunit 60010 "UI Pallet Functions"
{

    //Get List Of Pallets
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPallets(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PalletHeader: Record "Pallet Header";
        PalletLines: Record "Pallet Line";
        Obj_JsonText: Text;

    begin
        IF pFunction <> 'GetListOfPallets' THEN
            EXIT;
        Obj_JsonText := '[';

        PalletHeader.reset;
        if PalletHeader.findset then
            repeat
                Obj_JsonText += '{' +
                            '"Pallet ID": ' +
                            '"' + palletheader."Pallet ID" + '"' +
                            ',' +
                            '"Location Code": "' +
                            PalletHeader."Location Code" +
                            '",' +
                            '"Status": "' +
                            format(PalletHeader."Pallet Status") +
                            '",' +
                            '"Exist in Shipment": "' +
                            format(PalletHeader."Exist in warehouse shipment") +
                            '"},'
            until PalletHeader.next = 0;

        Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
        Obj_JsonText += ']';
        pContent := Obj_JsonText;

    end;

    //Create Pallet by Json
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreatePalletFromJson(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        PalletLineCheck: Record "Pallet Line";
        PurchaseLineCheck: Record "purchase line";
        PalletSetup: Record "Pallet Process Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JsonText: text;
        JsonBuffer: Record "JSON Buffer" temporary;
        ManipulateString: Text;
        StrPosInteger: integer;
        LastLine: Integer;
        iCount: integer;
        ItemNo: code[20];
        UOM: code[20];
        Qty: integer;
        LOTNO: code[20];
        LocationCode: Code[20];
        PalletID: code[20];
        LineNumber: Integer;
        PalletLineNumber: Integer;
        PurchaseOrderNo: code[20];
        ItemRec: Record Item;
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        RM_Pallet: Text;
        RM_Pallet_Boolean: Boolean;
        PalletType: Text;

    begin
        IF pFunction <> 'CreatePalletFromJson' THEN
            EXIT;

        PalletSetup.get;
        if PalletSetup."Json Text Sample" <> '' then
            JsonText := PalletSetup."Json Text Sample"
        else
            JsonText := pContent;

        JsonBuffer.ReadFromText(JsonText);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'LocationCode') > 0 THEN
                        LocationCode := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'PalletType') > 0 THEN
                        PalletType := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'RMPallet') > 0 THEN begin
                        RM_Pallet := JSONBuffer.Value;
                        if RM_Pallet = 'true' then
                            RM_Pallet_Boolean := true
                        else
                            RM_Pallet_Boolean := false;
                    end;

            UNTIL JSONBuffer.NEXT = 0;

            //Create Pallet Header
            if PalletSetup.get then begin
                PalletID := NoSeriesMgt.GetNextNo(PalletSetup."Pallet No. Series", today, true);
                pContent := '{"palletid":"' + PalletID + '"}';
                PalletHeader.LockTable();
                PalletHeader.Init();
                PalletHeader."Pallet ID" := PalletID;
                PalletHeader."Location Code" := LocationCode;
                PalletHeader."Creation Date" := today;
                PalletHeader."User Created" := UserId;
                if RM_Pallet = 'true' then
                    PalletHeader."Raw Material Pallet" := true
                else
                    PalletHeader."Raw Material Pallet" := false;
                PalletHeader."Pallet Type" := PalletType;
                PalletHeader.Insert();
            end;

        end;

        //Getting Line Count
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 3);
        JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
        IF JSONBuffer.FINDLAST THEN BEGIN
            ManipulateString := DELSTR(JSONBuffer.Path, 1, 4);
            StrPosInteger := STRPOS(ManipulateString, ']');
            ManipulateString := COPYSTR(ManipulateString, 1, StrPosInteger - 1);
            EVALUATE(LastLine, ManipulateString);
        END;

        //Depth 2 - Lines
        iCount := 0;
        WHILE iCount <= LastLine DO BEGIN
            JSONBuffer.RESET;
            JSONBuffer.SETRANGE(JSONBuffer.Depth, 3);
            JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
            IF JSONBuffer.FINDSET THEN
                REPEAT

                    IF JSONBuffer.Path = ('[1][' + FORMAT(iCount) + '].ItemNo') THEN
                        ItemNo := JSONBuffer.Value
                    ELSE
                        IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].UnitOfMeasure' THEN
                            UOM := JSONBuffer.Value
                        ELSE
                            IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].Quantity' THEN
                                EVALUATE(Qty, JSONBuffer.Value)
                            ELSE
                                IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].LOTNo' THEN
                                    LOTNO := JSONBuffer.Value;

                UNTIL JSONBuffer.NEXT = 0;
            iCount += 1;
            if PalletHeader.get(PalletID) then begin
                PalletLineCheck.reset;
                PalletLineCheck.setrange("Pallet ID", PalletHeader."Pallet ID");
                if PalletLineCheck.findlast then
                    PalletLineNumber := PalletLineCheck."Line No." + 10000
                else
                    PalletLineNumber := 10000;

                PalletLine.LockTable();
                PalletLine.init;
                PalletLine."Pallet ID" := PalletID;
                PalletLine."Line No." := PalletLineNumber;
                PalletLine.validate("Item No.", ItemNo);
                if ItemRec.get(ItemNo) then begin
                    if format(ItemRec."Expiration Calculation") = '' then
                        PalletLine."Expiration Date" := today
                    else
                        PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), today);
                end;
                PalletLine.validate("Location Code", LocationCode);
                PalletLine."Lot Number" := LOTNO;
                PalletLine.Quantity := qty;
                PalletLine.Insert();
            end;
        END;

        //Taking Pallet Lines to Purchase Order
        PalletLine.reset;
        palletline.setrange("Pallet ID", PalletID);
        if PalletLine.findset then
            repeat
                //Create Purchase Line - From Pallet
                PurchaseHeader.reset;
                PurchaseHeader.setrange(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::Order);
                purchaseheader.setrange(PurchaseHeader."Batch Number", palletline."Lot Number");
                //PurchaseHeader.setrange(PurchaseHeader.status, PurchaseHeader.status::Open);
                if PalletType = 'grade' then
                    purchaseheader.setrange(PurchaseHeader."Grading Result PO", true);
                if PalletType = 'mw' then
                    purchaseheader.setrange(PurchaseHeader."Microwave Process PO", true);

                if purchaseheader.findfirst then begin
                    if PurchaseHeader.status = PurchaseHeader.status::Released then
                        DocmentStatusMgmt.PerformManualReopen(PurchaseHeader);

                    PurchaseOrderNo := PurchaseHeader."No.";

                    PurchaseLineCheck.reset;
                    PurchaseLineCheck.setrange("Document Type", PurchaseHeader."Document Type");
                    PurchaseLineCheck.setrange("Document No.", purchaseheader."No.");
                    if PurchaseLineCheck.findlast then
                        LineNumber := PurchaseLineCheck."Line No." + 10000
                    else
                        LineNumber := 10000;

                    PurchaseLine.init;
                    PurchaseLine."Document No." := PurchaseHeader."No.";
                    purchaseline."Document Type" := PurchaseHeader."Document Type";
                    PurchaseLine."Line No." := LineNumber;
                    PurchaseLine.insert;
                    PurchaseLine.type := PurchaseLine.type::Item;
                    purchaseline.validate("No.", PalletLine."Item No.");
                    purchaseline.validate("Location Code", PalletLine."Location Code");
                    PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity);
                    PurchaseLine.validate("Qty. to Receive", 0);
                    PurchaseLine.validate("qty. to invoice", 0);

                    //PurchaseLine.validate("Qty. to Receive", PurchaseLine.Quantity);
                    //PurchaseLine.validate("qty. to invoice", PurchaseLine.Quantity);
                    PurchaseLine.modify;

                    //if PalletLine.get(PalletID, PalletLineNumber) then begin
                    PalletLine."Purchase Order No." := PurchaseOrderNo;
                    PalletLine."Purchase Order Line No." := LineNumber;
                    palletline.modify;

                end;
            until PalletLine.next = 0;
    end;


    //Get List Of Items by Attributes
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfItemsByAttr(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemRec: Record Item;
        ItemAttributesRec: Record "Item Attribute Value";
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        TempItemFilteredFromAttributes: Record item temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        FilterText: text;
        ParameterCount: Integer;

        Obj_JsonText: Text;
        JsonBuffer: Record "JSON Buffer" temporary;
        JsonText: Text;
        Attr_OM: Text;
        Attr_Size: Text;
        Attr_PrimaryPackageType: Text;
        Attr_PackageDescription: Text;
        Attr_Grade: Text;
        Attr_Color: Text;
        DescText: Text;

    begin
        IF pFunction <> 'GetListOfItemsByAttr' THEN
            EXIT;

        if TempFilterItemAttributesBuffer.findset then
            TempFilterItemAttributesBuffer.deleteall;

        Attr_Grade := '';
        Attr_Size := '';
        Attr_OM := '';
        Attr_Color := '';
        Attr_PrimaryPackageType := '';
        Attr_PackageDescription := '';


        jsontext := pContent;
        JsonBuffer.ReadFromText(JsonText);
        JSONBuffer.RESET;

        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN begin
                    IF STRPOS(JSONBuffer.Path, 'grade') > 0 THEN begin
                        Attr_Grade := JSONBuffer.Value;
                        TempFilterItemAttributesBuffer.init;
                        TempFilterItemAttributesBuffer.Attribute := 'Grade';
                        TempFilterItemAttributesBuffer.Value := Attr_Grade;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                    IF STRPOS(JSONBuffer.Path, 'size') > 0 THEN begin
                        Attr_Size := JSONBuffer.Value;
                        TempFilterItemAttributesBuffer.init;
                        TempFilterItemAttributesBuffer.Attribute := 'Size';
                        TempFilterItemAttributesBuffer.Value := Attr_Size;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                    IF STRPOS(JSONBuffer.Path, 'om') > 0 THEN begin
                        Attr_OM := JSONBuffer.Value;
                        TempFilterItemAttributesBuffer.init;
                        TempFilterItemAttributesBuffer.Attribute := 'OM';
                        TempFilterItemAttributesBuffer.Value := Attr_OM;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                    IF STRPOS(JSONBuffer.Path, 'spacolor') > 0 THEN begin
                        Attr_Color := JSONBuffer.Value;
                        TempFilterItemAttributesBuffer.init;
                        TempFilterItemAttributesBuffer.Attribute := 'SPAColor';
                        TempFilterItemAttributesBuffer.Value := Attr_Color;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                    IF STRPOS(JSONBuffer.Path, 'primarypackagetype') > 0 THEN begin
                        Attr_PrimaryPackageType := JSONBuffer.Value;
                        TempFilterItemAttributesBuffer.init;
                        TempFilterItemAttributesBuffer.Attribute := 'Primary Packaging Type';
                        TempFilterItemAttributesBuffer.Value := Attr_PrimaryPackageType;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                    IF STRPOS(JSONBuffer.Path, 'packagedescription') > 0 THEN begin
                        Attr_PackageDescription := JSONBuffer.Value;
                        TempFilterItemAttributesBuffer.init;
                        TempFilterItemAttributesBuffer.Attribute := 'Package Description';
                        TempFilterItemAttributesBuffer.Value := Attr_PackageDescription;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                end;
            UNTIL JSONBuffer.NEXT = 0;
        end;
        Obj_JsonText := '[';
        ItemAttributeManagement.FindItemsByAttributes(TempFilterItemAttributesBuffer, TempItemFilteredFromAttributes);
        FilterText := ItemAttributeManagement.GetItemNoFilterText(TempItemFilteredFromAttributes, ParameterCount);
        if TempItemFilteredFromAttributes.findset then begin
            TempItemFilteredFromAttributes.reset;
            if TempItemFilteredFromAttributes.findset then
                repeat
                    if strpos(TempItemFilteredFromAttributes.Description, '"') > 0 then
                        DescText := ConvertStr(TempItemFilteredFromAttributes.Description, '"', ' ')
                    else
                        DescText := TempItemFilteredFromAttributes.Description;
                    Obj_JsonText += '{' +
                                '"Item No.": ' +
                                '"' + TempItemFilteredFromAttributes."No." + '"' +
                                ',' +
                                '"Description": "' +
                                DescText +
                                '"},'
                until TempItemFilteredFromAttributes.next = 0;
            Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
            Obj_JsonText += ']';
            pContent := Obj_JsonText;

        end
        else
            pcontent := 'No Items';
    end;

    //Get List Of Items by Attributes
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetItemAttributeValues(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        ItemAttributeValue: Record "Item Attribute Value";
        Attr_OM: label 'OM';
        Attr_Size: label 'Size';
        Attr_PackageType: label 'Primary Packaging Type';
        Attr_PackDesc: Label 'Packaging Description';
        Attr_Grade: label 'Grade';
        Attr_Color: label 'SPAColor';
        Json_OM: Text;
        Json_Size: Text;
        Json_PackageType: Text;
        Json_PackageDesc: text;
        Json_Grade: Text;
        json_Color: text;
        Json_Text: Text;



    begin
        IF pFunction <> 'GetItemAttributeValues' THEN
            EXIT;
        Json_Text := '{';

        //OM Attribute                        
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_OM);
        if ItemAttributeValue.findset then begin
            Json_OM := '"OM": [';
            repeat
                Json_OM += '{"Code": "'
                    + format(ItemAttributeValue.ID) +
                    '","Description": "' + ItemAttributeValue.Value + '"},';
            until ItemAttributeValue.next = 0;
            Json_OM := copystr(Json_OM, 1, strlen(Json_OM) - 1);
            Json_OM += ' ],';
            Json_Text += Json_OM;
        end;

        //Size Attribute
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_Size);
        if ItemAttributeValue.findset then begin
            Json_size := '"Size": [';
            repeat
                Json_size += '{"Code": "'
                    + format(ItemAttributeValue.ID) +
                    '","Description": "' + ItemAttributeValue.Value + '"},';
            until ItemAttributeValue.next = 0;
            Json_size := copystr(Json_size, 1, strlen(Json_size) - 1);
            Json_size += ' ],';
            Json_Text += Json_Size;
        end;

        //Primary Packaging Type Attribute                        
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_PackageType);
        if ItemAttributeValue.findset then begin
            Json_PackageType := '"PrimaryPackagingType": [';
            repeat
                Json_PackageType += '{"Code": "'
                    + format(ItemAttributeValue.ID) +
                    '","Description": "' + ItemAttributeValue.Value + '"},';
            until ItemAttributeValue.next = 0;
            Json_PackageType := copystr(Json_PackageType, 1, strlen(Json_PackageType) - 1);
            Json_PackageType += ' ],';
            Json_Text += Json_PackageType;
        end;

        //Packaging Description Attribute                        
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_PackDesc);
        if ItemAttributeValue.findset then begin
            Json_PackageDesc := '"PackagingDescription": [';
            repeat
                Json_PackageDesc += '{"Code": "'
                    + format(ItemAttributeValue.ID) +
                    '","Description": "' + ItemAttributeValue.Value + '"},';
            until ItemAttributeValue.next = 0;
            Json_PackageDesc := copystr(Json_PackageDesc, 1, strlen(Json_PackageDesc) - 1);
            Json_PackageDesc += ' ],';
            Json_Text += Json_PackageDesc;
        end;

        //Grade Attribute                        
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_Grade);
        if ItemAttributeValue.findset then begin
            Json_Grade := '"Grade": [';
            repeat
                Json_Grade += '{"Code": "'
                    + format(ItemAttributeValue.ID) +
                    '","Description": "' + ItemAttributeValue.Value + '"},';
            until ItemAttributeValue.next = 0;
            Json_Grade := copystr(Json_Grade, 1, strlen(Json_Grade) - 1);
            Json_Grade += ' ],';
            Json_Text += Json_Grade;
        end;

        //Color Attribute                        
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_Color);
        if ItemAttributeValue.findset then begin
            json_Color := '"Color": [';
            repeat
                json_Color += '{"Code": "'
                    + format(ItemAttributeValue.ID) +
                    '","Description": "' + ItemAttributeValue.Value + '"},';
            until ItemAttributeValue.next = 0;
            json_Color := copystr(json_Color, 1, strlen(json_Color) - 1);
            json_Color += ' ],';
            Json_Text += json_Color;
        end;
        Json_Text := copystr(Json_Text, 1, strlen(Json_Text) - 1);
        if Json_Text <> '' then
            pContent := Json_Text + '}'
        else
            pContent := 'No Data';
        pContent := 'Blah Blah';
    end;

    //Create Pallet by Json
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure AddItemToPallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        ItemRec: Record Item;
        PalletID: Code[20];
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineCheck: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderNo: code[20];
        LineNumber: Integer;
        ErrorText: Text;
        ManipulateString: text;
        StrPosInteger: Integer;
        LastLine: Integer;
        iCount: Integer;
        ItemNo: Code[20];
        UOM: code[20];
        Qty: Integer;
        LOTNO: code[20];
        PalletLineCheck: Record "Pallet Line";
        PalletLineNumber: Integer;

    begin
        IF pFunction <> 'AddItemToPallet' THEN
            EXIT;

        ErrorText := '';
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
        IF JSONBuffer.findfirst THEn
            PalletID := JSONBuffer.Value;

        if PalletHeader.get(PalletID) then begin

            if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::Closed then
                ErrorText := 'Error:Pallet Closed';

            //Getting Line Count
            JSONBuffer.RESET;
            JSONBuffer.SETRANGE(JSONBuffer.Depth, 3);
            JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
            IF JSONBuffer.FINDLAST THEN BEGIN
                ManipulateString := DELSTR(JSONBuffer.Path, 1, 4);
                StrPosInteger := STRPOS(ManipulateString, ']');
                ManipulateString := COPYSTR(ManipulateString, 1, StrPosInteger - 1);
                EVALUATE(LastLine, ManipulateString);

                //Depth 2 - Lines
                iCount := 0;
                WHILE iCount <= LastLine DO BEGIN
                    JSONBuffer.RESET;
                    JSONBuffer.SETRANGE(JSONBuffer.Depth, 3);
                    JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
                    IF JSONBuffer.FINDSET THEN
                        REPEAT

                            IF JSONBuffer.Path = ('[1][' + FORMAT(iCount) + '].ItemNo') THEN
                                ItemNo := JSONBuffer.Value;

                            IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].UnitOfMeasure' THEN
                                UOM := JSONBuffer.Value;

                            IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].Quantity' THEN
                                EVALUATE(Qty, JSONBuffer.Value);

                            IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].LOTNo' THEN
                                LOTNO := JSONBuffer.Value;

                        UNTIL JSONBuffer.NEXT = 0;

                    iCount += 1;

                    if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::Open then begin
                        PalletLineCheck.reset;
                        PalletLineCheck.setrange("Pallet ID", PalletID);
                        if PalletLineCheck.findlast then
                            PalletLineNumber := PalletLineCheck."Line No." + 10000
                        else
                            PalletLineNumber := 10000;

                        PalletLine.LockTable();
                        PalletLine.init;
                        PalletLine."Pallet ID" := PalletID;
                        PalletLine."Line No." := PalletLineNumber;
                        PalletLine.validate("Item No.", ItemNo);
                        if ItemRec.get(ItemNo) then begin
                            if format(ItemRec."Expiration Calculation") = '' then
                                PalletLine."Expiration Date" := today
                            else
                                PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), today);
                        end;
                        PalletLine."Location Code" := PalletHeader."Location Code";
                        PalletLine."Lot Number" := LOTNO;
                        PalletLine.Quantity := qty;
                        PalletLine.Insert();

                        //Create Purchase Line - From Pallet
                        PurchaseHeader.reset;
                        PurchaseHeader.setrange(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::Order);
                        purchaseheader.setrange(PurchaseHeader."Batch Number", LOTNO);
                        if purchaseheader.findfirst then begin
                            PurchaseOrderNo := PurchaseHeader."No.";

                            PurchaseLineCheck.reset;
                            PurchaseLineCheck.setrange("Document Type", PurchaseHeader."Document Type");
                            PurchaseLineCheck.setrange("Document No.", purchaseheader."No.");
                            if PurchaseLineCheck.findlast then
                                LineNumber := PurchaseLineCheck."Line No." + 10000
                            else
                                LineNumber := 10000;

                            PurchaseLine.init;
                            PurchaseLine."Document No." := PurchaseHeader."No.";
                            purchaseline."Document Type" := PurchaseHeader."Document Type";
                            PurchaseLine."Line No." := LineNumber;
                            PurchaseLine.insert;
                            PurchaseLine.type := PurchaseLine.type::Item;
                            purchaseline.validate("No.", PalletLine."Item No.");
                            purchaseline.validate("Location Code", PalletLine."Location Code");
                            PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity);
                            PurchaseLine.validate("Qty. to Receive", PurchaseLine.Quantity);
                            PurchaseLine.validate("qty. to invoice", PurchaseLine.Quantity);
                            PurchaseLine.modify;

                            //if PalletLine.get(PalletID, PalletLineNumber) then begin
                            PalletLine."Purchase Order No." := PurchaseOrderNo;
                            PalletLine."Purchase Order Line No." := LineNumber;
                            palletline.modify;
                        end;

                    end;
                end;

            end
            else
                ErrorText := 'Error: Pallet does not Exist';


            if ErrorText = '' then
                pContent := 'Success - Lines Added'
            else
                pContent := ErrorText;
        end;
    end;

    //Get List of Pallet Lines
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPalletLines(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletID: code[20];
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        Obj_JsonText: Text;

    begin
        IF pFunction <> 'GetListOfPalletLines' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'palletid') > 0 THEN
                        PalletID := JSONBuffer.Value;
            until JsonBuffer.next = 0;

        if PalletHeader.GET(PalletID) then begin

            Obj_JsonText := '[';
            //Create Purchase Receipt
            PalletLine.reset;
            PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
            if PalletLine.findset then begin
                Obj_JsonText += '{"Pallet ID": ' +
                                '"' + PalletID + '"' +
                                ',"Item List":[';
                repeat
                    Obj_JsonText += '{"Item No" :"' + PalletLine."Item No." + '",' +
                                 '"Item Description":"' + PalletLine.Description + '",' +
                                 '"location":"' + PalletLine."Location Code" + '",' +
                                 '"Lot":"' + PalletLine."Lot Number" + '",' +
                                 '"Unit of Measure":"' + PalletLine."Unit of Measure" + '",' +
                                  '"Item Qty" :"' + format(palletline.Quantity) + '"},';

                until PalletLine.next = 0;
                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']},';

            end;
            Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
            Obj_JsonText += ']';
            pContent := Obj_JsonText;
        end
        else
            pContent := 'No Pallet Exist';
    end;

    //Get LOT Numbers by Item
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetLotNumbersByItem(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        ItemNo: code[20];
        Locationcode: code[20];
        ItemLedgerEntry: Record "Item Ledger Entry";
        Obj_JsonText: Text;
        LotSelection: Record "Lot Selection" temporary;
        ItemTemp: Record Item temporary;
        PalletReservationFunctions: Codeunit "Pallet Reservation Functions";
        ReserevationEntry: Record "Reservation Entry";
        QtyReserved: Decimal;

    begin
        IF pFunction <> 'GetLotNumbersByItem' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);
        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'itemno' THEN
                        ItemNo := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'locationcode' THEN
                        Locationcode := JSONBuffer.Value;
            until jsonbuffer.next = 0;

            Obj_JsonText := '[';

            if LotSelection.findset then
                LotSelection.deleteall;

            if ItemTemp.findset then
                ItemTemp.deleteall;

            //Get Item Ledger Entries
            ItemLedgerEntry.RESET;
            ItemLedgerEntry.SETCURRENTKEY("Item No.", Open, "Variant Code", "Location Code", "Item Tracking",
              "Lot No.", "Serial No.");
            ItemLedgerEntry.SETRANGE("Item No.", ItemNo);
            ItemLedgerEntry.SETRANGE(Open, TRUE);
            ItemLedgerEntry.SETRANGE("Location Code", Locationcode);
            ItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');

            if ItemLedgerEntry.findset then
                repeat
                    if not ItemTemp.get(ItemLedgerEntry."Lot No.") then begin
                        pContent := ItemLedgerEntry."Lot No.";
                        ItemTemp.init;
                        ItemTemp."No." := ItemLedgerEntry."Lot No.";
                        ItemTemp."Price Unit Conversion" := ItemLedgerEntry.Quantity;

                        ReserevationEntry.reset;
                        ReserevationEntry.setrange("Lot No.", ItemLedgerEntry."Lot No.");
                        if ReserevationEntry.findset then begin
                            QtyReserved := 0;
                            repeat
                                QtyReserved += ReserevationEntry.Quantity;
                            until ReserevationEntry.next = 0;
                        end;
                        ItemTemp."Budget Quantity" := -1 * QtyReserved;
                        ItemTemp.insert;

                    end;
                until ItemLedgerEntry.next = 0;


            /*ItemTemp.reset;
            ItemTemp.setrange(ItemTemp."Unit Price", 0);
            if ItemTemp.findset then
                ItemTemp.deleteall;*/

            ItemTemp.reset;
            if ItemTemp.findset then begin
                repeat
                    Obj_JsonText += '{"Lot No": ' +
                        '"' + ItemTemp."No." + '"' +
                        ',' +
                        '"Qty": "' +
                        format(ItemTemp."Price Unit Conversion") +
                        '",' +
                        '"Reserved": "' +
                        format(ItemTemp."Budget Quantity") +
                        '"},';
                until itemtemp.next = 0;
                Obj_JsonText := copystr(Obj_JsonText, 1, strlen(Obj_JsonText) - 1);
                Obj_JsonText += ']';
                pContent := Obj_JsonText;
            end
            else
                pContent := 'No Entries Found';
        end;
    end;

    //Get LOT Numbers by Item
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure ChangeItemInPallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletLine: Record "Pallet Line";
        PalletHeader: Record "Pallet Header";
        PurchaseLine: Record "Purchase Line";
        ItemRec: Record Item;
        PalletID: code[20];
        OldItem: code[20];
        NewItem: code[20];
        BatchNumber: code[20];
        CU: Codeunit "Undo Purchase Receipt Line";

    begin
        IF pFunction <> 'ChangeItemInPallet' THEN
            EXIT;
        JsonBuffer.ReadFromText(pContent);
        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'palletId' THEN
                        PalletID := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'item' THEN
                        OldItem := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'newItem' THEN
                        NewItem := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'batch' THEN
                        BatchNumber := JSONBuffer.Value;

            until jsonbuffer.next = 0;
            if PalletHeader.get(PalletID) then begin
                PalletLine.reset;
                PalletLine.SetRange("Pallet ID", PalletHeader."Pallet ID");
                PalletLine.SetRange("Lot Number", BatchNumber);
                if PalletLine.FindFirst then begin

                    //Check if po line is not invoiced
                    if CheckPurchaseLine(PalletLine."Purchase Order No.", PalletLine."Purchase Order Line No.")
                        then
                        pContent := 'error, purchase line connected has invoice, cannot change item'
                    else begin
                        if not CheckReceiptExists(PalletLine."Purchase Order No.", PalletLine."Purchase Order Line No.") then begin
                            ChangeItemInPalleLine(PalletLine, NewItem);
                            ChangeItemInPurchaseLine(PalletLine, NewItem);
                            pContent := 'Item Changed';
                        end
                        else
                            pContent := 'error, Item has receipts, cannot change';
                    end;
                end;
            end
            else
                pContent := 'error,Pallet does not exist';

        end
        else
            pContent := 'error, item does not exist'
    end;

    procedure CheckPurchaseLine(var PO_Order: Code[20]; var PO_Line: integer): Boolean
    var
        Purchaseline: Record "Purchase Line";
    begin
        if Purchaseline.get(Purchaseline."Document Type"::Order, PO_Order, PO_Line) then
            if Purchaseline."Qty. Invoiced (Base)" = 0 then
                exit(false)
            else
                exit(true);
    end;

    procedure CheckReceiptExists(var PO_Order: Code[20]; var PO_Line: integer): Boolean
    var
        PurchRecptLine: Record "purch. Rcpt. Line";
    begin
        PurchRecptLine.reset;
        PurchRecptLine.setrange("Order No.", PO_Order);
        PurchRecptLine.setrange("Order Line No.", PO_Line);
        if PurchRecptLine.findfirst then
            exit(true)
        else
            exit(false);
    end;

    procedure ChangeItemInPalleLine(var PalletLine: Record "Pallet Line"; var New_Item: code[20])
    var
        ItemRec: Record Item;
    begin
        PalletLine.validate("Item No.", New_Item);
        if ItemRec.get(New_Item) then begin
            if format(ItemRec."Expiration Calculation") = '' then
                PalletLine."Expiration Date" := today
            else
                PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), today);
        end;
        PalletLine.modify;
    end;


    procedure ChangeItemInPurchaseLine(var PalletLine: Record "Pallet Line"; var New_Item: code[20])
    var
        ItemRec: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseLine.get(PurchaseLine."Document Type"::order, PalletLine."Purchase Order No.",
            PalletLine."Purchase Order Line No.") then begin
            purchaseline.validate("No.", New_Item);
            PurchaseLine.validate("Location Code", PalletLine."Location Code");
            PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity);
            PurchaseLine.validate("Qty. to Receive", PurchaseLine.Quantity);
            PurchaseLine.validate("qty. to invoice", PurchaseLine.Quantity);
            PurchaseLine.modify;
        end;
    end;
}

