pageextension 60039 PurchasePricesExt extends "purchase prices"
{
    layout
    {
        modify("Variant Code")
        {
            Visible = true;
            caption = 'Variety';
        }
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}