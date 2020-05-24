codeunit 60017 "Pallet Reservation Functions"
{
    //Action - Item Tracking
    [EventSubscriber(ObjectType::Page, page::"Pallet Card Subpage", 'OnBeforeActionEvent', 'Item Tracking', true, true)]
    local procedure OnBeforeActionItemTrackingPalletSubpage(var Rec: Record "Pallet Line")
    begin
        if rec.Quantity > 0 then
            error('LOT No. Exist for Item, please contact System administrator');
    end;

    //Get Qty Reserved by Pallet Line
    procedure FctGetLotQtyReservered(Var LotNumber: Code[20]): Decimal
    var
        PalletReservationEntry: Record "Pallet reservation Entry";
        QtyReserved: Decimal;
    begin
        QtyReserved := 0;
        PalletReservationEntry.reset;
        PalletReservationEntry.setrange("Lot No.", LotNumber);
        if PalletReservationEntry.findset then
            repeat
                QtyReserved += PalletReservationEntry.Quantity;
            until PalletReservationEntry.next = 0;
        exit(QtyReserved);
    end;

    //On AfterValidate - Lot Number
    [EventSubscriber(ObjectType::table, database::"Pallet Line", 'OnAfterValidateEvent', 'Lot Number', true, true)]
    local procedure OnAfterValidatePalletLineLot(var Rec: Record "Pallet Line"; var xRec: Record "Pallet Line")
    var
        PalletReservationEntry: Record "Pallet reservation Entry";
    begin
        if rec."Lot Number" <> '' then begin
            if not PalletReservationEntry.get(rec."Pallet ID", rec."Line No.", rec."Lot Number") then begin
                PalletReservationEntry.init;
                PalletReservationEntry."Pallet ID" := rec."Pallet ID";
                PalletReservationEntry."Pallet Line" := rec."Line No.";
                PalletReservationEntry."Lot No." := rec."Lot Number";
                PalletReservationEntry."Item No." := rec."Item No.";
                PalletReservationEntry."Variant Code" := rec."Variant Code";
                PalletReservationEntry.Quantity := rec.Quantity;
                PalletReservationEntry.Insert();
            end;
        end;
        if rec."Lot Number" = '' then begin
            PalletReservationEntry.reset;
            PalletReservationEntry.setrange("Pallet ID", rec."Pallet ID");
            PalletReservationEntry.setrange("Pallet Line", rec."Line No.");
            if PalletReservationEntry.findfirst then
                PalletReservationEntry.Delete();
            rec."Expiration Date" := 0D;
            rec.modify;
        end;
    end;


}