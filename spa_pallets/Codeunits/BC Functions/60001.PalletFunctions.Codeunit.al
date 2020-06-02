codeunit 60001 "Pallet Functions"
{
    Permissions = TableData 32 = rimd;
    trigger OnRun()
    begin

    end;

    //Close Pallet - Global Function
    procedure ClosePallet(var pPalletHeader: Record "Pallet Header")
    begin
        //No Lines - Dont close
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if not PalletLines.findfirst then
            error(Err04);

        //No Quantities - Dont close    
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
        PalletLines.setrange(Quantity, 0);
        if PalletLines.findfirst then
            error(Err05);

        //Change Status
        pPalletHeader."Pallet Status" := pPalletHeader."Pallet Status"::Closed;
        pPalletHeader.modify;

        AddMaterials(pPalletHeader); //Add Materials         
        PalletLedgerFunctions.PosPalletLedger(pPalletHeader); //Positive on Pallet Ledger
        ItemLedgerFunctions.NegItemLedgerEntry(pPalletHeader); //Negative on Item Journal                              
        ItemLedgerFunctions.PostLedger(pPalletHeader); //Post Item Journal
        //AddPoLines(pPalletHeader); //Add PO Lines
        TrackingLineFunctions.AddTrackingLineToPO(pPalletHeader); //Add Tracking Line to PO
    end;

    //Reopen Pallet - Global Function
    procedure ReOpenPallet(var pPalletHeader: Record "Pallet Header")
    var

    begin
        if UserSetup.get(UserId) then begin

            //Permission Check
            if (not UserSetup."Can ReOpen Pallet") then
                Error(Err01, 'ReOpen Pallet');

            //Not Chipped Check
            if pPalletHeader."Pallet Status" = pPalletHeader."Pallet Status"::Shipped then
                Error(Err02);

            //Exists in Warehouse Shipment Check
            PalletLines.reset;
            PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
            palletlines.setrange("Exists on Warehouse Shipment", true);
            if PalletLines.FindFirst() then
                Error(Err03);

            pPalletHeader."Pallet Status" := pPalletHeader."Pallet Status"::Open;
            pPalletHeader.modify;

            TrackingLineFunctions.RemoveTrackingLineFromPO(pPalletHeader); //Remove Tracking Line to PO
            ItemLedgerFunctions.PosItemLedgerEntry(pPalletHeader); //Positive on Item Journal Packing Material
            PalletLedgerFunctions.NegPalletLedger(pPalletHeader); //Negative on Pallet Ledger
            DeleteMaterials(pPalletHeader); //Delete Materials                                  
            ItemLedgerFunctions.PostLedger(pPalletHeader); //Post Item Journal - If Exist            
        end
        else
            Error(Err01, 'ReOpen Pallet');
    end;

    //After Post Transfer Line --> Shipment Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptLine', '', true, true)]
    local procedure OnAfterPostTransferOrderShip(TransLine: Record "Transfer Line"; var TransShptLine: Record "Transfer Shipment Line")
    begin
        TransShptLine."Pallet ID" := TransLine."Pallet ID";
        TransShptLine.Modify();
        PalletLedgerFunctions.NegPalletLedgerTransfer(TransShptLine);
    end;

    //After Post Transfer Line --> Receipt Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptLine', '', true, true)]
    local procedure OnAfterPostTransferOrderReceipt(TransLine: Record "Transfer Line"; var TransRcptLine: Record "Transfer Receipt Line")
    begin
        TransRcptLine."Pallet ID" := TransLine."Pallet ID";
        TransRcptLine.Modify();
        PalletLedgerFunctions.PosPalletLedgerTransfer(TransRcptLine);
    end;

    //On After Post Item Reclass Journal
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', true, true)]
    local procedure OnAfterInsertItemLedgerEntry(ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry."Pallet ID" := ItemJournalLine."Pallet ID";
        ItemLedgerEntry.modify;
        if ItemJournalLine."Journal Template Name" = 'RECLASS' then
            PalletLedgerFunctions.PalletLedgerEntryReclass(ItemLedgerEntry);
    end;

    //Adding Packing Materials - Global Function
    procedure AddMaterials(var PalletHeader: Record "Pallet Header")
    begin
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");
        if PalletLines.findset then
            repeat
                BomComponent.reset;
                BomComponent.setrange("Parent Item No.", PalletLines."Item No.");
                if BomComponent.findset then
                    repeat
                        if not PackingMaterials.get(PalletLines."Pallet ID",
                            BomComponent."No.", BomComponent."Unit of Measure Code") then begin
                            PackingMaterials.init;
                            PackingMaterials."Pallet ID" := PalletLines."Pallet ID";
                            PackingMaterials."Item No." := BomComponent."No.";
                            packingmaterials."Line No." := GetLastEntryPacking();
                            PackingMaterials.Description := BomComponent.Description;
                            PackingMaterials.Quantity := BomComponent."Quantity per" * PalletLines.Quantity;
                            PackingMaterials."Unit of Measure Code" := BomComponent."Unit of Measure Code";
                            PackingMaterials."Location Code" := PalletHeader."Location Code";
                            PackingMaterials.insert;
                        end
                        else begin
                            PackingMaterials.Quantity += BomComponent."Quantity per" * PalletLines.Quantity;
                            PackingMaterials.modify;

                        end;

                    until BomComponent.next = 0;
            until PalletLines.next = 0;
    end;

    //Delete Packing Materials - Global Function
    local procedure DeleteMaterials(var PalletHeader: Record "Pallet Header")
    begin
        PackingMaterials.reset;
        PackingMaterials.setrange(PackingMaterials."Pallet ID", PalletHeader."Pallet ID");
        if PackingMaterials.FindSet()
            then
            PackingMaterials.deleteall();
    end;

    //After Validate "Pallet ID" - on Pallet Header table
    [EventSubscriber(ObjectType::table, database::"Pallet Header", 'OnAfterValidateEvent', 'Pallet ID', true, true)]
    local procedure OnAfterValidatePalletID(var Rec: Record "Pallet Header"; var xRec: Record "Pallet Header")
    begin
        if rec."Pallet ID" <> xrec."Pallet ID" then
            error(err07);
    end;

    //On Before Action - Close - Pallet Card
    [EventSubscriber(ObjectType::page, page::"Pallet Card", 'OnBeforeActionEvent', 'Close Pallet', true, true)]
    local procedure OnBeforeActionPalletCard(var Rec: Record "Pallet Header")
    var
        ItemRec: Record Item;
        PalletLine: Record "Pallet Line";
        BoolCheck: Boolean;
    begin
        BoolCheck := false;
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", rec."Pallet ID");
        if PalletLine.findset then
            repeat
                if ItemRec.get(PalletLine."Item No.") then
                    if ItemRec."Item Tracking Code" <> '' then
                        if PalletLine."Lot Number" = '' then
                            BoolCheck := true;
            until PalletLine.next = 0;
        if BoolCheck then error(Err08);
    end;

    //On Before Action - Close - Pallet List
    [EventSubscriber(ObjectType::page, page::"Pallet Card", 'OnBeforeActionEvent', 'Close Pallet', true, true)]
    local procedure OnBeforeActionPalletList(var Rec: Record "Pallet Header")
    var
        ItemRec: Record Item;
        PalletLine: Record "Pallet Line";
        BoolCheck: Boolean;
    begin
        BoolCheck := false;
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", rec."Pallet ID");
        if PalletLine.findset then
            repeat
                if ItemRec.get(PalletLine."Item No.") then
                    if ItemRec."Item Tracking Code" <> '' then
                        if PalletLine."Lot Number" = '' then
                            BoolCheck := true;
            until PalletLine.next = 0;
        if BoolCheck then error(Err08);
    end;

    //On Before Delete Pallet Line - Pallet Line Table
    [EventSubscriber(ObjectType::table, database::"Pallet Line", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure OnBeforeDeletePalletLine(var Rec: Record "Pallet Line")
    var
        ItemRec: Record Item;
        PalletLine: Record "Pallet Line";
        BoolCheck: Boolean;
        Err001: label 'You cannot delete Pallet line, there is a Purchase line connectd to it';
        PalletReservation: Record "Pallet reservation Entry";
        Lbl001: label 'There are Reservation for Item %1 for Pallet Line, do you want to Delete Reservations?';
        Lbl002: label 'Pallet Line did not delete';

    begin
        if rec."Purchase Order No." <> '' then
            error(Err001);

        PalletReservation.reset;
        PalletReservation.setrange("Pallet ID", rec."Pallet ID");
        PalletReservation.setrange("Pallet Line", rec."Line No.");
        if PalletReservation.findfirst then begin
            if Confirm(StrSubstNo(Lbl001, rec."Item No.")) then begin
                repeat
                    PalletReservation.delete;
                until PalletReservation.next = 0;
            end
            else
                error(Lbl002);
        end;
    end;

    //Choose Packing Materials
    procedure ChoosePackingMaterials(var pPalletHeader: Record "Pallet Header")
    var
        PackingMaterialConfirm: Label 'Do you want to return the packing material into stock?';
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        ItemRec: Record Item;
        PMSelect: Record "Packing Materials Select" temporary;
        RecGItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        LineNumber: Integer;
        PackingMaterials: Record "Packing Material Line";
    begin
        if PMSelect.findset then
            pmselect.deleteall;

        if confirm(PackingMaterialConfirm) then begin
            PackingMaterials.reset;
            PackingMaterials.setrange("Pallet ID", pPalletHeader."Pallet ID");
            if PackingMaterials.findset then
                repeat
                    PMSelect.init;
                    PMSelect."Pallet ID" := pPalletHeader."Pallet ID";
                    PMSelect."PM Item No." := PackingMaterials."Item No.";
                    PMSelect."Pallet Packing Line No." := PackingMaterials."Line No.";
                    PMSelect."PM Item Description" := PackingMaterials.Description;
                    PMSelect."Unit of Measure" := PackingMaterials."Unit of Measure Code";
                    PMSelect.Quantity := PackingMaterials.Quantity;
                    pmselect.insert;
                until PackingMaterials.next = 0;
            page.runmodal(page::"Packing Materials Select", PMSelect);
        end;
    end;

    local procedure GetLastEntry(): Integer
    var
        PalletLedgerEntry: Record "Pallet Ledger Entry";
    begin
        PalletLedgerEntry.reset;
        if PalletLedgerEntry.findlast then
            exit(PalletLedgerEntry."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure GetLastEntryPacking(): Integer
    var
        PackingMaterialLine: Record "Packing Material Line";
    begin
        PackingMaterialLine.reset;
        if PackingMaterialLine.findlast then
            exit(PackingMaterialLine."Line No." + 1)
        else
            exit(1);
    end;

    var
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        ItemLedgerFunctions: Codeunit "Item Ledger Functions";
        TrackingLineFunctions: Codeunit "Tracking Line Functions";
        UserSetup: Record "User Setup";
        PalletLines: Record "Pallet Line";
        BomComponent: Record "BOM Component";
        PackingMaterials: Record "Packing Material Line";
        Err01: label 'User Cannot do the Following Operation - %1 - , Please contact system admin';
        Err02: label 'Cant reopen Pallet, Pallet Shipped';
        Err03: label 'Cant Reopen Pallet, Pulled to warehouse shipment';
        Err04: label 'There are no Lines, nothing to close';
        Err05: label 'There are no Quantities, nothing to close';
        Err06: label 'Lot No. exists in Pallet No. %1, Please remove Lot from the Pallet and Select Again';
        Err07: label 'You cannot enter Pallet ID Manualy';
        Err08: label 'not All lines have lot Numbers, Please enter Tracking line';
}