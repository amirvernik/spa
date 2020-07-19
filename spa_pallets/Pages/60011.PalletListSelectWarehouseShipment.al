page 60011 "Pallet List Select Whse Ship"
{

    PageType = StandardDialog;
    SourceTable = "Pallet List Select";
    Caption = 'Pallet List Select - For Warehouse Shipment';

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
                field("Total Qty"; "Total Qty")
                {
                    Editable = false;
                    ApplicationArea = All;

                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        //Page is closed with Cancel
        if CloseAction = CloseAction::Cancel then begin
            rec.reset;
            if rec.findfirst then begin
                WarehouseShipmentHeader.reset;
                WarehouseShipmentHeader.setrange("No.", rec."Source Document");
                if WarehouseShipmentheader.findfirst then
                    page.run(7335, WarehouseShipmentHeader);
            end;
        end;

        //Page is Open with OK
        if CloseAction = CloseAction::OK then begin
            //Check Conditions for Pallets
            GlobalErrorText := PalletAvailabilityFunctions.FctCheckSelectedPallets(rec, 'BC');
            PalletNumbers := '';
            if GlobalErrorText = '' then begin
                rec.reset;
                rec.setrange(Select, true);
                if rec.findset then begin
                    ShipmentNumnber := rec."Source Document";
                    //LineNumber := 20000;
                    repeat
                        PalletLine.reset;
                        PalletLine.setrange("Pallet ID", rec."Pallet ID");
                        if palletline.findset then
                            repeat
                                QuantityToUpdateShip := PalletLine.Quantity;
                                while QuantityToUpdateShip > 0 do begin
                                    WarehouseShipmentLine.reset;
                                    WarehouseShipmentLine.setrange("No.", ShipmentNumnber);
                                    WarehouseShipmentLine.setrange("Item No.", PalletLine."Item No.");
                                    WarehouseShipmentLine.setrange("Unit of Measure Code", PalletLine."Unit of Measure");
                                    WarehouseShipmentLine.Setrange("Variant Code", PalletLine."Variant Code");
                                    WarehouseShipmentLine.setrange("Location Code", PalletLine."Location Code");
                                    WarehouseShipmentLine.setfilter(WarehouseShipmentLine."Remaining Quantity", '>%1', 0);
                                    if WarehouseShipmentLine.findfirst then begin
                                        if WarehouseShipmentLine."Remaining Quantity" >= QuantityToUpdateShip then begin
                                            WarehousePallet.init;
                                            WarehousePallet."Whse Shipment No." := WarehouseShipmentLine."No.";
                                            WarehousePallet."Whse Shipment Line No." := WarehouseShipmentLine."Line No.";
                                            WarehousePallet."Pallet Line No." := PalletLine."Line No.";
                                            WarehousePallet."Pallet ID" := palletline."Pallet ID";
                                            WarehousePallet."Sales Order No." := WarehouseShipmentLine."Source No.";
                                            WarehousePallet."Sales Order Line No." := WarehouseShipmentLine."Source Line No.";
                                            WarehousePallet."Lot No." := PalletLine."Lot Number";
                                            WarehousePallet.Quantity := QuantityToUpdateShip;
                                            if WarehousePallet.insert then begin

                                                //Check Price List Availability
                                                FctCheckSalesPriceAvailable(
                                                    WarehousePallet."Sales Order No.",
                                                    WarehousePallet."Sales Order Line No.",
                                                    WarehousePallet."Pallet ID"
                                                );
                                                //Check Price List Availability

                                                if PalletHeader.get(palletline."Pallet ID") then begin
                                                    PalletHeader."Exist in warehouse shipment" := true;
                                                    PalletHeader.modify;
                                                end;
                                            end;
                                            QuantityToUpdateShip -= PalletLine.Quantity;
                                        end;
                                        if WarehouseShipmentLine."Remaining Quantity" <= QuantityToUpdateShip then begin
                                            WarehousePallet.init;
                                            WarehousePallet."Whse Shipment No." := WarehouseShipmentLine."No.";
                                            WarehousePallet."Whse Shipment Line No." := WarehouseShipmentLine."Line No.";
                                            WarehousePallet."Pallet Line No." := PalletLine."Line No.";
                                            WarehousePallet."Pallet ID" := palletline."Pallet ID";
                                            WarehousePallet.Quantity := WarehouseShipmentLine."Remaining Quantity";
                                            if WarehousePallet.insert then begin

                                                //Check Price List Availability
                                                FctCheckSalesPriceAvailable(
                                                    WarehousePallet."Sales Order No.",
                                                    WarehousePallet."Sales Order Line No.",
                                                    WarehousePallet."Pallet ID"
                                                );
                                                //Check Price List Availability

                                                if PalletHeader.get(palletline."Pallet ID") then begin
                                                    PalletHeader."Exist in warehouse shipment" := true;
                                                    PalletHeader.modify;
                                                end;
                                            end;
                                            QuantityToUpdateShip -= WarehouseShipmentLine."Remaining Quantity";
                                        end;
                                    end;

                                end;
                            until palletline.next = 0;
                    until rec.next = 0;

                    //Check Price list Availability
                    if PalletNumbers <> '' then begin
                        PalletNumbers := CopyStr(PalletNumbers, 1, strlen(PalletNumbers) - 1);
                        error(PalletsError, PalletNumbers);
                    end;
                    //Check Price list Availability  

                    Message(Lbl001);
                end;
                rec.reset;
                if rec.findfirst then begin
                    WarehouseShipmentHeader.reset;
                    WarehouseShipmentHeader.setrange("No.", rec."Source Document");
                    if WarehouseShipmentheader.findfirst then
                        page.run(7335, WarehouseShipmentHeader);
                end;
            end
            else begin

                /*rec.reset;
                if rec.findfirst then begin
                    WarehouseShipmentHeader.reset;
                    WarehouseShipmentHeader.setrange("No.", rec."Source Document");
                    if WarehouseShipmentheader.findfirst then
                        page.run(7335, WarehouseShipmentHeader);
                end;*/
            end;
        end;
    end;

    local procedure FctCheckSalesPriceAvailable(var pOrderNo: code[20]; var pOrderLine: integer; var pPalletID: code[20])
    var
        SalesPrice: Record "Sales Price";
        Salesline: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        BoolAll: Boolean;
        BoolOnlyOne: Boolean;

    begin
        SalesHeader.get(SalesHeader."Document Type"::Order, pOrderNo);
        BoolAll := false;
        BoolOnlyOne := false;
        if salesline.get(Salesline."Document Type"::Order, pOrderNo, pOrderLine) then begin
            SalesPrice.reset;
            SalesPrice.setrange("Item No.", salesline."No.");
            SalesPrice.setrange("Variant Code", Salesline."Variant Code");
            SalesPrice.setrange("Ending Date", 0D);
            SalesPrice.setfilter("Starting Date", '<=%1', today);
            SalesPrice.setrange(SalesPrice."Sales Type", SalesPrice."Sales Type"::"All Customers");
            if SalesPrice.findfirst then
                BoolAll := true;
        end;
        if not BoolAll then begin
            if salesline.get(Salesline."Document Type"::Order, pOrderNo, pOrderLine) then begin
                SalesPrice.reset;
                SalesPrice.setrange("Item No.", salesline."No.");
                SalesPrice.setrange("Variant Code", Salesline."Variant Code");
                SalesPrice.setrange("Ending Date", 0D);
                SalesPrice.setfilter("Starting Date", '<=%1', today);
                SalesPrice.setrange(SalesPrice."Sales Type", SalesPrice."Sales Type"::Customer);
                SalesPrice.setrange(SalesPrice."Sales Code", SalesHeader."Sell-to Customer No.");
                if SalesPrice.findfirst then
                    BoolOnlyOne := true;
            end;
        end;
        if ((BoolAll = false) and (BoolOnlyOne = false)) then
            PalletNumbers += pPalletID + ',';

    end;

    var
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        MaxEntry: Integer;
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "pallet line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehousePallet: Record "Warehouse Pallet";
        LineNumber: Integer;
        ShipmentNumnber: code[20];
        QuantityToUpdateShip: Integer;
        QuantityRemain: Integer;
        Err001: label 'Item does not Exist on Shipment, Cant Import Pallet %1';
        Lbl001: Label 'Pallet/s Added successfuly';
        GlobalErrorText: Text;
        PalletAvailabilityFunctions: Codeunit "Pallet Availability Functions";

        PalletNumbers: text[250];
        PalletsError: label 'Pallet/s %1 does not have price list effective, please select another';
}