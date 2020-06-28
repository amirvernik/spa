page 60026 "Change Quality SubPage"
{

    PageType = ListPart;
    SourceTable = "Pallet Change Quality";
    Caption = 'Pallet Change Quality';
    ApplicationArea = All;
    Editable = true;
    InsertAllowed = true;
    DeleteAllowed = true;
    UsageCategory = Lists;


    layout
    {
        area(content)
        {
            repeater("Change Qualities")
            {
                field("Line No."; "Line No.")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("New Item No."; "New Item No.")
                {
                    ApplicationArea = all;
                }
                field("New Variant Code"; "New Variant Code")
                {
                    ApplicationArea = all;
                }
                field(Description; Description)
                {
                    ApplicationArea = all;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = all;
                }
                field("New Quantity"; "New Quantity")
                {
                    ApplicationArea = all;
                }


            }
        }
    }

}
