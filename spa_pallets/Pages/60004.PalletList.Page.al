page 60004 "Pallet List"
{

    PageType = List;
    SourceTable = "Pallet Header";
    Caption = 'Pallet List';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "Pallet Card";
    Editable = false;
    SourceTableView = order(descending);

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = All;
                }

                field("Pallet Status"; "Pallet Status")
                {
                    ApplicationArea = All;
                }
                field(PalletTypeText; PalletTypeText)
                {
                    Caption = 'Pallet Type';
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
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
                field("Total Qty"; "Total Qty")
                {
                    ApplicationArea = All;
                }
                field("Raw Material Pallet"; "Raw Material Pallet")
                {
                    ApplicationArea = All;
                }
                field("Exist in warehouse shipment"; "Exist in warehouse shipment")
                {
                    ApplicationArea = All;
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = all;
                }
                field("User Created"; "User Created")
                {
                    ApplicationArea = all;
                }
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
                    PalletFunctions.ClosePallet(rec,'BC');
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

            action("Mark Shipped")
            {
                ApplicationArea = All;
                image = ReleaseShipment;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowShip;

            }
            action("ReOpen Pallet")
            {
                ApplicationArea = All;
                image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = ShowReopen;

                trigger OnAction()
                var
                    packingma: Record "Packing Material Line";
                begin
                    PalletFunctions.ChoosePackingMaterials(rec);
                    PalletFunctions.ReOpenPallet(rec);
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

        }
    }
    trigger OnOpenPage()
    begin
        if rec."Pallet Status" = rec."Pallet Status"::open then begin
            ShowReopen := false;
            ShowClose := true;
            ShowShip := false;
            ShowDisposed := false;
        end;
        if rec."Pallet Status" = rec."Pallet Status"::Closed then begin
            ShowReopen := true;
            ShowClose := false;
            ShowShip := true;
            ShowDisposed := true;
        end;
        if rec."Pallet Status" = rec."Pallet Status"::Shipped then begin
            ShowReopen := true;
            ShowClose := false;
            ShowShip := false;
            ShowDisposed := false;
        end;

    end;

    trigger OnAfterGetRecord()
    begin
        if rec."Pallet Status" = rec."Pallet Status"::open then begin
            ShowReopen := false;
            ShowClose := true;
            ShowShip := false;
            ShowDisposed := false;
        end;
        if rec."Pallet Status" = rec."Pallet Status"::Closed then begin
            ShowReopen := true;
            ShowClose := false;
            ShowShip := true;
            ShowDisposed := true;
        end;
        if rec."Pallet Status" = rec."Pallet Status"::Shipped then begin
            ShowReopen := true;
            ShowClose := false;
            ShowShip := false;
            ShowDisposed := false;
        end;
        if "Pallet Type" = 'mw' then
            PalletTypeText := 'Microwave'
        else
            if "Pallet Type" = 'grade' then
                PalletTypeText := 'Grading'
            else
                PalletTypeText := '';

    end;

    var
        PalletFunctions: Codeunit "Pallet Functions";
        PalletDisposalMgmt: Codeunit "Pallet Disposal Management";
        ShowClose: Boolean;
        ShowShip: Boolean;
        ShowReopen: Boolean;
        ShowDisposed: Boolean;
        PalletTypeText: Text;
}
