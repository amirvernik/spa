codeunit 60010 "UI Pallet Functions"
{

    //Get List Of Pallets - GetListOfPallets [8279]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPallets(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PackingMaterials: Record "Packing Material Line";
        PalletHeader: Record "Pallet Header";
        PalletLines: Record "Pallet Line";
        ItemRec: Record Item;
        ItemDescription: Text;
        ItemVariety: Record "Item Variant";
        ItemVarietyDescription: Text;
        Obj_JsonText: Text;

        JsonObj: JsonObject;
        JsonObjPM: JsonObject;
        JsonArr: JsonArray;
        JsonArrPM: JsonArray;
    begin
        IF pFunction <> 'GetListOfPallets' THEN
            EXIT;

        PalletHeader.reset;
        PalletHeader.SetFilter("Pallet Status", '= %1 | =%2', PalletHeader."Pallet Status"::Open, PalletHeader."Pallet Status"::Closed);
        if PalletHeader.findset then
            repeat
                JsonObj.add('Pallet ID', PalletHeader."Pallet ID");
                JsonObj.add('Location', PalletHeader."Location Code");
                JsonObj.add('Status', format(PalletHeader."Pallet Status"));
                JsonObj.add('Exist in Shipment', PalletHeader."Exist in warehouse shipment");
                JsonObj.add('PalletType', PalletHeader."Pallet Type");
                JsonObj.add('TotalQty', PalletHeader."Total Qty");
                JsonObj.add('RawMaterial', PalletHeader."Raw Material Pallet");
                JsonObj.add('CreationDate', PalletHeader."Creation Date");
                JsonObj.add('UserCreated', PalletHeader."User Created");
                PalletLines.reset;
                PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");
                if PalletLines.FindFirst() then begin
                    if ItemRec.Get(PalletLines."Item No.") then
                        ItemDescription := ItemRec.Description;

                    if ItemVariety.Get(PalletLines."Item No.", copystr(PalletLines."Variant Code", 1, 10)) then
                        ItemVarietyDescription := ItemVariety.Description;
                    JsonObj.add('Description', ItemDescription + '-' + ItemVarietyDescription);
                end;

                //Packing Materials
                PackingMaterials.reset;
                PackingMaterials.setrange("Pallet ID", PalletHeader."Pallet ID");
                if PackingMaterials.findset then
                    repeat
                        Clear(JsonObjPM);
                        JsonObjPM.add('Code', PackingMaterials."Item No.");
                        JsonObjPM.add('Description', PackingMaterials.Description);
                        JsonObjPM.add('Quantity', PackingMaterials.Quantity);
                        JsonArrPM.Add(JsonObjPM);
                    until PackingMaterials.next = 0;

                if JsonArrPM.Count > 0 then
                    JsonObj.add('Packing Materials', JsonArrPM);
                clear(JsonArrPM);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until palletheader.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Create Pallet by Json - CreatePalletFromJson [8301]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreatePalletFromJson(VAR pFunction: Text[50]; VAR
                                                                      pContent: Text)
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
        Qty: Decimal;
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
        VariantCode: Code[20];
        ItemUnitOfMeasure: Record "Item Unit of Measure";

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
                PalletID := NoSeriesMgt.GetNextNo(PalletSetup."Pallet No. Series", GetCurrTime, true);
                pContent := '{"palletid":"' + PalletID + '"}';
                PalletHeader.LockTable();
                PalletHeader.Init();
                PalletHeader."Pallet ID" := PalletID;
                PalletHeader."Location Code" := LocationCode;
                PalletHeader."Creation Date" := GetCurrTime();
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
                    else

                        IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].UnitOfMeasure' THEN
                            UOM := JSONBuffer.Value
                        else

                            IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].Quantity' THEN
                                EVALUATE(Qty, JSONBuffer.Value)
                            else

                                IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].LOTNo' THEN
                                    LOTNO := JSONBuffer.Value
                                else
                                    IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].VarietyCode' THEN
                                        VariantCode := JSONBuffer.Value;

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
                PalletLine.validate("Variant Code", VariantCode);
                if ItemRec.get(ItemNo) then begin
                    if format(ItemRec."Expiration Calculation") = '' then
                        PalletLine."Expiration Date" := GetCurrTime
                    else
                        PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), GetCurrTime);
                end;
                PalletLine.validate("Location Code", LocationCode);

                ItemRec.get(ItemNo);

                ItemUnitOfMeasure.reset;
                ItemUnitOfMeasure.setrange("Item No.", ItemNo);
                ItemUnitOfMeasure.SetRange("Default Unit Of Measure", true);
                if ItemUnitOfMeasure.findfirst then begin
                    //if ItemUnitOfMeasure.Code = UOM then begin //AV-27/08/2020
                    if ItemRec."Base Unit of Measure" = UOM then begin
                        PalletLine."Unit of Measure" := UOM;
                        PalletLine.validate(Quantity, qty);
                    end else begin
                        //AV-27/08/2020
                        PalletLine."Unit of Measure" := ItemRec."Base Unit of Measure";  //ItemUnitOfMeasure.Code;
                        PalletLine.validate(Quantity, qty * ItemUnitOfMeasure."Qty. per Unit of Measure");
                    end;
                end;
                PalletLine."Lot Number" := LOTNO;
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
                PurchaseHeader."Posting Date" := GetCurrTime; //yt14092020
                PurchaseHeader."Order Date" := GetCurrTime; //yt14092020

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
                    PurchaseLine.validate("Variant Code", PalletLine."Variant Code");
                    purchaseline.validate("Location Code", PalletLine."Location Code");
                    //New Web UI Fields - to Dummy Fields
                    PurchaseLine."Web UI Unit of Measure" := UOM;
                    PurchaseLine."Web UI Quantity" := PalletLine.Quantity;

                    ItemUnitOfMeasure.reset;
                    ItemUnitOfMeasure.setrange("Item No.", PalletLine."Item No.");
                    ItemUnitOfMeasure.SetRange("Default Unit Of Measure", true);
                    if ItemUnitOfMeasure.findfirst then
                        PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");
                    //PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity);
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


    //Get List Of Items by Attributes - GetListOfItemsByAttr [8506]
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
        JsonBuffer: Record "JSON Buffer" temporary;
        JsonText: Text;
        Attr_OM: Text;
        Attr_Size: Text;
        Attr_PrimaryPackageType: Text;
        Attr_PackageDescription: Text;
        Attr_Grade: Text;
        Attr_Color: Text;
        DescText: Text;
        JsonObj: JsonObject;
        JsonArr: JsonArray;
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
                        TempFilterItemAttributesBuffer.Attribute := 'Packaging Description';
                        TempFilterItemAttributesBuffer.Value := Attr_PackageDescription;
                        TempFilterItemAttributesBuffer.insert;
                    end;
                end;
            UNTIL JSONBuffer.NEXT = 0;
        end;
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
                    JsonObj.add('Item No.', TempItemFilteredFromAttributes."No.");
                    if ItemRec.get(TempItemFilteredFromAttributes."No.") then
                        JsonObj.add('ItemCategory', itemrec."Item Category Code");
                    JsonObj.add('Description', DescText);
                    JsonArr.Add(JsonObj);
                    clear(JsonObj);
                until TempItemFilteredFromAttributes.next = 0;
            JsonArr.WriteTo(pContent);
        end
        else
            pcontent := 'No Items';
    end;

    //Get List Of Items by Attributes - GetItemAttributeValues [8509]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetItemAttributeValues(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariant: Record "Item Variant";
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        JsonArr: JsonArray;

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
        Json_Variant: Text;
        JsonArrayAll: JsonArray;
    begin
        IF pFunction <> 'GetItemAttributeValues' THEN
            EXIT;

        clear(JsonArrayAll);

        //OM Attribute
        clear(jsonarr);
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_OM);
        if ItemAttributeValue.findset then
            repeat
                Clear(JsonObj);
                JsonObj.add('Code', ItemAttributeValue.ID);
                JsonObj.add('Description', ItemAttributeValue.Value);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemAttributeValue.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('OM', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        //Size Attribute
        clear(jsonarr);
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_size);
        if ItemAttributeValue.findset then
            repeat
                JsonObj.add('Code', ItemAttributeValue.ID);
                JsonObj.add('Description', ItemAttributeValue.Value);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemAttributeValue.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('Size', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        //Color Attribute
        clear(jsonarr);
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_Color);
        if ItemAttributeValue.findset then
            repeat
                JsonObj.add('Code', ItemAttributeValue.ID);
                JsonObj.add('Description', ItemAttributeValue.Value);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemAttributeValue.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('Color', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        //Grade Attribute
        clear(jsonarr);
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_Grade);
        if ItemAttributeValue.findset then
            repeat
                JsonObj.add('Code', ItemAttributeValue.ID);
                JsonObj.add('Description', ItemAttributeValue.Value);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemAttributeValue.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('Grade', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        //Primary Packaging Type Attribute
        clear(jsonarr);
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_PackageType);
        if ItemAttributeValue.findset then
            repeat
                JsonObj.add('Code', ItemAttributeValue.ID);
                JsonObj.add('Description', ItemAttributeValue.Value);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemAttributeValue.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('PrimaryPackagingType', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        //Packaging Description
        clear(jsonarr);
        ItemAttributeValue.reset;
        ItemAttributeValue.setrange(ItemAttributeValue."Attribute Name", Attr_PackDesc);
        if ItemAttributeValue.findset then
            repeat
                JsonObj.add('Code', ItemAttributeValue.ID);
                JsonObj.add('Description', ItemAttributeValue.Value);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemAttributeValue.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('PackagingDescription', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        //Item Variants
        clear(jsonarr);
        ItemVariant.reset;
        if ItemVariant.findset then
            repeat
                JsonObj.add('Item', ItemVariant."Item No.");
                JsonObj.add('Variety code', ItemVariant.Code);
                JsonObj.add('Description', ItemVariant.Description);
                JsonArr.Add(JsonObj);
                Clear(JsonObj);
            until ItemVariant.next = 0;

        if JsonArr.Count > 0 then begin
            JsonObj.add('Variaties', JsonArr);
            clear(JsonArr);
        end;
        JsonArrayAll.Add(JsonObj);
        clear(JsonObj);

        JsonArrayAll.WriteTo(pContent);
    end;

    //Add Item to Pallet - AddItemToPallet [8616]
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
        Qty: Decimal;
        POtype: text;
        LOTNO: code[20];
        PalletLineCheck: Record "Pallet Line";
        PalletLineNumber: Integer;
        VariantCode: code[20];
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        Released: Boolean;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        IF pFunction <> 'AddItemToPallet' THEN
            EXIT;

        ErrorText := '';
        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        iCount := 0;
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 2);
        JSONBuffer.SETRANGE(JSONBuffer."Token type", JSONBuffer."Token type"::String);
        IF JSONBuffer.FindSet() THEN
            repeat
                if JsonBuffer.path = '[' + format(icount) + '].palletid' then
                    PalletID := JSONBuffer.Value;
                if JsonBuffer.Path = '[' + Format(icount) + '].POtype' then
                    POtype := JSONBuffer.Value;
            until jsonbuffer.next = 0;

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

                            IF JSONBuffer.Path = '[1][' + FORMAT(iCount) + '].VarietyCode' THEN
                                VariantCode := JSONBuffer.Value;
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
                        PalletLine.validate("Variant Code", VariantCode);
                        if ItemRec.get(ItemNo) then begin
                            if format(ItemRec."Expiration Calculation") = '' then
                                PalletLine."Expiration Date" := GetCurrTime
                            else
                                PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), GetCurrTime);
                        end;
                        PalletLine."Location Code" := PalletHeader."Location Code";
                        PalletLine."Lot Number" := LOTNO;
                        PalletLine.Quantity := Qty;
                        PalletLine.Insert();

                        //Create Purchase Line - From Pallet
                        PurchaseHeader.reset;
                        PurchaseHeader.setrange(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::Order);
                        purchaseheader.setrange(PurchaseHeader."Batch Number", LOTNO);
                        case POtype of
                            'Grade':
                                PurchaseHeader.SetRange("Grading Result PO", true);
                            'Valueadd':
                                PurchaseHeader.SetRange("Microwave Process PO", true);
                        end;
                        if purchaseheader.findfirst then begin
                            PurchaseOrderNo := PurchaseHeader."No.";

                            PurchaseLineCheck.reset;
                            PurchaseLineCheck.setrange("Document Type", PurchaseHeader."Document Type");
                            PurchaseLineCheck.setrange("Document No.", purchaseheader."No.");
                            if PurchaseLineCheck.findlast then
                                LineNumber := PurchaseLineCheck."Line No." + 10000
                            else
                                LineNumber := 10000;

                            if PurchaseHeader.Status = PurchaseHeader.status::Released then begin
                                DocmentStatusMgmt.PerformManualReopen(PurchaseHeader);
                                Released := true;
                            end else
                                Released := false;

                            PurchaseLine.init;
                            PurchaseLine."Document No." := PurchaseHeader."No.";
                            purchaseline."Document Type" := PurchaseHeader."Document Type";
                            PurchaseLine."Line No." := LineNumber;
                            PurchaseLine.insert;
                            PurchaseLine.type := PurchaseLine.type::Item;
                            purchaseline.validate("No.", PalletLine."Item No.");
                            PurchaseLine.VALIDATE("Variant Code", PalletLine."Variant Code");
                            purchaseline.validate("Location Code", PalletLine."Location Code");
                            //PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity);
                            //PurchaseLine.Validate(Quantity);

                            //PurchaseLine.validate("Qty. to Receive", PurchaseLine.Quantity);
                            //PurchaseLine.validate("qty. to invoice", PurchaseLine.Quantity);
                            ItemUnitOfMeasure.reset;
                            ItemUnitOfMeasure.setrange("Item No.", PalletLine."Item No.");
                            ItemUnitOfMeasure.SetRange("Default Unit Of Measure", true);
                            if ItemUnitOfMeasure.findfirst then
                                PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");
                            //PurchaseLine.validate("Qty. (Base) SPA", PalletLine.Quantity);
                            //PurchaseLine.validate("Qty. to Receive", 0);
                            //PurchaseLine.validate("qty. to invoice", 0);
                            PurchaseLine.modify;

                            //if PalletLine.get(PalletID, PalletLineNumber) then begin
                            PalletLine."Purchase Order No." := PurchaseOrderNo;
                            PalletLine."Purchase Order Line No." := LineNumber;
                            palletline.modify;

                            if Released then
                                DocmentStatusMgmt.PerformManualRelease(PurchaseHeader);

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

    //Get List of Pallet Lines - GetListOfPalletLines [8627]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetListOfPalletLines(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletID: code[20];
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        JsonObjItems: JsonObject;
        JsonArrItems: JsonArray;
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
            PalletLine.reset;
            PalletLine.setrange(PalletLine."Pallet ID", PalletHeader."Pallet ID");
            if PalletLine.findset then begin
                JsonObj.add('Pallet ID', PalletHeader."Pallet ID");
                repeat
                    Clear(JsonObjItems);
                    JsonObjItems.add('Item No', PalletLine."Item No.");
                    JsonObjItems.add('Variety', PalletLine."Variant Code");
                    JsonObjItems.add('Item Description', PalletLine.Description);
                    JsonObjItems.add('Location', PalletLine."Location Code");
                    JsonObjItems.add('Lot', PalletLine."Variant Code");
                    JsonObjItems.add('Unit of Measure', PalletLine."Unit of Measure");
                    JsonObjItems.add('Item Qty', format(palletline.Quantity));
                    JsonObjItems.add('Line No', format(palletline."Line No."));
                    JsonArrItems.Add(JsonObjItems);

                until PalletLine.next = 0;
                if JsonArrItems.Count > 0 then
                    JsonObj.add('Item List', JsonArrItems);
                clear(JsonArrItems);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            end;
            JsonArr.WriteTo(pContent);
        end
        else
            pContent := 'No Pallet Exist';
    end;

    //Get LOT Numbers by Item - GetLotNumbersByItem [8556]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetLotNumbersByItem(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        ItemNo: code[20];
        Locationcode: code[20];
        ItemLedgerEntry: Record "Item Ledger Entry";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        LotSelection: Record "Lot Selection" temporary;
        ItemTemp: Record Item temporary;
        PalletReservationFunctions: Codeunit "Pallet Reservation Functions";
        ReserevationEntry: Record "Reservation Entry";
        QtyReserved: Decimal;
        VariantCode: Code[20];
        PurchaseHeader: Record "Purchase Header";

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
                    IF JSONBuffer.Path = 'varietycode' THEN
                        VariantCode := JSONBuffer.Value;

                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF JSONBuffer.Path = 'locationcode' THEN
                        Locationcode := JSONBuffer.Value;
            until jsonbuffer.next = 0;

            if LotSelection.findset then
                LotSelection.deleteall;

            if ItemTemp.findset then
                ItemTemp.deleteall;

            //Get Item Ledger Entries
            ItemLedgerEntry.RESET;
            ItemLedgerEntry.SETCURRENTKEY("Item No.", Open, "Variant Code", "Location Code", "Item Tracking",
              "Lot No.", "Serial No.");
            ItemLedgerEntry.SETRANGE("Item No.", ItemNo);
            if VariantCode <> '' then
                ItemLedgerEntry.SETRANGE("Variant Code", VariantCode);
            ItemLedgerEntry.SETRANGE(Open, TRUE);
            ItemLedgerEntry.SETRANGE("Location Code", Locationcode);
            ItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');

            if ItemLedgerEntry.findset then
                repeat
                    if not ItemTemp.get(ItemLedgerEntry."Lot No.") then begin
                        pContent := ItemLedgerEntry."Lot No.";
                        ItemTemp.init;
                        ItemTemp."No." := ItemLedgerEntry."Lot No.";
                        ItemTemp."Scrap %" := ItemLedgerEntry.Quantity;

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

            ItemTemp.reset;
            if ItemTemp.findset then begin
                repeat
                    JsonObj.add('Lot No', ItemTemp."No.");
                    PurchaseHeader.reset;
                    PurchaseHeader.setrange(PurchaseHeader."Document Type", PurchaseHeader."Document Type"::Order);
                    PurchaseHeader.setrange("Batch Number", ItemTemp."No.");
                    if PurchaseHeader.findfirst then
                        JsonObj.add('VendorShipmentNo', PurchaseHeader."Vendor Shipment No.")
                    else
                        JsonObj.add('VendorShipmentNo', '');
                    JsonObj.add('Qty', format(ItemTemp."Scrap %"));
                    JsonObj.add('Reserved', format(ItemTemp."Budget Quantity"));
                    JsonArr.Add(JsonObj);
                    clear(JsonObj);
                until ItemTemp.next = 0;
                JsonArr.WriteTo(pContent);
            end
            else
                pContent := 'No Entries Found';
        end;
    end;

    //Get LOT Numbers by Item
    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
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
    end;*/


    //Check Pallets Proccess Setup Password
    //Return true if password exist else false
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CheckPalletPass(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        Password: text[10];
        PalletProcessSetup: Record "Pallet Process Setup";
    begin
        IF pFunction <> 'CheckPalletPass' THEN
            EXIT;
        JsonObj.ReadFrom(pContent);
        JsonObj.SelectToken('pwd', JsonTkn);
        Password := JsonTkn.AsValue().AsText();

        if PalletProcessSetup.get() then begin

            if PalletProcessSetup."Password Pallet Management" = Password then begin
                pContent := 'true';
                exit;
            end;
        end;
        pContent := 'false';
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
                PalletLine."Expiration Date" := GetCurrTime()
            else
                PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), GetCurrTime);
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

    //Get List Of Variants - GetAllVariants [TFS9107]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllVariants(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        ItemTemp: Record Item temporary;
        ItemVariant: Record "Item Variant";
        JsonObj: JsonObject;
        JsonArr: JsonArray;

    begin
        IF pFunction <> 'GetAllVariants' THEN
            EXIT;

        if ItemTemp.findset then
            itemtemp.deleteall;

        ItemVariant.reset;
        if ItemVariant.findset then
            repeat
                if not ItemTemp.get(ItemVariant.Code) then begin
                    itemtemp.init;
                    ItemTemp."No." := ItemVariant.code;
                    ItemTemp.Description := ItemVariant.Description;
                    ItemTemp.insert;
                end;
            until ItemVariant.next = 0;

        ItemTemp.reset;
        if ItemTemp.findset then
            repeat
                JsonObj.add('Variety', ItemTemp."No.");
                JsonObj.add('Description', itemtemp.Description);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until ItemTemp.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    procedure GetCurrTime(): date;
    var
        lLocalTime: Time;
        lDateTimeTxt: Text;
        lTimeTxt: Text;
        IntHour: Integer;
        GMTplus: date;

    BEGIN
        EVALUATE(lLocalTime, '17:00:00');
        lDateTimeTxt := FORMAT(CREATEDATETIME(TODAY, time), 0, 9);
        lTimeTxt := COPYSTR(lDateTimeTxt, STRPOS(lDateTimeTxt, 'T') + 1);
        lTimeTxt := COPYSTR(lTimeTxt, 1, STRPOS(lTimeTxt, ':') - 1);
        evaluate(IntHour, lTimeTxt);
        if IntHour > 13 then
            GMTplus := CalcDate('+1D', Today)
        else
            GMTplus := Today;
        exit(GMTplus);
    END;



    //Cancel Pallet - UI
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CancelPallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletID: code[20];
        PalletHeader: Record "Pallet Header";
        LPalletLedgerEntry: Record "Pallet Ledger Entry";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        JsonObjItems: JsonObject;
        JsonArrItems: JsonArray;
        Err10: Label 'Canceled status is allowed only for open status pallet';
        Err11: Label 'Can`t cancel a pallet that has pallet ledger entries';
    begin
        IF pFunction <> 'CancelPallet' THEN
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
            if (PalletHeader."Pallet Status" = "PalletHeader"."Pallet Status"::Open) and not (PalletHeader."Exist in warehouse shipment") then begin
                LPalletLedgerEntry.Reset();
                LPalletLedgerEntry.SetRange("Pallet ID", PalletID);
                if LPalletLedgerEntry.FindFirst() then
                    pContent := Err11
                else begin
                    PalletHeader.validate("Pallet Status", "Pallet Status"::Canceled);
                    if not PalletHeader.Modify() then;
                    pContent := 'Success';
                end;
            end else
                pContent := Err10;
        end
        else
            pContent := StrSubstNo('Pallet %1 not Exist', PalletID);
    end;



}


