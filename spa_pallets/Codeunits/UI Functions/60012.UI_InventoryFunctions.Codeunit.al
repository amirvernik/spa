codeunit 60012 "UI Inventory Functions"
{
    //Close Pallet - By Pallet ID - ClosePallet [8496]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure ClosePallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PalletHeader: Record "Pallet Header";
        PalletFunctions: Codeunit "Pallet Functions";
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletID: code[20];
        PurchasePost: Codeunit "Purch.-Post";
        PurchaseHeaderTemp: Record "Purchase Header" temporary;
        PurchaseHeaderToPost: Record "Purchase Header";
        PurchaseLineCheck: Record "Purchase Line";
        PalletLines: Record "Pallet Line";
        PurchaseFunctions: Codeunit "SPA Purchase Functions";


    begin
        IF pFunction <> 'ClosePallet' THEN
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
            PalletFunctions.ClosePallet(PalletHeader);

            //Create Purchase Receipt
            PalletLines.reset;
            PalletLines.setrange(PalletLines."Pallet ID", PalletHeader."Pallet ID");
            if PalletLines.findset then
                repeat
                    if not PurchaseHeaderTemp.get(PurchaseHeaderTemp."Document Type"::order, PalletLines."Purchase Order No.") then begin
                        PurchaseHeaderTemp.init;
                        PurchaseHeaderTemp."Document Type" := PurchaseHeaderTemp."Document Type"::order;
                        PurchaseHeaderTemp."No." := PalletLines."Purchase Order No.";
                        PurchaseHeaderTemp.insert;
                    end;
                until PalletLines.next = 0;

            //Posting the Purchase Order
            PurchaseHeaderTemp.reset;
            if PurchaseHeaderTemp.findset then
                repeat
                    PurchaseLineCheck.reset;
                    PurchaseLineCheck.setrange("Document Type", PurchaseHeaderTemp."Document Type");
                    PurchaseLineCheck.setrange("Document No.", PurchaseHeaderTemp."No.");
                    PurchaseLineCheck.setfilter("Qty. to Receive", '<>%1', 0);
                    if PurchaseLineCheck.findset then begin
                        PurchaseHeaderToPost.reset;
                        PurchaseHeaderToPost.setrange(PurchaseHeaderToPost."Document Type", PurchaseHeaderTemp."Document Type");
                        PurchaseHeaderToPost.SetRange(PurchaseHeaderToPost."No.", PurchaseHeaderTemp."No.");
                        if PurchaseHeaderToPost.findfirst then begin
                            PurchaseHeaderTemp := PurchaseHeaderToPost;
                            PurchaseHeaderTemp.Receive := true;
                            PurchaseHeaderTemp.Invoice := false;
                            PurchasePost.Run(PurchaseHeaderTemp);

                            //Create Negative Adjustment for WebUI
                            //PurchaseFunctions.CreateRMNegativeAdjustment(PurchaseHeaderTemp);
                        end;
                    end;
                until PurchaseHeaderTemp.next = 0;

            if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::Closed then
                pContent := 'Success - Pallet closed' else
                pContent := 'Error1'
        end
        else
            pContent := 'Pallet does not exist : ' + PalletID;
    end;

    //Open Pallet - By Pallet ID - OpenPallet [8298]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure OpenPallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PalletHeader: Record "Pallet Header";
        PalletFunctions: Codeunit "Pallet Functions";
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletID: code[20];
        PackingMaterials: Record "Packing Material Line";
        PosInt: Integer;
    begin
        IF pFunction <> 'OpenPallet' THEN
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

        PosInt := StrPos(PalletID, '-');
        if PosInt > 0 then begin
            PalletID := CopyStr(PalletID, PosInt - 1);
            PalletID := DelChr(PalletID, '=', ' ');
        end;

        if PalletHeader.GET(PalletID) then begin
            //Mark All Packing Materials to return
            PackingMaterials.reset;
            PackingMaterials.setrange("Pallet ID", PalletHeader."Pallet ID");
            if PackingMaterials.findset then
                repeat
                    PackingMaterials.Returned := true;
                    PackingMaterials.modify;
                until PackingMaterials.next = 0;

            PalletFunctions.ReOpenPallet(PalletHeader);
            if PalletHeader."Pallet Status" = PalletHeader."Pallet Status"::Open then
                pContent := 'Succees - Pallet Opened' else
                pcontent := 'Error - Pallet is Not Closed'
        end
        else
            pContent := 'Error - Pallet does not Exist';
    end;

    //Get All Locations - GetAllLocations [8502]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllLocations(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        LocationRec: Record Location;
        JsonObj: JsonObject;
        JsonArr: JsonArray;
    begin
        IF pFunction <> 'GetAllLocations' THEN
            EXIT;
        LocationRec.reset;
        LocationRec.setrange("Use As In-Transit", false);
        if LocationRec.findset then
            repeat
                JsonObj.add('Location', LocationRec.code);
                JsonObj.add('Description', LocationRec.Name);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until LocationRec.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Get All Locations (In Transit)  GetAllLocationsInTransit [9266]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure GetAllLocationsInTransit(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        LocationRec: Record Location;
        JsonObj: JsonObject;
        JsonArr: JsonArray;
    begin
        IF pFunction <> 'GetAllLocationsInTransit' THEN
            EXIT;
        LocationRec.reset;
        LocationRec.setrange("Use As In-Transit", true);
        if LocationRec.findset then
            repeat
                JsonObj.add('Location', LocationRec.code);
                JsonObj.add('Description', LocationRec.Name);
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until LocationRec.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Create Purchase Order Line - CreatePurchaseOrderLine [8642]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure CreatePurchaseOrderLine(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        BatchNumber: code[20];
        PurchaseOrder: code[20];
        ItemNumber: code[20];
        UOM: code[20];
        Qty: Decimal;
        LocationCode: code[20];
        JsonBuffer: Record "JSON Buffer" temporary;
        PurchaseLine: Record "Purchase Line";
        PurchaseLineCheck: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        LineNumber: Integer;
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        MaxEntry: Integer;
        ItemRec: Record Item;
        PurchaseHeaderTemp: Record "Purchase Header" temporary;
        PurchasePost: Codeunit "Purch.-Post";

        Obj_JsonText: Text;
    begin
        IF pFunction <> 'CreatePurchaseOrderLine' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN begin
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'batchnumber') > 0 THEN
                        BatchNumber := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'ponumber') > 0 THEN
                        PurchaseOrder := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'itemno') > 0 THEN
                        ItemNumber := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'qty') > 0 THEN
                        evaluate(qty, JSONBuffer.Value);
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'unitofmeasure') > 0 THEN
                        evaluate(UOM, JSONBuffer.Value);
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'location') > 0 THEN
                        evaluate(LocationCode, JSONBuffer.Value);

            UNTIL JSONBuffer.NEXT = 0;

            pcontent := BatchNumber;
            if PurchaseHeader.get(PurchaseHeader."Document Type"::Order, PurchaseOrder) then begin

                if purchaseheader.status = PurchaseHeader.status::Released then
                    DocmentStatusMgmt.PerformManualReopen(PurchaseHeader);

                PurchaseLineCheck.reset;
                PurchaseLineCheck.setrange(PurchaseLineCheck."Document Type", PurchaseHeader."Document Type");
                PurchaseLineCheck.setrange(PurchaseLineCheck."Document No.", PurchaseHeader."No.");
                if PurchaseLineCheck.findlast then
                    LineNumber := PurchaseLineCheck."Line No." + 10000
                else
                    LineNumber := 10000;

                PurchaseLine.init;
                PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                PurchaseLine."Document No." := PurchaseHeader."No.";
                PurchaseLine."Line No." := LineNumber;
                PurchaseLine.insert;
                PurchaseLine.Type := PurchaseLine.type::Item;
                PurchaseLine.validate(PurchaseLine."No.", ItemNumber);
                PurchaseLine."Location Code" := LocationCode;
                PurchaseLine."Unit of Measure Code" := UOM;
                PurchaseLine.validate("Qty. (Base) SPA", qty);
                PurchaseLine.validate("Qty. to Receive", purchaseline.Quantity);
                PurchaseLine.validate("Qty. to Invoice", purchaseline.Quantity);
                PurchaseLine.modify;

            end;

            PurchaseLine.reset;
            PurchaseLine.setrange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
            PurchaseLine.setrange("Document No.", PurchaseOrder);
            PurchaseLine.setrange("Line No.", LineNumber);
            if PurchaseLineCheck.findfirst then begin

                pcontent := 'Success';
                PurchaseHeader.get(PurchaseHeader."Document Type"::order, PurchaseLine."Document No.");

                //DocmentStatusMgmt.PerformManualReopen(PurchaseHeader);
                if ItemRec.get(PurchaseLine."No.") then
                    if itemrec."Lot Nos." <> '' then begin
                        //Create Reservation Entry
                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;
                        RecGReservationEntry2.reset;
                        RecGReservationEntry2.setrange(RecGReservationEntry2."Source ID", PurchaseLine."Document No.");
                        RecGReservationEntry2.setrange(RecGReservationEntry2."Source Ref. No.", PurchaseLine."Line No.");
                        RecGReservationEntry2.setrange(RecGReservationEntry2."Source Type", 39);
                        RecGReservationEntry2.setrange(RecGReservationEntry2."Source Subtype", 1);
                        if not RecGReservationEntry2.findfirst then begin
                            RecGReservationEntry.init;
                            RecGReservationEntry."Entry No." := MaxEntry;
                            //V16.0 - Changed From [2] to "surplus" on Enum
                            RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                            //V16.0 - Changed From [2] to "surplus" on Enum
                            RecGReservationEntry."Creation Date" := Today;
                            RecGReservationEntry."Created By" := UserId;
                            RecGReservationEntry."Expected Receipt Date" := Today;
                            RecGReservationEntry.Positive := true;
                            RecGReservationEntry."Source Type" := 39;
                            RecGReservationEntry."Source Subtype" := 1;
                            RecGReservationEntry."Source ID" := PurchaseLine."Document No.";
                            RecGReservationEntry."Source Ref. No." := PurchaseLine."Line No.";
                            RecGReservationEntry.validate("Location Code", PurchaseLine."Location Code");
                            //V16.0 - Changed From [1] to "Lot No." on Enum
                            RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                            //V16.0 - Changed From [1] to "Lot No." on Enum
                            RecGReservationEntry."Lot No." := PurchaseHeader."Batch Number";
                            RecGReservationEntry.validate("Item No.", PurchaseLine."No.");
                            if PurchaseLine."Variant Code" <> '' then
                                RecGReservationEntry.Validate("Variant Code", PurchaseLine."Variant Code");
                            RecGReservationEntry.Description := PurchaseLine.Description;
                            RecGReservationEntry.validate("Quantity (Base)", purchaseline."Qty. (Base) SPA");
                            RecGReservationEntry.validate(Quantity, purchaseline.Quantity);
                            RecGReservationEntry."Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
                            RecGReservationEntry."Packing Date" := today;
                            if format(ItemRec."Expiration Calculation") <> '' then
                                RecGReservationEntry."Expiration Date" := calcdate('+' + format(ItemRec."Expiration Calculation"), today)
                            else
                                RecGReservationEntry."Expiration Date" := today;
                            RecGReservationEntry.insert;
                        end
                        else
                            pContent := 'Error';
                    end;
                DocmentStatusMgmt.PerformManualRelease(PurchaseHeader);

                PurchaseHeaderTemp.init;
                PurchaseHeaderTemp.TransferFields(PurchaseHeader);
                PurchaseHeaderTemp.Receive := true;
                PurchaseHeaderTemp.Invoice := false;
                PurchaseHeaderTemp.insert;
                PurchasePost.Run(PurchaseHeaderTemp);
            end;
        end;
    end;
}