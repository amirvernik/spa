page 60014 "Pallet Reservation Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    SourceTable = "Pallet reservation Entry";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = All;

                }
                field("Pallet Line"; "Pallet Line")
                {
                    ApplicationArea = All;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = all;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = all;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = All;
                }

            }
        }
        area(Factboxes)
        {

        }
    }


}