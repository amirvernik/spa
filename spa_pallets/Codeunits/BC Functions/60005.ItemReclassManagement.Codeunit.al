codeunit 60005 "Item Reclass Management"
{
    //Pallet Selection - Item Reclass Journal
    procedure PalletSelection(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.setrange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        if ItemJournalLine.findlast then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        if PalletListSelect.findset then
            PalletListSelect.Deleteall;

        palletheader.reset;
        palletheader.setrange(palletheader."Pallet Status", palletheader."Pallet Status"::Closed);
        //palletheader.setrange(palletheader."Location Code", TransferOrder."Transfer-from Code");
        if palletheader.findset then begin
            repeat
                PalletListSelect.init;
                PalletListSelect."Pallet ID" := palletheader."Pallet ID";
                //PalletListSelect."Transfer Order" := TransferOrder."No.";
                PalletListSelect.insert;
            until palletheader.next = 0;
            page.run(page::"Pallet List Select Reclass", PalletListSelect);
        end;
    end;

    //On After Post Item journal Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterPostItemJnlLine', '', true, true)]
    local procedure OnAfterPostItemReclassJournal(var ItemJournalLine: Record "Item Journal Line")

    begin
        PalletSetup.get;
        if ItemJournalLine."Journal Template Name" = PalletSetup."Item Reclass Template" then begin
            if palletheader.get(ItemJournalLine."Document No.") then begin

                //Changeing The Pallet Location
                PalletHeader."Location Code" := ItemJournalLine."New Location Code";
                PalletHeader.modify;

                PalletLine.reset;
                PalletLine.setrange("Pallet ID", PalletHeader."Pallet ID");
                if palletline.findset then
                    repeat
                        PalletLine."Location Code" := ItemJournalLine."New Location Code";
                        PalletLine.modify;
                    until PalletLine.next = 0;
            end;
        end;
    end;

    var
        PalletListSelect: Record "Pallet List Select";
        PalletSetup: Record "Pallet Process Setup";
        palletheader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        LineNumber: Integer;
        ItemJournalLine: Record "Item Journal Line";
        Lbl001: label 'No Pallets Found for %1 Location';
        Lbl002: label 'There are lines ontransfer order, cant import pallets';
}