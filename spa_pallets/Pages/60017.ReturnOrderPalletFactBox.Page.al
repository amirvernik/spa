page 60017 "Return Order Pallets FactBox"
{
    PageType = ListPart;
    Editable = false;
    SourceTable = "Pallet Ledger Entry";

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
                    Editable = false;
                    ApplicationArea = All;
                }
                field(Quantity; Quantity)
                {
                    Editable = false;
                    ApplicationArea = All;
                }
            }
        }

    }


    var
        PalletHeader: Record "Pallet Header";

}