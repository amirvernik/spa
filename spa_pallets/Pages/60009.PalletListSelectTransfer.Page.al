page 60009 "Pallet List Select Transfer"
{

    PageType = StandardDialog;
    SourceTable = "Pallet List Select";
    Caption = 'Pallet List Select - For Transfer Orders';

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
    begin
        if CloseAction = CloseAction::OK then begin
            rec.reset;
            rec.setrange(Select, true);
            if rec.findset then begin
                LineNumber := 10000;
                repeat
                    PalletLine.reset;
                    PalletLine.setrange("Pallet ID", rec."Pallet ID");
                    if palletline.findset then
                        repeat
                            TransferOrderNumber := rec."Source Document";
                            TransferLine.init;
                            TransferLine."Document No." := rec."Source Document";
                            TransferLine."Line No." := LineNumber;
                            TransferLine.validate("Item No.", PalletLine."Item No.");
                            TransferLine."Variant Code" := PalletLine."Variant Code";
                            TransferLine.validate(Quantity, PalletLine.Quantity);
                            TransferLine.validate("Qty. to Ship", PalletLine.Quantity);
                            TransferLine."Pallet ID" := rec."Pallet ID";
                            TransferLine."Lot No." := PalletLine."Lot Number";
                            if PalletHeader.get(PalletLine."Pallet ID") then
                                TransferLine."Pallet Type" := PalletHeader."Pallet Type";
                            TransferLine.insert;
                            LineNumber += 10000;
                        until palletline.next = 0;
                until rec.next = 0;
            end;
        end;

        TransferLine.reset;
        TransferLine.setrange("Document No.", TransferOrderNumber);
        if TransferLine.findset then
            repeat
                //Create Reservation Entry
                //From Location - Negative
                if ItemRec.get(TransferLine."Item No.") then
                    if itemrec."Lot Nos." <> '' then begin
                        //Create Reservation Entry

                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        //V16.0 - Changed From [2] to "Surplus" on Enum
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                        //V16.0 - Changed From [2] to "surplus" on Enum
                        RecGReservationEntry.validate("Creation Date", Today);
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Shipment Date" := today;
                        RecGReservationEntry."Source Type" := 5741;
                        RecGReservationEntry."Source Subtype" := 0;
                        RecGReservationEntry."Source ID" := TransferLine."Document No.";
                        RecGReservationEntry."Source Ref. No." := TransferLine."Line No.";
                        RecGReservationEntry."Location Code" := TransferLine."Transfer-from Code";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Lot No." := TransferLine."Lot No.";
                        RecGReservationEntry.validate("Item No.", TransferLine."Item No.");
                        if TransferLine."Variant Code" <> '' then
                            RecGReservationEntry.validate("Variant Code", TransferLine."Variant Code");
                        RecGReservationEntry.validate("Quantity (Base)", -1 * TransferLine.Quantity);
                        RecGReservationEntry.validate(Quantity, -1 * TransferLine.Quantity);
                        RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                        RecGReservationEntry."Packing Date" := PalletHeader."Creation Date";
                        RecGReservationEntry.Positive := false;
                        RecGReservationEntry.insert;

                        //To Location - Positive
                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        //V16.0 - Changed From [2] to "Surplus" on Enum
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                        //V16.0 - Changed From [2] to "Surplus" on Enum
                        RecGReservationEntry.validate("Creation Date", Today);
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Shipment Date" := today;
                        RecGReservationEntry."Source Type" := 5741;
                        RecGReservationEntry."Source Subtype" := 1;
                        RecGReservationEntry."Source ID" := TransferLine."Document No.";
                        RecGReservationEntry."Source Ref. No." := TransferLine."Line No.";
                        RecGReservationEntry."Location Code" := TransferLine."Transfer-to Code";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Lot No." := TransferLine."Lot No.";
                        RecGReservationEntry.validate("Item No.", TransferLine."Item No.");
                        if TransferLine."Variant Code" <> '' then
                            RecGReservationEntry.validate("Variant Code", TransferLine."Variant Code");
                        RecGReservationEntry.validate("Quantity (Base)", TransferLine.Quantity);
                        RecGReservationEntry.validate(Quantity, TransferLine.Quantity);
                        RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                        RecGReservationEntry."Packing Date" := PalletHeader."Creation Date";
                        RecGReservationEntry.Positive := true;
                        RecGReservationEntry.insert;
                    end;
            until TransferLine.next = 0;
    end;

    var
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "pallet line";
        TransferLine: Record "Transfer Line";
        LineNumber: Integer;
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        maxEntry: integer;
        LineNumber2: integer;
        TransferOrderNumber: code[20];
}
