pageextension 60042 SalesPricesExt extends "Sales Prices"
{
    layout
    {
        modify("Variant Code")
        {
            Visible = TRUE;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}