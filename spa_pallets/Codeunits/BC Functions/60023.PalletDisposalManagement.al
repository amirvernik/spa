codeunit 60023 "Pallet Disposal Management"
{

    procedure DisposePallet(var pPalletHeader: Record "Pallet Header")
    var
        PalletDisposeError: label 'You cannot dispose the pallet. it is not a closed pallet';
        PalletDisposeConf: label 'Are you sure you want to dispose the pallet?';
        DisposalBatchError: Label 'Disposal journal batch must be configured, please contact administrator';
    begin
        PalletSetup.get;
        if PalletSetup."Disposal Batch" = '' then
            error(DisposalBatchError);


        if pPalletHeader."Pallet Status" <> pPalletHeader."Pallet Status"::Closed then
            Error(PalletDisposeError);
        if confirm(PalletDisposeConf) then begin

            //Dispose Packing Materials
            DisposePackingMaterials(pPalletHeader);

            //Dispose Pallet Items
            DisposePalletItems(pPalletHeader);
        end;
    end;

    local procedure DisposePackingMaterials(var pPalletHeader: Record "Pallet Header")
    var
        PackingMaterials: Record "Packing Material Line";
        PMSelect: Record "Packing Materials Select" temporary;
        RecGItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
    begin
        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PackingMaterials.findset then
            repeat
                PMSelect.init;
                PMSelect."Pallet ID" := pPalletHeader."Pallet ID";
                PMSelect."PM Item No." := PackingMaterials."Item No.";
                PMSelect."PM Item Description" := PackingMaterials.Description;
                PMSelect.Quantity := PackingMaterials.Quantity;
                pmselect.insert;
            until PackingMaterials.next = 0;
        page.runmodal(page::"Packing Materials Select", PMSelect);

        PMSelect.reset;
        PMSelect.setrange(Select, true);
        if PMSelect.findset then
            repeat
                PalletSetup.get();
                RecGItemJournalLine.reset;
                RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
                RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Disposal Batch");
                if RecGItemJournalLine.FindLast() then
                    LineNumber := RecGItemJournalLine."Line No." + 10000
                else
                    LineNumber := 10000;

                RecGItemJournalLine.init;
                RecGItemJournalLine."Journal Template Name" := 'ITEM';
                RecGItemJournalLine."Journal Batch Name" := PalletSetup."Disposal Batch";
                RecGItemJournalLine."Line No." := LineNumber;
                RecGItemJournalLine.insert;
                RecGItemJournalLine."Entry Type" := RecGItemJournalLine."Entry Type"::"Positive Adjmt.";
                RecGItemJournalLine."External Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine."Posting Date" := Today;
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.Description := PMSelect."PM Item Description";
                RecGItemJournalLine.validate("Item No.", PMSelect."PM Item No.");
                RecGItemJournalLine.validate("Location Code", pPalletHeader."Location Code");
                RecGItemJournalLine.validate(Quantity, PMSelect.Quantity);
                RecGItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                RecGItemJournalLine.modify;
                lineNumber += 10000;
            until PMSelect.next = 0;
    end;

    local procedure DisposePalletItems(var pPalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";
        RecGItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
    begin
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                PalletSetup.get();
                RecGItemJournalLine.reset;
                RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
                RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Disposal Batch");
                if RecGItemJournalLine.FindLast() then
                    LineNumber := RecGItemJournalLine."Line No." + 10000
                else
                    LineNumber := 10000;

                RecGItemJournalLine.init;
                RecGItemJournalLine."Journal Template Name" := 'ITEM';
                RecGItemJournalLine."Journal Batch Name" := PalletSetup."Disposal Batch";
                RecGItemJournalLine."Line No." := LineNumber;
                RecGItemJournalLine.insert;
                RecGItemJournalLine."Entry Type" := RecGItemJournalLine."Entry Type"::"Negative Adjmt.";
                RecGItemJournalLine."External Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine."Posting Date" := Today;
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.Description := PalletLine.Description;
                RecGItemJournalLine.validate("Item No.", PalletLine."Item No.");
                RecGItemJournalLine.validate("Location Code", PalletLine."Location Code");
                RecGItemJournalLine.validate(Quantity, PalletLine.Quantity);
                RecGItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                RecGItemJournalLine.modify;
                lineNumber += 10000;
            until PalletLine.next = 0;
    end;

    var
        PalletHeader: Record "Pallet Header";
        Palletline: Record "Pallet Line";
        PalletSetup: Record "Pallet Process Setup";
}