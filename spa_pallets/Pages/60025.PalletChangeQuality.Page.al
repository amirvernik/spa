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
                        CalcChangeQuality(PalletID, PalletLineNo);
                        rec.setfilter("Pallet ID", PalletID);
                        Rec.SetRange("Line No.", PalletLineNo);
                        rec.setfilter("User ID", UserId);
                        CurrPage.update;
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
                    Caption = 'New Quantity';
                    Editable = true;
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
                // Visible = false;
                Promoted = true;
                PromotedCategory = process;
                ApplicationArea = All;
                Image = Change;

                trigger OnAction()
                var
                    ChangeQualityMgmt: Codeunit "Change Quality Management";
                    TrackingItemNumber: code[20];
                    PalletItemChgLine: Record "Pallet Change Quality";
                    ErrQty: Label 'The replaced item cant be with 0 QTY';
                    ErrNewItem: Label 'You have not enterd a new item line';
                    PalletChangeQuality: Record "Pallet Change Quality";
                begin
                    //Check if needs to do
                    //ChangeQualityMgmt.CheckChangeItem(Rec);
                    PalletChangeQuality.Reset();
                    PalletChangeQuality.SetRange("Pallet ID", "Pallet ID");
                    PalletChangeQuality.SetRange("User Created", UserId);
                    PalletChangeQuality.SetRange("Pallet Line No.", "Line No.");
                    if not PalletChangeQuality.FindFirst() then begin
                        Error(ErrNewItem);
                        exit;
                    end;
                    PalletItemChgLine.reset;
                    PalletItemChgLine.setrange("Pallet ID", Rec."Pallet ID");
                    PalletItemChgLine.setrange("User Created", UserId);
                    PalletItemChgLine.setrange("New Quantity", 0);
                    if PalletItemChgLine.FindFirst() then begin
                        Error(ErrQty);
                        exit;
                    end;

                    TrackingItemNumber := ChangeQualityMgmt.ValidatePackMaterialsCreate(Rec);
                    if not (TrackingItemNumber = '') then begin
                        error('Error : Packing Material ' + TrackingItemNumber + ' Does not have sufficient Quantity');
                        exit;
                    end;

                    ChangeQualityMgmt.NegAdjChangeQuality(Rec); //Negative Change Quality  
                    // ChangeQualityMgmt.PostItemLedger(); //Post Neg Item Journals to New Items                 
                    ChangeQualityMgmt.ChangeQuantitiesOnPalletline(Rec); //Change Quantities on Pallet Line                    
                    ChangeQualityMgmt.ChangePalletReservation(Rec); //Change Pallet Reservation Line                    
                    ChangeQualityMgmt.PalletLedgerAdjustOld(rec); //Adjust Pallet Ledger Entries - Old Items  
                    ChangeQualityMgmt.AddNewItemsToPallet(rec); //Add New Lines                    
                    ChangeQualityMgmt.PosAdjNewItems(rec); //Positivr Adj to New Lines
                    // ChangeQualityMgmt.PostItemLedger(); //Post Pos Item Journals to New Items                    
                    ChangeQualityMgmt.NegAdjToNewPacking(rec); //Neg ADjustment to New Packing Materials
                    ChangeQualityMgmt.PostItemLedger(rec."Pallet ID"); //Post Pos Item Journals to New Items  
                    ChangeQualityMgmt.AddPackingMaterialsToExisting(rec); //Add Packing Materials to Existing Packing Materials                                      
                    ChangeQualityMgmt.RecreateReservations(rec."Pallet ID");
                    ChangeQualityMgmt.RemoveZeroPalletLine(rec); // Remove Pallet Lines with Zero Quantities
                    CurrPage.Close();
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
        PalletLineChangeQuality.setrange("Pallet ID", PalletID);
        PalletLineChangeQuality.SetRange("Line No.", PalletLineNo);
        if PalletLineChangeQuality.findset then
            PalletLineChangeQuality.DeleteAll();

        if PalletID = '' then
            PalletSelect := true
        else
            palletselect := false;

        PalletChangeQuality.reset;
        PalletChangeQuality.setrange("User Created", UserId);
        PalletChangeQuality.setrange("Pallet ID", PalletID);
        PalletChangeQuality.SetRange("Pallet Line No.", PalletLineNo);
        if PalletChangeQuality.findset then
            PalletChangeQuality.DeleteAll();

        if PalletID <> '' then begin
            CalcChangeQuality(PalletID, PalletLineNo);
            rec.setfilter("Pallet ID", PalletID);
            rec.SetRange("Line No.", PalletLineNo);
            rec.setfilter("User ID", UserId);
        end
        else begin
            rec.setfilter("Pallet ID", 'X');
            //rec.setfilter("User ID", UserId);
        end;

        CurrPage.update;
    end;

    procedure SetPalletIDAndPalletLine(pPalletID: code[20]; pPalletLine: Integer)
    begin
        PalletID := pPalletID;
        PalletLineNo := pPalletLine;
    end;

    //Calc Change Quality
    procedure CalcChangeQuality(pPalletID: code[20]; pPalletLine: Integer)
    var

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
        PalletLine.SetRange("Line No.", pPalletLine);
        if PalletLine.findset then
            repeat
                PalletLineChangeQuality.init;
                PalletLineChangeQuality.TransferFields(PalletLine);
                PalletLineChangeQuality."User ID" := UserId;
                PalletLineChangeQuality.Quantity := PalletLine.Quantity - PalletLine."QTY Consumed";
                PalletLineChangeQuality."Replaced Qty" := PalletLine.Quantity;
                PalletLineChangeQuality.insert;
            until palletline.next = 0;
    end;

    var
        PalletID: code[20];
        PalletLineNo: Integer;
        PalletLine: Record "Pallet Line";
        PalletChangeQuality: Record "Pallet Change Quality";
        PalletLineChangeQuality: Record "Pallet Line Change Quality";

        PalletSelect: Boolean;

}
