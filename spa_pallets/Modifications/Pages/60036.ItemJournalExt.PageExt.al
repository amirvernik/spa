pageextension 60036 ItemJournalExt extends "Item Journal"
{
    layout
    {
        modify("Variant Code")
        {
            visible = true;
            caption = 'Variety Code';
        }

    }
    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}