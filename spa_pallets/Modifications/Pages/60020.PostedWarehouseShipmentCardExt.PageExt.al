pageextension 60020 PostedWarehouseShipmentCardExt extends "Posted Whse. Shipment"
{
    layout
    {
        addafter(Control1905767507)
        {
            part(MyWarehousePart; "Posted Whse. Pallet FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseShptLines;
                SubPageLink = "Whse Shipment No." = field("No."), "Whse Shipment Line No." = field("Line No.");
                Visible = PalletsExists;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }
    trigger OnAfterGetRecord()
    begin
        PalletsExists := true;
        PostedWarehousePallets.reset;
        PostedWarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not PostedWarehousePallets.findset then
            PalletsExists := false;
    end;

    trigger OnOpenPage()
    begin
        PalletsExists := true;
        PostedWarehousePallets.reset;
        PostedWarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not PostedWarehousePallets.findset then
            PalletsExists := false;
    end;

    var
        PalletsExists: Boolean;
        PostedWarehousePallets: Record "Posted Warehouse Pallet";
}