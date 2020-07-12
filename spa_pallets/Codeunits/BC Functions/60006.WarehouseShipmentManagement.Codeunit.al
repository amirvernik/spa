codeunit 60006 "Warehouse Shipment Management"
{

    //Remove All Pallets - Global function
    procedure RemoveAllPallets(var WarehouseShipment: Record "Warehouse Shipment Header")
    var
        WarehousePallet: Record "Warehouse Pallet";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if Confirm(Lbl005) then begin
            WarehousePallet.reset;
            WarehousePallet.setrange(WarehousePallet."Whse Shipment No.", WarehouseShipment."No.");
            if WarehousePallet.findset then
                repeat
                    if RecGReservationEntry.get(WarehousePallet."Reserve. Entry No.") then
                        RecGReservationEntry.Delete();
                    if WarehouseShipmentLine.get(WarehousePallet."Whse Shipment No.", WarehousePallet."Whse Shipment Line No.") then begin
                        WarehouseShipmentLine."Remaining Quantity" := 0;
                        WarehouseShipmentLine.modify;
                    end;
                    WarehousePallet.Delete();
                    if PalletHeader.get(WarehousePallet."Pallet ID") then begin
                        PalletHeader."Exist in warehouse shipment" := false;
                        PalletHeader.modify;
                    end;
                until WarehousePallet.next = 0;

            WarehouseShipmentLine.reset;
            WarehouseShipmentLine.setrange("No.", WarehouseShipment."No.");
            if WarehouseShipmentLine.findset then
                WarehouseShipmentLine.ModifyAll("Remaining Quantity", WarehouseShipmentLine.Quantity);
        end;
        message(Lbl006);
    end;


    //Pallet Select to remove - Global function
    procedure SelectPalletToRemove(var WarehouseShipment: Record "Warehouse Shipment Header")
    var
        PalletListSelect: Record "Pallet List Select" temporary;
        WarehousePallet: Record "Warehouse Pallet";
    begin
        if PalletListSelect.findset then
            PalletListSelect.deleteall;

        WarehousePallet.reset;
        WarehousePallet.setrange("Whse Shipment No.", WarehouseShipment."No.");
        if WarehousePallet.findset then
            repeat
                if not PalletListSelect.get(WarehousePallet."Pallet ID") then begin
                    PalletListSelect.init;
                    PalletListSelect."Source Document" := WarehouseShipment."No.";
                    PalletListSelect."Pallet ID" := WarehousePallet."Pallet ID";
                    PalletListSelect.Insert();
                end;
            until WarehousePallet.next = 0;

        page.run(page::"Pallet List Select Remove", PalletListSelect);
    end;

    //Pallet Selection Page - Popup
    procedure PalletSelection(var WarehouseShipment: Record "Warehouse Shipment Header")
    var
        PalletListSelect: Record "Pallet List Select" temporary;
        WarehousePallet: Record "Warehouse Pallet";
        PalletItemTemp: Record "Item Variant" temporary;
        BoolPallet: Boolean;
    begin
        if PalletItemTemp.findset then
            PalletItemTemp.deleteall;

        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", WarehouseShipment."No.");
        if not WarehouseShipmentLine.findset then
            error(Lbl002);

        //Getting List of items in Shipment
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", WarehouseShipment."No.");
        if WarehouseShipmentLine.findset then
            repeat
                if not PalletItemTemp.get(WarehouseShipmentLine."Item No.", WarehouseShipmentLine."Variant Code") then begin
                    PalletItemTemp.init;
                    PalletItemTemp.code := WarehouseShipmentLine."Variant Code";
                    PalletItemTemp."Item No." := WarehouseShipmentLine."Item No.";
                    PalletItemTemp.Insert;
                end;
            until WarehouseShipmentLine.next = 0;

        if PalletListSelect.findset then
            PalletListSelect.Deleteall;

        palletheader.reset;
        palletheader.setrange(palletheader."Pallet Status", palletheader."Pallet Status"::Closed);
        palletheader.setrange(palletheader."Location Code", WarehouseShipment."Location Code");
        palletheader.setrange(palletheader."Exist in warehouse shipment", false);
        if palletheader.findset then begin
            BoolPallet := false;
            repeat
                PalletLine.reset;
                PalletLine.setrange("Pallet ID", Palletheader."Pallet ID");
                if PalletLine.findset then
                    repeat
                        if PalletItemTemp.get(PalletLine."Item No.", palletline."Variant Code") then
                            BoolPallet := true;
                    until palletline.next = 0;

                if BoolPallet then begin
                    PalletListSelect.init;
                    PalletListSelect."Pallet ID" := palletheader."Pallet ID";
                    PalletListSelect."Source Document" := WarehouseShipment."No.";
                    Palletheader.CalcFields("Total Qty");
                    PalletListSelect."Total Qty" := Palletheader."Total Qty";
                    PalletListSelect.insert;
                end;
            until palletheader.next = 0;
            page.run(page::"Pallet List Select Whse Ship", PalletListSelect);
        end
        else
            message(Lbl001, WarehouseShipment."Location Code");
    end;

    //OnAfterDelete - Warehouse Shipment Line
    [EventSubscriber(ObjectType::table, 7321, 'OnAfterDeleteEvent', '', true, true)]
    local procedure OnAfterDeleteShipmentLine(var Rec: Record "Warehouse Shipment Line")
    begin
        WarehousePallet.reset;
        WarehousePallet.setrange("Whse Shipment No.", rec."No.");
        if WarehousePallet.findfirst then
            error(Err001);
    end;

    //OnInsert - Warehouse Pallet
    [EventSubscriber(ObjectType::table, database::"Warehouse Pallet", 'OnAfterInsertEvent', '', true, true)]
    local procedure FctOnAfterInsertWarehousePallet(var Rec: Record "Warehouse Pallet")
    var
        ItemRec: Record Item;
        SalesLine: Record "Sales Line";

    begin
        if WarehouseShipmentLine.get(rec."Whse Shipment No.", rec."Whse Shipment line No.") then begin
            //WarehouseShipmentLine."Qty. to Ship" += rec.Quantity;
            //WarehouseShipmentLine."Qty. to Ship (Base)" += rec.Quantity;
            /*if SalesLine.get(SalesLine."Document Type"::Order, rec."Sales Order No.", rec."Sales Order Line No.") then begin
                SalesLine.validate(SalesLine."Qty. to Ship", SalesLine."Qty. to Ship" - rec.Quantity);
            end;*/
            WarehouseShipmentLine."Remaining Quantity" -= rec.quantity;
            WarehouseShipmentLine.modify;

            if ItemRec.get(WarehouseShipmentLine."Item No.") then
                if itemrec."Lot Nos." <> '' then begin
                    //Create Reservation Entry

                    RecGReservationEntry2.reset;
                    if RecGReservationEntry2.findlast then
                        maxEntry := RecGReservationEntry2."Entry No." + 1;

                    PalletLine.get(rec."Pallet ID", rec."Pallet Line No.");
                    RecGReservationEntry.init;
                    RecGReservationEntry."Entry No." := MaxEntry;
                    //V16.0 - Changed From [2] to "surplus" on Enum
                    RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                    //V16.0 - Changed From [2] to "surplus" on Enum
                    RecGReservationEntry."Creation Date" := Today;
                    RecGReservationEntry."Created By" := UserId;
                    RecGReservationEntry.Positive := false;
                    RecGReservationEntry."Source Type" := 37;
                    RecGReservationEntry."Source Subtype" := 1;
                    RecGReservationEntry."Source ID" := WarehouseShipmentLine."Source No.";
                    RecGReservationEntry."Source Ref. No." := WarehouseShipmentLine."Source Line No.";
                    RecGReservationEntry."Shipment Date" := today;
                    RecGReservationEntry."Item No." := WarehouseShipmentLine."Item No.";
                    if PalletLine."Variant Code" <> '' then
                        RecGReservationEntry."Variant Code" := PalletLine."Variant Code";
                    //V16.0 - Changed From [1] to "Lot No." on Enum
                    RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                    //V16.0 - Changed From [1] to "Lot No." on Enum
                    RecGReservationEntry."Location Code" := WarehouseShipmentLine."Location Code";
                    RecGReservationEntry."Lot No." := PalletLine."Lot Number";
                    RecGReservationEntry.validate("Quantity (Base)", -1 * rec.Quantity);
                    RecGReservationEntry.validate(Quantity, -1 * rec.Quantity);
                    RecGReservationEntry.insert;

                    if PalletHeader.get(rec."Pallet ID") then
                        RecGReservationEntry."Packing Date" := Palletheader."Creation Date";
                    if PalletLine.get(rec."Pallet ID", rec."Pallet Line No.") then
                        RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                    RecGReservationEntry.modify;

                    Rec."Reserve. Entry No." := MaxEntry;
                    Rec.modify;
                end;
        end;
    end;

    //OnAfterInsert - Warehouse Shipment Line
    [EventSubscriber(ObjectType::table, 7321, 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertWarehouseShipmentLine(var Rec: Record "Warehouse Shipment Line")
    begin
        rec."Remaining Quantity" := rec.Quantity;
        rec.modify;
    end;

    //On Before onfirm Shipment Post
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment (Yes/No)", 'OnBeforeConfirmWhseShipmentPost', '', true, true)]
    local procedure MyProcedure(var WhseShptLine: Record "Warehouse Shipment Line")
    begin
        BoolCheck := false;
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", WhseShptLine."No.");
        if WarehouseShipmentLine.findset then
            repeat
                if WarehouseShipmentLine.Quantity <> WarehouseShipmentLine."Qty. to Ship" then
                    BoolCheck := true;
            until WarehouseShipmentLine.next = 0;
        if BoolCheck then
            message(Lbl003);
    end;

    //On After Post Whse. Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterPostedWhseShptHeaderInsert', '', true, true)]
    local procedure OnAfterPostedWhseShptHeaderInsert(PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; LastShptNo: Code[20])
    var
        PostedWarehousePallet: Record "Posted Warehouse Pallet";
        PostedWarehousePallet2: Record "Posted Warehouse Pallet";
        WarehousePallet: Record "Warehouse Pallet";
        PostedWhseShipNo: code[20];

    begin
        //Update Warehouse Shipment - On Posted
        PostedWarehousePallet.reset;
        PostedWarehousePallet.setrange("Whse Shipment No.", PostedWhseShipmentHeader."Whse. Shipment No.");
        if PostedWarehousePallet.findset then begin
            PostedWhseShipNo := PostedWhseShipmentHeader."No.";
            repeat
                PostedWarehousePallet2.init;
                PostedWarehousePallet2.TransferFields(PostedWarehousePallet);
                PostedWarehousePallet2."Whse Shipment No." := PostedWhseShipNo;
                PostedWarehousePallet2.insert;
                PostedWarehousePallet.delete;

            until PostedWarehousePallet.next = 0;
        end;
    end;

    //On After Post Whse. Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostedWhseShptHeaderInsert', '', true, true)]
    local procedure OnBeforePostedWhseShptHeaderInsert(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        PostedWarehousePallet: Record "Posted Warehouse Pallet";
        PostedWarehousePallet2: Record "Posted Warehouse Pallet";
        WarehousePallet: Record "Warehouse Pallet";
        PostedWhseShipNo: code[20];
        WarehouseShipmentLine: Record "Warehouse Shipment Line";

    begin
        //Move to Posted Pallet  - Working      
        WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentHeader."No.");
        if WarehousePallet.findset then
            repeat
                PostedWarehousePallet.init;
                PostedWarehousePallet.TransferFields(WarehousePallet);
                PostedWarehousePallet.insert(true);
                WarehousePallet.delete;
            until WarehousePallet.next = 0;
    end;

    //On AFter Insert Sales Shipment Line 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesShptLineInsert', '', true, true)]
    local procedure OnAfterSalesShptLineInsert(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line")
    begin
        PalletLedgerFunctions.PalletLedgerEntryWarehouseShipment(SalesShipmentLine, SalesLine);
    end;

    //If warehouse Shipment for sales return Order - On Before Post Shipment
    [EventSubscriber(ObjectType::page, page::"Warehouse Shipment", 'OnBeforeActionEvent', 'P&ost Shipment', true, true)]
    local procedure OnBeforePostShipment(var Rec: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", rec."No.");
        WarehouseShipmentLine.setrange(WarehouseShipmentLine."Source Document", WarehouseShipmentLine."Source Document"::"Sales Return Order");
        if WarehouseShipmentLine.findset then
            LinesCountReturn := WarehouseShipmentLine.count;

        if LinesCountReturn > 0 then begin

        end;
    end;

    //On Before Insert Warehouse Shipment Header - Table
    [EventSubscriber(ObjectType::Table, database::"Warehouse Shipment Header", 'OnBeforeInsertEvent', '', true, true)]
    local procedure OnAfterInsertWarehouseShipment(var Rec: Record "Warehouse Shipment Header")
    begin
        rec."User Created" := UserId;
    end;

    var
        LinesCount: integer;
        LinesCountReturn: Integer;
        BoolCheck: Boolean;
        WarehousePallet: Record "Warehouse Pallet";
        PalletHeader_Temp: Record "Pallet Header" temporary;
        PalletLine_Temp: Record "Pallet Line" temporary;
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        Palletheader: Record "Pallet Header";
        Lbl001: label 'No Pallets Found for %1 Location';
        Lbl002: label 'The chosen pallet cant be added because it holds items that do not exist in the warehouse shipment';
        Lbl003: label 'Notice that QTY is less then sales order QTY, are you sure you want to post the shipment?';
        Lbl004: Label 'Ok. so we dont';
        Lbl005: label 'Do you want to remove all pallets from shipments?';
        Lbl006: Label 'All Pallets removed';
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        Err001: Label 'You cannot delete warehouse shipment line. there are Pallets connected, Remove pallets and try again';
        MaxEntry: Integer;
        PalletLine: Record "Pallet Line";

}