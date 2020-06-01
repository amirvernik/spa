codeunit 60024 "Change Quality Management"
{
    [EventSubscriber(ObjectType::table, database::"Pallet Change Quality", 'OnAfterValidateEvent', 'New Variant Code', true, true)]
    local procedure OnAfterValidateItemVariant(var Rec: Record "Pallet Change Quality")
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Reset();
        ItemVariant.setrange(code, rec."New Variant Code");
        ItemVariant.setrange("Item No.", rec."New Item No.");
        if ItemVariant.findfirst then begin
            Rec.Description := ItemVariant.Description;
            rec.modify;
        end;
    end;

    [EventSubscriber(ObjectType::table, database::"Pallet Line Change Quality", 'OnAfterValidateEvent', 'Replaced Qty', true, true)]
    local procedure OnAfterValidateReplacedQty(var Rec: Record "Pallet Line Change Quality")
    var
        ErrReplacedQty: label 'You cannot replace quantity %1 that is bigger than %2';
    begin
        if rec."Replaced Qty" > rec.Quantity then
            error(ErrReplacedQty, format(rec."Replaced Qty"), format(rec.Quantity));
    end;

    //Negative Adjustment to The Items
    procedure NegAdjChangeQuality(var pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        ItemRec: Record item;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        MaxEntry: Integer;
    begin
        PurchaseProcessSetup.get();
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        if ItemJournalLine.FindLast() then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        pPalletLineChg.reset;
        if pPalletLineChg.findset then
            repeat
                ItemJournalLine.init;
                ItemJournalLine."Journal Template Name" := 'ITEM';
                ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                ItemJournalLine."Line No." := LineNumber;
                ItemJournalLine.insert;
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                ItemJournalLine."Posting Date" := Today;
                ItemJournalLine."Document No." := pPalletLineChg."Pallet ID";
                ItemJournalLine."Document Date" := today;
                ItemJournalLine.validate("Item No.", pPalletLineChg."Item No.");
                ItemJournalLine.validate("Variant Code", pPalletLineChg."Variant Code");
                ItemJournalLine.validate("Location Code", pPalletLineChg."Location Code");
                ItemJournalLine.validate(Quantity, (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                ItemJournalLine.modify;
                //Create Reservation Entry
                if ItemRec.get(pPalletLineChg."Item No.") then
                    if Itemrec."Lot Nos." <> '' then begin
                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                        RecGReservationEntry."Creation Date" := Today;
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Source Type" := 83;
                        RecGReservationEntry."Source Subtype" := 3;
                        RecGReservationEntry."Source ID" := 'ITEM';
                        RecGReservationEntry."Source Ref. No." := LineNumber;
                        RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        RecGReservationEntry.validate("Location Code", pPalletLineChg."Location Code");
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                        RecGReservationEntry.validate("Item No.", pPalletLineChg."Item No.");
                        RecGReservationEntry.validate("Variant Code", pPalletLineChg."Variant Code");
                        RecGReservationEntry.validate("Quantity (Base)", -1 *
                        (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                        RecGReservationEntry.validate(Quantity, -1 *
                        (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                        RecGReservationEntry.Positive := false;
                        RecGReservationEntry.insert;
                    end;
                LineNumber += 10000;
            until pPalletLineChg.next = 0;
    end;

    //Positive Adjustment to New Lines
    procedure PosAdjNewItems(var pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        ItemRec: Record item;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        MaxEntry: Integer;
        PalletChangeQuality: Record "Pallet Change Quality";
    begin
        PurchaseProcessSetup.get();
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        if ItemJournalLine.FindLast() then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        pPalletLineChg.reset;
        if pPalletLineChg.findset then
            repeat
                PalletChangeQuality.reset;
                PalletChangeQuality.SetRange("Pallet ID", pPalletLineChg."Pallet ID");
                PalletChangeQuality.setrange("Pallet Line No.", pPalletLineChg."Line No.");
                if PalletChangeQuality.findset then
                    repeat
                        ItemJournalLine.init;
                        ItemJournalLine."Journal Template Name" := 'ITEM';
                        ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        ItemJournalLine."Line No." := LineNumber;
                        ItemJournalLine.insert;
                        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
                        ItemJournalLine."Posting Date" := Today;
                        ItemJournalLine."Document No." := pPalletLineChg."Pallet ID";
                        ItemJournalLine."Document Date" := today;
                        ItemJournalLine.validate("Item No.", PalletChangeQuality."new Item No.");
                        ItemJournalLine.validate("Variant Code", PalletChangeQuality."new Variant Code");
                        ItemJournalLine.validate("Location Code", pPalletLineChg."Location Code");
                        ItemJournalLine.validate(Quantity, PalletChangeQuality."New Quantity");
                        ItemJournalLine.modify;
                        //Create Reservation Entry
                        if ItemRec.get(pPalletLineChg."Item No.") then
                            if Itemrec."Lot Nos." <> '' then begin
                                RecGReservationEntry2.reset;
                                if RecGReservationEntry2.findlast then
                                    maxEntry := RecGReservationEntry2."Entry No." + 1;

                                RecGReservationEntry.init;
                                RecGReservationEntry."Entry No." := MaxEntry;
                                RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                                RecGReservationEntry."Creation Date" := Today;
                                RecGReservationEntry."Created By" := UserId;
                                RecGReservationEntry."Expected Receipt Date" := Today;
                                RecGReservationEntry."Source Type" := 83;
                                RecGReservationEntry."Source Subtype" := 3;
                                RecGReservationEntry."Source ID" := 'ITEM';
                                RecGReservationEntry."Source Ref. No." := LineNumber;
                                RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                                RecGReservationEntry.validate("Location Code", pPalletLineChg."Location Code");
                                RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                                RecGReservationEntry.validate("Item No.", PalletChangeQuality."new Item No.");
                                RecGReservationEntry.validate("Variant Code", PalletChangeQuality."new Variant Code");
                                RecGReservationEntry.validate("Quantity (Base)", PalletChangeQuality."New Quantity");
                                RecGReservationEntry.validate(Quantity, PalletChangeQuality."New Quantity");
                                RecGReservationEntry.Positive := true;
                                RecGReservationEntry.insert;
                            end;
                        LineNumber += 10000;
                    until PalletChangeQuality.next = 0;
            until pPalletLineChg.next = 0;
    end;

    //Adjust Pallet Line Quantities
    procedure ChangeQuantitiesOnPalletline(var pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLine: Record "Pallet Line";
    begin
        pPalletLineChg.reset;
        if pPalletLineChg.findset then
            repeat
                if PalletLine.get(pPalletLineChg."Pallet ID", pPalletLineChg."Line No.") then begin
                    PalletLine.Quantity := pPalletLineChg."Replaced Qty";
                    PalletLine.modify;
                end;
            until pPalletLineChg.next = 0;
    end;

    //Adjust Pallet Reservation
    procedure ChangePalletReservation(var pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletReservationEntry: Record "Pallet reservation Entry";
    begin
        pPalletLineChg.reset;
        if pPalletLineChg.findset then
            repeat
                if PalletReservationEntry.get(pPalletLineChg."Pallet ID", pPalletLineChg."Line No.",
                    pPalletLineChg."Lot Number") then begin

                    PalletReservationEntry.Quantity := pPalletLineChg."Replaced Qty";
                    PalletReservationEntry.modify;
                end;
            until pPalletLineChg.next = 0;
    end;

    //Adjust Pallet LedgerEntries
    procedure PalletLedgerAdjust(var pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        LineNumber: Integer;
    begin
        LineNumber := GetLastEntry();
        pPalletLineChg.reset;
        if pPalletLineChg.findset then
            repeat
                PalletLedgerEntry.Init();
                PalletLedgerEntry."Entry No." := LineNumber;
                PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Quality Change";
                PalletLedgerEntry."Pallet ID" := pPalletLineChg."Pallet ID";
                PalletLedgerEntry."Pallet Line No." := pPalletLineChg."Line No.";
                PalletLedgerEntry."Document No." := pPalletLineChg."Pallet ID";
                PalletLedgerEntry.validate("Posting Date", Today);
                PalletLedgerEntry.validate("Item No.", pPalletLineChg."Item No.");
                PalletLedgerEntry."Variant Code" := pPalletLineChg."Variant Code";
                PalletLedgerEntry."Item Description" := pPalletLineChg.Description;
                PalletLedgerEntry."Lot Number" := pPalletLineChg."Lot Number";
                PalletLedgerEntry.validate("Location Code", pPalletLineChg."Location Code");
                PalletLedgerEntry.validate("Unit of Measure", pPalletLineChg."Unit of Measure");
                PalletLedgerEntry.validate(Quantity, -1 * (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                PalletLedgerEntry."User ID" := userid;
                PalletLedgerEntry.Insert();
                LineNumber += 1;
            until pPalletLineChg.next = 0;

    end;

    //Add The new items to the Pallet
    procedure AddNewItemsToPallet(var pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLine: Record "Pallet Line";
        PalletItemChgLine: Record "Pallet Change Quality";
        LineNumber: integer;
        ItemRec: Record Item;
    begin
        pPalletLineChg.reset;
        if pPalletLineChg.findset then
            repeat
                PalletItemChgLine.reset;
                PalletItemChgLine.setrange("Pallet ID", pPalletLineChg."Pallet ID");
                PalletItemChgLine.setrange("Pallet Line No.", pPalletLineChg."Line No.");
                if PalletItemChgLine.findset then
                    repeat

                        PalletLine.reset;
                        PalletLine.setrange("Pallet ID", pPalletLineChg."Pallet ID");
                        if PalletLine.findlast then
                            LineNumber := PalletLine."Line No." + 10000
                        else
                            LineNumber := 10000;

                        PalletLine.init;
                        PalletLine."Pallet ID" := pPalletLineChg."Pallet ID";
                        PalletLine."Line No." := LineNumber;
                        PalletLine.validate("Item No.", PalletItemChgLine."New Item No.");
                        PalletLine."Location Code" := pPalletLineChg."Location Code";
                        PalletLine."Lot Number" := pPalletLineChg."Lot Number";
                        PalletLine.Quantity := PalletItemChgLine."New Quantity";
                        PalletLine."Unit of Measure" := PalletItemChgLine."Unit of Measure";
                        PalletLine.validate("Variant Code", PalletItemChgLine."New Variant Code");

                        if ItemRec.get(PalletItemChgLine."New Item No.") then begin
                            if format(ItemRec."Expiration Calculation") = '' then
                                PalletLine."Expiration Date" := today
                            else
                                PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), today);
                        end;
                        PalletLine."User ID" := UserId;
                        PalletLine.insert;
                    until PalletItemChgLine.next = 0;
            until pPalletLineChg.next = 0;
    end;

    local procedure GetLastEntry(): Integer
    var
        PalletLedgerEntry: Record "pallet ledger entry";
    begin
        PalletLedgerEntry.reset;
        if PalletLedgerEntry.findlast then
            exit(PalletLedgerEntry."Entry No." + 1)
        else
            exit(1);
    end;

}