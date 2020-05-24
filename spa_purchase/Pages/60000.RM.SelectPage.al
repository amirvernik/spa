page 60000 "Raw Material Select Page"
{

    PageType = StandardDialog;
    SourceTable = "Purchase Header";
    Caption = 'Raw Material Select Item';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Raw Material Item"; "Raw Material Item")
                {
                    ApplicationArea = All;
                }
                field("RM Location"; "RM Location")
                {
                    ApplicationArea = All;
                }
                field("Item LOT Number"; "Item LOT Number")
                {
                    ApplicationArea = All;
                }
                field("RM Qty"; "RM Qty")
                {
                    ApplicationArea = All;
                }

            }
        }
    }

}
