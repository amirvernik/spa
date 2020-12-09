page 60036 "PO Details Factbox"
{
    PageType = ListPart;
    SourceTable = "PO Details Factbox";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    Caption = 'Pallet Information';
    // RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater("")
            {
                field("Purchase Order Line No."; Rec."Purchase Order Line No.")
                {
                    ApplicationArea = All;
                }
                field("Pallet ID"; Rec."Pallet ID")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        PalletRecord: Record "Pallet Header";
                        PalletCard: Page "Pallet Card";
                    begin
                        if Rec."Pallet ID" <> '' then
                            IF PalletRecord.Get(Rec."Pallet ID") then begin
                                Clear(PalletCard);
                                PalletCard.SetRecord(PalletRecord);
                                PalletCard.SetTableView(PalletRecord);
                                PalletCard.Run();
                            end;
                    end;


                }
                field("Pallet Line No."; Rec."Pallet Line No.")
                {
                    ApplicationArea = All;

                }
                field("Pallet Type"; "Pallet Type")
                {
                    ApplicationArea = All;
                }
                field("Pallet Status"; "Pallet Status")
                {
                    ApplicationArea = All;
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        SORecord: Record "Sales Header";
                        SORecordArchive: Record "Sales Header Archive";
                        SOCard: Page "Sales Order";
                        SOCardArchive: Page "Sales Order Archive";
                    begin
                        if Rec."Sales Order No." <> '' then begin
                            SORecord.Reset();
                            SORecord.SetRange("Document Type", SORecord."Document Type"::Order);
                            SORecord.SetRange("No.", Rec."Sales Order No.");
                            IF SORecord.FindLast() then begin
                                Clear(SOCard);
                                SOCard.SetRecord(SORecord);
                                SOCard.SetTableView(SORecord);
                                SOCard.Run();
                            end else begin
                                SORecordArchive.Reset();
                                SORecordArchive.SetRange("Document Type", SORecordArchive."Document Type"::Order);
                                SORecordArchive.SetRange("No.", Rec."Sales Order No.");
                                IF SORecordArchive.FindLast() then begin
                                    Clear(SOCardArchive);
                                    SOCardArchive.SetRecord(SORecordArchive);
                                    SOCardArchive.SetTableView(SORecordArchive);
                                    SOCardArchive.Run();
                                end;
                            end;
                        end;
                    end;


                }
                field("Whse Shipment No."; Rec."Whse Shipment No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        WSRecord: Record "Warehouse Shipment Header";
                        WSCard: Page "Warehouse Shipment";
                    begin
                        if Rec."Whse Shipment No." <> '' then
                            IF WSRecord.Get(Rec."Whse Shipment No.") then begin
                                Clear(WSCard);
                                WSCard.SetRecord(WSRecord);
                                WSCard.SetTableView(WSRecord);
                                WSCard.Run();
                            end;
                    end;
                }
                field("Whse Shipment Line No."; Rec."Whse Shipment Line No.")
                {
                    ApplicationArea = All;
                    BlankZero = true;

                }
                field("Posted Whse Shipment No."; Rec."Posted Whse Shipment No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        WSRecord: Record "Posted Whse. Shipment Header";
                        WSCard: Page "Posted Whse. Shipment";
                    begin
                        if Rec."Posted Whse Shipment No." <> '' then
                            IF WSRecord.Get(Rec."Posted Whse Shipment No.") then begin
                                Clear(WSCard);
                                WSCard.SetRecord(WSRecord);
                                WSCard.SetTableView(WSRecord);
                                WSCard.Run();
                            end;
                    end;

                }
                field("Posted Whse Shipment Line No."; Rec."Posted Whse Shipment Line No.")
                {
                    ApplicationArea = All;
                    BlankZero = true;

                }

            }
        }
    }

    procedure SetPO(PONumber: Code[20]; pVer: Integer);//; POLine: Integer);
    var
        LPalletLine: Record "Pallet Line";
        LPalletHeader: Record "Pallet Header";
        LWarehousePallet: Record "Warehouse Pallet";
        LPostedWarehousePallet: Record "Posted Warehouse Pallet";
        LPurchaseLine: Record "Purchase Line";
        LPurchaseLineArchive: Record "Purchase Line Archive";
        LSalesLine: Record "Sales Line";
    begin
        Rec.Reset();
        Rec.SetRange("User Created", UserId);
        if Rec.FindSet() then Rec.DeleteAll();

        LPurchaseLine.Reset();
        LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
        LPurchaseLine.SetRange("Document No.", PONumber);
        if LPurchaseLine.FindSet() then begin
            repeat
                LPalletLine.Reset();
                LPalletLine.SetCurrentKey("Purchase Order No.", "Purchase Order Line No.");
                LPalletLine.SetRange("Purchase Order No.", LPurchaseLine."Document No.");
                LPalletLine.SetRange("Purchase Order Line No.", LPurchaseLine."Line No.");
                IF LPalletLine.FindSet() then begin
                    repeat
                        Rec.Init();
                        Rec."User Created" := UserId;
                        Rec."Purchase Order No." := PONumber;
                        Rec."Purchase Order Line No." := LPurchaseLine."Line No.";
                        Rec."Pallet ID" := LPalletLine."Pallet ID";
                        Rec."Pallet Line No." := LPalletLine."Line No.";
                        LPalletHeader.Get(LPalletLine."Pallet ID");
                        Rec."Pallet Type" := LPalletHeader."Pallet Type";
                        Rec."RM Pallet" := LPalletHeader."Raw Material Pallet";
                        Rec."Pallet Status" := LPalletHeader."Pallet Status";
                        LPostedWarehousePallet.Reset();
                        LPostedWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                        LPostedWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                        If LPostedWarehousePallet.FindLast() then begin
                            Rec."Posted Whse Shipment No." := LPostedWarehousePallet."Whse Shipment No.";
                            Rec."Posted Whse Shipment Line No." := LPostedWarehousePallet."Whse Shipment Line No.";
                            LSalesLine.Reset();
                            LSalesLine.SetRange("Document Type", LSalesLine."Document Type"::"Return Order");
                            LSalesLine.SetRange("SPA Order No.", LWarehousePallet."Sales Order No.");
                            LSalesLine.SetRange("SPA Order Line No.", LWarehousePallet."Sales Order Line No.");
                            if not LSalesLine.FindFirst() then
                                Rec."Sales Order No." := LPostedWarehousePallet."Sales Order No.";

                        end else begin
                            LWarehousePallet.Reset();
                            LWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                            LWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                            If LWarehousePallet.FindLast() then begin
                                Rec."Posted Whse Shipment No." := LWarehousePallet."Whse Shipment No.";
                                Rec."Posted Whse Shipment Line No." := LWarehousePallet."Whse Shipment Line No.";

                                LSalesLine.Reset();
                                LSalesLine.SetRange("Document Type", LSalesLine."Document Type"::"Return Order");
                                LSalesLine.SetRange("SPA Order No.", LWarehousePallet."Sales Order No.");
                                LSalesLine.SetRange("SPA Order Line No.", LWarehousePallet."Sales Order Line No.");
                                if not LSalesLine.FindFirst() then
                                    Rec."Sales Order No." := LWarehousePallet."Sales Order No.";

                            end;

                        end;
                        if not Rec.Insert() then Rec.Modify();
                    until LPalletLine.Next() = 0;
                end else begin
                    Rec.Init();
                    Rec."Purchase Order No." := LPurchaseLine."Document No.";
                    Rec."Purchase Order Line No." := LPurchaseLine."Line No.";
                    Rec."Pallet ID" := '';
                    if not Rec.Insert() then Rec.Modify();
                end;
            until LPurchaseLine.Next() = 0;
        end else begin
            LPurchaseLineArchive.Reset();
            LPurchaseLineArchive.SetRange("Document Type", LPurchaseLineArchive."Document Type"::Order);
            LPurchaseLineArchive.SetRange("Document No.", PONumber);
            if pVer <> 0 then
                LPurchaseLineArchive.SetRange("Version No.", pVer);
            if LPurchaseLineArchive.FindSet() then
                repeat
                    LPalletLine.Reset();
                    LPalletLine.SetRange("Purchase Order No.", LPurchaseLineArchive."Document No.");
                    LPalletLine.SetRange("Purchase Order Line No.", LPurchaseLineArchive."Line No.");
                    IF LPalletLine.FindSet() then begin
                        repeat
                            Rec.Init();
                            Rec."User Created" := UserId;
                            Rec."Purchase Order No." := PONumber;
                            Rec."Purchase Order Line No." := LPurchaseLineArchive."Line No.";
                            Rec."Pallet ID" := LPalletLine."Pallet ID";
                            Rec."Pallet Line No." := LPalletLine."Line No.";
                            LPalletHeader.Get(LPalletLine."Pallet ID");
                            Rec."Pallet Type" := LPalletHeader."Pallet Type";
                            Rec."RM Pallet" := LPalletHeader."Raw Material Pallet";
                            Rec."Pallet Status" := LPalletHeader."Pallet Status";
                            LPostedWarehousePallet.Reset();
                            LPostedWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                            LPostedWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                            If LPostedWarehousePallet.FindLast() then begin
                                Rec."Posted Whse Shipment No." := LPostedWarehousePallet."Whse Shipment No.";
                                Rec."Posted Whse Shipment Line No." := LPostedWarehousePallet."Whse Shipment Line No.";
                                Rec."Sales Order No." := LPostedWarehousePallet."Sales Order No.";
                            end else begin
                                LWarehousePallet.Reset();
                                LWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                                LWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                                If LWarehousePallet.FindLast() then begin
                                    Rec."Posted Whse Shipment No." := LWarehousePallet."Whse Shipment No.";
                                    Rec."Posted Whse Shipment Line No." := LWarehousePallet."Whse Shipment Line No.";
                                    Rec."Sales Order No." := LWarehousePallet."Sales Order No.";
                                end;
                            end;
                            if not Rec.Insert() then Rec.Modify();

                        until LPalletLine.Next() = 0;
                    end else begin
                        Rec.Init();
                        Rec."Purchase Order No." := LPurchaseLineArchive."Document No.";
                        Rec."Purchase Order Line No." := LPurchaseLineArchive."Line No.";
                        Rec."Pallet ID" := '';
                        if not Rec.Insert() then Rec.Modify();
                    end;
                until LPurchaseLineArchive.Next() = 0;
        end;

        Rec.SetRange("User Created", UserId);
        Rec.SetRange("Purchase Order No.", PONumber);
        Rec.Ascending;
        CurrPage.Update(false);

    end;



}