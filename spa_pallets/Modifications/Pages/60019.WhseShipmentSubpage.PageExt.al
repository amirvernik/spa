pageextension 60019 WhseShipmentSubpage extends "Whse. Shipment Subform"
{
    layout
    {
        modify("Variant Code")
        {
            Visible = true;
            caption = 'Variety Code';
        }
        modify("Source No.")
        {
            trigger OnLookup(var Text: Text): Boolean
            var
                LSalesOrderPage: Page "Sales Order";
                LSalesOrderArchive: Page "Sales Order Archive";
                LSalesHeader: Record "Sales Header";
                LSalesHeaderArchive: Record "Sales Header Archive";
            begin
                if "Source Document" = "Source Document"::"Sales Order" then begin
                    LSalesHeader.Reset();
                    LSalesHeader.SetRange("Document Type", LSalesHeader."Document Type"::Order);
                    LSalesHeader.SetRange("No.", "Source No.");
                    if LSalesHeader.FindLast() then begin
                        Clear(LSalesOrderPage);
                        LSalesOrderPage.SetRecord(LSalesHeader);
                        LSalesOrderPage.SetTableView(LSalesHeader);
                        LSalesOrderPage.Run();
                    end else begin
                        LSalesHeaderArchive.Reset();
                        LSalesHeaderArchive.SetRange("Document Type", LSalesHeaderArchive."Document Type"::Order);
                        LSalesHeaderArchive.SetRange("No.", "Source No.");
                        if LSalesHeaderArchive.FindLast() then begin
                            Clear(LSalesOrderPage);
                            LSalesOrderArchive.SetRecord(LSalesHeaderArchive);
                            LSalesOrderArchive.SetTableView(LSalesHeaderArchive);
                            LSalesOrderArchive.Run();
                        end;
                    end;
                end;
            end;
        }
        addafter(quantity)
        {
            field("Remaining Quantity"; "Remaining Quantity")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }

    actions
    {
    }

}