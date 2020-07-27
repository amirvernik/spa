codeunit 60034 "UI Transfer Order Management"
{
    //Create Transfer Order - CreateTransferOrder [9108]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure CreateTransferOrder(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        PalletID: code[20];
        FromLocation: code[20];
        ToLocation: code[20];
        InTransitLocation: code[20];
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        TransferNo: code[20];
        LineNumber: Integer;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        ItemRec: Record Item;
        maxEntry: Integer;
        ReleaseTransferDocument: Codeunit "Release Transfer Document";

    begin
        IF pFunction <> 'CreateTransferOrder' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        JsonObj.SelectToken('from', JsonTkn);
        FromLocation := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('to', JsonTkn);
        ToLocation := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('intransit', JsonTkn);
        InTransitLocation := JsonTkn.AsValue().AsText();

        //Create the Transfer Order
        TransferHeader.init;
        TransferHeader.insert(true);
        TransferHeader.validate("Transfer-from Code", FromLocation);
        TransferHeader.validate("Transfer-to Code", ToLocation);
        TransferHeader.validate("In-Transit Code", InTransitLocation);
        TransferHeader.modify;
        TransferNo := TransferHeader."No.";

        pcontent := 'Transfer Order created: ' + TransferNo;

    end;

    //Ship Transfer Order - ShipTransferOrder [9109]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure ShipTransferOrder(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        TransferNo: code[20];
        TransferHeader: Record "Transfer Header";
        Err001: Label 'Error : Transfer Order does not exist';
        Err002: Label 'Error : Transfer Order is not released';
        PostTransferShipment: Codeunit "TransferOrder-Post Shipment";
        ReleaseTransfer: Codeunit "Release Transfer Document";

    begin
        IF pFunction <> 'ShipTransferOrder' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Transfer Order No.
        JsonObj.SelectToken('transferno', JsonTkn);
        TransferNo := JsonTkn.AsValue().AsText();

        //Errors on Transfer Ship
        if not TransferHeader.get(TransferNo) then
            pContent := err001;

        if TransferHeader.get(TransferNo) then
            if TransferHeader.Status <> TransferHeader.status::Released then
                pContent := err002;

        if TransferHeader.get(TransferNo) then
            if TransferHeader.status = TransferHeader.status::Open then begin
                ReleaseTransfer.Run(TransferHeader);
                PostTransferShipment.run(TransferHeader);
                pContent := 'Transfer Order ' + TransferNo + ' Shipped';
            end;
    end;

    //Receive Transfer Order - ReceiveTransferOrder [9110]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure ReceiveTransferOrder(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        TransferNo: code[20];
        TransferHeader: Record "Transfer Header";
        Err001: Label 'Error : Transfer Order does not exist';
        Err002: Label 'Error : Transfer Order is not released';
        PostTransferReceipt: Codeunit "TransferOrder-Post Receipt";

    begin
        IF pFunction <> 'ReceiveTransferOrder' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Transfer Order No.
        JsonObj.SelectToken('transferno', JsonTkn);
        TransferNo := JsonTkn.AsValue().AsText();

        //Errors on Transfer Ship
        if not TransferHeader.get(TransferNo) then
            pContent := err001;

        if TransferHeader.get(TransferNo) then
            if TransferHeader.Status <> TransferHeader.status::Released then
                pContent := err002;

        if TransferHeader.get(TransferNo) then
            if TransferHeader.status = TransferHeader.status::Released then begin
                PostTransferReceipt.run(TransferHeader);
                pContent := 'Transfer Order ' + TransferNo + ' Received'
            end;
    end;

    //List of Transfer Orders - GetListOfTransferOrdersForPallet [9111]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure GetListOfTransferOrdersForPallet(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        JsonObj: JsonObject;
        JsonObjLines: JsonObject;
        JsonArr: JsonArray;
        JsonArrLines: JsonArray;

    begin
        IF pFunction <> 'GetListOfTransferOrdersForPallet' THEN
            EXIT;

        TransferHeader.reset;
        if TransferHeader.findset then
            repeat
                if CheckIfTransferOrderShipped(TransferHeader) then
                    if CheckIfPallet(TransferHeader) then begin
                        JsonObj.add('TransferOrder', TransferHeader."No.");
                        JsonObj.add('FromLocation', TransferHeader."Transfer-from Code");
                        JsonObj.add('ToLocation', TransferHeader."Transfer-to Code");
                        TransferLine.reset;
                        TransferLine.setrange("Document No.", TransferHeader."No.");
                        if TransferLine.findset then begin
                            repeat
                                Clear(JsonObjLines);
                                JsonObjLines.add('LineNo', TransferLine."Line No.");
                                JsonObjLines.add('ItemNo', TransferLine."Item No.");
                                JsonObjLines.add('VarietyCode', TransferLine."Variant Code");
                                JsonObjLines.add('QtyToShip', TransferLine."Qty. to Ship");
                                JsonObjLines.add('LotNo', TransferLine."Lot No.");
                                JsonObjLines.add('PalletID', TransferLine."Pallet ID");
                                JsonArrLines.Add(JsonObjLines);
                            until TransferLine.next = 0;
                            if JsonArrLines.Count > 0 then
                                JsonObj.add('Item List', JsonArrLines);
                            clear(JsonArrLines);
                            JsonArr.Add(JsonObj);
                            clear(JsonObj);
                        end;
                    end;
            until TransferHeader.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //List of Transfer Orders - GetListOfTransferOrdersForItem [9237]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure GetListOfTransferOrdersForItem(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        JsonObj: JsonObject;
        JsonObjLines: JsonObject;
        JsonArr: JsonArray;
        JsonArrLines: JsonArray;

    begin
        IF pFunction <> 'GetListOfTransferOrdersForItem' THEN
            EXIT;

        TransferHeader.reset;
        if TransferHeader.findset then
            repeat
                if CheckIfTransferOrderShipped(TransferHeader) then
                    if not CheckIfPallet(TransferHeader) then begin
                        JsonObj.add('TransferOrder', TransferHeader."No.");
                        JsonObj.add('FromLocation', TransferHeader."Transfer-from Code");
                        JsonObj.add('ToLocation', TransferHeader."Transfer-to Code");
                        TransferLine.reset;
                        TransferLine.setrange("Document No.", TransferHeader."No.");
                        if TransferLine.findset then begin
                            repeat
                                Clear(JsonObjLines);
                                JsonObjLines.add('LineNo', TransferLine."Line No.");
                                JsonObjLines.add('ItemNo', TransferLine."Item No.");
                                JsonObjLines.add('VarietyCode', TransferLine."Variant Code");
                                JsonObjLines.add('QtyToShip', TransferLine."Qty. to Ship");
                                JsonArrLines.Add(JsonObjLines);
                            until TransferLine.next = 0;
                            if JsonArrLines.Count > 0 then
                                JsonObj.add('Item List', JsonArrLines);
                            clear(JsonArrLines);
                            JsonArr.Add(JsonObj);
                            clear(JsonObj);
                        end;
                    end;
            until TransferHeader.next = 0;
        JsonArr.WriteTo(pContent);
    end;

    //Delete Transfer Order Line - DeleteTransferOrderLine [9238]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure DeleteTransferOrderLine(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        TransferNo: code[20];
        LineNo: Integer;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        Err001: Label 'Error : Transfer Order Line Shipped, cant delete';
        Err002: Label 'Error : Transfer Order is not released';
        ReservationEntry: Record "Reservation Entry";
    begin
        IF pFunction <> 'DeleteTransferOrderLine' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Transfer Order No.
        JsonObj.SelectToken('transferno', JsonTkn);
        TransferNo := JsonTkn.AsValue().AsText();

        //Get Transfer Order Line
        JsonObj.SelectToken('lineno', JsonTkn);
        LineNo := JsonTkn.AsValue().AsInteger();

        //TRansfer Order Line is shipped
        if TransferLine.get(TransferNo, LineNo) then
            if TransferLine."Qty. Shipped (Base)" > 10 then begin
                pContent := err001;
                exit;
            end;

        if TransferLine.get(TransferNo, LineNo) then begin
            TransferLine.Delete();
            ReservationEntry.reset;
            ReservationEntry.setrange("Source ID", TransferNo);
            ReservationEntry.setrange("Source Type", 5741);
            ReservationEntry.setrange("Source Ref. No.", LineNo);
            if ReservationEntry.findset then
                ReservationEntry.deleteall;
        end;
        pContent := 'Transfer Order ' + TransferNo + ' Line No. ' + format(LineNo) + ' Deleted';
    end;

    //Add Transfer Order Line From Pallet - AddTransferOrderLinePallet [9239]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure AddTransferOrderLinePallet(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonObjResult: JsonObject;
        JsonTkn: JsonToken;
        TransferNo: code[20];
        PalletId: code[20];
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        ReservationEntry: Record "Reservation Entry";
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        LineNumber: integer;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        ItemRec: Record Item;
        maxEntry: Integer;

    begin
        IF pFunction <> 'AddTransferOrderLinePallet' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Transfer Order No.
        JsonObj.SelectToken('transferno', JsonTkn);
        TransferNo := JsonTkn.AsValue().AsText();

        //Get Pallet ID
        JsonObj.SelectToken('palletid', JsonTkn);
        PalletId := JsonTkn.AsValue().AsText();

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", PalletId);
        if palletline.findset then
            repeat
                TransferLine.reset;
                transferline.setrange("Document No.", TransferNo);
                if TransferLine.FindLast then
                    LineNumber := TransferLine."Line No." + 10000
                else
                    LineNumber := 10000;

                TransferLine.init;
                TransferLine."Document No." := TransferNo;
                TransferLine."Line No." := LineNumber;
                TransferLine.validate("Item No.", PalletLine."Item No.");
                TransferLine."Variant Code" := PalletLine."Variant Code";
                TransferLine.validate(Quantity, PalletLine.Quantity);
                TransferLine.validate("Qty. to Ship", PalletLine.Quantity);
                TransferLine."Pallet ID" := PalletId;
                TransferLine."Lot No." := PalletLine."Lot Number";
                if PalletHeader.get(PalletLine."Pallet ID") then
                    TransferLine."Pallet Type" := PalletHeader."Pallet Type";
                TransferLine.insert;
                //Create Reservation Entry
                //From Location - Negative
                if ItemRec.get(TransferLine."Item No.") then
                    if itemrec."Lot Nos." <> '' then begin
                        //Create Reservation Entry

                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        //V16.0 - Changed From [2] to "Surplus" on Enum
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                        //V16.0 - Changed From [2] to "surplus" on Enum
                        RecGReservationEntry.validate("Creation Date", Today);
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Shipment Date" := today;
                        RecGReservationEntry."Source Type" := 5741;
                        RecGReservationEntry."Source Subtype" := 0;
                        RecGReservationEntry."Source ID" := TransferLine."Document No.";
                        RecGReservationEntry."Source Ref. No." := TransferLine."Line No.";
                        RecGReservationEntry."Location Code" := TransferLine."Transfer-from Code";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Lot No." := TransferLine."Lot No.";
                        RecGReservationEntry.validate("Item No.", TransferLine."Item No.");
                        if TransferLine."Variant Code" <> '' then
                            RecGReservationEntry.validate("Variant Code", TransferLine."Variant Code");
                        RecGReservationEntry.validate("Quantity (Base)", -1 * TransferLine.Quantity);
                        RecGReservationEntry.validate(Quantity, -1 * TransferLine.Quantity);
                        RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                        RecGReservationEntry."Packing Date" := PalletHeader."Creation Date";
                        RecGReservationEntry.Positive := false;
                        RecGReservationEntry.insert;

                        //To Location - Positive
                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        //V16.0 - Changed From [2] to "Surplus" on Enum
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                        //V16.0 - Changed From [2] to "Surplus" on Enum
                        RecGReservationEntry.validate("Creation Date", Today);
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Shipment Date" := today;
                        RecGReservationEntry."Source Type" := 5741;
                        RecGReservationEntry."Source Subtype" := 1;
                        RecGReservationEntry."Source ID" := TransferLine."Document No.";
                        RecGReservationEntry."Source Ref. No." := TransferLine."Line No.";
                        RecGReservationEntry."Location Code" := TransferLine."Transfer-to Code";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Lot No." := TransferLine."Lot No.";
                        RecGReservationEntry.validate("Item No.", TransferLine."Item No.");
                        if TransferLine."Variant Code" <> '' then
                            RecGReservationEntry.validate("Variant Code", TransferLine."Variant Code");
                        RecGReservationEntry.validate("Quantity (Base)", TransferLine.Quantity);
                        RecGReservationEntry.validate(Quantity, TransferLine.Quantity);
                        RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                        RecGReservationEntry."Packing Date" := PalletHeader."Creation Date";
                        RecGReservationEntry.Positive := true;
                        RecGReservationEntry.insert;
                    end;
            until palletline.next = 0;
        if TransferLine.get(TransferNo, LineNumber) then begin
            JsonObjResult.add('message', 'Success');
            JsonObjResult.add('lineNum', LineNumber);
            JsonObjResult.WriteTo(pContent);
        end
        else begin
            JsonObjResult.add('message', 'Error');
            JsonObjResult.WriteTo(pContent);
        end;
    end;

    //Add Transfer Order Line From Item - AddTransferOrderLineItem [9268]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure AddTransferOrderLineItem(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        JsonObj: JsonObject;
        JsonObjResult: JsonObject;
        JsonTkn: JsonToken;
        TransferNo: code[20];
        ItemNumber: code[20];
        VariantCode: code[20];
        QtyToShip: Decimal;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        LineNumber: integer;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        ItemRec: Record Item;
        maxEntry: Integer;

    begin
        IF pFunction <> 'AddTransferOrderLineItem' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Transfer Order No.
        JsonObj.SelectToken('transferno', JsonTkn);
        TransferNo := JsonTkn.AsValue().AsText();

        //Get Item Number
        JsonObj.SelectToken('itemno', JsonTkn);
        ItemNumber := JsonTkn.AsValue().AsText();

        //Get Variety Code
        JsonObj.SelectToken('varietycode', JsonTkn);
        VariantCode := JsonTkn.AsValue().AsText();

        //Get Qty to Ship
        JsonObj.SelectToken('quantity', JsonTkn);
        QtyToShip := JsonTkn.AsValue().AsDecimal();

        pContent := '';

        TransferLine.reset;
        transferline.setrange("Document No.", TransferNo);
        if TransferLine.FindLast then
            LineNumber := TransferLine."Line No." + 10000
        else
            LineNumber := 10000;

        TransferLine.init;
        TransferLine."Document No." := TransferNo;
        TransferLine."Line No." := LineNumber;
        TransferLine.validate("Item No.", ItemNumber);
        TransferLine.validate("Variant Code", VariantCode);
        TransferLine.validate(Quantity, QtyToShip);
        TransferLine.validate("Qty. to Ship", QtyToShip);
        TransferLine.insert;

        if TransferLine.get(TransferNo, LineNumber) then begin
            JsonObjResult.add('message', 'Success');
            JsonObjResult.add('lineNum', LineNumber);
            JsonObjResult.WriteTo(pContent);
        end
        else begin
            JsonObjResult.add('message', 'Error');
            JsonObjResult.WriteTo(pContent);
        end;
    end;

    procedure CheckIfTransferOrderShipped(pTransferHeader: Record "Transfer Header"): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.reset;
        TransferLine.setrange("Document No.", pTransferHeader."No.");
        TransferLine.setfilter("Qty. to Ship", '>%1', 0);
        if TransferLine.findfirst then
            exit(true) else
            exit(false);
    end;

    procedure CheckIfPallet(pTransferHeader: Record "Transfer Header"): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.reset;
        TransferLine.setrange("Document No.", pTransferHeader."No.");
        TransferLine.setfilter("Pallet ID", '<>%1', '');
        if TransferLine.findfirst then
            exit(true) else
            exit(false);
    end;
}