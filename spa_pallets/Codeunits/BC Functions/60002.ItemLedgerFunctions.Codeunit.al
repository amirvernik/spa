codeunit 60002 "Item Ledger Functions"
{
    Permissions = TableData 32 = rimd;

    //Negative Item Journal from a Pallet - Global Function
    procedure NegItemLedgerEntry(var pPalletHeader: Record "Pallet Header")
    begin
        //Inserting Item Journal
        PalletSetup.get();
        RecGItemJournalLine.reset;
        RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
        RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        if RecGItemJournalLine.FindLast() then
            LineNumber := RecGItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PackingMaterials.findset then
            repeat
                RecGItemJournalLine.init;
                RecGItemJournalLine."Journal Template Name" := 'ITEM';
                RecGItemJournalLine."Journal Batch Name" := PalletSetup."Item Journal Batch";
                RecGItemJournalLine."Line No." := LineNumber;
                RecGItemJournalLine.insert;
                RecGItemJournalLine."Entry Type" := RecGItemJournalLine."Entry Type"::"Negative Adjmt.";
                RecGItemJournalLine."Posting Date" := Today;
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.Description := PackingMaterials.Description;
                RecGItemJournalLine.validate("Item No.", PackingMaterials."Item No.");
                RecGItemJournalLine.validate("Location Code", pPalletHeader."Location Code");
                RecGItemJournalLine.validate(Quantity, PackingMaterials.Quantity);
                RecGItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                RecGItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                RecGItemJournalLine.modify;
                LineNumber += 10000;
            until PackingMaterials.next = 0;
    end;

    //Positive item Journal from a Pallet - Global Function
    procedure PosItemLedgerEntry(var pPalletHeader: Record "Pallet Header")
    begin
        //Inserting Item Journal
        PalletSetup.get();
        RecGItemJournalLine.reset;
        RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
        RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        if RecGItemJournalLine.FindLast() then
            LineNumber := RecGItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", pPalletHeader."Pallet ID");
        PackingMaterials.setrange(returned, true);
        if PackingMaterials.findset then
            repeat
                RecGItemJournalLine.init;
                RecGItemJournalLine."Journal Template Name" := 'ITEM';
                RecGItemJournalLine."Journal Batch Name" := PalletSetup."Item Journal Batch";
                RecGItemJournalLine."Line No." := LineNumber;
                RecGItemJournalLine.insert;
                RecGItemJournalLine."Entry Type" := RecGItemJournalLine."Entry Type"::"Positive Adjmt.";
                RecGItemJournalLine."Posting Date" := Today;
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.Description := PackingMaterials.Description;
                RecGItemJournalLine.validate("Item No.", PackingMaterials."Item No.");
                RecGItemJournalLine.validate("Location Code", pPalletHeader."Location Code");
                RecGItemJournalLine.validate(Quantity, PackingMaterials."Qty to Return");
                RecGItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                RecGItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                RecGItemJournalLine.modify;
                LineNumber += 10000;
                //CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", RecGItemJournalLine);
            until PackingMaterials.next = 0;
    end;

    //Post Item Journal - Global Function
    procedure PostLedger(var PalletHeader: Record "Pallet Header")
    begin
        PalletSetup.get();
        RecGItemJournalLine.reset;
        RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
        RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        RecGItemJournalLine.setrange("Pallet ID", PalletHeader."Pallet ID");
        if RecGItemJournalLine.findset() then
            CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Batch", RecGItemJournalLine);
    end;

    //On AFter Post Item Journal Line
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Item Jnl.-Post Line", 'OnAfterPostItemJnlLine', '', true, true)]
    local procedure OnAfterPostItemJnlLine(ItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    var
        PalletSetup: Record "Pallet Process Setup";
    begin
        PalletSetup.get;
        ItemLedgerEntry."Pallet ID" := ItemJournalLine."Document No.";
        ItemLedgerEntry."Pallet Type" := ItemJournalLine."Pallet Type";
        ItemLedgerEntry.Disposal := ItemJournalLine.Disposal;
        ItemLedgerEntry.modify;
        if ItemJournalLine."Journal Template Name" = 'ITEM' then begin
            if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Positive Adjmt." then begin
                PalletLedgerFunctions.PosPalletLedgerEntryItem(ItemLedgerEntry); //19/02/2020 - Remove by Oren Ask
                //Moved Back after Talk with oren 21/05/2020 ^
                ItemLedgerEntry.Description := 'POS-' + ItemJournalLine.Description;
                ItemLedgerEntry.Modify();
            end;
            if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Negative Adjmt." then begin
                PalletLedgerFunctions.NegPalletLedgerEntryItem(ItemLedgerEntry); //19/02/2020 - Remove by Oren Ask
                //Moved Back after Talk with oren 21/05/2020 ^
                ItemLedgerEntry.Description := 'NEG-' + ItemJournalLine.Description;
                ItemLedgerEntry.Modify();
            end;
        end;
        if ItemJournalLine."Journal Template Name" = PalletSetup."Item Reclass Template" then begin
            PalletLedgerFunctions.PalletLedgerEntryReclass(ItemLedgerEntry);
            ItemLedgerEntry.Description := ItemJournalLine.Description;
            ItemLedgerEntry.Modify();
        end;
    end;

    var
        RecGItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        PackingMaterials: Record "Packing Material Line";
        LineNumber: Integer;
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
}