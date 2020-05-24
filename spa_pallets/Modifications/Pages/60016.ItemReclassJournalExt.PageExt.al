pageextension 60016 ItemReclassJournalExt extends "Item Reclass. Journal"
{
    layout
    {
        modify("Variant Code")
        {
            Visible = true;
            Caption = 'Variety';
        }
        addafter(Quantity)
        {
            field("Pallet ID"; "Pallet ID")
            {
                ApplicationArea = all;
            }
            field("Pallet Type"; "Pallet Type")
            {
                ApplicationArea = all;
            }
        }
    }
    actions
    {
        addlast("F&unctions")
        {
            action("Transfer Pallet")
            {
                Image = ImportCodes;

                //Promoted = true;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ItemReclassFunctions.PalletSelection(rec);
                    currpage.close;
                end;
            }
        }
    }

    var
        ItemReclassFunctions: Codeunit "Item Reclass Management";


}