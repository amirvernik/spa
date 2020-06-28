page 60010 "Pallet List Select Reclass"
{

    PageType = StandardDialog;
    SourceTable = "Pallet List Select";
    Caption = 'Pallet List Select - For Reclass Journal';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Select; Select)
                {
                    ApplicationArea = All;
                }
                field("Pallet ID"; "Pallet ID")
                {
                    Editable = false;
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        PalletHeader.reset;
                        PalletHeader.setrange(PalletHeader."Pallet ID", rec."Pallet ID");
                        if palletheader.findfirst then
                            page.run(page::"Pallet Card", palletheader);
                    end;
                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ItemRec: Record Item;
        PalletHeader: Record "Pallet Header";
    begin
        PalletSetup.get;
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", PalletSetup."Item Reclass Template");
        ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Reclass Batch");
        if ItemJournalLine.findlast then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        rec.reset;
        rec.setrange(Select, true);
        if rec.findset then begin
            repeat
                PalletLine.reset;
                PalletLine.setrange("Pallet ID", rec."Pallet ID");
                if palletline.findset then
                    repeat
                        PalletProcessSetup.get;
                        ItemJournalLine.init;
                        ItemJournalLine."Journal Template Name" := PalletProcessSetup."Item Reclass Template";
                        ItemJournalLine."Journal Batch Name" := PalletProcessSetup."Item Reclass Batch";
                        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Transfer;
                        ItemJournalLine."Document Date" := today;
                        ItemJournalLine."Line No." := LineNumber;
                        ItemJournalLine.insert;
                        ItemJournalLine."Document No." := rec."Pallet ID";
                        ItemJournalLine."Posting Date" := today;
                        ItemJournalLine.validate("Item No.", PalletLine."Item No.");
                        ItemJournalLine."Variant Code" := palletline."Variant Code";
                        ItemJournalLine.validate(Quantity, PalletLine.Quantity);
                        ItemJournalLine."Pallet ID" := rec."Pallet ID";
                        ItemJournalLine.validate("Location Code", PalletLine."Location Code");
                        if palletheader.get(PalletLine."Pallet ID") then
                            ItemJournalLine."Pallet Type" := PalletHeader."Pallet Type";
                        ItemJournalLine.modify;

                        if ItemRec.get(PalletLine."Item No.") then
                            if itemrec."Lot Nos." <> '' then begin
                                //Create Reservation Entry

                                RecGReservationEntry2.reset;
                                if RecGReservationEntry2.findlast then
                                    maxEntry := RecGReservationEntry2."Entry No." + 1;

                                RecGReservationEntry.init;
                                RecGReservationEntry."Entry No." := MaxEntry;
                                //V16.0 - Changed From [3] to "Prospect" on Enum
                                RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                                //V16.0 - Changed From [3] to "Prospect" on Enum
                                RecGReservationEntry.validate("Creation Date", Today);
                                RecGReservationEntry."Created By" := UserId;
                                RecGReservationEntry."Expected Receipt Date" := Today;
                                RecGReservationEntry."Shipment Date" := today;
                                RecGReservationEntry."Source Type" := 83;
                                RecGReservationEntry."Source Subtype" := 4;
                                RecGReservationEntry."Source ID" := PalletProcessSetup."Item Reclass Template";
                                RecGReservationEntry."Source Batch Name" := PalletProcessSetup."Item Reclass Batch";
                                RecGReservationEntry."Source Ref. No." := LineNumber;
                                RecGReservationEntry."Location Code" := ItemJournalLine."Location Code";
                                //V16.0 - Changed From [1] to "Lot No." on Enum
                                RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                //V16.0 - Changed From [1] to "Lot No." on Enum
                                RecGReservationEntry."Lot No." := PalletLine."Lot Number";
                                RecGReservationEntry."New Lot No." := PalletLine."Lot Number";
                                RecGReservationEntry.validate("Item No.", PalletLine."Item No.");
                                if PalletLine."Variant Code" <> '' then
                                    RecGReservationEntry.validate("Variant Code", PalletLine."Variant Code");
                                RecGReservationEntry.validate("Quantity (Base)", -1 * PalletLine.Quantity);
                                RecGReservationEntry.validate(Quantity, -1 * palletline.Quantity);
                                RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                                RecGReservationEntry."Packing Date" := Today;
                                RecGReservationEntry.Positive := false;
                                RecGReservationEntry.insert;

                                LineNumber += 10000;
                            end;
                    until palletline.next = 0;
            until rec.next = 0;

            PalletSetup.Get();
            ItemJournalLine.reset;
            ItemJournalLine.setrange("Journal Template Name", PalletSetup."Item Reclass Template");
            ItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Reclass Batch");
            page.run(393, ItemJournalLine);

        end;
    end;

    var
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "pallet line";
        ItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        LineNumber: Integer;
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        maxEntry: integer;
        PalletProcessSetup: Record "Pallet Process Setup";
}
