codeunit 60027 "UI Change Quality Functions"
{
    //Change Item in Pallet - ChangeItemInPallet
    [EventSubscriber(ObjectType::Codeunit, Codeunit::UIFunctions, 'WSPublisher', '', true, true)]
    procedure ChangeItemInPallet(VAR pFunction: Text[50]; VAR pContent: Text)

    begin
        IF pFunction <> 'ChangeItemInPallet' THEN
            EXIT;

        //Get Pallet ID
        JsonObj.ReadFrom(pContent);

        //Get Pallet ID
        JsonObj.SelectToken('palletId', JsonTkn);
        PalletID := JsonTkn.AsValue().AsText();

        //Get Old Item 
        JsonObj.SelectToken('oldItemId', JsonTkn);
        oldItemId := JsonTkn.AsValue().AsText();

        //Get Old Variant
        JsonObj.SelectToken('oldVariety', JsonTkn);
        oldVariety := JsonTkn.AsValue().AsText();

        //Get Qty to Remove
        JsonObj.SelectToken('qtyToRemove', JsonTkn);
        qtyToRemove := JsonTkn.AsValue().AsDecimal();

        //Get New Item ID
        JsonObj.SelectToken('newItemId', JsonTkn);
        newItemId := JsonTkn.AsValue().AsText();

        //Get New Variant code
        JsonObj.SelectToken('newVariety', JsonTkn);
        newVariety := JsonTkn.AsValue().AsText();

        //Get New Unit of Measure code
        JsonObj.SelectToken('newUM', JsonTkn);
        newUM := JsonTkn.AsValue().AsText();

        //Get New Quantity to Add
        JsonObj.SelectToken('qtyToAdd', JsonTkn);
        qtyToAdd := JsonTkn.AsValue().AsDecimal();

        CalcChangeQuality(palletId);
        PalletLineChangeQuality.reset;
        PalletLineChangeQuality.setrange("Pallet ID", PalletID);
        PalletLineChangeQuality.setrange("User ID", userid);
        if PalletLineChangeQuality.findfirst then begin

            ChangeQualityMgmt.NegAdjChangeQuality(PalletLineChangeQuality); //Negative Change Quality  
            ChangeQualityMgmt.PostItemLedger(); //Post Neg Item Journals to New Items                 
            ChangeQualityMgmt.ChangeQuantitiesOnPalletline(PalletLineChangeQuality); //Change Quantities on Pallet Line                    
            ChangeQualityMgmt.ChangePalletReservation(PalletLineChangeQuality); //Change Pallet Reservation Line                    
            ChangeQualityMgmt.PalletLedgerAdjustOld(PalletLineChangeQuality); //Adjust Pallet Ledger Entries - Old Items                   
            ChangeQualityMgmt.AddNewItemsToPallet(PalletLineChangeQuality); //Add New Lines                    
            ChangeQualityMgmt.PosAdjNewItems(PalletLineChangeQuality); //Positive Adj to New Lines
            ChangeQualityMgmt.PostItemLedger(); //Post Pos Item Journals to New Items                    
            ChangeQualityMgmt.NegAdjToNewPacking(PalletLineChangeQuality); //Neg ADjustment to New Packing Materials
            ChangeQualityMgmt.PostItemLedger(); //Post Pos Item Journals to New Items                                        
            ChangeQualityMgmt.AddPackingMaterialsToExisting(PalletLineChangeQuality); //Add Packing Materials to Existing Packing Materials
            if GetLastErrorText = '' then
                pContent := 'Success' else
                pcontent := 'Error : ' + GetLastErrorText;
        end;
    end;


    //Calc Change Quality
    local procedure CalcChangeQuality(var pPalletID: Code[20])

    begin
        PalletLineChange.reset;
        PalletLineChange.SetRange("User Created", UserId);
        if PalletLineChange.findset then
            PalletLineChange.DeleteAll();

        PalletLineChangeQuality.reset;
        PalletLineChangeQuality.setrange("User ID", UserId);
        if PalletLineChangeQuality.findset then
            PalletLineChangeQuality.DeleteAll();

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletId);
        if PalletLine.findset then
            repeat
                PalletLineChangeQuality.init;
                PalletLineChangeQuality.TransferFields(PalletLine);
                PalletLineChangeQuality."User ID" := UserId;
                PalletLineChangeQuality."Replaced Qty" := PalletLineChangeQuality.Quantity - qtyToRemove;
                PalletLineChangeQuality.insert;

                PalletLineChange.init;
                PalletLineChange."Pallet ID" := PalletLine."Pallet ID";
                PalletLineChange."Pallet Line No." := PalletLine."Line No.";
                PalletLineChange."Line No." := 10000;
                PalletLineChange."New Item No." := newItemId;
                PalletLineChange."New Variant Code" := newVariety;
                if Item.get(newItemId) then
                    PalletLineChange.Description := item.Description;
                if ItemVariant.get(newItemId, newVariety) then
                    PalletLineChange.Description := ItemVariant.Description;
                PalletLineChange."Unit of Measure" := newUM;
                PalletLineChange."New Quantity" := qtyToAdd;
                PalletLineChange."User Created" := userid;
                PalletLineChange.insert;


            until palletline.next = 0;


    end;

    var
        Item: Record Item;
        PalletLine: Record "Pallet Line";
        ItemVariant: Record "Item Variant";
        PalletLineChange: Record "Pallet Change Quality";
        PalletLineChangeQuality: Record "Pallet Line Change Quality";
        ChangeQualityMgmt: Codeunit "Change Quality Management";
        JsonObj: JsonObject;
        JsonTkn: JsonToken;
        JsonArr: JsonArray;
        palletId: code[20];
        oldItemId: code[20];
        oldVariety: code[20];
        qtyToRemove: Decimal;
        newItemId: code[20];
        newVariety: code[10];
        newUM: code[20];
        qtyToAdd: Decimal;

}