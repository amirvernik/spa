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
        palletheader.SetRange("Exist in warehouse shipment", false);
        palletheader.SetRange("Exist in Transfer Order", false);
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

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterValidateEvent', 'Pallet ID', false, false)]
    local procedure OnAfterValidateEventPalletID_ITemJournalLine(CurrFieldNo: Integer; var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line")
    var
        LPalletHeader: Record "Pallet Header";
        PalletSetup: Record "Pallet Process Setup";
    begin

        PalletSetup.get;
        if Rec."Journal Template Name" = PalletSetup."Item Reclass Template" then
            if LPalletHeader.Get(Rec."Pallet ID") then begin
                LPalletHeader.TestField("Exist in warehouse shipment", false);
                LPalletHeader.validate("Exist in Transfer Order", true);
                LPalletHeader."Transfer Order" := Rec."Journal Batch Name";
                LPalletHeader.Modify();
            end;

    end;


    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterValidateEvent', 'Quantity Received', false, false)]
    local procedure OnAfterValidateEventQuantityReceived(CurrFieldNo: Integer; var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line")
    var
        LTransferLine: Record "Transfer Line";
        LPalletHeader: Record "Pallet Header";
        PalletSetup: Record "Pallet Process Setup";
        LItemJournalLine: Record "Item Journal Line";
        LboolTransferLineExist: Boolean;
    begin
        if Rec."Quantity Received" = Rec.Quantity then begin
            if LPalletHeader.Get(Rec."Pallet ID") then begin
                LboolTransferLineExist := false;
                LTransferLine.Reset();
                LTransferLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                LTransferLine.SetFilter("Quantity Received", '<>%1', LTransferLine.Quantity);
                if LTransferLine.FindSet() then
                    repeat
                        if (LTransferLine."Document No." <> Rec."Document No.")
                        or ((LTransferLine."Document No." = Rec."Document No.") and (LTransferLine."Line No." <> Rec."Line No.")) then
                            LboolTransferLineExist := true;
                    until LTransferLine.Next() = 0;

                IF not LboolTransferLineExist then begin
                    PalletSetup.get;
                    LItemJournalLine.Reset();
                    LItemJournalLine.SetRange("Journal Template Name", PalletSetup."Item Reclass Template");
                    LItemJournalLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                    if not LItemJournalLine.FindFirst() then begin
                        LPalletHeader.validate("Exist in Transfer Order", false);
                        LPalletHeader."Transfer Order" := '';
                        LPalletHeader.Modify();
                    end;
                end;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteEventTransferLine(RunTrigger: Boolean; var Rec: Record "Transfer Line")
    var
        LTransferLine: Record "Transfer Line";
        LPalletHeader: Record "Pallet Header";
        PalletSetup: Record "Pallet Process Setup";
        LItemJournalLine: Record "Item Journal Line";
        LboolTransferLineExist: Boolean;
    begin
        if LPalletHeader.Get(Rec."Pallet ID") then begin
            LboolTransferLineExist := false;
            LTransferLine.Reset();
            LTransferLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
            LTransferLine.SetFilter("Quantity Received", '<>%1', LTransferLine.Quantity);
            if LTransferLine.FindSet() then
                repeat
                    if (LTransferLine."Document No." <> Rec."Document No.")
                    or ((LTransferLine."Document No." = Rec."Document No.") and (LTransferLine."Line No." <> Rec."Line No.")) then begin
                        LboolTransferLineExist := true;
                        LPalletHeader."Transfer Order" := TransferLines."Document No.";
                        LPalletHeader.Modify();
                    end;
                until LTransferLine.Next() = 0;

            IF not LboolTransferLineExist then begin
                PalletSetup.get;
                LItemJournalLine.Reset();
                LItemJournalLine.SetRange("Journal Template Name", PalletSetup."Item Reclass Template");
                LItemJournalLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                if not LItemJournalLine.FindFirst() then begin
                    LPalletHeader.validate("Exist in Transfer Order", false);
                    LPalletHeader."Transfer Order" := '';
                    LPalletHeader.Modify();
                end else begin
                    LPalletHeader."Transfer Order" := LItemJournalLine."Journal Batch Name";
                    LPalletHeader.Modify();
                end;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteEventTransferHeader(RunTrigger: Boolean; var Rec: Record "Transfer Header")
    var
        LTransferLine: Record "Transfer Line";
        RecTransferLine: Record "Transfer Line";
        LPalletHeader: Record "Pallet Header";
        PalletSetup: Record "Pallet Process Setup";
        LItemJournalLine: Record "Item Journal Line";
        LboolTransferLineExist: Boolean;
    begin
        RecTransferLine.Reset();
        RecTransferLine.SetRange("Document No.", Rec."No.");
        RecTransferLine.SetFilter("Pallet ID", '<>%1', '');
        if RecTransferLine.FindSet() then
            repeat
                if LPalletHeader.Get(RecTransferLine."Pallet ID") then begin
                    LboolTransferLineExist := false;
                    LTransferLine.Reset();
                    LTransferLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                    LTransferLine.SetFilter("Quantity Received", '<>%1', LTransferLine.Quantity);
                    if LTransferLine.FindSet() then
                        repeat
                            if (LTransferLine."Document No." <> RecTransferLine."Document No.")
                            or ((LTransferLine."Document No." = RecTransferLine."Document No.") and (LTransferLine."Line No." <> RecTransferLine."Line No.")) then begin
                                LboolTransferLineExist := true;
                                LPalletHeader."Transfer Order" := TransferLines."Document No.";
                                LPalletHeader.Modify();
                            end;
                            LboolTransferLineExist := true;
                        until LTransferLine.Next() = 0;

                    IF not LboolTransferLineExist then begin
                        PalletSetup.get;
                        LItemJournalLine.Reset();
                        LItemJournalLine.SetRange("Journal Template Name", PalletSetup."Item Reclass Template");
                        LItemJournalLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                        if not LItemJournalLine.FindFirst() then begin
                            LPalletHeader.validate("Exist in Transfer Order", false);
                            LPalletHeader."Transfer Order" := '';
                            LPalletHeader.Modify();
                        end else begin
                            LPalletHeader."Transfer Order" := LItemJournalLine."Journal Batch Name";
                            LPalletHeader.Modify();
                        end;
                    end;
                end;
            until RecTransferLine.Next() = 0;
    end;


    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteEventItemJournalLine(RunTrigger: Boolean; var Rec: Record "Item Journal Line")
    var
        LTransferLine: Record "Transfer Line";
        RecTransferLine: Record "Transfer Line";
        LPalletHeader: Record "Pallet Header";
        PalletSetup: Record "Pallet Process Setup";
        LItemJournalLine: Record "Item Journal Line";
        LboolTransferLineExist: Boolean;
    begin
        PalletSetup.get;
        if (Rec."Journal Template Name" = PalletSetup."Item Reclass Template") and (Rec."Pallet ID" <> '') then begin
            if LPalletHeader.Get(Rec."Pallet ID") then begin
                LTransferLine.Reset();
                LTransferLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                LTransferLine.SetFilter("Quantity Received", '<>%1', LTransferLine.Quantity);
                if not LTransferLine.FindFirst() then begin
                    LItemJournalLine.Reset();
                    LItemJournalLine.SetRange("Journal Template Name", PalletSetup."Item Reclass Template");
                    LItemJournalLine.SetRange("Pallet ID", LPalletHeader."Pallet ID");
                    LItemJournalLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
                    if not LItemJournalLine.FindFirst() then begin
                        LPalletHeader.validate("Exist in Transfer Order", false);
                        LPalletHeader."Transfer Order" := '';
                        LPalletHeader.Modify();
                    end else begin
                        LPalletHeader."Transfer Order" := LItemJournalLine."Journal Batch Name";
                        LPalletHeader.Modify();
                    end;
                end else begin
                    LPalletHeader."Transfer Order" := LTransferLine."Document No.";
                    LPalletHeader.Modify();
                end;
            end;
        end;
    end;



    //On Before Post Item Journal -> Transfer Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforePostItemJournalLine', '', true, true)]
    local procedure OnBeforePostItemJournalLine_Ship(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line")
    begin
        ItemJournalLine.validate("Pallet ID", TransferLine."Pallet ID");
        ItemJournalLine."Pallet Type" := TransferLine."Pallet Type";
    end;

    //On Before Post Item Journal -> Transfer Receipt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforePostItemJournalLine', '', true, true)]
    local procedure OnBeforePostItemJournalLine_Rct(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line");
    begin
        ItemJournalLine.validate("Pallet ID", TransferLine."Pallet ID");
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