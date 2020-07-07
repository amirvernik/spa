page 60029 "Format Types"
{

    Caption = 'Format Types';
    PageType = List;
    SourceTable = "Format Type";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Sticker Formats")
            {
                Image = BulletList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ApplicationArea = all;
                trigger OnAction()
                var
                    Stickerformat: Record "Sticker Format";
                begin
                    Stickerformat.reset;
                    Stickerformat.setrange("Format Type", rec.code);
                    page.run(page::"Sticker Formats", Stickerformat);
                end;

            }
        }
    }
}
