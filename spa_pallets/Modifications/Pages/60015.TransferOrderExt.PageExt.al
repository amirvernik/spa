pageextension 60015 TransferOrderExt extends "Transfer Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter("P&osting")
        {
            action("Transfer Pallet")
            {
                Image = ImportCodes;
                Promoted = true;
                ApplicationArea = All;
                trigger OnAction()
                begin
                    TransferOrderManagement.PalletSelection(rec);
                end;

            }
        }
    }

    var
        TransferOrderManagement: Codeunit "Transfer Order Management";
}