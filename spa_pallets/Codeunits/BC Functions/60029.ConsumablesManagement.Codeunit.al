codeunit 60029 "Consumables Management"
{

    procedure ConsumeItems(var pPalletHeader: Record "Pallet Header")
    var
        ConsumLineSelect: Record "Pallet Consume Line" temporary;
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletLine: Record "Pallet Line";
    begin
        if ConsumLineSelect.findset then
            ConsumLineSelect.deleteall;

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PalletLine.findset then
            repeat
                ConsumLineSelect.init;
                ConsumLineSelect."Pallet ID" := PalletLine."Pallet ID";
                ConsumLineSelect."Pallet Line" := PalletLine."Line No.";
                ConsumLineSelect."Item No." := PalletLine."Item No.";
                ConsumLineSelect."Variant Code" := PalletLine."Variant Code";
                ConsumLineSelect.Description := PalletLine.Description;
                ConsumLineSelect.Quantity := PalletLine.Quantity;
                ConsumLineSelect."Remaining Qty" := PalletLine."Remaining Qty";
                ConsumLineSelect."Consumed Qty" := PalletLine."Remaining Qty";
                ConsumLineSelect.insert;
            until PalletLine.next = 0;
        page.runmodal(page::"Pallet Consume Select", ConsumLineSelect);

        ConsumLineSelect.reset;
        ConsumLineSelect.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if ConsumLineSelect.findset then
            repeat
                if PalletLine.get(ConsumLineSelect."Pallet ID", ConsumLineSelect."Pallet Line") then begin
                    PalletLine."QTY Consumed" += ConsumLineSelect."Consumed Qty";
                    PalletLine."Remaining Qty" := PalletLine.Quantity - PalletLine."QTY Consumed";
                    PalletLine.modify;
                    PalletLedgerFunctions.ValueAddConsume(PalletLine, ConsumLineSelect."Consumed Qty");
                end;
            until ConsumLineSelect.next = 0;

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletHeader."Pallet ID");
        PalletLine.setfilter("Remaining Qty", '<>%1', 0);
        if PalletLine.FindFirst() then begin
            pPalletHeader."Pallet Status" := pPalletHeader."Pallet Status"::"Partially consumed";
            pPalletHeader.modify;
        end
        else begin
            pPalletHeader."Pallet Status" := pPalletHeader."Pallet Status"::Consumed;
            pPalletHeader.modify;
        end;
    end;

    procedure UnConsumeItems(var pPalletHeader: Record "Pallet Header")
    var
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletLine: Record "Pallet Line";
    begin
        pPalletHeader."pallet status" := pPalletHeader."Pallet Status"::Closed;
        pPalletHeader.modify;
        PalletLedgerFunctions.ValueAddunConsume(pPalletHeader);
    end;

}