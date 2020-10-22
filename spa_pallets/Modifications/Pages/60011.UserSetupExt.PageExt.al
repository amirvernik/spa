pageextension 60011 UserSetpExt extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("Can ReOpen Pallet"; "Can ReOpen Pallet")
            {
                ApplicationArea = all;
            }
            field("Remove Pallet from Whse. Ship"; "Remove Pallet from Whse. Ship")
            {
                ApplicationArea = all;
            }
            field("Reopen Cancelled Pallets"; "Reopen Cancelled Pallets")
            {
                ApplicationArea = All;
            }
        }

        addafter("User ID")
        {
            field("UI Password"; "UI Password")
            {
                ApplicationArea = All;
            }
            field("WS Access Key"; "WS Access Key")
            {
                ApplicationArea = All;
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