codeunit 60006 "Warehouse Shipment Management"
{

    //Remove All Pallets - Global function
    procedure RemoveAllPallets(var WarehouseShipment: Record "Warehouse Shipment Header")
    var
        WarehousePallet: Record "Warehouse Pallet";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
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
                repeat

                    WarehouseShipmentLine."Remaining Quantity" := WarehouseShipmentLine.Quantity - WarehouseShipmentLine."Qty. Shipped";
                    WarehouseShipmentLine."Qty. to Ship" := 0;
                    WarehouseShipmentLine.modify;
                until WarehouseShipmentLine.Next() = 0;
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
        Palletheader.SetRange(Palletheader."Exist in Transfer Order", false);
        Palletheader.setrange(Palletheader."Raw Material Pallet", false);
        if palletheader.findset then begin
            repeat
                BoolPallet := false;
                PalletLine.reset;
                PalletLine.setrange("Pallet ID", Palletheader."Pallet ID");
                if PalletLine.findset then
                    repeat
                        if PalletItemTemp.get(PalletLine."Item No.", PalletLine."Variant Code") then
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
        WarehousePallet.SetRange("Whse Shipment Line No.", Rec."Line No.");
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
            //WarehouseShipmentLine."Qty. to Ship" += rec.quantity;
            WarehouseShipmentLine.validate("Qty. to Ship", WarehouseShipmentLine."Qty. to Ship" + rec.quantity);
            WarehouseShipmentLine."Remaining Quantity" -= rec.quantity;
            WarehouseShipmentLine.modify;
            if ItemRec.get(WarehouseShipmentLine."Item No.") then
                if itemrec."Lot Nos." <> '' then begin
                    //Create Reservation Entry

                    RecGReservationEntry2.reset;
                    if RecGReservationEntry2.findlast then
                        maxEntry := RecGReservationEntry2."Entry No." + 1;

                    if PalletLine.get(rec."Pallet ID", rec."Pallet Line No.") then begin
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
                        RecGReservationEntry.validate("Qty. to Handle (Base)", -1 * rec.Quantity);
                        RecGReservationEntry.insert;

                        if PalletHeader.get(rec."Pallet ID") then
                            RecGReservationEntry."Packing Date" := Palletheader."Creation Date";
                        // if PalletLine.get(rec."Pallet ID", rec."Pallet Line No.") then
                        //     RecGReservationEntry."Expiration Date" := PalletLine."Expiration Date";
                        RecGReservationEntry.modify;

                        Rec."Reserve. Entry No." := MaxEntry;
                        Rec.modify;
                    end;
                end;
        end;
    end;

    //OnAfterInsert - Warehouse Shipment Line
    [EventSubscriber(ObjectType::table, 7321, 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterInsertWarehouseShipmentLine(var Rec: Record "Warehouse Shipment Line")
    begin
        rec."Remaining Quantity" := rec.Quantity;
        rec."Qty. to Ship" := 0;
        rec."Qty. to Ship (Base)" := 0;
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

    [EventSubscriber(ObjectType::Page, Page::"Warehouse Shipment", 'OnAfterActionEvent', 'Post and &Print', true, true)]
    procedure OnAfterPostWhseShipmentPostandPrint(var Rec: Record "Warehouse Shipment Header");
    begin
        PostWarehouseShipment(Rec);
    end;


    [EventSubscriber(ObjectType::Page, Page::"Warehouse Shipment", 'OnAfterActionEvent', 'Posted &Whse. Shipments', true, true)]
    procedure OnAfterPostWhseShipmentPostedWhseShipments(var Rec: Record "Warehouse Shipment Header");
    begin
        PostWarehouseShipment(Rec);
    end;


    [EventSubscriber(ObjectType::Page, Page::"Warehouse Shipment", 'OnAfterActionEvent', 'P&ost Shipment', true, true)]
    procedure OnAfterPostWhseShipmentPostShipment(var Rec: Record "Warehouse Shipment Header");
    var
    begin
        PostWarehouseShipment(Rec);
    end;

    procedure PostWarehouseShipment(Rec: Record "Warehouse Shipment Header");
    var
        LPurchaseHeader: Record "Purchase Header";
        LSalesHeader: Record "Sales Header";
        LCustomerPostingGroup: Record "Customer Posting Group";
        LPurchaseLine: Record "Purchase Line";
        LPalletLine: Record "Pallet Line";
        enumPurchaseStatus: Enum "Purchase Document Status";
        isReleased: Boolean;
        Lcustomer: Record Customer;
        PostedWarehouseShipment: Record "Posted Whse. Shipment Header";
        errorinpayback: Text;
        PostedWarehousePallet: Record "Posted Warehouse Pallet";
        WarehousePallet: Record "Warehouse Pallet";
        LboolExist: Boolean;
        PostPurchase: Codeunit "Purch.-Post";
        Errmsgpayback: Label 'Please note that the following pallet lines numbers : %1 - have already be archived or fully invoiced. The PO line price has not been updated.';
    begin

        errorinpayback := '';
        PostedWarehouseShipment.Reset();
        PostedWarehouseShipment.SetCurrentKey("Whse. Shipment No.");
        PostedWarehouseShipment.SetRange("Whse. Shipment No.", Rec."No.");
        if PostedWarehouseShipment.FindLast() then begin

            PostedWarehousePallet.Reset();
            PostedWarehousePallet.setrange("Whse Shipment No.", PostedWarehouseShipment."No.");
            if PostedWarehousePallet.findset then begin
                repeat
                    LSalesHeader.Reset();
                    LSalesHeader.SetRange("Document Type", LSalesHeader."Document Type"::Order);
                    LSalesHeader.SetRange("No.", PostedWarehousePallet."Sales Order No.");
                    if LSalesHeader.FindFirst() then begin
                        LCustomer.Get(LSalesHeader."Sell-to Customer No.");
                        LCustomerPostingGroup.Reset();
                        LCustomerPostingGroup.SetRange(code, LCustomer."Customer Posting Group");
                        LCustomerPostingGroup.SetRange("Pay-Pack", true);
                        if LCustomerPostingGroup.FindFirst() then begin
                            if LPalletLine.Get(PostedWarehousePallet."Pallet ID", PostedWarehousePallet."Pallet Line No.") then
                                if LPurchaseLine.Get(LPurchaseLine."Document Type"::Order, LPalletLine."Purchase Order No.", LPalletLine."Purchase Order Line No.") and (LPalletLine."Purchase Order No." <> '') then begin
                                    if LPurchaseLine."Quantity Invoiced" > 0 then begin
                                        if errorinpayback = '' then
                                            errorinpayback := PostedWarehousePallet."Pallet ID" + '-' + Format(PostedWarehousePallet."Pallet Line No.")
                                        else
                                            errorinpayback += ', ' + PostedWarehousePallet."Pallet ID" + '-' + Format(PostedWarehousePallet."Pallet Line No.");
                                    end else begin

                                        LPurchaseHeader.get(LPurchaseHeader."Document Type"::Order, LPalletLine."Purchase Order No.");
                                        isReleased := false;
                                        if LPurchaseHeader.Status <> LPurchaseHeader.Status::Open then begin
                                            enumPurchaseStatus := LPurchaseHeader.Status;
                                            LPurchaseHeader.Status := LPurchaseHeader.Status::Open;
                                            LPurchaseHeader.Modify();
                                            isReleased := true;

                                        end;
                                        LPurchaseLine.Validate("Unit Cost", 0);
                                        LPurchaseLine.Modify();
                                        if isReleased then begin
                                            LPurchaseHeader.Status := enumPurchaseStatus;
                                            LPurchaseHeader.Modify();
                                        end;
                                        //  PostPurchase.Run(LPurchaseHeader);
                                    end;
                                end else begin
                                    if errorinpayback = '' then
                                        errorinpayback := PostedWarehousePallet."Pallet ID" + '-' + Format(PostedWarehousePallet."Pallet Line No.")
                                    else
                                        errorinpayback += ', ' + PostedWarehousePallet."Pallet ID" + '-' + Format(PostedWarehousePallet."Pallet Line No.");
                                end;
                        end;
                        /*else begin
                            if errorinpayback = '' then
                                errorinpayback := PostedWarehousePallet."Pallet ID" + '-' + Format(PostedWarehousePallet."Pallet Line No.")
                            else
                                errorinpayback += ', ' + PostedWarehousePallet."Pallet ID" + '-' + Format(PostedWarehousePallet."Pallet Line No.");
                        end;*/

                    end;
                until PostedWarehousePallet.next = 0;
            end;
        end else begin

            WarehousePallet.Reset();
            WarehousePallet.setrange("Whse Shipment No.", Rec."No.");
            if WarehousePallet.findset then begin
                repeat
                    LSalesHeader.Reset();
                    LSalesHeader.SetRange("Document Type", LSalesHeader."Document Type"::Order);
                    LSalesHeader.SetRange("No.", WarehousePallet."Sales Order No.");
                    if LSalesHeader.FindFirst() then begin
                        LCustomer.Get(LSalesHeader."Sell-to Customer No.");
                        LCustomerPostingGroup.Reset();
                        LCustomerPostingGroup.SetRange(code, LCustomer."Customer Posting Group");
                        LCustomerPostingGroup.SetRange("Pay-Pack", true);
                        if LCustomerPostingGroup.FindFirst() then begin
                            if LPalletLine.Get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.") then
                                if LPurchaseLine.Get(LPurchaseLine."Document Type"::Order, LPalletLine."Purchase Order No.", LPalletLine."Purchase Order Line No.") and (LPalletLine."Purchase Order No." <> '') then begin
                                    if LPurchaseLine."Quantity Invoiced" > 0 then begin
                                        if errorinpayback = '' then
                                            errorinpayback := WarehousePallet."Pallet ID" + '-' + Format(WarehousePallet."Pallet Line No.")
                                        else
                                            errorinpayback += ', ' + WarehousePallet."Pallet ID" + '-' + Format(WarehousePallet."Pallet Line No.");
                                    end else begin

                                        LPurchaseHeader.get(LPurchaseHeader."Document Type"::Order, LPalletLine."Purchase Order No.");
                                        isReleased := false;
                                        if LPurchaseHeader.Status <> LPurchaseHeader.Status::Open then begin
                                            enumPurchaseStatus := LPurchaseHeader.Status;
                                            LPurchaseHeader.Status := LPurchaseHeader.Status::Open;
                                            LPurchaseHeader.Modify();
                                            isReleased := true;

                                        end;
                                        LPurchaseLine.Validate("Unit Cost", 0);
                                        LPurchaseLine.Modify();
                                        if isReleased then begin
                                            LPurchaseHeader.Status := enumPurchaseStatus;
                                            LPurchaseHeader.Modify();
                                        end;
                                        //  PostPurchase.Run(LPurchaseHeader);
                                    end;
                                end else begin
                                    if errorinpayback = '' then
                                        errorinpayback := WarehousePallet."Pallet ID" + '-' + Format(WarehousePallet."Pallet Line No.")
                                    else
                                        errorinpayback += ', ' + WarehousePallet."Pallet ID" + '-' + Format(WarehousePallet."Pallet Line No.");
                                end;
                        end;
                    end;

                until WarehousePallet.next = 0;

            end;
        end;

        if errorinpayback <> '' then
            Message(StrSubstNo(Errmsgpayback, errorinpayback));
    end;


    //On After Post Whse. Shipment
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostedWhseShptHeaderInsert', '', true, true)]
    local procedure OnBeforePostedWhseShptHeaderInsert(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        PostedWarehousePallet: Record "Posted Warehouse Pallet";
        PostedWarehousePallet2: Record "Posted Warehouse Pallet";
        WarehousePallet: Record "Warehouse Pallet";
        LCustomer: Record Customer;
        CustomerNo: code[20];
        LSalesHeader: Record "Sales Header";
        // LCustomerPostingGroup: Record "Customer Posting Group";
        //LPurchaseLine: Record "Purchase Line";
        //LPalletLine: Record "Pallet Line";
        PostedWhseShipNo: code[20];
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    //LPurchaseHeader: Record "Purchase Header";
    //enumPurchaseStatus: Enum "Purchase Document Status";
    //isReleased: Boolean;
    //errorinpayback: Text;
    //PostPurchase: Codeunit "Purch.-Post";
    // Errmsgpayback: Label 'Please note that the following po numbers : %1 - have already be archived or fully invoiced. The po line price has not been updated.';
    begin
        //  errorinpayback := '';
        WarehousePallet.Reset();
        WarehousePallet.setrange("Whse Shipment No.", WarehouseShipmentHeader."No.");
        if WarehousePallet.findset then
            repeat
                /*  LSalesHeader.Reset();
                  LSalesHeader.SetRange("Document Type", LSalesHeader."Document Type"::Order);
                  LSalesHeader.SetRange("No.", WarehousePallet."Sales Order No.");
                  if LSalesHeader.FindFirst() then begin
                      LCustomer.Get(LSalesHeader."Sell-to Customer No.");
                      LCustomerPostingGroup.Reset();
                      LCustomerPostingGroup.SetRange(code, LCustomer."Customer Posting Group");
                      LCustomerPostingGroup.SetRange("Pay-Pack", true);
                      if LCustomerPostingGroup.FindFirst() then
                          if LPalletLine.Get(WarehousePallet."Pallet ID", WarehousePallet."Pallet Line No.") then
                              if LPurchaseLine.Get(LPurchaseLine."Document Type"::Order, LPalletLine."Purchase Order No.", LPalletLine."Purchase Order Line No.") and (LPalletLine."Purchase Order No." <> '') then begin
                                  if LPurchaseLine."Quantity Invoiced" > 0 then begin
                                      if errorinpayback = '' then
                                          errorinpayback := LPalletLine."Purchase Order No." + '-' + Format(LPalletLine."Purchase Order Line No.")
                                      else
                                          errorinpayback += ', ' + LPalletLine."Purchase Order No." + '-' + Format(LPalletLine."Purchase Order Line No.");
                                  end else begin

                                      LPurchaseHeader.get(LPurchaseHeader."Document Type"::Order, LPalletLine."Purchase Order No.");
                                      isReleased := false;
                                      if LPurchaseHeader.Status <> LPurchaseHeader.Status::Open then begin
                                          enumPurchaseStatus := LPurchaseHeader.Status;
                                          LPurchaseHeader.Status := LPurchaseHeader.Status::Open;
                                          LPurchaseHeader.Modify();
                                          isReleased := true;

                                      end;
                                      LPurchaseLine.Validate("Unit Cost", 0);
                                      LPurchaseLine.Modify();
                                      if isReleased then begin
                                          LPurchaseHeader.Status := enumPurchaseStatus;
                                          LPurchaseHeader.Modify();
                                      end;
                                      //  PostPurchase.Run(LPurchaseHeader);
                                  end;
                              end else begin
                                  if errorinpayback = '' then
                                      errorinpayback := LPalletLine."Purchase Order No." + '-' + Format(LPalletLine."Purchase Order Line No.")
                                  else
                                      errorinpayback += ', ' + LPalletLine."Purchase Order No." + '-' + Format(LPalletLine."Purchase Order Line No.");
                              end;
                  end else begin
                      if errorinpayback = '' then
                          errorinpayback := LPalletLine."Purchase Order No." + '-' + Format(LPalletLine."Purchase Order Line No.")
                      else
                          errorinpayback += ', ' + LPalletLine."Purchase Order No." + '-' + Format(LPalletLine."Purchase Order Line No.");
                  end;*/
                PostedWarehousePallet.init;
                PostedWarehousePallet.TransferFields(WarehousePallet);
                PostedWarehousePallet.insert(true);
                WarehousePallet.delete;

            until WarehousePallet.next = 0;

        // if errorinpayback <> '' then
        //    Message(StrSubstNo(Errmsgpayback, errorinpayback));
    end;

    //On AFter Insert Sales Shipment Line 
    [EventSubscriber(ObjectType::Table, database::"Posted Whse. Shipment Line", 'OnAfterInsertEvent', '', true, true)]
    local procedure OnBeforePostedWhseShptLineInsert(RunTrigger: Boolean; var Rec: Record "Posted Whse. Shipment Line")
    var
    begin
        PalletLedgerFunctions.PalletLedgerEntryWarehouseShipment(Rec);
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