codeunit 60000 "SPA Purchase Functions"
{

    //OnBeforePost - Purchase Document (Order) - Only on Grading Result PO
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', true, true)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        //PrePack Waste on Value Add - Addition
        /*if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            if PurchaseHeader."Microwave Process PO" then
                if PurchaseHeader."Scrap QTY (KG)" = 0 then
                    Error(Err005);*/

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            if PurchaseHeader."Grading Result PO" then
                FctCheckReleasePO(PurchaseHeader);
    end;

    //OnBefore New PO - Select Template
    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnNewRecordEvent', '', true, true)]
    procedure FctOnNewPO(var Rec: Record "Purchase Header")
    begin
        //if rec."No." <> '' then begin
        Selection := STRMENU(TypeOfPO, 1, TypeOfPOTitle);
        if selection = 0 then
            exit;
        if selection = 2 then begin
            RecSPASetup.get;
            rec."Grading Result PO" := true;
            rec."Batch Number" := NoSeriesManagement.GetNextNo(RecSPASetup."Batch No. Series", today, true);
        end;
        if Selection = 3 then
            rec."Microwave Process PO" := true;
        //end;
    end;

    //Check Release - Purchase Order
    [EventSubscriber(ObjectType::page, page::"Purchase Order", 'OnBeforeActionEvent', 'Release', true, true)]
    procedure FctOnBeforeReleasePO_Card(VAR Rec: Record "Purchase Header")
    begin
        FctCheckReleasePO(rec);
    end;

    //Check Release - Purchase Order List
    [EventSubscriber(ObjectType::page, page::"Purchase Order List", 'OnBeforeActionEvent', 'Release', true, true)]
    procedure FctOnBeforeReleasePO_List(VAR Rec: Record "Purchase Header")
    begin
        FctCheckReleasePO(rec);
    end;

    //Release PO - Local Procedure
    procedure FctCheckReleasePO(pPurchaseHeader: Record "Purchase Header");
    var
        PurchaseLine: Record "purchase line";
        ItemRec: Record item;
        maxEntry: Integer;

    begin
        //PrePack Waste on Value Add - Addition
        /*if pPurchaseHeader."Microwave Process PO" then
            if pPurchaseHeader."Scrap QTY (KG)" = 0 then
                error(Err005);*/

        if pPurchaseHeader."Grading Result PO" then
            if ((pPurchaseHeader."Number Of Raw Material Bins" = 0) or (pPurchaseHeader."Harvest Date" = 0D))
                then
                error(err001);

        //Removed By Oren Ask - TFS98096
        /*if pPurchaseHeader."Microwave Process PO" then begin
            if ((pPurchaseHeader."Raw Material Item" = '') or (pPurchaseHeader."RM Location" = '')
                or (pPurchaseHeader."RM Qty" = 0) or (pPurchaseHeader."Item LOT Number" = ''))
                    then
                error(err003);
        end;*/

        if ((pPurchaseHeader."Vendor Shipment No." = '') and (pPurchaseHeader."Grading Result PO" = true)) then
            error(Err004);

        if ((pPurchaseHeader."Grading Result PO" = true) or (pPurchaseHeader."Microwave Process PO" = true)) then begin
            PurchaseLine.reset;
            PurchaseLine.setrange("Document Type", pPurchaseHeader."Document Type");
            PurchaseLine.setrange("Document No.", pPurchaseHeader."No.");
            PurchaseLine.setfilter("Outstanding Quantity", '<>%1', 0);
            if PurchaseLine.findset then
                repeat
                    if ItemRec.get(PurchaseLine."No.") then
                        if itemrec."Lot Nos." <> '' then begin
                            //Create Reservation Entry
                            RecGReservationEntry2.reset;
                            if RecGReservationEntry2.findlast then
                                maxEntry := RecGReservationEntry2."Entry No." + 1;
                            RecGReservationEntry2.reset;
                            RecGReservationEntry2.setrange(RecGReservationEntry2."Source ID", PurchaseLine."Document No.");
                            RecGReservationEntry2.setrange(RecGReservationEntry2."Source Ref. No.", PurchaseLine."Line No.");
                            RecGReservationEntry2.setrange(RecGReservationEntry2."Source Type", 39);
                            RecGReservationEntry2.setrange(RecGReservationEntry2."Source Subtype", 1);
                            if not RecGReservationEntry2.findfirst then begin
                                RecGReservationEntry.init;
                                RecGReservationEntry."Entry No." := MaxEntry;
                                //V16.0 - Changed From [2] to "surplus" on Enum
                                RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Surplus;
                                //V16.0 - Changed From [2] to "surplus" on Enum
                                RecGReservationEntry."Creation Date" := Today;
                                RecGReservationEntry."Created By" := UserId;
                                RecGReservationEntry."Expected Receipt Date" := Today;
                                RecGReservationEntry.Positive := true;
                                RecGReservationEntry."Source Type" := 39;
                                RecGReservationEntry."Source Subtype" := 1;
                                RecGReservationEntry."Source ID" := PurchaseLine."Document No.";
                                RecGReservationEntry."Source Ref. No." := PurchaseLine."Line No.";
                                RecGReservationEntry.validate("Location Code", PurchaseLine."Location Code");
                                //V16.0 - Changed From [1] to "Lot No." on Enum
                                RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                //V16.0 - Changed From [1] to "Lot No." on Enum
                                RecGReservationEntry."Lot No." := pPurchaseHeader."Batch Number";
                                RecGReservationEntry.validate("Item No.", PurchaseLine."No.");
                                RecGReservationEntry.validate("Variant Code", PurchaseLine."Variant Code");
                                RecGReservationEntry."Variant Code" := PurchaseLine."Variant Code";
                                RecGReservationEntry.Description := PurchaseLine.Description;
                                RecGReservationEntry.validate("Quantity (Base)", purchaseline."Qty. (Base) SPA");
                                RecGReservationEntry.validate(Quantity, purchaseline.Quantity);
                                RecGReservationEntry."Packing Date" := today;
                                /*if format(ItemRec."Expiration Calculation") <> '' then
                                    RecGReservationEntry."Expiration Date" := calcdate('+' + format(ItemRec."Expiration Calculation"), today)
                                else
                                    RecGReservationEntry."Expiration Date" := today;*/
                                RecGReservationEntry.insert;
                            end;
                        end;
                until PurchaseLine.next = 0;
        end;
    end;

    Procedure CreateRMNegativeAdjustment(pPurchaseHeader: Record "Purchase Header")
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        maxEntry: Integer;
        ItemRec: Record Item;

    begin
        //Inserting Item Journal - Positive Adjustment
        if pPurchaseHeader."Microwave Process PO" then
            if pPurchaseHeader."RM Add Neg" = false then begin
                PurchaseProcessSetup.get();
                ItemJournalLine.reset;
                ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                if ItemJournalLine.FindLast() then
                    LineNumber := ItemJournalLine."Line No." + 10000
                else
                    LineNumber := 10000;

                ItemJournalLine.init;
                ItemJournalLine."Journal Template Name" := 'ITEM';
                ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                ItemJournalLine."Line No." := LineNumber;
                ItemJournalLine.insert;
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                ItemJournalLine."Posting Date" := Today;
                ItemJournalLine."Document No." := pPurchaseHeader."No.";
                ItemJournalLine."Document Date" := today;
                ItemJournalLine.validate("Item No.", pPurchaseHeader."Raw Material Item");
                ItemJournalLine.validate("Location Code", pPurchaseHeader."RM Location");
                ItemJournalLine.validate(Quantity, pPurchaseHeader."RM Qty");
                ItemJournalLine.modify;

                //Create Reservation Entry
                if ItemRec.get(pPurchaseHeader."Raw Material Item") then
                    if Itemrec."Lot Nos." <> '' then begin
                        RecGReservationEntry2.reset;
                        if RecGReservationEntry2.findlast then
                            maxEntry := RecGReservationEntry2."Entry No." + 1;

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        //V16.0 - Changed From [3] to "Prospect" on Enum
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                        //V16.0 - Changed From [3] to "Prospect" on Enum
                        RecGReservationEntry."Creation Date" := Today;
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := Today;
                        RecGReservationEntry."Source Type" := 83;
                        RecGReservationEntry."Source Subtype" := 3;
                        RecGReservationEntry."Source ID" := 'ITEM';
                        RecGReservationEntry."Source Ref. No." := LineNumber;
                        RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        RecGReservationEntry.validate("Location Code", pPurchaseHeader."RM Location");
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        //V16.0 - Changed From [1] to "Lot No." on Enum
                        RecGReservationEntry."Lot No." := pPurchaseHeader."Item LOT Number";
                        RecGReservationEntry.validate("Item No.", pPurchaseHeader."Raw Material Item");
                        RecGReservationEntry.validate("Quantity (Base)", -1 * pPurchaseHeader."RM Qty");
                        RecGReservationEntry.validate(Quantity, -1 * pPurchaseHeader."RM Qty");
                        RecGReservationEntry.Positive := false;
                        RecGReservationEntry.insert;

                        //Post the Journal
                        ItemJournalLine.reset;
                        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                        ItemJournalLine.setrange(ItemJournalLine."Document No.", pPurchaseHeader."No.");
                        if ItemJournalLine.findset() then
                            CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
                        pPurchaseHeader."RM Add Neg" := true;
                        pPurchaseHeader.modify;
                    end;
            end;
    end;

    procedure LookupItemsForVendors(var pVendor: code[20]; var pDate: date; var RetPurchasePrice: Record "Purchase Price")
    var
        ItemList: Page "Item List";
        ItemRec: Record Item;
        Vendor: Record Vendor;
        PurchaseCalculation: Codeunit "Price Calculation - V16";
        TempPriceListLine: Record "Price List Line" temporary;
        ItemSelectByVendor: Record "Item Select By Vendor" temporary;
    begin
        PurchasePrice.reset;
        PurchasePrice.setrange("Vendor No.", pVendor);
        PurchasePrice.SetFilter("Ending Date", '=%1 | >=%2', 0D, pDate);
        PurchasePrice.setfilter("Starting Date", '=%1 | <=%2', 0D, pdate);
        if PurchasePrice.findset then
            repeat
                if not ItemSelectByVendor.get(PurchasePrice."Item No.",
                    PurchasePrice."Variant Code", PurchasePrice."Unit of Measure Code") then begin
                    ItemSelectByVendor.init;
                    ItemSelectByVendor."Item No." := PurchasePrice."Item No.";
                    ItemSelectByVendor."Variant Code" := PurchasePrice."Variant Code";
                    ItemSelectByVendor."Unit of Measure" := PurchasePrice."Unit of Measure Code";
                    ItemSelectByVendor."Direct Unit Cost" := PurchasePrice."Direct Unit Cost";
                    if ItemRec.get(PurchasePrice."Item No.") then
                        ItemSelectByVendor."Item Description" := ItemRec.Description;
                    ItemSelectByVendor.insert;
                end;
            until PurchasePrice.next = 0;

        IF PAGE.RUNMODAL(0, ItemSelectByVendor) = ACTION::LookupOK THEN begin
            RetPurchasePrice.reset;
            RetPurchasePrice.setrange("Vendor No.", pVendor);
            RetPurchasePrice.SetFilter("Ending Date", '=%1 | >=%2', 0D, pDate);
            RetPurchasePrice.setfilter("Starting Date", '=%1 | <=%2', 0D, pdate);
            RetPurchasePrice.setfilter("Item No.", ItemSelectByVendor."Item No.");
            RetPurchasePrice.setfilter("Variant Code", ItemSelectByVendor."Variant Code");
            RetPurchasePrice.SetFilter("Unit of Measure Code", ItemSelectByVendor."Unit of Measure");
            if RetPurchasePrice.findfirst then;
        end;
    end;

    procedure LookupNotItems(pType: Text): code[20]
    var
        GlAccount: Record "G/L Account";
        ResourceRec: Record Resource;
        FixedAsset: Record "Fixed Asset";
        ItemCharges: Record "Item Charge";
        ItemRec: Record Item;
    begin
        if pType = 'ITM' then begin
            ItemRec.reset;
            if ItemRec.FindSet then begin
                IF PAGE.RUNMODAL(0, ItemRec) = ACTION::LookupOK THEN
                    exit(ItemRec."No.");
            end;
        end;

        if pType = 'GL' then begin
            GlAccount.reset;
            if GlAccount.FindSet then begin
                IF PAGE.RUNMODAL(0, GlAccount) = ACTION::LookupOK THEN
                    exit(GlAccount."No.");
            end;
        end;
        if pType = 'FA' then begin
            FixedAsset.reset;
            if FixedAsset.FindSet then begin
                IF PAGE.RUNMODAL(0, FixedAsset) = ACTION::LookupOK THEN
                    exit(FixedAsset."No.");
            end;
        end;
        if pType = 'RES' then begin
            ResourceRec.reset;
            if ResourceRec.FindSet then begin
                IF PAGE.RUNMODAL(0, ResourceRec) = ACTION::LookupOK THEN
                    exit(ResourceRec."No.");
            end;
        end;
        if pType = 'CHRG' then begin
            ItemCharges.reset;
            if ItemCharges.FindSet then begin
                IF PAGE.RUNMODAL(0, ItemCharges) = ACTION::LookupOK THEN
                    exit(ItemCharges."No.");
            end;
        end;

    end;

    procedure ValidateItemsForVendors(var pVendor: code[20]; var pDate: date; var pItem: code[20]; var RetPurchasePrice: Record "Purchase Price");
    var
        ErrVendorItem: Label 'Item does not Exist on Vendor Price List';
        ItemRec: Record item;
        PurchasePrice: Record "Purchase Price";
        BoolResult: Boolean;
    begin
        BoolResult := false;
        if ItemRec.get(pItem) then begin
            PurchasePrice.reset;
            PurchasePrice.setrange("Vendor No.", pVendor);
            PurchasePrice.SetFilter("Ending Date", '=%1 | >=%2', 0D, pDate);
            PurchasePrice.setfilter("Starting Date", '=%1 | <=%2', 0D, pdate);
            PurchasePrice.setrange("Item No.", pItem);
            PurchasePrice.setfilter("Unit of Measure Code", itemrec."Base Unit of Measure");
            if PurchasePrice.findfirst then begin
                RetPurchasePrice.Copy(PurchasePrice);
                BoolResult := true;
            end
            else begin
                PurchasePrice.reset;
                PurchasePrice.setrange("Vendor No.", pVendor);
                PurchasePrice.SetFilter("Ending Date", '=%1 | >=%2', 0D, pDate);
                PurchasePrice.setfilter("Starting Date", '=%1 | <=%2', 0D, pdate);
                PurchasePrice.setrange("Item No.", pItem);
                PurchasePrice.setfilter("Unit of Measure Code", '<>%1', itemrec."Base Unit of Measure");
                if PurchasePrice.findfirst then begin
                    RetPurchasePrice.copy(PurchasePrice);
                    BoolResult := true;
                end;
            end;
        end;
        if not BoolResult then
            error(ErrVendorItem);
    end;

    //Get SPecial Price
    procedure GetSpecialPrice(var pVendor: code[20]; var pDate: date; var pItem: code[20]): Decimal
    begin
        PurchasePrice.reset;
        PurchasePrice.setrange("Vendor No.", pVendor);
        PurchasePrice.setfilter("Ending Date", '=%1 | >=%2', 0D, pDate);
        PurchasePrice.setfilter("Starting Date", '=%1 | <=%2', 0D, pdate);
        PurchasePrice.setrange("Item No.", pItem);
        if PurchasePrice.findfirst then
            exit(PurchasePrice."Direct Unit Cost");
    end;

    var
        TypeOfPO: Label 'Regular PO,Grading Result PO,Value Add PO';
        TypeOfPOTitle: Label 'Select Purchase Order Type';
        Err001: label 'Grade Result PO Must have Number of raw material bins/Harvest Date, Cant Release';
        Err002: label 'Grade Result PO Must have Number of raw material bins/Harvest Date, Cant Post';
        Err003: label 'This is a Microwave PO Process, You must Edit RAW Material Data';
        Err004: label 'You must enter Vendor Shipment No.';
        Err005: label 'You need to enter a Prepack Waste';
        Selection: Integer;
        RecGItemJournalLine: Record "Item Journal Line";
        RecPurchaseLine: Record "Purchase Line";
        RecPurchaseHeader: Record "Purchase Header";
        RecGReservationEntry: record "Reservation Entry";
        RecGReservationEntry2: record "Reservation Entry";
        RecGLotInformation: Record "Lot No. Information";
        LineNumber: Integer;
        MaxEntry: integer;
        ReservEntry: Record "Reservation Entry";
        RecGItem: Record item;
        RecSPASetup: Record "SPA Purchase Process Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        PurchasePrice: Record "Purchase Price"; //Mark for Removal [V16.0]

}