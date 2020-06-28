pageextension 60028 SalesOrderExt extends "Sales Order"
{
    layout
    {
        modify("No.")
        {
            Visible = true;
        }
        addafter(Status)
        {
            field("User Created"; "User Created")
            {
                ApplicationArea = all;
                editable = false;
            }
            field("SPA Location"; "SPA Location")
            {
                ApplicationArea = all;
                editable = false;
            }
            field("Dispatch Date"; "Dispatch Date")
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