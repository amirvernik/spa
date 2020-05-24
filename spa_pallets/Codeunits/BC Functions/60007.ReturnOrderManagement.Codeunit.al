codeunit 60007 "Return Order Management"
{

    //On After Copy Sales Line From Sales Shpt Line Buffer
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesLineFromSalesShptLineBuffer', '', true, true)]
    local procedure OnAfterCopySalesLinesToDoc(FromSalesShipmentLine: Record "Sales Shipment Line"; var ToSalesLine: Record "Sales Line")
    begin
        ToSalesLine."SPA Order No." := FromSalesShipmentLine."Order No.";
        ToSalesLine."SPA Order Line No." := FromSalesShipmentLine."Order Line No.";
        PalletLedgerEntry.reset;
        PalletLedgerEntry.SetRange(PalletLedgerEntry."Entry Type", PalletLedgerEntry."Entry Type"::"Sales Shipment");
        PalletLedgerEntry.setrange(PalletLedgerEntry."Order No.", FromSalesShipmentLine."Order No.");
        PalletLedgerEntry.setrange(PalletLedgerEntry."Order Line No.", FromSalesShipmentLine."Order Line No.");
        PalletLedgerEntry.setrange("Order Type", 'Sales Order');
        if PalletLedgerEntry.findfirst then
            ToSalesLine."Pallet/s Exist" := true;
        ToSalesLine.modify;

    end;

    //On After Return Rcpt Line Insert
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterReturnRcptLineInsert', '', true, true)]
    local procedure OnAfterReturnRcptLineInsert(var ReturnRcptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
        PalletLedgerFunctions.PalletLedgerEntryReturnReceipt(ReturnRcptLine, SalesLine);
    end;

    var
        TempLines: Integer;
        OriginalLines: Integer;
        BoolError: Boolean;
        SalesLine: Record "Sales Line";
        PalletHeader: Record "Pallet Header";
        PalletLines: Record "Pallet Line";
        PalletHeader_Temp: Record "Pallet Header" temporary;
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletLine_Temp: Record "Pallet Line" temporary;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        Err001: label 'The return shipment contains at least one pallet that is not fully return, make sure that the return pallet content is the same as in the posted sales shipment';
        Msg001: label 'Do the pallet/s contains packing materials?';

}