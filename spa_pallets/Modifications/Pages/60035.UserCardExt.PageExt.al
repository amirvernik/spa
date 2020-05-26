pageextension 60035 UserCardExt extends "User Card"
{
    actions
    {
        addfirst(processing)
        {
            action("Show Users Ui Passord")
            {
                Image = ImportCodes;
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    UserSetUp.reset;
                    UserSetUp.setrange(UserSetUp."User ID", rec."User Name");
                    if UserSetUp.findfirst then
                        page.RunModal(page::"User Ui Passwords", UserSetUp)
                end;
            }
        }
    }

    var
        UserSetUp: Record "User Setup";
}
