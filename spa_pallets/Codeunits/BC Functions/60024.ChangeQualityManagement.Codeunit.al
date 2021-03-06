codeunit 60024 "Change Quality Management"
{
    [EventSubscriber(ObjectType::table, database::"Pallet Change Quality", 'OnAfterValidateEvent', 'New Variant Code', true, true)]
    local procedure OnAfterValidateItemVariant(var Rec: Record "Pallet Change Quality")
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Reset();
        ItemVariant.setrange(code, rec."New Variant Code");
        ItemVariant.setrange("Item No.", rec."New Item No.");
        if ItemVariant.findfirst then begin
            Rec.Description := ItemVariant.Description;
            rec.modify;
        end;
    end;

    [EventSubscriber(ObjectType::table, database::"Pallet Line Change Quality", 'OnAfterValidateEvent', 'Replaced Qty', true, true)]
    local procedure OnAfterValidateReplacedQty(var Rec: Record "Pallet Line Change Quality")
    var
        ErrReplacedQty: label 'You cannot replace quantity %1 that is bigger than %2';
    begin
        if rec."Replaced Qty" > rec.Quantity then
            error(ErrReplacedQty, format(rec."Replaced Qty"), format(rec.Quantity));
    end;

    //Check Negative to Packing Materials
    Procedure ValidatePackMaterialsCreate(var pPalletLineChg: Record "Pallet Line Change Quality"): code[20]
    var
        PalletID: code[20];
        PalletLineTemp: Record "Pallet Line" temporary;
        PalletItemChgLine: Record "Pallet Change Quality";
        PalletLine: Record "Pallet Line";
        BomComponent: Record "BOM Component";
        PackingMaterialsTemp: Record "Packing Material Line" temporary;
        PalletHeader: Record "Pallet Header";
        LineNumberPacking: Integer;
        BoolSuficient: Boolean;
        ItemLedgerEntry: Record "Item Ledger Entry";
        SumInventory: Decimal;
        PackingMaterialItem: code[20];
        PackingMaterials: Record "Packing Material Line";
        PalletLineNo: Integer;
    begin
        if PalletLineTemp.FindSet() then PalletLineTemp.DeleteAll();

        PalletID := pPalletLineChg."Pallet ID";
        pPalletLineChg.reset;
        pPalletLineChg.SetRange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        if pPalletLineChg.findset then
            repeat
                PalletItemChgLine.reset;
                PalletItemChgLine.setrange("Pallet ID", pPalletLineChg."Pallet ID");
                PalletItemChgLine.setrange("User Created", UserId);
                PalletItemChgLine.SetRange("Pallet Line No.", pPalletLineChg."Line No.");
                if PalletItemChgLine.FindFirst() then begin
                    //Adding Old Item to Temp Table
                    //if PalletLine.get(pPalletLineChg."Pallet ID", pPalletLineChg."Line No.") then begin
                    PalletLineTemp.init;
                    PalletLineTemp."Pallet ID" := pPalletLineChg."Pallet ID";
                    PalletLineTemp."Line No." := GetLastPalletLine(pPalletLineChg."Pallet ID");
                    PalletLineTemp.validate("Item No.", PalletItemChgLine."New Item No.");
                    PalletLineTemp."Location Code" := pPalletLineChg."Location Code";
                    PalletLineTemp."Lot Number" := pPalletLineChg."Lot Number";
                    PalletLineTemp.Quantity := PalletItemChgLine."New Quantity";
                    PalletLineTemp."Remaining Qty" := PalletItemChgLine."New Quantity";
                    PalletLineTemp.validate("Unit of Measure", PalletItemChgLine."Unit of Measure");
                    PalletLineTemp.validate("Variant Code", PalletItemChgLine."New Variant Code");
                    PalletLineTemp."Purchase Order No." := pPalletLineChg."Purchase Order No.";
                    PalletLineTemp."Purchase Order Line No." := pPalletLineChg."Purchase Order Line No.";
                    PalletLineTemp.Replaced := true;
                    PalletLineTemp."User ID" := UserId;
                    PalletLineTemp.insert;
                    // end;
                end;
            until pPalletLineChg.next = 0;



        //Validate Sufficient - Build Temp Tracking
        PalletHeader.get(PalletID);
        PalletLineTemp.reset;
        PalletLineTemp.setrange("Pallet ID", PalletID);
        if PalletLineTemp.FindFirst() then begin
            BomComponent.reset;
            BomComponent.setrange("Parent Item No.", PalletLineTemp."Item No.");
            if BomComponent.findset then
                repeat
                    if not PackingMaterialsTemp.get(PalletLineTemp."Pallet ID",
                        BomComponent."No.", BomComponent."Unit of Measure Code") then begin

                        PackingMaterialsTemp.reset;
                        PackingMaterialsTemp.SetRange("Pallet ID", PalletID);
                        if PackingMaterialsTemp.findlast then
                            LineNumberPacking := PackingMaterialsTemp."Line No." + 1
                        else
                            LineNumberPacking := 1;

                        PackingMaterialsTemp.init;
                        PackingMaterialsTemp."Pallet ID" := PalletLineTemp."Pallet ID";
                        PackingMaterialsTemp."Item No." := BomComponent."No.";
                        PackingMaterialsTemp."Line No." := LineNumberPacking;
                        PackingMaterialsTemp.Description := BomComponent.Description;
                        PackingMaterialsTemp."Reusable Item" := BomComponent."Reusable item";
                        if BomComponent."Fixed Value" then
                            PackingMaterialsTemp.Quantity := BomComponent."Quantity per"
                        else
                            PackingMaterialsTemp.Quantity := BomComponent."Quantity per" * PalletLineTemp.Quantity;
                        PackingMaterialsTemp."Unit of Measure Code" := BomComponent."Unit of Measure Code";
                        PackingMaterialsTemp."Location Code" := PalletHeader."Location Code";
                        PackingMaterialsTemp.insert;
                    end
                    else begin
                        PackingMaterialsTemp.Quantity += BomComponent."Quantity per" * PalletLineTemp.Quantity;
                        PackingMaterialsTemp.modify;
                    end;
                until BomComponent.next = 0;
        end;


        //Validate Sufficient - check Existing
        BoolSuficient := true;
        PackingMaterialsTemp.reset;
        if PackingMaterialsTemp.findset then
            repeat
                if BoolSuficient then begin
                    SumInventory := 0;
                    ItemLedgerEntry.reset;
                    ItemLedgerEntry.setrange("Item No.", PackingMaterialsTemp."Item No.");
                    ItemLedgerEntry.setrange("Location Code", PackingMaterialsTemp."Location Code");
                    if ItemLedgerEntry.findset then
                        repeat
                            SumInventory += ItemLedgerEntry.Quantity;
                        until ItemLedgerEntry.next = 0;
                    if SumInventory < 0 then begin
                        PackingMaterialItem := ItemLedgerEntry."Item No.";
                        BoolSuficient := false;
                    end;
                end;
            until PackingMaterialsTemp.next = 0;

        if PalletLineTemp.FindSet() then PalletLineTemp.DeleteAll();

        if not BoolSuficient then
            exit(PackingMaterialItem) else
            exit('');
    end;

    //Check to See if all lines needs to be adjusted
    procedure CheckChangeItem(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletID: Code[20];
        BadCount: Boolean;
        ErrorToChange: Label 'Cannot change, please update new Qty to be different than Qty';
    begin
        BadCount := false;
        PalletID := pPalletLineChg."Pallet ID";
        pPalletLineChg.reset;
        pPalletLineChg.SetRange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        if pPalletLineChg.findset then
            repeat
                if pPalletLineChg.Quantity = pPalletLineChg."Replaced Qty" then
                    BadCount := true;
            until pPalletLineChg.next = 0;
        if BadCount then Error(ErrorToChange);
    end;

    //Negative Adjustment to The Items
    procedure NegAdjChangeQuality(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        ItemRec: Record item;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        PalletLedgerType: Enum "Pallet Ledger Type";
        MaxEntry: Integer;
        PalletID: Code[20];
        PalletLineNo: Integer;
        LPalletLine: Record "Pallet Line";
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletChangeQuality: Record "Pallet Change Quality";
        LineNoOriginal: Integer;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin

        PurchaseProcessSetup.get();
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        if ItemJournalLine.FindLast() then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";

        pPalletLineChg.reset;
        pPalletLineChg.SetRange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.findset then
            repeat
                PalletChangeQuality.Reset();
                PalletChangeQuality.SetRange("User Created", UserId);
                PalletChangeQuality.SetRange("Pallet ID", PalletID);
                PalletChangeQuality.FindFirst();
                LineNoOriginal := PalletChangeQuality."Line No.";
                if pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty" > 0 then begin
                    LPalletLine.Reset();
                    LPalletLine.SetRange("Pallet ID", PalletID);
                    LPalletLine.SetRange("Line No.", LineNoOriginal);
                    if LPalletLine.FindFirst() then begin
                        LPalletLine."Remaining Qty" -= pPalletLineChg."Replaced Qty";
                        if LPalletLine."Remaining Qty" < 0 then
                            LPalletLine."Remaining Qty" := 0;
                        LPalletLine.Modify();
                    end;

                    ItemJournalLine.init;
                    ItemJournalLine."Journal Template Name" := 'ITEM';
                    ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                    ItemJournalLine."Line No." := LineNumber;
                    ItemJournalLine.insert;
                    ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                    ItemJournalLine."Posting Date" := Today;
                    ItemJournalLine."Document No." := pPalletLineChg."Pallet ID";
                    ItemJournalLine."Pallet ID" := pPalletLineChg."Pallet ID";
                    ItemJournalLine."Pallet Line No." := LineNoOriginal;
                    ItemJournalLine."Lot No." := pPalletLineChg."Lot Number";
                    ItemJournalLine."Document Date" := today;
                    ItemJournalLine.validate("Item No.", pPalletLineChg."Item No.");
                    ItemJournalLine.validate("Variant Code", pPalletLineChg."Variant Code");
                    ItemJournalLine.validate("Location Code", pPalletLineChg."Location Code");
                    ItemJournalLine.validate(Quantity, (pPalletLineChg.Quantity));
                    ItemJournalLine."Order No." := pPalletLineChg."Purchase Order No.";
                    ItemJournalLine."Order Line No." := pPalletLineChg."Purchase Order Line No.";
                    ItemJournalLine.modify;
                    //Create Reservation Entry
                    if ItemRec.get(pPalletLineChg."Item No.") then
                        if Itemrec."Lot Nos." <> '' then begin

                            ItemJournalLine.Modify();
                            RecGReservationEntry2.reset;
                            if RecGReservationEntry2.findlast then
                                maxEntry := RecGReservationEntry2."Entry No." + 1;

                            RecGReservationEntry.init;
                            RecGReservationEntry."Entry No." := MaxEntry;
                            RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                            RecGReservationEntry."Creation Date" := Today;
                            RecGReservationEntry."Created By" := UserId;
                            RecGReservationEntry.validate("Item Tracking", RecGReservationEntry."Item Tracking"::"Lot No.");
                            RecGReservationEntry."Expected Receipt Date" := Today;
                            RecGReservationEntry."Source Type" := 83;
                            RecGReservationEntry."Source Subtype" := 3;
                            RecGReservationEntry."Source ID" := 'ITEM';
                            RecGReservationEntry."Source Ref. No." := LineNumber;
                            RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                            RecGReservationEntry.validate("Item No.", pPalletLineChg."Item No.");
                            RecGReservationEntry.validate("Variant Code", pPalletLineChg."Variant Code");
                            RecGReservationEntry.validate("Location Code", pPalletLineChg."Location Code");
                            RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                            RecGReservationEntry.validate("Quantity (Base)", -1 *
                            (pPalletLineChg.Quantity));
                            RecGReservationEntry.validate(Quantity, -1 *
                            (pPalletLineChg.Quantity));
                            RecGReservationEntry.Positive := false;
                            RecGReservationEntry.insert;
                            PalletLedgerFunctions.NegPalletLedgerEntryItem(ItemJournalLine, PalletLedgerType::"Quality Change");
                        end;

                    LineNumber += 10000;

                    LineNumber := GetLastEntry();
                    PalletLedgerEntry.Init();
                    PalletLedgerEntry."Entry No." := LineNumber;
                    PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Quality Change";
                    PalletLedgerEntry."Pallet ID" := pPalletLineChg."Pallet ID";
                    PalletLedgerEntry."Pallet Line No." := LineNoOriginal;
                    PalletLedgerEntry."Document No." := pPalletLineChg."Purchase Order No.";
                    //PalletLedgerEntry."Item Ledger Entry No." := ItemJournalLine."Entry No.";
                    PalletLedgerEntry.validate("Posting Date", Today);
                    PalletLedgerEntry.validate("Item No.", pPalletLineChg."Item No.");
                    if ItemRec.get(pPalletLineChg."Item No.") then
                        PalletLedgerEntry."Item Description" := ItemRec.Description;
                    PalletLedgerEntry."Variant Code" := pPalletLineChg."Variant Code";
                    PalletLedgerEntry.validate("Location Code", pPalletLineChg."Location Code");
                    PalletLedgerEntry.validate("Unit of Measure", pPalletLineChg."Unit of Measure");
                    PalletLedgerEntry."Lot Number" := pPalletLineChg."Lot Number";
                    ItemUnitOfMeasure.reset;
                    ItemUnitOfMeasure.setrange("Item No.", pPalletLineChg."Item No.");
                    ItemUnitOfMeasure.setrange(code, pPalletLineChg."Unit of Measure");
                    if ItemUnitOfMeasure.findfirst then
                        PalletLedgerEntry.validate(Quantity, pPalletLineChg."Replaced Qty" * ItemUnitOfMeasure."Qty. per Unit of Measure")
                    else
                        PalletLedgerEntry.validate(Quantity, pPalletLineChg."Replaced Qty");
                    PalletLedgerEntry."User ID" := userid;
                    if PalletLedgerEntry.Quantity <> 0 then
                        PalletLedgerEntry.Insert();
                    LineNumber += 10000;
                end;
            until pPalletLineChg.next = 0;
    end;


    //Positive Adjustment to New Lines
    procedure PosAdjNewItems(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        LineNumber: Integer;
        ItemRec: Record item;
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        MaxEntry: Integer;
        LPalletLine: Record "Pallet Line";
        PalletChangeQuality: Record "Pallet Change Quality";
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletLedgerType: Enum "Pallet Ledger Type";
        PalletID: Code[20];
        PalletLineNo: Integer;
    begin
        PurchaseProcessSetup.get();
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        if ItemJournalLine.FindLast() then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";

        pPalletLineChg.reset;
        pPalletLineChg.SetRange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.findset then
            repeat
                PalletChangeQuality.reset;
                PalletChangeQuality.SetRange("Pallet ID", pPalletLineChg."Pallet ID");
                PalletChangeQuality.setrange("Pallet Line No.", pPalletLineChg."Line No.");
                PalletChangeQuality.setrange("User Created", UserId);
                if PalletChangeQuality.findset then
                    repeat
                        ItemJournalLine.init;
                        ItemJournalLine."Journal Template Name" := 'ITEM';
                        ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        ItemJournalLine."Line No." := LineNumber;
                        ItemJournalLine.insert(true);
                        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
                        ItemJournalLine."Posting Date" := Today;

                        ItemJournalLine."Document No." := pPalletLineChg."Pallet ID";
                        ItemJournalLine."Document Date" := today;
                        ItemJournalLine.validate("Item No.", PalletChangeQuality."new Item No.");
                        ItemJournalLine.validate("Variant Code", PalletChangeQuality."new Variant Code");
                        ItemJournalLine.validate("Location Code", pPalletLineChg."Location Code");
                        ItemJournalLine.validate(Quantity, PalletChangeQuality."New Quantity");
                        ItemJournalLine.validate("Lot No.", pPalletLineChg."Lot Number");
                        ItemJournalLine.Validate("Pallet ID", pPalletLineChg."Pallet ID");
                        ItemJournalLine."Pallet Line No." := GNewItemLineNo;
                        ItemJournalLine.modify;
                        //Create Reservation Entry
                        if ItemRec.get(PalletChangeQuality."new Item No.") then
                            if Itemrec."Lot Nos." <> '' then begin
                                RecGReservationEntry2.reset;
                                if RecGReservationEntry2.findlast then
                                    maxEntry := RecGReservationEntry2."Entry No." + 1;

                                RecGReservationEntry.init;
                                RecGReservationEntry."Entry No." := MaxEntry;
                                RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                                RecGReservationEntry."Creation Date" := Today;
                                RecGReservationEntry."Created By" := UserId;
                                RecGReservationEntry."Expected Receipt Date" := Today;
                                RecGReservationEntry."Source Type" := 83;
                                RecGReservationEntry."Source Subtype" := 2;
                                RecGReservationEntry."Source ID" := 'ITEM';
                                RecGReservationEntry."Source Ref. No." := LineNumber;
                                RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                                RecGReservationEntry.validate("Location Code", pPalletLineChg."Location Code");
                                RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                RecGReservationEntry.validate("Item No.", PalletChangeQuality."new Item No.");
                                RecGReservationEntry.validate("Variant Code", PalletChangeQuality."new Variant Code");
                                RecGReservationEntry.validate("Quantity (Base)", PalletChangeQuality."New Quantity");
                                RecGReservationEntry.validate(Quantity, PalletChangeQuality."New Quantity");
                                RecGReservationEntry.Positive := true;
                                RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                                RecGReservationEntry.insert;
                            end;
                        PalletLedgerFunctions.PosPalletLedgerEntryItem(ItemJournalLine, PalletLedgerType::"Quality Change");

                        LineNumber += 10000;
                    until PalletChangeQuality.next = 0;
            until pPalletLineChg.next = 0;
    end;


    //Adjust Pallet Line Quantities
    procedure ChangeQuantitiesOnPalletline(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLine: Record "Pallet Line";
        PalletID: Code[20];
        PalletLineNo: Integer;
        PalletFunctionsCU: Codeunit "Pallet Functions";
    begin
        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";
        pPalletLineChg.reset;
        pPalletLineChg.setrange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.findset then
            repeat
                //if pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty" > 0 then
                PalletLine.get(pPalletLineChg."Pallet ID", pPalletLineChg."Line No.");
                PalletLine.Quantity := pPalletLineChg."Replaced Qty";
                PalletLine."Remaining Qty" := pPalletLineChg."Replaced Qty";
                PalletLine.modify;
                PalletFunctionsCU.CreatePosAdjustmentToPackingMaterials_PalletLine(PalletLine, pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty")
            until pPalletLineChg.next = 0;
    end;

    //Adjust Pallet Reservation
    procedure ChangePalletReservation(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletReservationEntry: Record "Pallet reservation Entry";
        PalletID: Code[20];
        PalletLineNo: Integer;
        LPOLineNo: Integer;
        LPurchaseHeader: Record "Purchase Header";
        LPurchaseHeaderArchive: Record "Purchase Header Archive";
        LPurchaseLine: Record "Purchase Line";
        LPurchaseLineNewQty: Record "Purchase Line";
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        CUPurchasePost: Codeunit "Purch.-Post";
        LpalletLine: Record "Pallet Line";
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        maxEntry: Integer;
        ItemRec: Record Item;
        LisReleased: Boolean;
        ErrArchived: Label 'The PO was already invoiced, please change item quality manually';
    begin
        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";
        pPalletLineChg.reset;
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.setrange("User ID", UserId);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.findset then
            repeat
                if (pPalletLineChg."Purchase Order No." <> '') and (pPalletLineChg."Purchase Order Line No." <> 0) then begin


                    LPurchaseHeader.Reset();
                    LPurchaseHeader.SetRange("Document Type", LPurchaseHeader."Document Type"::Order);
                    LPurchaseHeader.SetRange("No.", pPalletLineChg."Purchase Order No.");
                    if LPurchaseHeader.FindFirst() then begin
                        LisReleased := false;
                        If LPurchaseHeader.Status <> LPurchaseHeader.Status::Open then begin
                            LisReleased := true;
                            LPurchaseHeader.Status := LPurchaseHeader.Status::Open;

                        end;
                        LPurchaseHeader.Invoice := false;
                        LPurchaseHeader.Receive := true;
                        LPurchaseHeader.Modify();

                        LPurchaseLine.Reset();
                        LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                        LPurchaseLine.SetRange("Document No.", pPalletLineChg."Purchase Order No.");
                        LPurchaseLine.SetFilter("Qty. to Receive", '<>0');
                        if LPurchaseLine.FindSet() then
                            repeat
                                LPurchaseLine."Qty. to Receive" := 0;
                                LPurchaseLine.Modify();
                            until LPurchaseLine.Next() = 0;


                        LPOLineNo := 0;
                        LPurchaseLine.Reset();
                        LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                        LPurchaseLine.SetRange("Document No.", pPalletLineChg."Purchase Order No.");
                        if LPurchaseLine.FindLast() then begin
                            LPOLineNo := LPurchaseLine."Line No." + 10000;

                            if LpalletLine.Get(pPalletLineChg."Pallet ID", pPalletLineChg."Line No.") then begin
                                LpalletLine."Purchase Order Line No." := LPOLineNo;
                                LpalletLine.Modify();
                            end;


                            LPurchaseLine.Reset();
                            LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                            LPurchaseLine.SetRange("Document No.", pPalletLineChg."Purchase Order No.");
                            LPurchaseLine.SetRange("Line No.", pPalletLineChg."Purchase Order Line No.");
                            if LPurchaseLine.FindFirst() then begin
                                if pPalletLineChg."Replaced Qty" > 0 then begin
                                    LPurchaseLineNewQty.Init();
                                    LPurchaseLineNewQty."Document No." := pPalletLineChg."Purchase Order No.";
                                    LPurchaseLineNewQty."Document Type" := LPurchaseLineNewQty."Document Type"::Order;
                                    LPurchaseLineNewQty."Line No." := LPOLineNo;
                                    LPurchaseLineNewQty.insert;
                                    LPurchaseLineNewQty.type := LPurchaseLineNewQty.type::Item;
                                    LPurchaseLineNewQty.validate("No.", LPurchaseLine."No.");
                                    LPurchaseLineNewQty.validate("Variant Code", LPurchaseLine."Variant Code");
                                    LPurchaseLineNewQty.validate("Location Code", LPurchaseLine."Location Code");
                                    //New Web UI Fields - to Dummy Fields
                                    LPurchaseLineNewQty."Web UI Unit of Measure" := LPurchaseLine."Unit of Measure";
                                    LPurchaseLineNewQty."Web UI Quantity" := pPalletLineChg."Replaced Qty";

                                    /*    ItemUnitOfMeasure.reset;
                                        ItemUnitOfMeasure.setrange("Item No.", pPalletLineChg."Item No.");
                                        ItemUnitOfMeasure.SetRange(Code, LPurchaseLine."Unit of Measure");
                                        ItemUnitOfMeasure.findfirst;*/
                                    LPurchaseLineNewQty.validate("Qty. (Base) SPA", pPalletLineChg."Replaced Qty");//* ItemUnitOfMeasure."Qty. per Unit of Measure");
                                    LPurchaseLineNewQty.validate("Qty. to Receive", LPurchaseLineNewQty.Quantity);
                                    LPurchaseLineNewQty.validate("qty. to invoice", 0);
                                    LPurchaseLineNewQty.modify;

                                    if ItemRec.get(LPurchaseLine."No.") then
                                        if itemrec."Lot Nos." <> '' then begin
                                            //Create Reservation Entry
                                            RecGReservationEntry2.reset;
                                            if RecGReservationEntry2.findlast then
                                                maxEntry := RecGReservationEntry2."Entry No." + 1;

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
                                            RecGReservationEntry."Source ID" := LPurchaseLine."Document No.";
                                            RecGReservationEntry."Source Ref. No." := LPurchaseLine."Line No.";
                                            RecGReservationEntry.validate("Location Code", LPurchaseLine."Location Code");
                                            RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                            RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                                            RecGReservationEntry.validate("Item No.", LPurchaseLine."No.");
                                            RecGReservationEntry.validate("Variant Code", LPurchaseLine."Variant Code");
                                            RecGReservationEntry.Description := LPurchaseLine.Description;
                                            RecGReservationEntry.validate("Quantity (Base)", LPurchaseLine."Qty. (Base) SPA");
                                            RecGReservationEntry.validate(Quantity, LPurchaseLine.Quantity);
                                            RecGReservationEntry."Packing Date" := today;
                                            RecGReservationEntry.insert;

                                        end;
                                end;
                                LPurchaseLine.Validate("Line Discount %", 100);
                                LPurchaseLine.Modify();

                                if LisReleased then
                                    DocmentStatusMgmt.PerformManualRelease(LPurchaseHeader);
                            end;
                        end;
                    end;

                end;

                if pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty" > 0 then
                    if PalletReservationEntry.get(pPalletLineChg."Pallet ID", pPalletLineChg."Line No.",
                        pPalletLineChg."Lot Number") then begin
                        PalletReservationEntry.Quantity := pPalletLineChg."Replaced Qty";
                        PalletReservationEntry.modify;
                    end;
            until pPalletLineChg.next = 0;
    end;

    //Adjust Pallet LedgerEntries - Old Items
    procedure PalletLedgerAdjustOld(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        LineNumber: Integer;
        PalletID: Code[20];
        PalletLineNo: Integer;
    begin
        //LineNumber := GetLastEntry();
        PalletLedgerEntry.LockTable();
        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";
        pPalletLineChg.reset;
        pPalletLineChg.setrange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.findset then
            repeat
                if pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty" > 0 then begin
                    PalletLedgerEntry.Init();
                    PalletLedgerEntry."Entry No." := GetLastEntry();
                    PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Quality Change";
                    PalletLedgerEntry."Pallet ID" := pPalletLineChg."Pallet ID";
                    PalletLedgerEntry."Pallet Line No." := pPalletLineChg."Line No.";
                    PalletLedgerEntry."Document No." := pPalletLineChg."Pallet ID";
                    PalletLedgerEntry.validate("Posting Date", Today);
                    PalletLedgerEntry.validate("Item No.", pPalletLineChg."Item No.");
                    PalletLedgerEntry."Variant Code" := pPalletLineChg."Variant Code";
                    PalletLedgerEntry."Item Description" := pPalletLineChg.Description;
                    PalletLedgerEntry."Lot Number" := pPalletLineChg."Lot Number";
                    PalletLedgerEntry.validate("Location Code", pPalletLineChg."Location Code");
                    PalletLedgerEntry.validate("Unit of Measure", pPalletLineChg."Unit of Measure");
                    PalletLedgerEntry.validate(Quantity, -1 * (pPalletLineChg.Quantity - pPalletLineChg."Replaced Qty"));
                    PalletLedgerEntry."User ID" := userid;

                    if PalletLedgerEntry.Quantity <> 0 then
                        PalletLedgerEntry.Insert();
                    //LineNumber += 1;
                end;
            until pPalletLineChg.next = 0;
    end;

    //Add The new items to the Pallet
    procedure AddNewItemsToPallet(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLine: Record "Pallet Line";
        PalletItemChgLine: Record "Pallet Change Quality";
        LPurchaseLine: Record "Purchase Line";
        LPurchaseHeader: Record "Purchase Header";
        LisReleased: Boolean;
        POLineno: Integer;
        maxEntry: Integer;
        LineNumber: integer;
        ItemRec: Record Item;
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        RecGReservationEntry: Record "Reservation Entry";
        RecGReservationEntry2: Record "Reservation Entry";
        PalletID: Code[20];
        PalletLineNo: Integer;
        PostPurchase: Codeunit "Purch.-Post";
    begin
        PalletLedgerEntry.LockTable();
        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";
        pPalletLineChg.reset;
        pPalletLineChg.setrange("User ID", userid);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.findset then
            repeat
                PalletItemChgLine.reset;
                PalletItemChgLine.setrange("Pallet ID", pPalletLineChg."Pallet ID");
                PalletItemChgLine.setrange("Pallet Line No.", pPalletLineChg."Line No.");
                PalletItemChgLine.setrange("User Created", UserId);
                if PalletItemChgLine.findset then
                    repeat
                        if PalletItemChgLine."New Quantity" > 0 then begin
                            PalletLine.init;
                            PalletLine."Pallet ID" := pPalletLineChg."Pallet ID";
                            PalletLine."Line No." := GetLastPalletLine(pPalletLineChg."Pallet ID");
                            GNewItemLineNo := PalletLine."Line No.";
                            PalletLine.validate("Item No.", PalletItemChgLine."New Item No.");
                            PalletLine."Location Code" := pPalletLineChg."Location Code";
                            PalletLine."Lot Number" := pPalletLineChg."Lot Number";
                            PalletLine.Quantity := PalletItemChgLine."New Quantity";
                            PalletLine."Remaining Qty" := PalletItemChgLine."New Quantity";
                            PalletLine.validate("Unit of Measure", PalletItemChgLine."Unit of Measure");
                            PalletLine.validate("Variant Code", PalletItemChgLine."New Variant Code");

                            if (pPalletLineChg."Purchase Order No." <> '') then begin
                                LPurchaseHeader.Reset();
                                LPurchaseHeader.SetRange("Document Type", LPurchaseHeader."Document Type"::Order);
                                LPurchaseHeader.SetRange("No.", pPalletLineChg."Purchase Order No.");
                                if LPurchaseHeader.FindFirst() then begin
                                    LisReleased := false;
                                    If LPurchaseHeader.Status <> LPurchaseHeader.Status::Open then begin
                                        LisReleased := true;
                                        LPurchaseHeader.Status := LPurchaseHeader.Status::Open;

                                        LPurchaseHeader.Modify();
                                    end;

                                    LPurchaseLine.Reset();
                                    LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                                    LPurchaseLine.SetRange("Document No.", pPalletLineChg."Purchase Order No.");
                                    LPurchaseLine.FindLast();
                                    POLineno := LPurchaseLine."Line No." + 10000;


                                    LPurchaseLine.init;
                                    LPurchaseLine."Document No." := pPalletLineChg."Purchase Order No.";
                                    Lpurchaseline."Document Type" := LPurchaseLine."Document Type"::Order;
                                    LPurchaseLine."Line No." := POLineno;
                                    LPurchaseLine.insert;
                                    LPurchaseLine.type := LPurchaseLine.type::Item;
                                    Lpurchaseline.validate("No.", PalletItemChgLine."New Item No.");
                                    LPurchaseLine.validate("Variant Code", PalletItemChgLine."New Variant Code");
                                    LPurchaseLine.validate("Location Code", pPalletLineChg."Location Code");
                                    //New Web UI Fields - to Dummy Fields
                                    LPurchaseLine."Web UI Unit of Measure" := PalletItemChgLine."Unit of Measure";
                                    LPurchaseLine."Web UI Quantity" := PalletItemChgLine."New Quantity";
                                    ItemUnitOfMeasure.reset;
                                    ItemUnitOfMeasure.setrange("Item No.", PalletItemChgLine."New Item No.");
                                    ItemUnitOfMeasure.SetRange(Code, PalletItemChgLine."Unit of Measure");
                                    ItemUnitOfMeasure.findfirst;
                                    LPurchaseLine.validate("Qty. (Base) SPA", PalletItemChgLine."New Quantity" * ItemUnitOfMeasure."Qty. per Unit of Measure");
                                    LPurchaseLine.validate("Qty. to Receive", LPurchaseLine.Quantity);
                                    LPurchaseLine.validate("qty. to invoice", 0);
                                    LPurchaseLine.modify;

                                    PalletLine."Purchase Order No." := pPalletLineChg."Purchase Order No.";
                                    PalletLine."Purchase Order Line No." := POLineno;
                                    //PalletLine.Modify();



                                    if ItemRec.get(LPurchaseLine."No.") then
                                        if itemrec."Lot Nos." <> '' then begin
                                            //Create Reservation Entry
                                            RecGReservationEntry2.reset;
                                            if RecGReservationEntry2.findlast then
                                                maxEntry := RecGReservationEntry2."Entry No." + 1;

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
                                            RecGReservationEntry."Source ID" := LPurchaseLine."Document No.";
                                            RecGReservationEntry."Source Ref. No." := LPurchaseLine."Line No.";
                                            RecGReservationEntry.validate("Location Code", LPurchaseLine."Location Code");
                                            RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                                            RecGReservationEntry."Lot No." := pPalletLineChg."Lot Number";
                                            RecGReservationEntry.validate("Item No.", LPurchaseLine."No.");
                                            RecGReservationEntry.validate("Variant Code", LPurchaseLine."Variant Code");
                                            RecGReservationEntry.Description := LPurchaseLine.Description;
                                            RecGReservationEntry.validate("Quantity (Base)", LPurchaseLine."Qty. (Base) SPA");
                                            RecGReservationEntry.validate(Quantity, LPurchaseLine.Quantity);
                                            RecGReservationEntry."Packing Date" := today;
                                            RecGReservationEntry.insert;

                                        end;


                                    DocmentStatusMgmt.PerformManualRelease(LPurchaseHeader);
                                    PostPurchase.Run(LPurchaseHeader);
                                end;
                            end;
                            PalletLine.Replaced := true;
                            if ItemRec.get(PalletItemChgLine."New Item No.") then begin
                                if format(ItemRec."Expiration Calculation") = '' then
                                    PalletLine."Expiration Date" := today
                                else
                                    PalletLine."Expiration Date" := CalcDate('+' + format(ItemRec."Expiration Calculation"), today);
                            end;
                            PalletLine."User ID" := UserId;
                            PalletLine.insert;

                            LineNumber := GetLastEntry();
                            PalletLedgerEntry.Init();
                            PalletLedgerEntry."Entry No." := LineNumber;
                            PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Quality Change";
                            PalletLedgerEntry."Pallet ID" := PalletLine."Pallet ID";
                            PalletLedgerEntry."Pallet Line No." := PalletLine."Line No.";
                            PalletLedgerEntry."Document No." := PalletLine."Purchase Order No.";
                            PalletLedgerEntry."Lot Number" := PalletLine."Lot Number";
                            //PalletLedgerEntry."Item Ledger Entry No." := ItemJournalLine."Entry No.";
                            PalletLedgerEntry.validate("Posting Date", Today);
                            PalletLedgerEntry.validate("Item No.", PalletLine."Item No.");
                            if ItemRec.get(PalletLine."Item No.") then
                                PalletLedgerEntry."Item Description" := ItemRec.Description;
                            PalletLedgerEntry."Variant Code" := PalletLine."Variant Code";
                            PalletLedgerEntry.validate("Location Code", PalletLine."Location Code");
                            PalletLedgerEntry.validate("Unit of Measure", PalletLine."Unit of Measure");
                            ItemUnitOfMeasure.reset;
                            ItemUnitOfMeasure.setrange("Item No.", PalletLine."Item No.");
                            ItemUnitOfMeasure.setrange(code, PalletLine."Unit of Measure");
                            if ItemUnitOfMeasure.findfirst then
                                PalletLedgerEntry.validate(Quantity, PalletLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure")
                            else
                                PalletLedgerEntry.validate(Quantity, PalletLine.Quantity);
                            PalletLedgerEntry."User ID" := userid;
                            if PalletLedgerEntry.Quantity <> 0 then
                                PalletLedgerEntry.Insert();

                        end;
                    until PalletItemChgLine.next = 0;

            until pPalletLineChg.next = 0;
    end;

    //Post Negative Item Ledger Entry
    procedure PostItemLedger(pPalletNumber: Code[20])
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
    begin
        PurchaseProcessSetup.get();


        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        ItemJournalLine.SetFilter(Quantity, '<>%1', 0);
        ItemJournalLine.SetRange("Pallet ID", pPalletNumber);
        if ItemJournalLine.findset then
            repeat
                CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);
            until ItemJournalLine.Next() = 0;

        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        ItemJournalLine.SetRange("Pallet ID", pPalletNumber);
        if ItemJournalLine.FindSet() then
            ItemJournalLine.DeleteAll();

    end;

    //Recreate Pallet reservations  
    procedure RecreateReservations(pPalletID: code[20])
    var
        PalletHeader: Record "Pallet Header";
        PalletLine: Record "Pallet Line";
        PalletReservation: Record "Pallet reservation Entry";
    begin
        PalletReservation.reset;
        PalletReservation.setrange("Pallet ID", pPalletID);
        if PalletReservation.findset then
            PalletReservation.DeleteAll();

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletID);
        if PalletLine.findset then
            repeat
                if (PalletLine.Replaced) then begin
                    PalletLine."Remaining Qty" := PalletLine.Quantity;
                    PalletLine.modify;
                end;
                if palletLine.Quantity <> 0 then begin
                    PalletReservation.init;
                    PalletReservation."Pallet ID" := PalletLine."Pallet ID";
                    PalletReservation."Pallet Line" := PalletLine."Line No.";
                    PalletReservation."Lot No." := PalletLine."Lot Number";
                    PalletReservation.Quantity := PalletLine.Quantity;
                    PalletReservation."Variant Code" := PalletLine."Variant Code";
                    PalletReservation.Insert();
                end;
            until PalletLine.next = 0;

        PalletLine.reset;
        palletline.setfilter(PalletLine.Quantity, '=%1', 0);
        if PalletLine.findset then
            repeat
                PalletReservation.reset;
                PalletReservation.setrange("Pallet ID", PalletLine."Pallet ID");
                PalletReservation.setrange("Pallet Line", PalletLine."Line No.");
                if PalletReservation.findfirst then
                    PalletReservation.delete;
                PalletLine.delete;
            until PalletLine.next = 0;
    end;

    //Neg ADjustment to New Packing Materials
    procedure NegAdjToNewPacking(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        QualityChangeLine: Record "Pallet Change Quality";
        BomComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        PalletHeader: Record "Pallet Header";
        RecGReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        LineNumber: Integer;
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        PalletLedgerType: Enum "Pallet Ledger Type";
        ItemRec: Record Item;
        maxEntry: Integer;
    begin
        PurchaseProcessSetup.get;
        ItemJournalLine.reset;
        ItemJournalLine.setrange("Journal Template Name", 'ITEM');
        ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
        if ItemJournalLine.findlast then
            LineNumber := ItemJournalLine."Line No." + 10000
        else
            LineNumber := 10000;

        QualityChangeLine.reset;
        QualityChangeLine.setrange("Pallet ID", pPalletLineChg."Pallet ID");
        QualityChangeLine.SetRange("Line No.", pPalletLineChg."Line No.");
        QualityChangeLine.SetRange("User Created", UserId);
        if QualityChangeLine.FindSet then
            repeat
                PalletHeader.get(pPalletLineChg."Pallet ID");
                BomComponent.reset;
                BomComponent.setrange("Parent Item No.", QualityChangeLine."New Item No.");
                if BomComponent.findset then
                    repeat
                        ItemJournalLine.init;
                        ItemJournalLine."Journal Template Name" := 'ITEM';
                        ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        ItemJournalLine."Line No." := LineNumber;
                        ItemJournalLine.insert;
                        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                        ItemJournalLine."Posting Date" := Today;
                        ItemJournalLine."Document No." := QualityChangeLine."Pallet ID";
                        ItemJournalLine.Description := QualityChangeLine.Description;

                        ItemJournalLine.validate("Item No.", BomComponent."No.");
                        ItemJournalLine.validate("Variant Code", BomComponent."Variant Code");
                        ItemJournalLine.validate("Location Code", PalletHeader."Location Code");
                        ItemJournalLine.Validate("Unit of Measure Code", BomComponent."Unit of Measure Code");
                        if BomComponent."Fixed Value" then
                            ItemJournalLine.validate(Quantity, QualityChangeLine."New Quantity")
                        else
                            ItemJournalLine.validate(Quantity, QualityChangeLine."New Quantity" * BomComponent."Quantity per");

                        ItemJournalLine."Pallet ID" := QualityChangeLine."Pallet ID";
                        ItemJournalLine."Pallet Line No." := GNewItemLineNo;
                        ItemJournalLine.modify;
                        PalletLedgerFunctions.NegPalletLedgerEntryItem(ItemJournalLine, PalletLedgerType::"Consume Packing Materials");

                        LineNumber += 10000;
                    until BomComponent.next = 0;
            until QualityChangeLine.next = 0;
    end;

    //Add Packing Materials to Existing Packing Materials
    procedure AddPackingMaterialsToExisting(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        QualityChangeLine: Record "Pallet Change Quality";
        BomComponent: Record "BOM Component";
        PalletHeader: Record "Pallet Header";
        PalletLines: Record "Pallet Line";
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        PackingMaterials: Record "Packing Material Line";
        PalletFunctions: Codeunit "Pallet Functions";
        PalletID: Code[20];
        PalletLineNo: Integer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LQty: Decimal;
    begin
        PalletID := pPalletLineChg."Pallet ID";
        PalletLineNo := pPalletLineChg."Line No.";
        PalletHeader.get(PalletID);
        PalletLedgerEntry.LockTable();

        pPalletLineChg.reset;
        pPalletLineChg.setrange("User ID", UserId);
        pPalletLineChg.SetRange("Pallet ID", PalletID);
        pPalletLineChg.SetRange("Line No.", PalletLineNo);
        if pPalletLineChg.FindSet() then
            repeat
                if PalletLines.Get(PalletID, PalletLineNo) then begin
                    BomComponent.reset;
                    BomComponent.setrange("Parent Item No.", pPalletLineChg."Item No.");
                    if BomComponent.findset then
                        repeat
                            if not PackingMaterials.get(PalletLines."Pallet ID",
                                BomComponent."No.", BomComponent."Unit of Measure Code") then begin
                                PackingMaterials.init;
                                PackingMaterials."Pallet ID" := PalletLines."Pallet ID";
                                PackingMaterials."Item No." := BomComponent."No.";
                                packingmaterials."Line No." := PalletFunctions.GetLastEntryPacking(PalletHeader);
                                PackingMaterials.Description := BomComponent.Description;
                                PackingMaterials."Reusable Item" := BomComponent."Reusable item";
                                if BomComponent."Fixed Value" then begin
                                    PackingMaterials.Quantity := BomComponent."Quantity per";
                                    PackingMaterials."Fixed Value" := true;
                                end else
                                    PackingMaterials.Quantity := BomComponent."Quantity per" * PalletLines.Quantity;
                                PackingMaterials."Unit of Measure Code" := BomComponent."Unit of Measure Code";
                                PackingMaterials."Location Code" := PalletLines."Location Code";
                                PackingMaterials.insert;
                            end
                            else begin
                                if not (BomComponent."Fixed Value") then begin
                                    PackingMaterials.Quantity -= BomComponent."Quantity per" * pPalletLineChg."Replaced Qty";
                                    PackingMaterials.modify;
                                end else begin
                                    if pPalletLineChg."Replaced Qty" = PalletLines.Quantity then begin
                                        PackingMaterials.Quantity -= BomComponent."Quantity per";
                                        PackingMaterials.modify;
                                    end;
                                end;
                            end;

                        until BomComponent.next = 0;
                end;
            until pPalletLineChg.Next() = 0;


        QualityChangeLine.Reset();
        QualityChangeLine.SetRange("User Created", UserId);
        QualityChangeLine.SetRange("Pallet ID", PalletID);
        QualityChangeLine.SetRange("Pallet Line No.", PalletLineNo);
        if QualityChangeLine.FindSet() then
            repeat
                BomComponent.reset;
                BomComponent.setrange("Parent Item No.", QualityChangeLine."New Item No.");
                if BomComponent.findset then
                    repeat
                        if not PackingMaterials.get(PalletLines."Pallet ID",
                            BomComponent."No.", BomComponent."Unit of Measure Code") then begin
                            PackingMaterials.init;
                            PackingMaterials."Pallet ID" := PalletLines."Pallet ID";
                            PackingMaterials."Item No." := BomComponent."No.";
                            packingmaterials."Line No." := PalletFunctions.GetLastEntryPacking(PalletHeader);
                            PackingMaterials.Description := BomComponent.Description;
                            PackingMaterials."Reusable Item" := BomComponent."Reusable item";
                            if BomComponent."Fixed Value" then begin
                                PackingMaterials.Quantity := BomComponent."Quantity per";
                                PackingMaterials."Fixed Value" := true;
                            end else
                                PackingMaterials.Quantity := BomComponent."Quantity per" * QualityChangeLine."New Quantity";
                            PackingMaterials."Unit of Measure Code" := BomComponent."Unit of Measure Code";
                            PackingMaterials."Location Code" := PalletLines."Location Code";
                            PackingMaterials.insert;
                        end
                        else begin
                            if PackingMaterials."Fixed Value" then begin
                                if BomComponent."Fixed Value" then begin
                                    if BomComponent."Quantity per" > PackingMaterials.Quantity then
                                        PackingMaterials.Quantity := BomComponent."Quantity per";
                                end else
                                    if BomComponent."Quantity per" * QualityChangeLine."New Quantity" > PackingMaterials.Quantity then
                                        PackingMaterials.Quantity := BomComponent."Quantity per" * QualityChangeLine."New Quantity";
                            end else begin
                                if BomComponent."Fixed Value" then begin
                                    if BomComponent."Quantity per" > PackingMaterials.Quantity then
                                        PackingMaterials.Quantity := BomComponent."Quantity per";
                                end else
                                    PackingMaterials.Quantity += BomComponent."Quantity per" * QualityChangeLine."New Quantity";
                            end;
                            PackingMaterials.modify;
                        end;

                        PalletLedgerEntry.Init();
                        PalletLedgerEntry."Entry No." := GetLastEntry();
                        PalletLedgerEntry."Entry Type" := PalletLedgerEntry."Entry Type"::"Consume Packing Materials";
                        PalletLedgerEntry."Pallet ID" := PackingMaterials."Pallet ID";
                        PalletLedgerEntry."Pallet Line No." := PalletLines."Line No.";
                        PalletLedgerEntry."Document No." := PackingMaterials."Pallet ID";
                        PalletLedgerEntry.validate("Posting Date", Today);
                        PalletLedgerEntry.validate("Item No.", PackingMaterials."Item No.");
                        PalletLedgerEntry."Variant Code" := BomComponent."Variant Code";
                        PalletLedgerEntry."Item Description" := PackingMaterials.Description;
                        PalletLedgerEntry."Lot Number" := PalletLines."Lot Number";
                        PalletLedgerEntry.validate("Location Code", PalletLines."Location Code");
                        PalletLedgerEntry.validate("Unit of Measure", BomComponent."Unit of Measure Code");
                        PalletLedgerEntry.validate(Quantity, -BomComponent."Quantity per" * QualityChangeLine."New Quantity");
                        PalletLedgerEntry."User ID" := userid;

                        ItemLedgerEntry.Reset();
                        ItemLedgerEntry.SetRange("Document No.", PalletID);
                        ItemLedgerEntry.SetRange("Item No.", PalletLedgerEntry."Item No.");
                        ItemLedgerEntry.SetRange("Variant Code", PalletLedgerEntry."Variant Code");
                        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
                        //ItemLedgerEntry.SetRange("Unit of Measure Code", PalletLedgerEntry."Unit of Measure");
                        // ItemLedgerEntry.SetRange(Quantity, PalletLedgerEntry.Quantity);
                        ItemLedgerEntry.SetRange("Posting Date", Today());
                        if ItemLedgerEntry.FindLast() then begin
                            PalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
                        end;
                        if PalletLedgerEntry.Quantity <> 0 then
                            PalletLedgerEntry.Insert();

                    until BomComponent.next = 0;

                PalletLedgerEntry.Reset();
                PalletLedgerEntry.SetRange("Pallet ID", PalletID);
                PalletLedgerEntry.SetRange("Item Ledger Entry No.", 0);
                if PalletLedgerEntry.FindSet() then
                    repeat
                        ItemLedgerEntry.Reset();
                        ItemLedgerEntry.SetRange("Posting Date", PalletLedgerEntry."Posting Date");
                        ItemLedgerEntry.SetRange("Item No.", PalletLedgerEntry."Item No.");
                        ItemLedgerEntry.SetRange("Variant Code", PalletLedgerEntry."Variant Code");
                        ItemLedgerEntry.SetRange("Document No.", PalletID);
                        if PalletLedgerEntry.Quantity < 0 then
                            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.")
                        else
                            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
                        if ItemLedgerEntry.FindLast() then begin
                            PalletLedgerEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
                            PalletLedgerEntry.Modify();
                        end;

                    until PalletLedgerEntry.Next() = 0;
            until QualityChangeLine.Next() = 0;
    end;

    //Calc Change Quality
    procedure CalcChangeQuality(var pPalletID: code[20])
    var
        PalletLine: Record "Pallet Line";
        PalletChangeQuality: Record "Pallet Change Quality";
        PalletLineChangeQuality: Record "Pallet Line Change Quality";

    begin
        PalletLineChangeQuality.reset;
        PalletLineChangeQuality.SetRange("User ID", UserId);
        if PalletLineChangeQuality.findset then
            PalletLineChangeQuality.DeleteAll();

        PalletChangeQuality.reset;
        PalletChangeQuality.setrange("User Created", UserId);
        if PalletChangeQuality.findset then
            PalletChangeQuality.DeleteAll();

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletID);
        if PalletLine.findset then
            repeat
                PalletLineChangeQuality.init;
                PalletLineChangeQuality.TransferFields(PalletLine);
                PalletLineChangeQuality."User ID" := UserId;
                PalletLineChangeQuality."Replaced Qty" := PalletLine.Quantity;
                PalletLineChangeQuality.insert;
            until palletline.next = 0;
    end;

    //Remove Pallet line with Zero Quantity
    Procedure RemoveZeroPalletLine(pPalletLineChg: Record "Pallet Line Change Quality")
    var
        PalletLine: Record "Pallet Line";
        PalletReservation: Record "Pallet reservation Entry";
    begin

        PalletLine.reset;
        PalletLine.setrange("Pallet ID", pPalletLineChg."Pallet ID");
        //PalletLine.setrange("Line No.", pPalletLineChg."Line No.");
        PalletLine.setfilter(Quantity, '=%1', 0);
        if PalletLine.findset then
            repeat
                PalletReservation.reset;
                PalletReservation.setrange("Pallet ID", PalletLine."Pallet ID");
                PalletReservation.setrange("Pallet Line", palletline."Line No.");
                if PalletReservation.findset then
                    repeat
                        PalletReservation.Delete();
                    until PalletReservation.next = 0;
                PalletLine.delete;
            until PalletLine.next = 0;

    end;

    local procedure GetLastEntry(): Integer
    var
        PalletLedgerEntry: Record "pallet ledger entry";
    begin
        PalletLedgerEntry.reset;
        if PalletLedgerEntry.findlast then
            exit(PalletLedgerEntry."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure GetLastPalletLine(pPalletID: code[20]): Integer
    var
        LineNumber: Integer;
        PalletLineRec: Record "Pallet Line";
    begin
        PalletLineRec.reset;
        PalletLineRec.setrange("Pallet ID", pPalletID);
        if PalletLineRec.findlast then
            LineNumber := PalletLineRec."Line No." + 10000
        else
            LineNumber := 10000;
        exit(LineNumber);
    end;

    var

        GNewItemLineNo: Integer;
        GOldItemLineNo: Integer;

}