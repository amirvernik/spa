page 60002 "Lot Selection List"
{

    PageType = List;
    SourceTable = "item ledger entry";
    Caption = 'Lot Selection List';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                }

                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

}
