page 60012 "Warehouse Pallet FactBox"
{
    PageType = ListPart;
    ApplicationArea = All;
    Editable = false;
    UsageCategory = Administration;
    SourceTable = "Warehouse Pallet";
    caption = 'Pallets';

    layout
    {
        area(Content)
        {
            repeater(Pallets)
            {
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
                field("Pallet Line No."; "Pallet Line No.")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                }
                field("Sales Order No."; "Sales Order No.")
                {
                    ApplicationArea = All;
                }
                field("Sales Order Line No."; "Sales Order Line No.")
                {
                    ApplicationArea = All;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = All;
                }
            }
        }

    }

    var
        PalletHeader: Record "Pallet Header";
}