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
                    editable = PalletSelect;
                    Caption = 'Pallet ID';
                    ApplicationArea = All;
                    TableRelation = "Pallet Header" where("Pallet Status" = filter(Closed));
                    trigger OnValidate()
                    begin
                        CalcChangeQuality(PalletID)
                    end;
                }


            }
            repeater(Group)
            {
                Caption = 'Pallet Change Quality';
                Editable = true;
                ShowCaption = true;


                field("Item No."; "Item No.")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Variant Code"; "Variant Code")
                {
                    Editable = false;
                    ApplicationArea = all;
                }

                field(Description; Description)
                {
                    Editable = false;
                    ApplicationArea = all;
                }
                field("Lot Number"; "Lot Number")
                {
                    Editable = false;
                    ApplicationArea = all;
                }
                field(Quantity; Quantity)
                {
                    Editable = false;
                    ApplicationArea = all;
                }
                field("Replaced Qty"; "Replaced Qty")
                {
                    editable = true;
                    ApplicationArea = all;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    Editable = false;
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

            action("Change Items")
            {
                Promoted = true;
                PromotedCategory = process;
                ApplicationArea = All;
                Image = Change;
                trigger OnAction()
                var
                    ChangeQualityMgmt: Codeunit "Change Quality Management";
                begin

                    //ChangeQualityMgmt.NegAdjChangeQuality(Rec); //Negative Change Quality                    
                    //ChangeQualityMgmt.ChangeQuantitiesOnPalletline(Rec); //Change Quantities on Pallet Line                    
                    //ChangeQualityMgmt.ChangePalletReservation(Rec); //Change Pallet Reservation Line                    
                    //ChangeQualityMgmt.PalletLedgerAdjust(rec); //Adjust Pallet Ledger Entries                    
                    //ChangeQualityMgmt.AddNewItemsToPallet(rec); //Add New Lines
                    //Post Negative    
                    //PosAdjNewItems
                    //ChangeQualityMgmt.PosAdjNewItems(rec)
                    //Post Positive
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
        if PalletID = '' then
            PalletSelect := true
        else
            palletselect := false;

        PalletChangeQuality.reset;
        PalletChangeQuality.setrange("User Created", UserId);
        if PalletChangeQuality.findset then
            PalletChangeQuality.DeleteAll();

        if PalletID <> '' then
            CalcChangeQuality(PalletID);
        CurrPage.update;
    end;

    procedure SetPalletID(var pPalletID: code[20])
    begin
        PalletID := pPalletID;
    end;

    procedure CalcChangeQuality(var pPalletID: code[20])
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
        PalletLine.setrange("Pallet ID", pPalletID);
        if PalletLine.findset then
            repeat
                PalletLineChangeQuality.init;
                PalletLineChangeQuality.TransferFields(PalletLine);
                PalletLineChangeQuality."User ID" := UserId;
                PalletLineChangeQuality."Replaced Qty" := PalletLine.Quantity;
                PalletLineChangeQuality.insert;
            until palletline.next = 0;
    end;

    var
        PalletID: code[20];
        PalletLine: Record "Pallet Line";
        PalletChangeQuality: Record "Pallet Change Quality";
        PalletLineChangeQuality: Record "Pallet Line Change Quality";
        PalletSelect: Boolean;

}
