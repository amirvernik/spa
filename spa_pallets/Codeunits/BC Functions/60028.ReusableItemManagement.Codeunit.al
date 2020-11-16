codeunit 60028 "ReusableItemManagement"
{
    [EventSubscriber(ObjectType::Table, database::"BOM Component", 'OnAfterValidateEvent', 'No.', true, true)]
    local procedure UpdateReusable(VAR Rec: Record "BOM Component"; VAR xRec: Record "BOM Component"; CurrFieldNo: Integer)
    var
        Item: Record Item;
    begin
        CASE Rec.Type OF
            Rec.Type::Item:
                BEGIN
                    if Item.GET(Rec."No.") then
                        rec."Reusable item" := Item."Reusable item";
                end;
        end;
    end;

   /* [EventSubscriber(ObjectType::Codeunit, 90, 'OnAfterPostPurchaseDoc', '', true, true)]
    local procedure OnAfterPostPurchaseDoc(VAR PurchaseHeader: Record "Purchase Header"; VAR GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    begin
        if not (PurchaseHeader."Microwave Process PO") then
            exit;
        FillPostItemJournal(PurchRcpHdrNo);
    end;
*/
    procedure FillPostItemJournal(PurchRcpHdrNo: code[20])
    var
        RecGItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        PurchRcpLine: record "Purch. Rcpt. Line";
        ItemLedgerEntry: Record "Item Ledger Entry";

        Item: Record Item;
        LineNumber: Integer;
        FirstLine: Integer;
        BoolToPost: Boolean;
    begin
        //Inserting Item Journal
        PalletSetup.get();
        RecGItemJournalLine.reset;
        RecGItemJournalLine.setrange("Journal Template Name", 'ITEM');
        RecGItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        if RecGItemJournalLine.FindLast() then
            FirstLine := RecGItemJournalLine."Line No." + 10000
        else
            FirstLine := 10000;
        LineNumber := FirstLine;
        PurchRcpLine.reset;
        PurchRcpLine.setrange("Document No.", PurchRcpHdrNo);
        if PurchRcpLine.findset then begin
            repeat
                If ItemLedgerEntry.get(PurchRcpLine."Item Rcpt. Entry No.") and (Item.get(PurchRcpLine."No.") and Item."Reusable item") then begin
                    RecGItemJournalLine.init;
                    RecGItemJournalLine."Journal Template Name" := 'ITEM';
                    RecGItemJournalLine."Journal Batch Name" := PalletSetup."Item Journal Batch";
                    RecGItemJournalLine."Line No." := LineNumber;
                    RecGItemJournalLine.insert;
                    RecGItemJournalLine."Entry Type" := RecGItemJournalLine."Entry Type"::"Positive Adjmt.";
                    RecGItemJournalLine."Posting Date" := PurchRcpLine."Posting Date";
                    RecGItemJournalLine."Document No." := PurchRcpLine."Order No.";
                    RecGItemJournalLine.Description := PurchRcpLine.Description;
                    RecGItemJournalLine.validate("Item No.", PurchRcpLine."No.");
                    if PurchRcpLine."Variant Code" <> '' then
                        RecGItemJournalLine.validate("Variant Code", PurchRcpLine."Variant Code");
                    RecGItemJournalLine.validate("Location Code", PurchRcpLine."Location Code");
                    RecGItemJournalLine.validate(Quantity, PurchRcpLine."Quantity");
                    RecGItemJournalLine."Pallet ID" := ItemLedgerEntry."Pallet ID";
                    RecGItemJournalLine."Pallet Type" := ItemLedgerEntry."Pallet Type";
                    RecGItemJournalLine.Disposal := ItemLedgerEntry.disposal;
                    RecGItemJournalLine.modify;
                    LineNumber += 10000;
                    BoolToPost := true;
                end;
            until PurchRcpLine.next = 0;

            if BoolToPost then begin
                RecGItemJournalLine.setrange("Line No.", FirstLine, LineNumber);
                if RecGItemJournalLine.FindSet() then
                    repeat
                        CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", RecGItemJournalLine);
                    until RecGItemJournalLine.Next() = 0;
            end;
        end;
    end;

}