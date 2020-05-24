page 60019 "Pallet Avail Error List"
{

    PageType = StandardDialog;
    SourceTable = "Pallet Avail Error";
    Caption = 'Pallet Avail Error List';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Error Description"; "Error Description")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        rec.reset;
        if rec.findfirst then begin
            WarehouseShipmentHeader.reset;
            WarehouseShipmentHeader.setrange("No.", rec."Shipment No.");
            if WarehouseShipmentheader.findfirst then
                page.run(7335, WarehouseShipmentHeader);

        end;
    end;
}
