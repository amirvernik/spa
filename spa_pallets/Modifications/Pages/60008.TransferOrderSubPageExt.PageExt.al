pageextension 60008 TransferOrderSubPageExt extends "Transfer Order Subform"
{
    layout
    {

        modify("Variant Code")
        {
            Visible = true;
            Caption = 'Variety';
        }

        addafter(Quantity)
        {
            field("Pallet ID"; "Pallet ID")
            {
                ApplicationArea = all;
                Editable = false;
            }
            field("Lot No."; "Lot No.")
            {
                ApplicationArea = all;
                Editable = false;

            }
            field("Pallet Type"; "Pallet Type")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}