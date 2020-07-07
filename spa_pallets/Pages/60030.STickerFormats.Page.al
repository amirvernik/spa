page 60030 "Sticker Formats"
{

    Caption = 'Sticker Formats';
    PageType = List;
    SourceTable = "Sticker Format";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Sticker Code"; "Sticker Code")
                {
                    ApplicationArea = All;
                }
                field("Sticker Description"; "Sticker Description")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

}
