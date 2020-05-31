codeunit 60026 "UI Pallet Dispose Functions"
{
    //Dispose A Pallet - DisposePallet [9003]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    local procedure DisposePallet(VAR pFunction: Text[50]; VAR pContent: Text)
    VAR
        PalletDisposalFunctions: Codeunit "Pallet Disposal Management";
        PalletHeader: Record "Pallet Header";
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        JsonArr: JsonArray;
        PalletID: Text[20];
        Searcher: Integer;
        ItemID: Text;
        QtyToAdjust: Decimal;
        QtyToAdjustText: Text;
        TempPackingMaterialsSelect: Record "Packing Materials Select" temporary;

    begin
        IF pFunction <> 'DisposePallet' THEN
            EXIT;

        if TempPackingMaterialsSelect.findset then
            TempPackingMaterialsSelect.deleteall;

        //Get Pallet ID
        JsonObj.ReadFrom(pContent);
        JsonObj.SelectToken('palletId', JsonTkn);
        PalletID := JsonTkn.AsValue().AsText();
        if PalletHeader.get(PalletID) then begin

            //Search Packing Materials
            JsonObj.SelectToken('packingMaterialsToAdjust', JsonTkn);
            JsonArr := JsonTkn.AsArray();

            Searcher := 0;

            while Searcher < JsonArr.Count do begin
                ItemID := '';
                QtyToAdjust := 0;

                JsonArr.Get(Searcher, JsonTkn);
                JsonObj := JsonTkn.AsObject();

                JsonObj.SelectToken('itemId', JsonTkn);
                ItemID := JsonTkn.AsValue().AsText();
                JsonObj.SelectToken('qty', JsonTkn);
                QtyToAdjust := JsonTkn.AsValue().AsDecimal();

                TempPackingMaterialsSelect.init;
                TempPackingMaterialsSelect."Pallet ID" := PalletID;
                TempPackingMaterialsSelect."PM Item No." := ItemID;
                TempPackingMaterialsSelect.insert;
                TempPackingMaterialsSelect."Pallet Packing Line No." := Searcher + 1;
                TempPackingMaterialsSelect.Quantity := QtyToAdjust;
                TempPackingMaterialsSelect.modify;
                Searcher += 1;
            end;
            pContent := '';

            PalletDisposalFunctions.CheckDisposalSetup(PalletHeader);
            PalletDisposalFunctions.ChangeDisposalStatus(PalletHeader);
            PalletDisposalFunctions.DisposePackingMaterialsUI(PalletHeader, TempPackingMaterialsSelect);
            PalletDisposalFunctions.DisposePalletItems(PalletHeader);
            PalletDisposalFunctions.PostDisposalBatch;
            pContent := 'Success';
        end
        else
            pContent := 'Pallet does not exist';
    end;

}