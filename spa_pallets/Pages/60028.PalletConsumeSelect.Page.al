page 60028 "Pallet Consume Select"
{

    PageType = StandardDialog;
    SourceTable = "Pallet Consume Line";
    Caption = 'Select Consumeables';
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            label(LblMessage)

            {
                Style = Strong;
                Caption = 'Please choose quantities to consume on Raw Materials';

            }
            repeater(General)
            {
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Remaining Qty"; "Remaining Qty")
                {
                    ApplicationArea = all;
                    editable = false;
                }
                field("Consumed Qty"; "Consumed Qty")
                {
                    ApplicationArea = all;
                    editable = true;
                }

            }
        }
    }
    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        PackingTrackingLine: Record "Packing Material Line";
        PalletLine: Record "Pallet Line";
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletHeader: Record "Pallet Header";
    begin
        if CloseAction = action::OK then begin
            rec.reset;
            if rec.findset then
                repeat
                    PalletHeader.get(rec."Pallet ID");
                    if PalletLine.get(rec."Pallet ID", rec."Pallet Line") then begin
                        PalletLine."QTY Consumed" += rec."Consumed Qty";
                        PalletLine."Remaining Qty" := PalletLine.Quantity - PalletLine."QTY Consumed";
                        PalletLine.modify;
                        PalletLedgerFunctions.ValueAddConsume(PalletLine, rec."Consumed Qty");
                    end;
                until rec.next = 0;

            PalletLine.reset;
            PalletLine.setrange("Pallet ID", PalletHeader."Pallet ID");
            PalletLine.setfilter("Remaining Qty", '<>%1', 0);
            if PalletLine.FindFirst() then begin
                PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::"Partially consumed";
                PalletHeader.modify;
            end
            else begin
                PalletHeader."Pallet Status" := PalletHeader."Pallet Status"::Consumed;
                PalletHeader.modify;
            end;
        end;
    end;
}