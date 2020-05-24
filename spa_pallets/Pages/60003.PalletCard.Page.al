page 60003 "Pallet Card"
{

    PageType = Card;
    SourceTable = "Pallet Header";
    Caption = 'Pallet Card';

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
                field("Raw Material Pallet"; "Raw Material Pallet")
                {
                    ApplicationArea = all;
                }
                field("Pallet Type"; "Pallet Type")
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
            action("Close Pallet")
            {
                ApplicationArea = All;
                image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowClose;

                trigger OnAction()
                begin
                    PalletFunctions.ClosePallet(rec);
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
                begin
                    PalletDisposalMgmt.DisposePallet(rec);
                end;
            }

            action("Pallet Reservations")
            {
                ApplicationArea = All;
                image = ItemReservation;
                Promoted = true;
                PromotedCategory = Process;

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
            action("Print Pallet")
            {
                ApplicationArea = All;
                image = Print;
                Promoted = true;
                PromotedCategory = Process;
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
                Promoted = true;
                PromotedCategory = Process;

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
            group("Microwave")
            {
                action("Microwave Pallet")
                {
                    ApplicationArea = All;
                    image = Category;
                    trigger OnAction()
                    begin
                        rec."Pallet Status" := rec."Pallet Status"::Consumed;
                        rec.modify;
                    end;
                }
                action("Unmark Microwave Pallet")
                {
                    ApplicationArea = All;
                    image = UndoCategory;

                    trigger OnAction()
                    begin
                        rec."Pallet Status" := rec."Pallet Status"::Open;
                        rec.modify;
                    end;
                }

            }
        }
    }
    trigger OnOpenPage()
    begin
        if rec."Pallet Status" = rec."Pallet Status"::open then begin
            ShowReopen := false;
            ShowClose := true;
            ShowDisposed := false;
        end;
        if rec."Pallet Status" = rec."Pallet Status"::Closed then begin
            ShowReopen := true;
            ShowClose := false;
            ShowDisposed := true;
        end;
        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", rec."Pallet ID");
        if PackingMaterials.findfirst then
            PackingExists := true
        else
            PackingExists := false;

    end;

    trigger OnAfterGetRecord()
    begin
        if rec."Pallet Status" = rec."Pallet Status"::open then begin
            ShowReopen := false;
            ShowClose := true;
            ShowDisposed := false;
        end;
        if rec."Pallet Status" = rec."Pallet Status"::Closed then begin
            ShowReopen := true;
            ShowClose := false;
            ShowDisposed := true;
        end;
        PackingMaterials.reset;
        PackingMaterials.setrange("Pallet ID", rec."Pallet ID");
        if PackingMaterials.findfirst then
            PackingExists := true
        else
            PackingExists := false;
    end;

    var
        PalletFunctions: Codeunit "Pallet Functions";
        PalletDisposalMgmt: Codeunit "Pallet Disposal Management";
        ShowClose: Boolean;
        ShowReopen: Boolean;
        PackingExists: Boolean;
        ShowDisposed: Boolean;
        PackingMaterials: Record "Packing Material Line";

}
