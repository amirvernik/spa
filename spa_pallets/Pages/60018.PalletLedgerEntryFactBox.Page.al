page 60018 "Pallet Ledger Entry Factbox"
{
    PageType = ListPart;
    //ApplicationArea = All;
    Editable = false;
    //UsageCategory = Administration;
    SourceTable = "Pallet Ledger Entry";
    //caption = 'Pallets';

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