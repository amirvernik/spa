codeunit 60002 "Item Ledger Functions"
{
    Permissions = TableData 32 = rm;

    //Negative Item Journal from a Pallet - Global Function
    procedure NegItemLedgerEntry(var pPalletHeader: Record "Pallet Header")
    var
        ItemUOM: Record "Item Unit of Measure";
        PalletLedgerType: Enum "Pallet Ledger Type";
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
                RecGItemJournalLine.validate("Journal Template Name", 'ITEM');
                RecGItemJournalLine.validate("Journal Batch Name", PalletSetup."Item Journal Batch");
                RecGItemJournalLine.validate("Line No.", LineNumber);
                RecGItemJournalLine."Source Code" := 'ITEMJNL';
                RecGItemJournalLine.insert(true);
                RecGItemJournalLine."Entry Type" := RecGItemJournalLine."Entry Type"::"Negative Adjmt.";
                RecGItemJournalLine."Posting Date" := Today;
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.validate("Pallet ID", pPalletHeader."Pallet ID");
                RecGItemJournalLine.Description := PackingMaterials.Description;
                RecGItemJournalLine.validate("Item No.", PackingMaterials."Item No.");
                RecGItemJournalLine.validate("Location Code", pPalletHeader."Location Code");
                //RecGItemJournalLine.validate(Quantity, PackingMaterials.Quantity);
                ItemUOM.reset;
                ItemUOM.setrange("Item No.", PackingMaterials."Item No.");
                itemuom.SetRange(code, PackingMaterials."Unit of Measure Code");
                if ItemUOM.FindFirst() then
                    RecGItemJournalLine.validate(Quantity, PackingMaterials.Quantity * ItemUOM."Qty. per Unit of Measure")
                else
                    RecGItemJournalLine.validate(Quantity, PackingMaterials.Quantity);

                RecGItemJournalLine.validate("Pallet ID", pPalletHeader."Pallet ID");
                RecGItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                RecGItemJournalLine."Packing Material Qty" := PackingMaterials.Quantity;
                RecGItemJournalLine."Packing Material UOM" := PackingMaterials."Unit of Measure Code";
                RecGItemJournalLine.modify;
                LineNumber += 10000;
                PalletLedgerFunctions.NegPalletLedgerEntryItem(RecGItemJournalLine, PalletLedgerType::"Consume Packing Materials");
            until PackingMaterials.next = 0;
    end;

    //Positive item Journal from a Pallet - Global Function
    procedure PosItemLedgerEntry(var pPalletHeader: Record "Pallet Header")
    var
        ItemUOM: Record "Item Unit of Measure";
        PalletLedgerType: Enum "Pallet Ledger Type";
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
                RecGItemJournalLine.Validate("Pallet ID", pPalletHeader."Pallet ID");
                //RecGItemJournalLine.validate(Quantity, PackingMaterials."Qty to Return");
                ItemUOM.reset;
                ItemUOM.setrange("Item No.", PackingMaterials."Item No.");
                itemuom.SetRange(code, PackingMaterials."Unit of Measure Code");
                if ItemUOM.FindFirst() then
                    RecGItemJournalLine.validate(Quantity, PackingMaterials."Qty to Return" * ItemUOM."Qty. per Unit of Measure")
                else
                    RecGItemJournalLine.validate(Quantity, PackingMaterials."Qty to Return");

                RecGItemJournalLine.validate("Pallet ID", pPalletHeader."Pallet ID");
                RecGItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                RecGItemJournalLine."Packing Material Qty" := PackingMaterials.Quantity;
                RecGItemJournalLine."Packing Material UOM" := PackingMaterials."Unit of Measure Code";
                RecGItemJournalLine.modify;
                LineNumber += 10000;
                //CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", RecGItemJournalLine);
                PalletLedgerFunctions.PosPalletLedgerEntryItem(RecGItemJournalLine, PalletLedgerType::"Dispose Raw Materials");
            until PackingMaterials.next = 0;
    end;

    //Post Item Journal - Global Function
    procedure PostLedger(var pPalletHeader: Record "Pallet Header")
    var
    begin
        PalletSetup.get();
        RecGItemJournalLine.reset;
        RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
        RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        RecGItemJournalLine.SetFilter(Quantity, '<>%1', 0);
        RecGItemJournalLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        if RecGItemJournalLine.findset() then
            repeat
                CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", RecGItemJournalLine);
            until RecGItemJournalLine.Next() = 0;

        RecGItemJournalLine.reset;
        RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
        RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        RecGItemJournalLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        if RecGItemJournalLine.FindSet() then
            RecGItemJournalLine.DeleteAll();

    end;

    //On AFter Post Item Journal Line
    [EventSubscriber(ObjectType::Codeunit, codeunit::"Item Jnl.-Post Line", 'OnAfterPostItemJnlLine', '', true, true)]
    local procedure OnAfterPostItemJnlLine(ItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    var
        PalletSetup: Record "Pallet Process Setup";
        LPalletLedgerEntry: Record "Pallet Ledger Entry";
    begin
        SelectLatestVersion();
        PalletSetup.get;
        ItemLedgerEntry."Pallet ID" := ItemJournalLine."Pallet ID";
        ItemLedgerEntry."Pallet Line No." := ItemJournalLine."Pallet Line No.";
        ItemLedgerEntry."Pallet Type" := ItemJournalLine."Pallet Type";
        ItemLedgerEntry."Packing Material Qty" := ItemJournalLine."Packing Material Qty";
        ItemLedgerEntry."Packing Material UOM" := ItemJournalLine."Packing Material UOM";
        ItemLedgerEntry.Disposal := ItemJournalLine.Disposal;
        ItemLedgerEntry.modify;

        LPalletLedgerEntry.Reset();
        LPalletLedgerEntry.SetRange("Document No.", ItemJournalLine."Document No.");
        LPalletLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        LPalletLedgerEntry.SetRange("Variant Code", ItemJournalLine."Variant Code");
        LPalletLedgerEntry.SetRange("Item Ledger Entry No.", 0);
        LPalletLedgerEntry.SetRange("Posting Date", ItemJournalLine."Posting Date");
        LPalletLedgerEntry.SetRange("Lot Number", ItemJournalLine."Lot No.");
        // LPalletLedgerEntry.SetRange("Unit of Measure", ItemJournalLine."Unit of Measure Code");
        // LPalletLedgerEntry.SetFilter(Quantity, '=%1 | =%2', -ItemJournalLine.Quantity, ItemJournalLine.Quantity);
        if LPalletLedgerEntry.FindLast() then begin
            LPalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";

            LPalletLedgerEntry.Modify();
        end else begin
            LPalletLedgerEntry.Reset();
            LPalletLedgerEntry.SetRange("Pallet ID", ItemJournalLine."Pallet ID");
            LPalletLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
            LPalletLedgerEntry.SetRange("Variant Code", ItemJournalLine."Variant Code");
            LPalletLedgerEntry.SetRange("Pallet Line No.", ItemJournalLine."Pallet Line No.");
            LPalletLedgerEntry.SetRange("Item Ledger Entry No.", 0);
            LPalletLedgerEntry.SetRange("Posting Date", ItemJournalLine."Posting Date");
            LPalletLedgerEntry.SetRange("Unit of Measure", ItemJournalLine."Unit of Measure Code");
            LPalletLedgerEntry.SetFilter(Quantity, '=%1 | =%2', -ItemJournalLine.Quantity, ItemJournalLine.Quantity);
            if LPalletLedgerEntry.FindLast() then begin
                LPalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";

                LPalletLedgerEntry.Modify();
            end else begin
                LPalletLedgerEntry.Reset();
                LPalletLedgerEntry.SetCurrentKey("Lot Number", "Item No.", "Variant Code");
                LPalletLedgerEntry.SetRange("Lot Number", ItemJournalLine."Lot No.");
                LPalletLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
                LPalletLedgerEntry.SetRange("Variant Code", ItemJournalLine."Variant Code");
                LPalletLedgerEntry.SetRange("Item Ledger Entry No.", 0);
                LPalletLedgerEntry.SetRange("Posting Date", ItemJournalLine."Posting Date");
                if LPalletLedgerEntry.FindLast() then begin
                    LPalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";

                    LPalletLedgerEntry.Modify();
                end;
            end;
        end;
        if ItemJournalLine."Journal Template Name" = 'ITEM' then begin
            if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Positive Adjmt." then begin
                // PalletLedgerFunctions.PosPalletLedgerEntryItem(ItemLedgerEntry);
                ItemLedgerEntry.Description := 'POS-' + ItemJournalLine.Description;
                ItemLedgerEntry.Modify();

            end;
            if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Negative Adjmt." then begin
                // PalletLedgerFunctions.NegPalletLedgerEntryItem(ItemLedgerEntry);
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