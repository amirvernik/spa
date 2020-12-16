pageextension 60018 WarehouseShipmentCardExt extends "Warehouse Shipment"
{
    layout
    {

        addafter("Sorting Method")
        {
            field("User Created"; "User Created")
            {
                editable = false;
                ApplicationArea = all;
            }
            field(Allocated; Allocated)
            {
                Editable = false;
                ApplicationArea = all;
            }
        }
        addafter(Control1901796907)
        {
            part(MyWarehousePart; "Warehouse Pallet FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseShptLines;
                SubPageLink = "Whse Shipment No." = field("No."), "Whse Shipment Line No." = field("Line No.");
                Visible = PalletsExists;
            }
        }
    }

    actions
    {
        modify("P&ost Shipment")
        {
            trigger OnAfterAction()
            var
                //Delete Whse Shipment - Temporary [GOLIVE-Temp]
                PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
                PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";

                WhseShipmentLine: Record "Warehouse Shipment Line";
                WhseShipmentHeader: Record "Warehouse Shipment Header";

                ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";

                WhseShipmentNumber_Before: code[20];
                WhseShipmentNumber_Posted: code[20];
            begin

                WhseShipmentNumber_Before := Rec."No.";
                CurrPage.Close();

                PostedWhseShipmentHeader.reset;
                PostedWhseShipmentHeader.setrange("Whse. Shipment No.", WhseShipmentNumber_Before);
                if PostedWhseShipmentHeader.findfirst then
                    WhseShipmentNumber_Posted := PostedWhseShipmentHeader."No.";

                PostedWhseShipmentLine.reset;
                PostedWhseShipmentLine.setrange("No.", WhseShipmentNumber_Posted);
                if PostedWhseShipmentLine.findset then
                    repeat
                        WhseShipmentLine.reset;
                        WhseShipmentLine.setrange("No.", WhseShipmentNumber_Before);
                        WhseShipmentLine.setrange("Line No.", PostedWhseShipmentLine."Line No.");
                        if WhseShipmentLine.findfirst then begin
                            WhseShipmentHeader.get(WhseShipmentNumber_Before);
                            IF WhseShipmentHeader.Status = WhseShipmentHeader.Status::Released THEN
                                ReleaseWhseShptDoc.Reopen(WhseShipmentHeader);
                            WhseShipmentLine.Validate("Qty. Shipped", PostedWhseShipmentLine.Quantity);
                            WhseShipmentLine.modify;
                        end;
                    until PostedWhseShipmentLine.next = 0;

                if WhseShipmentHeader.get(WhseShipmentNumber_Before) then
                    WhseShipmentHeader.delete(true);
            end;
        }

        addlast(processing)
        {
            group(Pallets)
            {
                Caption = 'P&allets';
                Image = CalculateShipment;

                action("Add a Pallet")
                {
                    Image = ImportCodes;
                    Promoted = true;
                    ApplicationArea = All;
                    Visible = ShowAddPallet;

                    trigger OnAction()
                    begin
                        WarehouseShipmentLine.reset;
                        WarehouseShipmentLine.setrange("No.", rec."No.");
                        WarehouseShipmentLine.setfilter(WarehouseShipmentLine."Remaining Quantity", '<>%1', 0);
                        if not WarehouseShipmentLine.findfirst then
                            error(Lbl001);

                        WarehouseShipmentManagement.PalletSelection(rec);
                        currpage.close;


                        CurrPage.Update(false);
                    end;

                }
                action("Remove a Pallet")
                {
                    Image = RemoveLine;
                    Promoted = true;
                    ApplicationArea = All;
                    Visible = ShowRemovePallet;
                    trigger OnAction()
                    begin
                        WarehouseShipmentManagement.SelectPalletToRemove(rec);
                        currpage.close;
                        CurrPage.Update(false);
                    end;

                }
                action("Remove all Pallets")
                {
                    Image = ClearLog;
                    Promoted = true;
                    ApplicationArea = All;
                    Visible = ShowRemovePallet;
                    trigger OnAction()
                    begin
                        WarehouseShipmentManagement.RemoveAllPallets(rec);
                        currpage.update;
                    end;
                }
                action("Sticker Note")
                {
                    image = PrintCover;
                    ApplicationArea = all;
                    Visible = ShowPrint;
                    trigger OnAction()
                    var
                        StickerNoteFunctions: Codeunit "Sticker note functions";
                        LWarehousepallet: Record "Warehouse Pallet";
                        LPAlletHeader: Record "Pallet Header";
                        PageSelectPallets: Page "Select Pallets";
                        LPalletsFilterText: Text;
                    begin
                        LPalletsFilterText := '';
                        LWarehousepallet.Reset();
                        LWarehousepallet.SetRange("Whse Shipment No.", Rec."No.");
                        if LWarehousepallet.FindSet() then
                            repeat
                                if LPalletsFilterText = '' then
                                    LPalletsFilterText := LWarehousepallet."Pallet ID"
                                else
                                    LPalletsFilterText += '|' + LWarehousepallet."Pallet ID";
                            until LWarehousepallet.Next() = 0;
                        if LPalletsFilterText <> '' then begin
                            LPAlletHeader.Reset();
                            LPAlletHeader.SetFilter("Pallet ID", LPalletsFilterText);
                            LPAlletHeader.FindSet();
                            Clear(PageSelectPallets);
                            PageSelectPallets.SetTableView(LPAlletHeader);
                            PageSelectPallets.SetRecord(LPAlletHeader);
                            PageSelectPallets.SetPageType('WarehouseShipment');
                            PageSelectPallets.SetWarehouseShipment(Rec);
                            PageSelectPallets.RunModal();
                        end;
                        // StickerNoteFunctions.CreatePalletStickerNoteFromShipment(rec, 'BC');
                        /* LWarehousepallet.Reset();
                         LWarehousepallet.SetRange("Whse Shipment No.", Rec."No.");
                         if LWarehousepallet.FindSet() then
                             repeat
                                 LWarehousepallet.Printed := true;
                                 if not LWarehousepallet.Modify(false) then;
                             until LWarehousepallet.Next() = 0;*/
                    end;
                }
            }

        }
    }
    trigger OnAfterGetRecord()
    begin
        ShowAddPallet := true;
        ShowRemovePallet := true;
        PalletsExists := true;
        ShowPrint := true;
        WarehousePallets.reset;
        WarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not WarehousePallets.findset then begin
            PalletsExists := false;
            ShowPrint := false;
            ShowRemovePallet := false;
        end;
        if UserSetup.get(UserId) then
            if not UserSetup."Remove Pallet from Whse. Ship" then
                ShowRemovePallet := false;

        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", rec."No.");
        if not WarehouseShipmentLine.findset then
            ShowAddPallet := false;
    end;

    trigger OnOpenPage()
    begin
        ShowAddPallet := true;
        ShowRemovePallet := true;
        PalletsExists := true;
        ShowPrint := true;
        WarehousePallets.reset;
        WarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not WarehousePallets.findset then begin
            PalletsExists := false;
            ShowRemovePallet := false;
            ShowPrint := false;
        end;
        if UserSetup.get(UserId) then
            if not UserSetup."Remove Pallet from Whse. Ship" then
                ShowRemovePallet := false;

        WarehouseShipmentLine.reset;
        WarehouseShipmentLine.setrange("No.", rec."No.");
        if not WarehouseShipmentLine.findset then
            ShowAddPallet := false;
    end;

    var
        ShowPrint: Boolean;
        PalletsExists: Boolean;
        WarehousePallets: Record "Warehouse Pallet";
        WarehouseShipmentManagement: Codeunit "Warehouse Shipment Management";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Lbl001: label 'All lines have pallets';
        ShowRemovePallet: Boolean;
        ShowAddPallet: Boolean;
        UserSetup: Record "user setup";

}