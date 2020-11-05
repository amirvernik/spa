codeunit 60014 "Tracking Line Functions"
{
    //Add Tracking line to PO Line - global function
    procedure AddTrackingLineToPO(var pPalletHeader: Record "Pallet Header")
    var
        ItemRec: Record Item;
        DocmentStatusMgmt: Codeunit "Release Purchase Document";

    begin
        PalletLine.reset;
        PalletLine.setrange(palletline."Pallet ID", pPalletHeader."Pallet ID");
        if palletline.findset then
            repeat
                if (PurchaseLine.get(PurchaseLine."Document Type"::order, palletline."Purchase Order No.",
                    PalletLine."Purchase Order Line No.")) then
                    if (PurchaseLine."Outstanding Quantity" <> 0) then begin

                        PurchaseHeader.get(PurchaseHeader."Document Type"::order, palletline."Purchase Order No.");
                        if ItemRec.get(PurchaseLine."No.") then
                            if itemrec."Lot Nos." <> '' then begin

                                //Update Qty to Receive
                                if PurchaseHeader.Status = PurchaseHeader.status::Released then
                                    DocmentStatusMgmt.PerformManualReopen(PurchaseHeader);

                                PurchaseLine.validate("Qty. to Receive", PurchaseLine."Outstanding Quantity");
                                PurchaseLine.validate("qty. to invoice", PurchaseLine.Quantity);
                                PurchaseLine.modify;

                                //Create Reservation Entry
                                RecGReservationEntry2.reset;
                                if RecGReservationEntry2.findlast then
                                    maxEntry := RecGReservationEntry2."Entry No." + 1;

                                RecGReservationEntry.init;
                                RecGReservationEntry."Entry No." := MaxEntry;
                                RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                                RecGReservationEntry."Creation Date" := Today;
                                RecGReservationEntry."Created By" := UserId;
                                RecGReservationEntry."Expected Receipt Date" := PurchaseLine."Expected Receipt Date";
                                RecGReservationEntry."Source Type" := 39;
                                RecGReservationEntry."Source Subtype" := 1;
                                RecGReservationEntry."Source ID" := PurchaseHeader."No.";
                                RecGReservationEntry."Source Ref. No." := PurchaseLine."Line No.";
                                RecGReservationEntry.Positive := true;
                                RecGReservationEntry.validate("Location Code", purchaseline."Location Code");
                                RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                RecGReservationEntry."Lot No." := PurchaseHeader."Batch Number";
                                RecGReservationEntry."Packing Date" := pPalletHeader."Creation Date";
                                // RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                                RecGReservationEntry.validate("Item No.", PurchaseLine."No.");
                                if purchaseline."Variant code" <> '' then
                                    RecGReservationEntry.Validate("Variant code", purchaseline."Variant code");
                                RecGReservationEntry.validate("Quantity (Base)", PurchaseLine."Quantity (Base)");
                                RecGReservationEntry.validate(Quantity, PurchaseLine.Quantity);
                                RecGReservationEntry.insert;
                            end;
                        if PurchaseHeader.Status = PurchaseHeader.status::Released then begin
                            DocmentStatusMgmt.PerformManualReopen(PurchaseHeader);
                            DocmentStatusMgmt.PerformManualRelease(PurchaseHeader);
                        end;

                        if PurchaseHeader.Status = PurchaseHeader.status::Open then
                            DocmentStatusMgmt.PerformManualRelease(PurchaseHeader);
                    end;
            until PalletLine.next = 0;
    end;

    //Remove Tracking line From PO Line - Global function
    procedure RemoveTrackingLineFromPO(var pPalletHeader: Record "Pallet Header")

    begin
        PalletLine.reset;
        PalletLine.setrange(palletline."Pallet ID", pPalletHeader."Pallet ID");
        if palletline.findset then
            repeat
                RecGReservationEntry.reset;
                //RecGReservationEntry.SetRange("Source Type", 39);
                //RecGReservationEntry.setrange("Source Subtype", 1);
                RecGReservationEntry.SetRange("Item No.", PalletLine."Item No.");
                RecGReservationEntry.setrange("Lot No.", PalletLine."Lot Number");
                if RecGReservationEntry.findset() then
                    repeat
                        RecGReservationEntry.delete();
                    until RecGReservationEntry.next = 0;
            until palletline.next = 0;

    end;

    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PalletLine: Record "Pallet Line";
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        MaxEntry: integer;
}