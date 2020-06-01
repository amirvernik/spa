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
                        //V16.0 - Changed From [3] to "Prospect" on Enum
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                        //V16.0 - Changed From [3] to "Prospect" on Enum
                        RecGReservationEntry."Creation Date" := Today;
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Source Type" := 83;
                        RecGReservationEntry."Source Subtype" := 3;
                        RecGReservationEntry."Source ID" := 'ITEM';
                        RecGReservationEntry."Source Ref. No." := LineNumber;
                        RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        RecGReservationEntry.validate("Location Code", pPalletLineChg."Location Code");
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                        RecGReservationEntry.validate("Item No.", pPalletLineChg."Item No.");
                        RecGReservationEntry.validate("Quantity (Base)", -1 *
                        (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                        RecGReservationEntry.validate(Quantity, -1 *
                        (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                        RecGReservationEntry.Positive := false;
                        RecGReservationEntry.insert;
                    end;
            until pPalletLineChg.next = 0;
    end;
}