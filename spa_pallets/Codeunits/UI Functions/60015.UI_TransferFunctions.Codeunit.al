codeunit 60015 "UI Transfer Functions"
{
    //Transfer Pallet - TransferPallet [8559]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure TransferPallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PalletHeader: Record "Pallet Header";
        PalletHeader2: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        JsonBuffer: Record "JSON Buffer" temporary;
        PalletSetup: Record "Pallet Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        PalletID: code[20];
        ToLocation: code[20];
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        maxEntry: Integer;
        ItemRec: Record Item;
        ErrLocation: Label 'Ship from location can`t be equal to the shipping location';

    begin
        IF pFunction <> 'TransferPallet' THEN
            EXIT;

        JsonBuffer.ReadFromText(pContent);

        //Depth 2 - Header
        JSONBuffer.RESET;
        JSONBuffer.SETRANGE(JSONBuffer.Depth, 1);
        IF JSONBuffer.FINDSET THEN
            REPEAT
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'palletid') > 0 THEN
                        PalletID := JSONBuffer.Value;
                IF JSONBuffer."Token type" = JSONBuffer."Token type"::String THEN
                    IF STRPOS(JSONBuffer.Path, 'tolocation') > 0 THEN
                        ToLocation := JSONBuffer.Value;
            until JsonBuffer.next = 0;

        PalletHeader.Reset();
        PalletHeader.SetRange("Pallet ID", PalletID);
        PalletHeader.SetRange("Pallet Status", PalletHeader."Pallet Status"::Closed);
        PalletHeader.SetRange("Exist in warehouse shipment", false);
        if PalletHeader.FindFirst() then begin
            if PalletHeader."Location Code" = ToLocation then begin
                Error(ErrLocation);
                exit;
            end;

            PalletSetup.get;
            ItemJournalLine.reset;
            ItemJournalLine.setrange("Journal Template Name", PalletSetup."Item Reclass Template");
            ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Reclass Batch");
            if ItemJournalLine.findlast then
                LineNumber := ItemJournalLine."Line No." + 10000
            else
                LineNumber := 10000;


            PalletLine.reset;
            PalletLine.setrange("Pallet ID", PalletID);
            if palletline.findset then
                repeat
                    ItemJournalLine.init;
                    ItemJournalLine."Journal Template Name" := PalletSetup."Item Reclass Template";
                    ItemJournalLine."Journal Batch Name" := PalletSetup."Item Reclass Batch";
                    ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Transfer;
                    ItemJournalLine."Line No." := LineNumber;
                    ItemJournalLine.insert;
                    ItemJournalLine."Document No." := PalletID;
                    ItemJournalLine."Posting Date" := PalletFunctionCodeunit.GetCurrTime();
                    ItemJournalLine."Document Date" := PalletFunctionCodeunit.GetCurrTime();
                    ItemJournalLine.validate("Item No.", PalletLine."Item No.");
                    ItemJournalLine.Validate("Variant Code", PalletLine."Variant Code");
                    ItemJournalLine.validate(Quantity, PalletLine.Quantity);
                    ItemJournalLine."Pallet ID" := PalletID;
                    ItemJournalLine.validate("Location Code", PalletLine."Location Code");
                    ItemJournalLine.validate("New Location Code", ToLocation);
                    ItemJournalLine."Pallet Type" := PalletHeader."Pallet Type";
                    ItemJournalLine.modify;

                    //Create Reservation Entry
                    if ItemRec.get(PalletLine."Item No.") then
                        if itemrec."Lot Nos." <> '' then begin


                            RecGReservationEntry2.reset;
                            if RecGReservationEntry2.findlast then
                                maxEntry := RecGReservationEntry2."Entry No." + 1;

                            RecGReservationEntry.init;
                            RecGReservationEntry."Entry No." := MaxEntry;
                            //V16.0 - Changed From [3] to "Prospect" on Enum
                            RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                            //V16.0 - Changed From [3] to "Prospect" on Enum
                            RecGReservationEntry.validate("Creation Date", PalletFunctionCodeunit.GetCurrTime());
                            RecGReservationEntry."Created By" := UserId;
                            RecGReservationEntry."Expected Receipt Date" := PalletFunctionCodeunit.GetCurrTime();
                            RecGReservationEntry."Shipment Date" := PalletFunctionCodeunit.GetCurrTime();
                            RecGReservationEntry."Source Type" := 83;
                            RecGReservationEntry."Source Subtype" := 4;
                            RecGReservationEntry."Source ID" := PalletSetup."Item Reclass Template";
                            RecGReservationEntry."Source Batch Name" := PalletSetup."Item Reclass Batch";
                            RecGReservationEntry."Source Ref. No." := LineNumber;
                            RecGReservationEntry."Location Code" := ItemJournalLine."Location Code";
                            //V16.0 - Changed From [1] to "Lot No." on Enum
                            RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                            //V16.0 - Changed From [1] to "Lot No." on Enum
                            RecGReservationEntry."Lot No." := PalletLine."Lot Number";
                            RecGReservationEntry."New Lot No." := PalletLine."Lot Number";
                            RecGReservationEntry.validate("Item No.", PalletLine."Item No.");
                            if PalletLine."Variant Code" <> '' then
                                RecGReservationEntry.validate("Variant Code", PalletLine."Variant Code");
                            RecGReservationEntry.validate("Quantity (Base)", -1 * PalletLine.Quantity);
                            RecGReservationEntry.validate(Quantity, -1 * palletline.Quantity);
                            RecGReservationEntry."Packing Date" := PalletFunctionCodeunit.GetCurrTime();
                            // RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                            RecGReservationEntry."New Expiration Date" := PalletLine."Expiration Date";
                            RecGReservationEntry.Description := Palletline.Description;
                            RecGReservationEntry.Positive := false;
                            RecGReservationEntry.insert;

                            LineNumber += 10000;

                            //Post the Journal
                            ItemJournalLine.reset;
                            ItemJournalLine.setrange("Journal Template Name", PalletSetup."Item Reclass Template");
                            ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Reclass Batch");
                            ItemJournalLine.setrange(ItemJournalLine."Document No.", PalletHeader."Pallet ID");
                            if ItemJournalLine.findset() then
                                CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);

                            if PalletHeader2.get(PalletID) then begin
                                PalletHeader2."Location Code" := ToLocation;
                                PalletHeader2.modify;
                            end;
                        end;
                until palletline.next = 0;
        end;

        pContent := 'Success - Pallet Tansfered to Location ' + ToLocation;

    end;
    //Create Purchase Order Header 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure DeleteTrk(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        ReservationEntry: Record "Reservation Entry";

    begin
        IF pFunction <> 'DeleteTrk' THEN
            EXIT;

        ReservationEntry.reset;
        ReservationEntry.setrange("Source Type", 37);
        if ReservationEntry.findset then
            ReservationEntry.DeleteAll();

        pContent := 'Success';
    end;

    var
        PalletFunctionCodeunit: Codeunit "UI Pallet Functions";
}