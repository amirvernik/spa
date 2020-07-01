codeunit 60033 "UI Transfer Order Mgmt"
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
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        TransferNo: code[20];
        LineNumber: Integer;
        Err001: label 'Error: Pallet ID does not Exist, Cant create transfer for pallet';
        Err002: Label 'Error: Pallet is not closed, cant create transfer for pallet';
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        ItemRec: Record Item;
        maxEntry: Integer;
        ReleaseTransferDocument: Codeunit "Release Transfer Document";

    begin
        IF pFunction <> 'CreateTransferOrder' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Get Pallet ID
        JsonObj.SelectToken('palletid', JsonTkn);
        PalletID := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('from', JsonTkn);
        FromLocation := JsonTkn.AsValue().AsText();

        JsonObj.SelectToken('to', JsonTkn);
        ToLocation := JsonTkn.AsValue().AsText();

        //Errors on creation
        if not PalletHeader.get(PalletID) then
            pContent := err001;

        if PalletHeader.get(PalletID) then
            if PalletHeader."Pallet Status" <> PalletHeader."Pallet Status"::closed then
                pContent := err002;

        //Create the Transfer Order
        if PalletHeader.get(PalletID) then
            if palletheader."Pallet Status" = PalletHeader."Pallet Status"::Closed then begin
                TransferHeader.init;
                TransferHeader.insert(true);
                TransferHeader.validate("Transfer-from Code", FromLocation);
                TransferHeader.validate("Transfer-to Code", ToLocation);
                TransferHeader.modify;

                TransferNo := TransferHeader."No.";

                LineNumber := 10000;

                PalletLine.reset;
                PalletLine.setrange("Pallet ID", PalletID);
                if palletline.findset then
                    repeat
                        TransferLine.init;
                        TransferLine."Document No." := TransferNo;
                        TransferLine."Line No." := LineNumber;
                        TransferLine.validate("Item No.", PalletLine."Item No.");
                        TransferLine."Variant Code" := PalletLine."Variant Code";
                        TransferLine.validate(Quantity, PalletLine.Quantity);
                        TransferLine.validate("Qty. to Ship", PalletLine.Quantity);
                        TransferLine."Pallet ID" := PalletID;
                        TransferLine."Lot No." := PalletLine."Lot Number";
                        if PalletHeader.get(PalletLine."Pallet ID") then
                            TransferLine."Pallet Type" := PalletHeader."Pallet Type";
                        TransferLine.insert;
                        LineNumber += 10000;
                    until palletline.next = 0;
            end;
        TransferLine.reset;
        TransferLine.setrange("Document No.", TransferNo);
        if TransferLine.findset then
            repeat
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
                        RecGReservationEntry."Lot No." := PalletLine."Lot Number";
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
                        RecGReservationEntry."Lot No." := PalletLine."Lot Number";
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
            until TransferLine.next = 0;

        //Release Transfer Order
        if TransferHeader.get(TransferNo) then
            ReleaseTransferDocument.Run(TransferHeader);

        pContent := 'Transfer Order created : ' + TransferHeader."No.";
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
            if TransferHeader.status = TransferHeader.status::Released then begin
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

    //List of Transfer Orders - ListOfTransferOrders [9111]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure ListOfTransferOrders(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        TransferHeader: Record "Transfer Header";
        JsonObj: JsonObject;
        JsonArr: JsonArray;

    begin
        IF pFunction <> 'ListOfTransferOrders' THEN
            EXIT;

        TransferHeader.reset;
        if TransferHeader.findset then
            repeat
                JsonObj.add('TransferOrder', TransferHeader."No.");
                JsonObj.add('FromLocation', TransferHeader."Transfer-from Code");
                JsonObj.add('ToLocation', TransferHeader."Transfer-to Code");
                JsonArr.Add(JsonObj);
                clear(JsonObj);
            until TransferHeader.next = 0;
        JsonArr.WriteTo(pContent);
    end;
}