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
                    Visible = ShowRemovePallet;
                    trigger OnAction()
                    var
                        StickerNoteFunctions: Codeunit "Sticker note functions";
                    begin
                        StickerNoteFunctions.CreatePalletStickerNoteFromShipment(rec);
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
        WarehousePallets.reset;
        WarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not WarehousePallets.findset then begin
            PalletsExists := false;
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
        WarehousePallets.reset;
        WarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not WarehousePallets.findset then begin
            PalletsExists := false;
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

    var
        PalletsExists: Boolean;
        WarehousePallets: Record "Warehouse Pallet";
        WarehouseShipmentManagement: Codeunit "Warehouse Shipment Management";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        Lbl001: label 'All lines have pallets';
        ShowRemovePallet: Boolean;
        ShowAddPallet: Boolean;
        UserSetup: Record "user setup";

}