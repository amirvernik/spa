page 60038 "Select Pallets"
{
    PageType = NavigatePage;
    UsageCategory = Administration;
    SourceTable = "Pallet Header";
    ModifyAllowed = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Check; Check)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Pallet ID"; "Pallet ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Pallet Status"; "Pallet Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage();
    begin
        if Rec.FindSet() then
            Rec.ModifyAll(Check, true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        StickerNoteFunctions: Codeunit "Sticker note functions";
        LPalletText: Text;
    begin
        case PageType of
            'WarehouseShipment':
                begin
                    LPalletText := '';
                    Rec.SetRange(Check, true);
                    IF rec.FindSet() then begin
                        repeat
                            If LPalletText = '' then
                                LPalletText := Rec."Pallet ID"
                            else
                                LPalletText += '|' + Rec."Pallet ID";
                        until Rec.Next() = 0;
                        StickerNoteFunctions.CreatePalletStickerNoteFromShipmentNew(GWarehouseShipment, LPalletText, 'BC');
                    end;
                end;
            'PostedWarehouseShipment':
                begin
                    LPalletText := '';
                    Rec.SetRange(Check, true);
                    IF rec.FindSet() then begin
                        repeat
                            If LPalletText = '' then
                                LPalletText := Rec."Pallet ID"
                            else
                                LPalletText += '|' + Rec."Pallet ID";
                        until Rec.Next() = 0;
                        StickerNoteFunctions.CreatePalletStickerNoteFromPostedShipmentNew(GPostedWarehouseShipment, LPalletText, 'BC');
                    end;
                end;
        end;
    end;

    procedure SetWarehouseShipment(pWarehouseShipment: Record "Warehouse Shipment Header")
    begin
        GWarehouseShipment := pWarehouseShipment;
    end;

    procedure SetPostedWarehouseShipment(pPostedWarehouseShipment: Record "Posted Whse. Shipment Header")
    begin
        GPostedWarehouseShipment := pPostedWarehouseShipment;
    end;

    procedure SetPageType(pPageType: Text)
    begin
        PageType := PageType;
    end;

    var
        PageType: Text;
        GPostedWarehouseShipment: Record "Posted Whse. Shipment Header";
        GWarehouseShipment: Record "Warehouse Shipment Header";

}