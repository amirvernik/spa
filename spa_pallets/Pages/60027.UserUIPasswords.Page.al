page 60027 "User Ui Passwords"
{
    PageType = Card;
    SourceTable = "User Setup";
    Caption = 'Users Ui Password';
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("UI Password"; "UI Password")
                {
                    ApplicationArea = All;
                    Caption = 'UI Password';
                    Editable = true;
                }
                field("WS Access Key"; "WS Access Key")
                {
                    ApplicationArea = All;
                    Caption = 'Web Service Access Key';
                    Editable = true;
                }
            }
        }
    }
}
