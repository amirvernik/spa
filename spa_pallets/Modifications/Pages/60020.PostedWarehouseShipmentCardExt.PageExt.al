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
                begin
                    StickerNoteFunctions.CreatePalletStickerNoteFromPostedShipment(rec, 'BC');
                end;
            }
            /*   action("ConsugnmentNoteReportfortest")
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