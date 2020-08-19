page 60033 "Item Select By Customer"
{

    PageType = List;
    SourceTable = "Item Select By Customer";
    Caption = 'Item Select By customer';
    UsageCategory = None;
    Editable = false;
    ModifyAllowed = false;
    DeleteAllowed = false;


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
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = all;
                    Caption = 'Variety';
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = all;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = all;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = All;
                }

            }
        }
    }

}
