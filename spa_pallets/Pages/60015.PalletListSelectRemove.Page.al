page 60015 "Pallet List Select Remove"
{
    PageType = StandardDialog;
    SourceTable = "Pallet List Select";

    layout
    {
        area(Content)
        {
            repeater(Group)
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
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction();
                begin

                end;
            }

        }

    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SalesLine: Record "Sales Line";
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
            rec.reset;
            rec.setrange(Select, true);
            if rec.findset then begin
                ShipmentNumnber := rec."Source Document";
                repeat
                    WarehousePallet.reset;
                    WarehousePallet.setrange(WarehousePallet."Whse Shipment No.", ShipmentNumnber);
                    WarehousePallet.setrange("Pallet ID", rec."Pallet ID");
                    if WarehousePallet.findset then begin
                        repeat
                            if RecGReservationEntry.get(WarehousePallet."Reserve. Entry No.") then
                                RecGReservationEntry.Delete();
                            if WarehouseShipmentLine.get(WarehousePallet."Whse Shipment No.", WarehousePallet."Whse Shipment Line No.") then begin
                                SalesLine.Reset();
                                SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                                SalesLine.SetRange("Document No.", WarehouseShipmentLine."Source No.");
                                SalesLine.SetRange("Line No.", WarehouseShipmentLine."Source Line No.");
                                if SalesLine.FindFirst() then begin
                                    SalesLine."Qty. to Ship" -= WarehousePallet.quantity;
                                    SalesLine.Modify();
                                end;

                                WarehouseShipmentLine."Remaining Quantity" += WarehousePallet.quantity;
                                WarehouseShipmentLine."Qty. to Ship" -= WarehousePallet.quantity;
                                WarehouseShipmentLine.modify;
                            end;
                            WarehousePallet.Delete();
                        until WarehousePallet.next = 0;
                    end;
                    if PalletHeader.get(WarehousePallet."Pallet ID") then begin
                        PalletHeader."Exist in warehouse shipment" := false;
                        PalletHeader.modify;
                    end;
                until rec.next = 0;

                WarehouseShipmentHeader.reset;
                WarehouseShipmentHeader.setrange("No.", rec."Source Document");
                if WarehouseShipmentheader.findfirst then
                    page.run(7335, WarehouseShipmentHeader);
                message(Lbl002);
            end;
        end;
    end;

    var
        WarehousePallet: Record "Warehouse Pallet";
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        MaxEntry: Integer;
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "pallet line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LineNumber: Integer;
        ShipmentNumnber: code[20];
        QuantityToUpdateShip: Integer;
        QuantityRemain: Integer;
        Err001: label 'Item does not Exist on Shipment, Cant Import Pallet %1';
        Lbl001: Label 'Pallet/s Added successfuly';
        Lbl002: label 'Pallet/s Removed Succesfuly';

}