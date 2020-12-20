pageextension 60020 PostedWarehouseShipmentCardExt extends "Posted Whse. Shipment"
{
    layout
    {
        addafter(Control1905767507)
        {
            part(MyWarehousePart; "Posted Whse. Pallet FactBox")
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
            action("Sticker Note")
            {
                image = PrintCover;
                ApplicationArea = all;
                Visible = PalletsExists;
                trigger OnAction()
                var
                    StickerNoteFunctions: Codeunit "Sticker note functions";
                    LWarehousepallet: Record "Posted Warehouse Pallet";
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
                        PageSelectPallets.SetPageType('PostedWarehouseShipment');
                        PageSelectPallets.SetPostedWarehouseShipment(Rec);
                        PageSelectPallets.RunModal();
                    end;

                    //  StickerNoteFunctions.CreatePalletStickerNoteFromPostedShipment(rec, 'BC');
                end;
            }
            /*    action("ConsugnmentNoteReportfortest")
                {
                    ApplicationArea = ALL;
                    // Visible = false;
                    trigger OnAction();
                    var
                        pcu: Codeunit "UI Pallet Functions";
                        PSL: Record "Posted Whse. Shipment lINE";
                    begin
                        PSL.Reset();
                        PSl.SetRange("No.", rEC."No.");
                        PSL.SetFilter("Source No.", '<>%1', '');
                        IF PSL.FindFirst() then
                            pcu.ConsugnmentNoteReportfortest(PSL
                            );
                    end;
                }*/
        }
    }
    trigger OnAfterGetRecord()
    begin
        PalletsExists := true;
        PostedWarehousePallets.reset;
        PostedWarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not PostedWarehousePallets.findset then
            PalletsExists := false;
    end;

    trigger OnOpenPage()
    begin
        PalletsExists := true;
        PostedWarehousePallets.reset;
        PostedWarehousePallets.setrange("Whse Shipment No.", rec."No.");
        if not PostedWarehousePallets.findset then
            PalletsExists := false;
    end;

    var
        PalletsExists: Boolean;
        PostedWarehousePallets: Record "Posted Warehouse Pallet";
}