page 60025 "Pallet Change Quality"
{

    PageType = Worksheet;
    SourceTable = "Pallet Line change quality";
    Caption = 'Pallet Line Change Quality';
    ApplicationArea = All;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            group("General")
            {
                field(PalletID; PalletID)
                {
                    editable = true;
                    Caption = 'Pallet ID';
                    ApplicationArea = All;
                    TableRelation = "Pallet Header";
                    trigger OnValidate()
                    var
                        PalletChangeQuality: Record "Pallet Change Quality";
                        PalletLineChangeQuality: Record "Pallet Line Change Quality";
                    begin

                        PalletLineChangeQuality.reset;
                        PalletLineChangeQuality.SetRange("User ID", UserId);
                        if PalletLineChangeQuality.findset then
                            PalletLineChangeQuality.DeleteAll();

                        PalletChangeQuality.reset;
                        PalletChangeQuality.setrange("User Created", UserId);
                        if PalletChangeQuality.findset then
                            PalletChangeQuality.DeleteAll();

                        PalletLine.reset;
                        PalletLine.setrange("Pallet ID", PalletID);
                        if PalletLine.findset then
                            repeat
                                PalletLineChangeQuality.init;
                                PalletLineChangeQuality.TransferFields(PalletLine);
                                PalletLineChangeQuality."User ID" := UserId;
                                PalletLineChangeQuality.insert;
                            until palletline.next = 0;
                    end;
                }


            }
            repeater(Group)
            {
                Caption = 'Pallet Change Quality';
                Editable = false;
                ShowCaption = true;


                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = all;
                }

                field(Description; Description)
                {
                    ApplicationArea = all;
                }
                field("Lot Number"; "Lot Number")
                {
                    ApplicationArea = all;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = all;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = all;
                }
            }

            part(ChangeQualityLines; "Change Quality SubPage")
            {
                ApplicationArea = all;
                Editable = true;
                SubPageLink = "Pallet ID" = field("Pallet ID"), "Pallet Line No." = field("Line No."), "User Created" = field("User ID");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action("Change")
            {
                Promoted = true;
                PromotedCategory = process;
                ApplicationArea = All;
                Image = Change;
                trigger OnAction()


                begin
                end;

            }
        }
    }

    trigger OnOpenPage()
    var
        PalletLineChangeQuality: Record "Pallet Line Change Quality";
        PalletChangeQuality: Record "Pallet Change Quality";
    begin
        PalletLineChangeQuality.reset;
        PalletLineChangeQuality.SetRange("User ID", UserId);
        if PalletLineChangeQuality.findset then
            PalletLineChangeQuality.DeleteAll();

        PalletChangeQuality.reset;
        PalletChangeQuality.setrange("User Created", UserId);
        if PalletChangeQuality.findset then
            PalletChangeQuality.DeleteAll();
    end;

    var
        PalletID: code[20];
        PalletLine: Record "Pallet Line";
}
