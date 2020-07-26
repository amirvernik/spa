page 60031 "Sticker Note Printers"
{

    Caption = 'Sticker Note Printers';
    PageType = List;
    SourceTable = "Sticker note Printer";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("User Code"; "User Code")
                {
                    ApplicationArea = all;
                }
                field("Sticker Note Type"; "Sticker Note Type")
                {
                    ApplicationArea = all;
                }
                field("Sticker Note Format"; "Sticker Note Format")
                {
                    ApplicationArea = All;
                }
                field("Sticker Note Description"; "Sticker Note Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }

                field("Printer Path"; "Printer Path")
                {
                    ApplicationArea = all;
                }
                field("Printer Description"; "Printer Description")
                {
                    ApplicationArea = all;
                }
                field("Sticker Format Name(BTW)"; "Sticker Format Name(BTW)")
                {
                    ApplicationArea = all;
                }
                field("Printer Name"; "Printer Name")
                {
                    ApplicationArea = all;
                }
            }
        }
    }

}
