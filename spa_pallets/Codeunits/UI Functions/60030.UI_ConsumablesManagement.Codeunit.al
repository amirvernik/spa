codeunit 60030 "UI Consumables Management"
{
    //Consume Raw Material - ConsumeRawMaterial [9080]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure ConsumeRawMaterial(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        JsonObj: JsonObject;
        PalletLine: Record "Pallet Line";
        PalletID: Code[20];
        LineNumber: Integer;
        ConsumeQty: Decimal;

    begin
        IF pFunction <> 'ConsumeRawMaterial' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Here - the Json Read

        if PalletLine.get(PalletID, LineNumber) then begin
            PalletLedgerFunctions.ValueAddConsume(PalletLine, ConsumeQty);
            PalletLine."QTY Consumed" += ConsumeQty;
            PalletLine."Remaining Qty" := PalletLine.Quantity - PalletLine."QTY Consumed";
            PalletLine.modify;            
        end;
    end;

    //UnConsume Raw Material - UnConsumeRawMaterial [9081]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure UnConsumeRawMaterial(VAR pFunction: Text[50]; VAR pContent: Text)
    var
        ConsumeableFunctions: Codeunit "Consumables Management";
        JsonObj: JsonObject;
        PalletHeader: Record "Pallet Header";
        PalletID: Code[20];
    begin
        IF pFunction <> 'UnConsumeRawMaterial' THEN
            EXIT;

        JsonObj.ReadFrom(pContent);

        //Here - the Json Read
        if PalletHeader.get(PalletID) then begin
            ConsumeableFunctions.UnConsumeItems(PalletHeader);
        end;
    end;
}