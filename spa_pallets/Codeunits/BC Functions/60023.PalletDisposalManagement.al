codeunit 60023 "Pallet Disposal Management"
{

    procedure DisposePallet(var pPalletHeader: Record "Pallet Header")
    var
        DPWI: Codeunit DisposePalletWorkflowInit;
        DPW: Codeunit "Dispose Pallet Workflow";
        myRec: Variant;
        ItemJournalLine: Record "Item Journal Line";
    begin
        if DPWI.IsDisposePalletEnabled(pPalletHeader) = true then begin
            myRec := pPalletHeader;
            DPW.SetStatusToPendingApprovalDisposePallet(myRec);
        end
        else begin
            PalletSetup.get;
            ItemJournalLine.reset;
            ItemJournalLine.setrange("Journal Template Name", 'ITEM');
            ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Disposal Batch");
            ItemJournalLine.SetRange("Document No.", pPalletHeader."Pallet ID");
            if ItemJournalLine.findset then
                ItemJournalLine.DeleteAll();

            CheckDisposalSetup(pPalletHeader);
            DisposePackingMaterials(pPalletHeader);
            DisposePalletItems(pPalletHeader);
            PostDisposalBatch(pPalletHeader."Pallet ID");
            ChangeDisposalStatus(pPalletHeader, 'BC');
        end;

    end;

    //Check Disposal Setup
    procedure CheckDisposalSetup(var pPalletHeader: Record "Pallet Header")
    var
        DisposalBatchError: Label 'Disposal journal batch must be configured, please contact administrator';
    begin
        PalletSetup.get;
        if PalletSetup."Disposal Batch" = '' then
            error(DisposalBatchError);
    end;

    //Change to Status - Disposed
    procedure ChangeDisposalStatus(var pPalletHeader: Record "Pallet Header"; pType: Text)
    var
        PalletDisposeError: label 'You cannot dispose the pallet. it is not a closed pallet';
        PalletDisposeConf: label 'Are you sure you want to dispose the pallet?';
    begin
        if ptype = 'BC' then begin
            if pPalletHeader."Pallet Status" <> pPalletHeader."Pallet Status"::Closed then
                Error(PalletDisposeError);
            //if confirm(PalletDisposeConf) then begin
            pPalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Disposed;
            pPalletHeader.modify;
            //end;
        end;
        if pType = 'WEBUI' then begin
            pPalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Disposed;
            pPalletHeader.modify;
        end;
    end;

    //Dispose Packing Materials
    procedure DisposePackingMaterials(var pPalletHeader: Record "Pallet Header")
    var
        PackingMaterials: Record "Packing Material Line";
        PMSelect: Record "Packing Materials Select" temporary;
        RecGItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
    begin
        PMSelect.Reset();
        PMSelect.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        if PMSelect.FindSet() then PMSelect.DeleteAll();
        Commit();
        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PackingMaterials.findset then
            repeat
                PMSelect.init;
                PMSelect."Pallet ID" := pPalletHeader."Pallet ID";
                PMSelect."PM Item No." := PackingMaterials."Item No.";
                PMSelect."PM Item Description" := PackingMaterials.Description;
                PMSelect.Quantity := PackingMaterials.Quantity;
                PMSelect."Unit of Measure" := PackingMaterials."Unit of Measure Code";
                pmselect.insert;
            until PackingMaterials.next = 0;

        PMSelect.Reset();
        PMSelect.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        if PMSelect.FindSet() then;
        page.RunModal(page::"Packing Materials Select", PMSelect);

        PMSelect.reset;
        PMSelect.setrange(Select, true);
        PMSelect.SetRange("Pallet ID", pPalletHeader."Pallet ID");
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
                RecGItemJournalLine.Validate("Posting Date", Today);
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.Description := PMSelect."PM Item Description";
                RecGItemJournalLine.validate("Item No.", PMSelect."PM Item No.");
                RecGItemJournalLine.validate("Variant Code", Palletline."Variant Code");
                RecGItemJournalLine.validate("Location Code", pPalletHeader."Location Code");
                RecGItemJournalLine.validate(Quantity, PMSelect.Quantity);
                RecGItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                RecGItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                RecGItemJournalLine.modify;
                lineNumber += 10000;
            until PMSelect.next = 0;
    end;


    //Dispose Packing Materials UI
    procedure DisposePackingMaterialsUI(var pPalletHeader: Record "Pallet Header"; var pPackingSelect: Record "Packing Materials Select")
    var
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
    begin

        pPackingSelect.reset;
        pPackingSelect.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        if pPackingSelect.findset then
            repeat
                PalletSetup.get();
                ItemJournalLine.reset;
                ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Disposal Batch");
                if ItemJournalLine.FindLast() then
                    LineNumber := ItemJournalLine."Line No." + 10000
                else
                    LineNumber := 10000;

                ItemJournalLine.init;
                ItemJournalLine."Journal Template Name" := 'ITEM';
                ItemJournalLine."Journal Batch Name" := PalletSetup."Disposal Batch";
                ItemJournalLine."Line No." := LineNumber;
                ItemJournalLine.insert;
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
                ItemJournalLine."External Document No." := pPalletHeader."Pallet ID";
                ItemJournalLine."Posting Date" := Today;
                ItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                ItemJournalLine.Description := pPackingSelect."PM Item Description";
                ItemJournalLine.validate("Item No.", pPackingSelect."PM Item No.");
                ItemJournalLine.validate("Variant Code", Palletline."Variant Code");
                ItemJournalLine.validate("Location Code", pPalletHeader."Location Code");
                ItemJournalLine.validate(Quantity, pPackingSelect.Quantity);
                ItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                ItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                ItemJournalLine.modify;

                lineNumber += 10000;
            until pPackingSelect.next = 0;
    end;




    //Dispose Pallet Items
    procedure DisposePalletItems(var pPalletHeader: Record "Pallet Header")
    var
        PalletLine: Record "Pallet Line";
        RecGItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        ItemRec: Record Item;
        PalletSetup: Record "Pallet Process Setup";
        maxEntry: integer;
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
                RecGItemJournalLine.validate("Posting Date", Today);
                RecGItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                RecGItemJournalLine.Description := PalletLine.Description;
                RecGItemJournalLine.validate("Item No.", PalletLine."Item No.");
                RecGItemJournalLine.validate("Variant Code", PalletLine."Variant Code");
                RecGItemJournalLine.validate("Location Code", PalletLine."Location Code");
                RecGItemJournalLine.validate(Quantity, PalletLine.Quantity);
                RecGItemJournalLine."Pallet ID" := pPalletHeader."Pallet ID";
                RecGItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                RecGItemJournalLine.Disposal := true;
                RecGItemJournalLine.modify;

                if ItemRec.get(PalletLine."Item No.") then
                    if Itemrec."Lot Nos." <> '' then begin
                        ReservationEntry2.reset;
                        if ReservationEntry2.findlast then
                            maxEntry := ReservationEntry2."Entry No." + 1;

                        ReservationEntry.init;
                        ReservationEntry."Entry No." := MaxEntry;
                        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
                        ReservationEntry."Creation Date" := Today;
                        ReservationEntry."Created By" := UserId;
                        ReservationEntry."Expected Receipt Date" := Today;
                        ReservationEntry."Source Type" := 83;
                        ReservationEntry."Source Subtype" := 3;
                        ReservationEntry."Source ID" := 'ITEM';
                        ReservationEntry."Source Ref. No." := LineNumber;
                        ReservationEntry."Source Batch Name" := PalletSetup."Disposal Batch";
                        ReservationEntry.validate("Location Code", PalletLine."Location Code");
                        ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
                        ReservationEntry."Lot No." := PalletLine."Lot Number";
                        ReservationEntry.validate("Item No.", PalletLine."Item No.");
                        if PalletLine."Variant Code" <> '' then
                            ReservationEntry.validate("Variant Code", PalletLine."Variant Code");
                        ReservationEntry.validate("Quantity (Base)", -1 * PalletLine.Quantity);
                        ReservationEntry.validate(Quantity, -1 * PalletLine.Quantity);
                        ReservationEntry.Positive := false;
                        ReservationEntry.insert;
                        lineNumber += 10000;
                    end;
            until PalletLine.next = 0;
    end;

    //Post Disposal Batch
    procedure PostDisposalBatch(pPalletNumber: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        PalletSetup.get;
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Disposal Batch");
        ItemJournalLine.SetRange("Pallet ID", pPalletNumber);
        if ItemJournalLine.findset then
            repeat
                CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);
            until ItemJournalLine.Next() = 0
    end;

    var
        PalletHeader: Record "Pallet Header";
        Palletline: Record "Pallet Line";
        PalletSetup: Record "Pallet Process Setup";
}