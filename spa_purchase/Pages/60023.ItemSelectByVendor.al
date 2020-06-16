page 60023 "Item Select By Vendor"
{

    PageType = List;
    SourceTable = "Item Select By Vendor";
    Caption = 'Item Select By Vendor';
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
