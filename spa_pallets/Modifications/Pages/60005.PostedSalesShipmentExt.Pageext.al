pageextension 60005 PostedSalesShipmentExt extends "Posted Sales Shipment"
{
    layout
    {
        addfirst(factboxes)
        {
            part(MyReturnPart; "Pallet Ledger Entry Factbox")
            {
                ApplicationArea = Warehouse;
                Provider = SalesShipmLines;
                SubPageLink = "Order No." = field("Order No."), "Order Line No." = field("Order Line No.");
                //Visible = PalletsExists;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        PalletsExists: Boolean;
        PostedWarehousePallets: Record "Posted Warehouse Pallet";
}