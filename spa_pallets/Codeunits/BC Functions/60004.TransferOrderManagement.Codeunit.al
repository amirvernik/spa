codeunit 60004 "Transfer Order Management"
{
    Permissions = TableData 32 = m;

    //Pallet Selection On Transfer Order - Global Function
    procedure PalletSelection(var TransferOrder: Record "Transfer Header")
    begin
        TransferLines.reset;
        TransferLines.setrange("Document No.", TransferOrder."No.");
        if TransferLines.findset then
            error(Lbl002);

        if PalletListSelect.findset then
            PalletListSelect.Deleteall;

        palletheader.reset;
        palletheader.setrange(palletheader."Pallet Status", palletheader."Pallet Status"::Closed);
        palletheader.setrange(palletheader."Location Code", TransferOrder."Transfer-from Code");
        if palletheader.findset then begin
            repeat
                PalletListSelect.init;
                PalletListSelect."Pallet ID" := palletheader."Pallet ID";
                PalletListSelect."Source Document" := TransferOrder."No.";
                PalletListSelect.insert;
            until palletheader.next = 0;
            page.run(page::"Pallet List Select Transfer", PalletListSelect);
        end
        else
            message(Lbl001, TransferOrder."Transfer-from Code");


    end;

    //On Before Post Item Journal -> Transfer Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforePostItemJournalLine', '', true, true)]
    local procedure OnBeforePostItemJournalLine_Ship(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line")
    begin
        ItemJournalLine."Pallet ID" := TransferLine."Pallet ID";
        ItemJournalLine."Pallet Type" := TransferLine."Pallet Type";
    end;

    //On Before Post Item Journal -> Transfer Receipt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforePostItemJournalLine', '', true, true)]
    local procedure OnBeforePostItemJournalLine_Rct(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line");
    begin
        ItemJournalLine."Pallet ID" := TransferLine."Pallet ID";
        ItemJournalLine."Pallet Type" := TransferLine."Pallet Type";
    end;

    //After Post Transfer Order - Ship
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterTransferOrderPostShipment', '', true, true)]
    local procedure OnAfterPostTransferOrderShipment(TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PalletID: code[20];
    begin

        //Updating Pallet - ID on Item Ledger Entris - In-Transit if Exist
        ItemLedgerEntry.reset;
        ItemLedgerEntry.setrange(ItemLedgerEntry."Document No.", TransferShipmentHeader."No.");
        if ItemLedgerEntry.findset then begin
            repeat
                if ItemLedgerEntry."Document No." <> ItemLedgerEntry."Pallet ID" then
                    PalletID := ItemLedgerEntry."Pallet ID";
            until ItemLedgerEntry.next = 0;
        end;

        ItemLedgerEntry.reset;
        ItemLedgerEntry.setrange(ItemLedgerEntry."Document No.", TransferShipmentHeader."No.");
        if ItemLedgerEntry.findset then begin
            repeat
                if ItemLedgerEntry."Document No." = ItemLedgerEntry."Pallet ID" then begin
                    ItemLedgerEntry."Pallet ID" := PalletID;
                    ItemLedgerEntry.modify;
                end;
            until ItemLedgerEntry.next = 0;
        end;

        TransferLines.reset;
        TransferLines.setrange(transferlines."Document No.", TransferHeader."No.");
        if transferlines.findset then
            repeat
                if TransferLines."Pallet ID" <> '' then
                    if PalletHeader.get(TransferLines."Pallet ID") then begin

                        if palletheader."Pallet ID" <> TransferHeader."Transfer-to Code" then begin
                            PalletHeader."Location Code" := TransferHeader."Transfer-to Code";
                            palletheader.modify;
                            PalletLine.reset;
                            PalletLine.setrange(PalletLine."Pallet ID", TransferLines."Pallet ID");
                            if PalletLine.findset then
                                repeat
                                    PalletLine."Location Code" := TransferHeader."Transfer-to Code";
                                    PalletLine.modify;
                                until PalletLine.next = 0;
                        end;
                    end;
            until TransferLines.next = 0;
    end;

    //After Post Transfer Order - Receipt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterTransferOrderPostReceipt', '', true, true)]
    local procedure OnAfterTransferOrderPostReceipt(var TransferHeader: Record "Transfer Header"; var TransferReceiptHeader: Record "Transfer Receipt Header")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PalletID: code[20];
    begin
        //Updating Pallet - ID on Item Ledger Entris - In-Transit if Exist
        ItemLedgerEntry.reset;
        ItemLedgerEntry.setrange(ItemLedgerEntry."Document No.", TransferReceiptHeader."No.");
        if ItemLedgerEntry.findset then begin
            repeat
                if ItemLedgerEntry."Document No." <> ItemLedgerEntry."Pallet ID" then
                    PalletID := ItemLedgerEntry."Pallet ID";
            until ItemLedgerEntry.next = 0;
        end;

        ItemLedgerEntry.reset;
        ItemLedgerEntry.setrange(ItemLedgerEntry."Document No.", TransferReceiptHeader."No.");
        if ItemLedgerEntry.findset then begin
            repeat
                if ItemLedgerEntry."Document No." = ItemLedgerEntry."Pallet ID" then begin
                    ItemLedgerEntry."Pallet ID" := PalletID;
                    ItemLedgerEntry.modify;
                end;
            until ItemLedgerEntry.next = 0;
        end;

        TransferLines.reset;
        TransferLines.setrange(transferlines."Document No.", TransferHeader."No.");
        if transferlines.findset then
            repeat
                if TransferLines."Pallet ID" <> '' then
                    if PalletHeader.get(TransferLines."Pallet ID") then begin

                        if palletheader."Pallet ID" <> TransferHeader."Transfer-to Code" then begin
                            PalletHeader."Location Code" := TransferHeader."Transfer-to Code";
                            palletheader.modify;
                            PalletLine.reset;
                            PalletLine.setrange(PalletLine."Pallet ID", TransferLines."Pallet ID");
                            if PalletLine.findset then
                                repeat
                                    PalletLine."Location Code" := TransferHeader."Transfer-to Code";
                                    PalletLine.modify;
                                until PalletLine.next = 0;
                        end;
                    end;
            until TransferLines.next = 0;
    end;

    var
        PalletListSelect: Record "Pallet List Select";
        palletheader: Record "Pallet Header";
        TransferLines: Record "Transfer Line";
        Lbl001: label 'No Pallets Found for %1 Location';
        Lbl002: label 'There are lines on transfer order, cant import pallets';

        PalletLine: Record "Pallet Line";


}