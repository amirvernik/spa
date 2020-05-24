page 60007 "Pallet Materials SubPage"
{

    PageType = ListPart;
    SourceTable = "Packing Material Line";
    Caption = 'Packing Material Items';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; "Line No.")
                {
                    ApplicationArea = All;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    ApplicationArea = all;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = all;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                }
                field(Returned; Returned)
                {
                    ApplicationArea = all;
                }

            }

        }

    }
}