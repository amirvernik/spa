page 60003 "Pallet Card"
{

    PageType = Card;
    SourceTable = "Pallet Header";
    Caption = 'Pallet Card';
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = All;
                    Editable = ShowClose;
                }
                field("Pallet Description"; "Pallet Description")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = ShowClose;
                }
                field(PurchaseOrder; PalletFunctions.GetFirstPO(Rec))
                {
                    Caption = ' Purchase Order';
                    ApplicationArea = all;
                    ToolTip = 'Show Purchase Order no. of First line on Pallet';
                    trigger OnDrillDown()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        PurchaseHeader.reset;
                        PurchaseHeader.setrange("Document Type", PurchaseHeader."Document Type"::Order);
                        PurchaseHeader.setrange("No.", PalletFunctions.GetFirstPO(Rec));
                        if PurchaseHeader.findfirst then
                            page.run(page::"Purchase Order", PurchaseHeader);
                    end;

                }
                field("Pallet Status"; "Pallet Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                    Editable = ShowClose;
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("User Created"; "User Created")
                {
                    ApplicationArea = all;
                    Editable = false;
                }
                field("Exist in warehouse shipment"; "Exist in warehouse shipment")
                {
                    ApplicationArea = all;
                    editable = false;

                }
                field("Warehouse Shipment No."; "Warehouse Shipment No.")
                {
                    ApplicationArea = All;
                }
                field("Raw Material Pallet"; "Raw Material Pallet")
                {
                    ApplicationArea = all;
                }
                field("Pallet Type"; "Pallet Type")
                {
                    ApplicationArea = all;
                    editable = false;
                }

                field("Disposal Status"; "Disposal Status")
                {
                    ApplicationArea = all;
                    editable = false;
                }
            }

            part(PalletLines; "Pallet Card Subpage")
            {
                ApplicationArea = Basic, Suite;
                Editable = ShowClose;
                SubPageLink = "Pallet ID" = FIELD("Pallet ID");
                UpdatePropagation = Both;
                caption = 'Lines';
            }

            part(PackingMaterials; "Pallet Materials SubPage")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Pallet ID" = FIELD("Pallet ID");
                UpdatePropagation = Both;
                caption = 'Packing Material Lines';
                Visible = PackingExists;
            }

        }
        area(factboxes)
        {
            systempart(Control60000; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control60001; Notes)
            {
                ApplicationArea = Notes;
            }

        }
    }
    actions
    {
        area(Processing)
        {
            group(Functions)
            {
                Image = Action;
                action(ClosePalletTestBtn)//DELETE ME
                {
                    ApplicationArea = All;
                    Visible = EnableTESTPROD1;
                    trigger OnAction()
                    begin
                        "Exist in warehouse shipment" := false;
                        "Pallet Status" := "Pallet Status"::Closed;
                        Modify();
                    end;

                }
                action("Cancel Pallet")
                {
                    ApplicationArea = All;
                    image = Cancel;
                    Promoted = true;
                    PromotedCategory = Process;
                    // Enabled = ("Pallet Status" = "Pallet Status"::Open) and (not ("Exist in warehouse shipment"));
                    Enabled = "Pallet Status" <> "Pallet Status"::Canceled;
                    trigger OnAction()
                    var
                        LPalletFunctions: Codeunit "Pallet Functions";
                    begin
                        LPalletFunctions.CancelPallet(Rec);
                    end;
                }

                action("Close Pallet")
                {
                    ApplicationArea = All;
                    image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = ShowClose;

                    trigger OnAction()
                    begin
                        PalletFunctions.ClosePallet(rec, 'BC');
                    end;
                }
                action("ReOpen Pallet")
                {
                    ApplicationArea = All;
                    image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = ShowReopen;

                    trigger OnAction()
                    begin
                        if rec."Pallet Status" <> rec."Pallet Status"::Canceled then
                            PalletFunctions.ChoosePackingMaterials(rec);
                        PalletFunctions.ReOpenPallet(rec);
                    end;
                }
                action("Dispose Pallet")
                {
                    ApplicationArea = All;
                    image = NegativeLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    Enabled = ShowDisposed;
                    trigger OnAction()
                    var
                        PalletDisposalConf: Label 'Are you sure you want to dispose the pallet?';
                    begin
                        if confirm(PalletDisposalConf) then
                            PalletDisposalMgmt.DisposePallet(rec);
                    end;
                }

                action("Pallet Reservations")
                {
                    ApplicationArea = All;
                    image = ItemReservation;

                    trigger OnAction()
                    var
                        PalletReservation: Record "Pallet reservation Entry";
                    begin
                        PalletReservation.reset;
                        PalletReservation.setrange("Pallet ID", rec."Pallet ID");
                        if PalletReservation.FindSet then
                            page.run(page::"Pallet Reservation Entries", PalletReservation);
                    end;
                }
                action("Ledger Entries")
                {
                    ApplicationArea = All;
                    image = LedgerEntries;

                    trigger OnAction()
                    var
                        PalletLedgerEntry: Record "Pallet Ledger Entry";
                    begin
                        PalletLedgerEntry.reset;
                        PalletLedgerEntry.setrange("Pallet ID", rec."Pallet ID");
                        if PalletLedgerEntry.findset then
                            page.run(page::"Pallet Ledger Entries", PalletLedgerEntry);
                    end;
                }
                action("Sticker Note")
                {
                    image = PrintCover;
                    ApplicationArea = all;
                    trigger OnAction()
                    var
                        StickerNoteFunctions: Codeunit "Sticker note functions";
                    begin
                        StickerNoteFunctions.CreatePalletStickerNoteFromPallet(rec);
                        message('Pallet Sticker note sent to Printer');
                    end;
                }
            }
            group("Value Add")
            {
                image = ServiceItemGroup;
                action("Value Add Pallet")
                {
                    ApplicationArea = All;
                    image = Category;
                    trigger OnAction()
                    begin
                        ConsumeablesMgmt.ConsumeItems(rec);
                        rec."Pallet Type" := 'mw';
                        rec.modify;
                    end;
                }
                action("Unmark Value Add Pallet")
                {
                    ApplicationArea = All;
                    image = UndoCategory;

                    trigger OnAction()
                    begin
                        ConsumeablesMgmt.UnConsumeItems(rec);
                        rec."Pallet Type" := '';
                        rec.modify;
                    end;
                }

            }
            group("Disposal Approval")
            {
                action("Approve Dispose Pallet")
                {
                    Enabled = ShowDisposePalletWorkFlow;
                    ApplicationArea = All;
                    Image = Approve;
                    trigger OnAction()
                    begin
                        varinat := rec;
                        DisposePalletWorkflow.SetStatusToApproveCodeDisposePallet(varinat);
                    end;
                }
                action("Reject Dispose Pallet")
                {
                    Enabled = ShowDisposePalletWorkFlow;
                    ApplicationArea = All;
                    Image = Reject;
                    trigger OnAction()
                    begin
                        varinat := rec;
                        DisposePalletWorkflow.SetStatusToRejectCodeDisposePallet(varinat);
                    end;
                }
            }

            action("Print Pallet")
            {
                ApplicationArea = All;
                image = Print;
                Promoted = true;
                PromotedCategory = Report;
                trigger OnAction()
                var

                    PalletHeader: Record "Pallet Header";

                begin
                    PalletHeader.reset;
                    PalletHeader.setrange("Pallet ID", rec."Pallet ID");
                    if palletheader.findfirst then
                        Report.Run(report::"Pallet Print", false, false, palletheader);
                end;

            }
            action("Attachments")
            {
                ApplicationArea = All;
                image = Attachments;
                //Promoted = true;
                //PromotedCategory = Process;

                trigger OnAction()
                var
                    RecRef: RecordRef;
                    PalletHeader: Record "Pallet Header";
                    DocumentAttachmentDetails: Page "Document Attachment Details";

                begin
                    RecRef.OPEN(DATABASE::"Pallet Header");
                    IF PalletHeader.GET("Pallet ID") THEN
                        RecRef.GETTABLE(PalletHeader);
                    DocumentAttachmentDetails.OpenForRecRef(RecRef);
                    DocumentAttachmentDetails.RUNMODAL;
                end;

            }
        }
    }
    trigger OnOpenPage()
    begin
        EnableTESTPROD1 := UserId() = 'PRODWARE1';


        //Ariel Change
        if rec."Disposal Status" = rec."Disposal Status"::"Pending Approval" then begin
            ShowDisposePalletWorkFlow := true;
        end
        else begin
            ShowDisposePalletWorkFlow := false;
        end;

        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", rec."Pallet ID");
        if PackingMaterials.findfirst then
            PackingExists := true
        else
            PackingExists := false;

    end;

    trigger OnAfterGetRecord()
    var
        LUserSetup: Record "User Setup";
    begin

        case rec."Pallet Status" of
            rec."Pallet Status"::open:
                begin
                    ShowReopen := false;
                    ShowClose := true;
                    ShowDisposed := false;
                    ShowCancel := true;
                end;
            rec."Pallet Status"::Closed:
                begin
                    ShowReopen := true;
                    ShowClose := false;
                    ShowDisposed := true;
                end;
            rec."Pallet Status"::Shipped:
                begin
                    ShowReopen := true;
                    ShowClose := false;
                    ShowDisposed := false;
                end;
            rec."Pallet Status"::Canceled:
                begin
                    ShowReopen := true;
                    ShowClose := false;
                    ShowDisposed := false;
                    ShowCancel := false;
                end;
        end;
        if "Exist in warehouse shipment" then ShowReopen := false;
        if "Pallet Status" = "Pallet Status"::Canceled then
            if LUserSetup.Get(UserId) then
                if not LUserSetup."Reopen Cancelled Pallets" then
                    ShowReopen := false;
        //Ariel Change
        if rec."Disposal Status" = rec."Disposal Status"::"Pending Approval" then begin
            ShowDisposePalletWorkFlow := true;
        end
        else begin
            ShowDisposePalletWorkFlow := false;
        end;

        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", rec."Pallet ID");
        if PackingMaterials.findfirst then
            PackingExists := true
        else
            PackingExists := false;
    end;

    var
        EnableTESTPROD1: Boolean;//DELETE ME
        ConsumeablesMgmt: Codeunit "Consumables Management";
        PalletFunctions: Codeunit "Pallet Functions";
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletDisposalMgmt: Codeunit "Pallet Disposal Management";
        DisposePalletWorkflow: Codeunit "Dispose Pallet Workflow";
        varinat: Variant;
        ShowClose: Boolean;
        ShowReopen: Boolean;
        ShowCancel: Boolean;
        PackingExists: Boolean;
        ShowDisposed: Boolean;
        ShowChanged: Boolean;
        ShowDisposePalletWorkFlow: Boolean;
        PackingMaterials: Record "Packing Material Line";

}
