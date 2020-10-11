page 60036 "PO Details Factbox"
{
    PageType = ListPart;
    SourceTable = "PO Details Factbox";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    // RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater("")
            {
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        PalletRecord: Record "Pallet Header";
                        PalletCard: Page "Pallet Card";
                    begin
                        if "Pallet ID" <> '' then
                            IF PalletRecord.Get("Pallet ID") then begin
                                Clear(PalletCard);
                                PalletCard.SetRecord(PalletRecord);
                                PalletCard.SetTableView(PalletRecord);
                                PalletCard.Run();
                            end;
                    end;


                }
                field("Pallet Line No."; "Pallet Line No.")
                {
                    ApplicationArea = All;

                }
                field("Sales Order No."; "Sales Order No.")
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
                        if "Sales Order No." <> '' then begin
                            SORecord.Reset();
                            SORecord.SetRange("Document Type", SORecord."Document Type"::Order);
                            SORecord.SetRange("No.", "Sales Order No.");
                            IF SORecord.FindLast() then begin
                                Clear(SOCard);
                                SOCard.SetRecord(SORecord);
                                SOCard.SetTableView(SORecord);
                                SOCard.Run();
                            end else begin
                                SORecordArchive.Reset();
                                SORecordArchive.SetRange("Document Type", SORecordArchive."Document Type"::Order);
                                SORecordArchive.SetRange("No.", "Sales Order No.");
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
                field("Whse Shipment No."; "Whse Shipment No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        WSRecord: Record "Warehouse Shipment Header";
                        WSCard: Page "Warehouse Shipment";
                    begin
                        if "Whse Shipment No." <> '' then
                            IF WSRecord.Get("Whse Shipment No.") then begin
                                Clear(WSCard);
                                WSCard.SetRecord(WSRecord);
                                WSCard.SetTableView(WSRecord);
                                WSCard.Run();
                            end;
                    end;
                }
                field("Whse Shipment Line No."; "Whse Shipment Line No.")
                {
                    ApplicationArea = All;
                    BlankZero = true;

                }
                field("Posted Whse Shipment No."; "Posted Whse Shipment No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        WSRecord: Record "Posted Whse. Shipment Header";
                        WSCard: Page "Posted Whse. Shipment";
                    begin
                        if "Posted Whse Shipment No." <> '' then
                            IF WSRecord.Get("Posted Whse Shipment No.") then begin
                                Clear(WSCard);
                                WSCard.SetRecord(WSRecord);
                                WSCard.SetTableView(WSRecord);
                                WSCard.Run();
                            end;
                    end;

                }
                field("Posted Whse Shipment Line No."; "Posted Whse Shipment Line No.")
                {
                    ApplicationArea = All;
                    BlankZero = true;

                }

            }
        }
    }

    procedure SetPO(PONumber: Code[20]);//; POLine: Integer);
    var
        LPalletLine: Record "Pallet Line";
        LWarehousePallet: Record "Warehouse Pallet";
        LPostedWarehousePallet: Record "Posted Warehouse Pallet";
    begin
        Rec.Reset();
        Rec.SetRange("User Created", UserId);
        if Rec.FindSet() then Rec.DeleteAll();

        LPalletLine.Reset();
        LPalletLine.SetCurrentKey("Purchase Order No.");
        LPalletLine.SetRange("Purchase Order No.", PONumber);
        //LPalletLine.SetRange("Purchase Order Line No.", POLine);
        IF LPalletLine.FindSet() then
            repeat
                Rec.Init();
                Rec."User Created" := UserId;
                Rec."Purchase Order No." := PONumber;
                //Rec."Purchase Order Line No." := POLine;
                Rec."Pallet ID" := LPalletLine."Pallet ID";
                Rec."Pallet Line No." := LPalletLine."Line No.";
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
        Rec.SetRange("User Created", UserId);
        Rec.SetRange("Purchase Order No.", PONumber);
        // Rec.SetRange("Purchase Order Line No.", POLine);
        CurrPage.Update(false);

    end;

}