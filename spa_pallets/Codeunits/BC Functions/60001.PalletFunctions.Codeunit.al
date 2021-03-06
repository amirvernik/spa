codeunit 60001 "Pallet Functions"
{
    Permissions = TableData 32 = rm;
    trigger OnRun()
    var
    begin

    end;

    //Close Pallet - Global Function
    procedure ClosePallet(var pPalletHeader: Record "Pallet Header"; pType: text[2])
    var
        LPurchaseOrderLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        LPurchaseOrdersText: Text;
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        CUPurchasePost: Codeunit "Purch.-Post";
    begin

        //No Lines - Dont close
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if not PalletLines.findfirst then
            error(Err04);

        //No Quantities - Dont close
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
        PalletLines.setrange(Quantity, 0);
        if PalletLines.findfirst then
            error(Err05);



        if pType = 'BC' then begin
            LPurchaseOrdersText := '';

            PalletLines.reset;
            PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
            PalletLines.SetFilter("Purchase Order Line No.", '<>%1', 0);
            if PalletLines.FindSet() then
                repeat
                    LPurchaseOrderLine.Reset();
                    LPurchaseOrderLine.SetRange("Document Type", LPurchaseOrderLine."Document Type"::Order);
                    LPurchaseOrderLine.SetRange("Document No.", PalletLines."Purchase Order No.");
                    LPurchaseOrderLine.SetRange("Line No.", PalletLines."Purchase Order Line No.");
                    LPurchaseOrderLine.SetRange("Quantity Received", 0);
                    if LPurchaseOrderLine.FindFirst() then
                        if LPurchaseOrdersText = '' then
                            LPurchaseOrdersText := PalletLines."Purchase Order No."
                        else
                            LPurchaseOrdersText += '|' + PalletLines."Purchase Order No.";
                until PalletLines.Next() = 0;

            if LPurchaseOrdersText <> '' then begin

                LPurchaseOrderLine.Reset();
                LPurchaseOrderLine.SetRange("Document Type", LPurchaseOrderLine."Document Type"::Order);
                LPurchaseOrderLine.SetFilter("Document No.", LPurchaseOrdersText);
                LPurchaseOrderLine.SetRange("Quantity Received", 0);
                LPurchaseOrderLine.SetFilter("Qty. to Receive", '<>%1', 0);
                IF LPurchaseOrderLine.FindSet() then
                    repeat
                        LPurchaseOrderLine.validate("Qty. to Receive", 0);
                        //LPurchaseOrderLine.validate("Qty. to Invoice", 0);
                        LPurchaseOrderLine.Modify();
                    until LPurchaseOrderLine.Next() = 0;

                GPurchaseHeader.Reset();
                GPurchaseHeader.SetRange("Document Type", GPurchaseHeader."Document Type"::Order);
                GPurchaseHeader.SetFilter("No.", LPurchaseOrdersText);
                if GPurchaseHeader.FindSet() then
                    repeat
                        if GPurchaseHeader.Status <> GPurchaseHeader.Status::Open then begin
                            //DocmentStatusMgmt.PerformManualReopen(LPurchaseHeader);
                            GPurchaseHeader.Status := GPurchaseHeader.Status::Open;
                            GPurchaseHeader.Modify();
                        end;
                        PalletLines.Reset();
                        PalletLines.SetRange("Pallet ID", pPalletHeader."Pallet ID");
                        PalletLines.SetRange("Purchase Order No.", GPurchaseHeader."No.");
                        if PalletLines.FindSet() then
                            repeat
                                LPurchaseOrderLine.Get(LPurchaseOrderLine."Document Type"::Order, PalletLines."Purchase Order No.", PalletLines."Purchase Order Line No.");
                                LPurchaseOrderLine.validate("Qty. to Receive", LPurchaseOrderLine."Outstanding Quantity");
                                LPurchaseOrderLine.validate("Qty. to Invoice", LPurchaseOrderLine.Quantity);
                                LPurchaseOrderLine.Modify();
                            until PalletLines.Next() = 0;

                        DocmentStatusMgmt.PerformManualRelease(GPurchaseHeader);
                        GPurchaseHeader.Receive := true;
                        GPurchaseHeader.Invoice := false;
                        GPurchaseHeader.Modify();
                        CUPurchasePost.Run(GPurchaseHeader);
                    until GPurchaseHeader.Next() = 0;
            end;
        end;

        //Update Remaining Quantity
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
        if PalletLines.findset then
            repeat
                if LPurchaseOrderLine.Get(LPurchaseOrderLine."Document Type"::Order, PalletLines."Purchase Order No.", PalletLines."Purchase Order Line No.")
                then begin
                    if LPurchaseOrderLine."Quantity Received" <= 0 then begin
                        Error('You can`t close the pallet if you have not received the purchase line, Please make sure the purchase line is received and then retry to close the pallet');
                        exit;
                    end;
                end;
                PalletLines."Remaining Qty" := PalletLines.Quantity;
                PalletLines."QTY Consumed" := 0;
                PalletLines.modify;

            until PalletLines.next = 0;

        UpdateNoOfCopies(pPalletHeader); //Change No. Of Copies
        if pPalletHeader."Pallet Status" <> pPalletHeader."Pallet Status"::Closed then begin
            AddMaterials(pPalletHeader); //Add Materials
            PalletLedgerFunctions.PosPalletLedger(pPalletHeader); //Positive on Pallet Ledger
            ItemLedgerFunctions.NegItemLedgerEntry(pPalletHeader); //Negative on Item Journal
            ItemLedgerFunctions.PostLedger(pPalletHeader); //Post Item Journal
                                                           //AddPoLines(pPalletHeader); //Add PO Lines
        end;
        //Change Status
        pPalletHeader."Pallet Status" := pPalletHeader."Pallet Status"::Closed;
        pPalletHeader.modify;

    end;



    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnAfterActionEvent', 'Post', false, false)]
    procedure OnBeforePostPurchaseDoc(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;


    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnBeforeActionEvent', 'Post &Batch', false, false)]
    procedure OnBeforePostPurchaseDocPostBatch(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;


    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnBeforeActionEvent', 'Post and &Print', false, false)]
    procedure OnBeforePostPurchaseDocPostandPrint(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnBeforeActionEvent', 'Post and Print Prepmt. Cr. Mem&o', false, false)]
    procedure OnBeforePostPurchaseDocPostandPrintPrepmtCM(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;


    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnBeforeActionEvent', 'Post and Print Prepmt. Invoic&e', false, false)]
    procedure OnBeforePostPurchaseDocPostandPrintPrepmtInv(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnBeforeActionEvent', 'Post', false, false)]
    procedure OnBeforePostPurchaseDocPost(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;


    [EventSubscriber(ObjectType::Page, page::"Purchase Order List", 'OnBeforeActionEvent', 'Post', false, false)]
    procedure OnBeforePostPurchaseDocListPost(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::"Purchase Order List", 'OnBeforeActionEvent', 'PostAndPrint', false, false)]
    procedure OnBeforePostPurchaseDocListPostandPrint(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;


    [EventSubscriber(ObjectType::Page, page::"Purchase Order List", 'OnBeforeActionEvent', 'PostBatch', false, false)]
    procedure OnBeforePostPurchaseDocListPostBatch(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Page, page::"Purchase Order", 'OnBeforeActionEvent', 'PostAndNew', false, false)]
    procedure OnBeforePostPurchaseDocPostAndNew(var Rec: Record "Purchase Header")
    var
        LpalletHeader: Record "Pallet Header";
        LPalletLine: Record "Pallet Line";
        NoteText: Label 'Please note that some pallets in this Purchase Order have yet to be shipped or cancelled or fully consumed.';
    begin
        if Rec."Grading Result PO" then begin
            LPalletLine.Reset();
            LPalletLine.SetCurrentKey("Purchase Order No.");
            LPalletLine.SetRange("Purchase Order No.", Rec."No.");
            if LPalletLine.FindSet() then
                repeat
                    LpalletHeader.Get(LPalletLine."Pallet ID");
                    if LpalletHeader."Pallet Status" = LpalletHeader."Pallet Status"::Closed then begin
                        Message(NoteText);
                        exit;
                    end;
                until LPalletLine.Next() = 0;
        end;
    end;

    //Reopen Pallet - Global Function
    procedure ReOpenPallet(var pPalletHeader: Record "Pallet Header")
    var

    begin
        if UserSetup.get(UserId) then begin

            //Permission Check
            if (not UserSetup."Can ReOpen Pallet") then
                Error(Err01, 'ReOpen Pallet');

            //Not Shipped Check
            if pPalletHeader."Pallet Status" = pPalletHeader."Pallet Status"::Shipped then
                Error(Err02);

            //Exists in Warehouse Shipment Check
            PalletLines.reset;
            PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
            palletlines.setrange("Exists on Warehouse Shipment", true);
            if PalletLines.FindFirst() then
                Error(Err03);

            pPalletHeader."Pallet Status" := pPalletHeader."Pallet Status"::Open;
            pPalletHeader.modify;

            //Update Remaining Quantity
            PalletLines.reset;
            PalletLines.setrange("Pallet ID", pPalletHeader."Pallet ID");
            if PalletLines.findset then
                repeat
                    PalletLines."Remaining Qty" := 0;
                    palletlines."QTY Consumed" := 0;
                    PalletLines.modify;
                until PalletLines.next = 0;

            TrackingLineFunctions.RemoveTrackingLineFromPO(pPalletHeader); //Remove Tracking Line to PO
            ItemLedgerFunctions.PosItemLedgerEntry(pPalletHeader); //Positive on Item Journal Packing Material
            PalletLedgerFunctions.NegPalletLedger(pPalletHeader); //Negative on Pallet Ledger
            DeleteMaterials(pPalletHeader); //Delete Materials
            ItemLedgerFunctions.PostLedger(pPalletHeader); //Post Item Journal - If Exist
        end
        else
            Error(Err01, 'ReOpen Pallet');
    end;

    //After Post Transfer Line --> Shipment Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptLine', '', true, true)]
    local procedure OnAfterPostTransferOrderShip(TransLine: Record "Transfer Line"; var TransShptLine: Record "Transfer Shipment Line")
    begin
        TransShptLine."Pallet ID" := TransLine."Pallet ID";
        TransShptLine.Modify();
        PalletLedgerFunctions.NegPalletLedgerTransfer(TransShptLine);
    end;

    //After Post Transfer Line --> Receipt Line
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptLine', '', true, true)]
    local procedure OnAfterPostTransferOrderReceipt(TransLine: Record "Transfer Line"; var TransRcptLine: Record "Transfer Receipt Line")
    begin
        TransRcptLine."Pallet ID" := TransLine."Pallet ID";
        TransRcptLine.Modify();
        PalletLedgerFunctions.PosPalletLedgerTransfer(TransRcptLine);
    end;

    //On After Post Item Reclass Journal
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', true, true)]
    local procedure OnAfterInsertItemLedgerEntry(ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        PalletSetup: Record "Pallet Process Setup";
        PurchRctLine: Record "Purch. Rcpt. Line";
    begin
        PalletSetup.get;
        ItemLedgerEntry."Pallet ID" := ItemJournalLine."Pallet ID";
        ItemLedgerEntry."Pallet Type" := ItemJournalLine."Pallet Type";
        ItemLedgerEntry.Disposal := ItemJournalLine.Disposal;
        ItemLedgerEntry.modify;
        if ItemJournalLine."Journal Template Name" = PalletSetup."Item Reclass Template" then
            PalletLedgerFunctions.PalletLedgerEntryReclass(ItemLedgerEntry);

        //Change Pallet ID To Pallet Number not receipt
        if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Purchase Receipt" then begin
            if PurchRctLine.get(ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.") then begin
                PalletLines.reset;
                palletlines.setrange("Purchase Order No.", PurchRctLine."Order No.");
                PalletLines.setrange("Purchase Order Line No.", PurchRctLine."Order Line No.");
                if PalletLines.findfirst then begin
                    ItemLedgerEntry."Pallet ID" := PalletLines."Pallet ID";
                    ItemLedgerEntry.modify;
                end;
            end;
        end;
    end;

    //Adding Packing Materials - Global Function
    procedure AddMaterials(var PalletHeader: Record "Pallet Header")
    begin
        PalletLines.reset;
        PalletLines.setrange("Pallet ID", PalletHeader."Pallet ID");

        if PalletLines.FindFirst() then begin

            BomComponent.reset;
            BomComponent.setrange("Parent Item No.", PalletLines."Item No.");
            if BomComponent.findset then
                repeat
                    if not PackingMaterials.get(PalletLines."Pallet ID",
                        BomComponent."No.", BomComponent."Unit of Measure Code") then begin
                        PackingMaterials.init;
                        PackingMaterials."Pallet ID" := PalletLines."Pallet ID";
                        PackingMaterials."Item No." := BomComponent."No.";
                        packingmaterials."Line No." := GetLastEntryPacking(PalletHeader);
                        PackingMaterials.Description := BomComponent.Description;
                        PackingMaterials."Reusable Item" := BomComponent."Reusable item";
                        if BomComponent."Fixed Value" then begin
                            PackingMaterials.Quantity := BomComponent."Quantity per";
                            PackingMaterials."Fixed Value" := true;
                        end else
                            PackingMaterials.Quantity := BomComponent."Quantity per" * PalletLines.Quantity;
                        PackingMaterials."Unit of Measure Code" := BomComponent."Unit of Measure Code";
                        PackingMaterials."Location Code" := PalletHeader."Location Code";
                        PackingMaterials.insert;

                    end
                    else begin
                        if PackingMaterials."Fixed Value" then begin
                            if BomComponent."Fixed Value" then begin
                                if BomComponent."Quantity per" > PackingMaterials.Quantity then
                                    PackingMaterials.Quantity := BomComponent."Quantity per";
                            end else
                                if BomComponent."Quantity per" * PalletLines.Quantity > PackingMaterials.Quantity then
                                    PackingMaterials.Quantity := BomComponent."Quantity per" * PalletLines.Quantity;
                        end else begin
                            if BomComponent."Fixed Value" then begin
                                if BomComponent."Quantity per" > PackingMaterials.Quantity then
                                    PackingMaterials.Quantity := BomComponent."Quantity per";
                            end else
                                PackingMaterials.Quantity += BomComponent."Quantity per" * PalletLines.Quantity;
                            //end;
                            PackingMaterials.modify;
                        end;
                    end;


                until BomComponent.next = 0;
        end;
    end;

    //Delete Packing Materials - Global Function
    local procedure DeleteMaterials(var PalletHeader: Record "Pallet Header")
    begin
        PackingMaterials.reset;
        PackingMaterials.setrange(PackingMaterials."Pallet ID", PalletHeader."Pallet ID");
        if PackingMaterials.FindSet()
            then
            PackingMaterials.deleteall();
    end;

    //After Validate "Pallet ID" - on Pallet Header table
    [EventSubscriber(ObjectType::table, database::"Pallet Header", 'OnAfterValidateEvent', 'Pallet ID', true, true)]
    local procedure OnAfterValidatePalletID(var Rec: Record "Pallet Header"; var xRec: Record "Pallet Header")
    begin
        if rec."Pallet ID" <> xrec."Pallet ID" then
            error(err07);
    end;

    //On Before Action - Close - Pallet Card
    [EventSubscriber(ObjectType::page, page::"Pallet Card", 'OnBeforeActionEvent', 'Close Pallet', true, true)]
    local procedure OnBeforeActionPalletCard(var Rec: Record "Pallet Header")
    var
        ItemRec: Record Item;
        PalletLine: Record "Pallet Line";
        BoolCheck: Boolean;
    begin
        BoolCheck := false;
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", rec."Pallet ID");
        if PalletLine.findset then
            repeat
                if ItemRec.get(PalletLine."Item No.") then
                    if ItemRec."Item Tracking Code" <> '' then
                        if PalletLine."Lot Number" = '' then
                            BoolCheck := true;
            until PalletLine.next = 0;
        if BoolCheck then error(Err08);
    end;

    //On Before Action - Close - Pallet List
    [EventSubscriber(ObjectType::page, page::"Pallet Card", 'OnBeforeActionEvent', 'Close Pallet', true, true)]
    local procedure OnBeforeActionPalletList(var Rec: Record "Pallet Header")
    var
        ItemRec: Record Item;
        PalletLine: Record "Pallet Line";
        BoolCheck: Boolean;
    begin
        BoolCheck := false;
        PalletLine.reset;
        PalletLine.setrange("Pallet ID", rec."Pallet ID");
        if PalletLine.findset then
            repeat
                if ItemRec.get(PalletLine."Item No.") then
                    if ItemRec."Item Tracking Code" <> '' then
                        if PalletLine."Lot Number" = '' then
                            BoolCheck := true;
            until PalletLine.next = 0;
        if BoolCheck then error(Err08);
    end;


    //Choose Packing Materials
    procedure ChoosePackingMaterials(var pPalletHeader: Record "Pallet Header")
    var
        PackingMaterialConfirm: Label 'Do you want to return the packing material into stock?';
        PalletLedgerEntry: Record "Pallet Ledger Entry";
        ItemRec: Record Item;
        PMSelect: Record "Packing Materials Select" temporary;
        RecGItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        LineNumber: Integer;
        PackingMaterials: Record "Packing Material Line";
    begin
        PMSelect.Reset();
        if PMSelect.findset then
            pmselect.deleteall;

        if confirm(PackingMaterialConfirm) then begin
            PackingMaterials.reset;
            PackingMaterials.setrange("Pallet ID", pPalletHeader."Pallet ID");
            if PackingMaterials.findset then
                repeat
                    PMSelect.init;
                    PMSelect."Pallet ID" := pPalletHeader."Pallet ID";
                    PMSelect."PM Item No." := PackingMaterials."Item No.";
                    PMSelect."Pallet Packing Line No." := PackingMaterials."Line No.";
                    PMSelect."PM Item Description" := PackingMaterials.Description;
                    PMSelect.validate("Unit of Measure", PackingMaterials."Unit of Measure Code");
                    PMSelect.Quantity := PackingMaterials.Quantity;
                    pmselect.insert;
                until PackingMaterials.next = 0;
            page.runmodal(page::"Packing Materials Select", PMSelect);
        end;
    end;

    local procedure GetLastEntry(): Integer
    var
        PalletLedgerEntry: Record "Pallet Ledger Entry";
    begin
        PalletLedgerEntry.reset;
        if PalletLedgerEntry.findlast then
            exit(PalletLedgerEntry."Entry No." + 1)
        else
            exit(1);
    end;

    //Update No. of Copies
    procedure UpdateNoOfCopies(PalletHeader: Record "Pallet Header");
    var
        Palletline: Record "Pallet Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        Palletline.reset;
        Palletline.setrange(Palletline."Pallet ID", PalletHeader."Pallet ID");
        if palletline.findset then
            repeat
                if ItemUOM.get(Palletline."Item No.", Palletline."Unit of Measure") then begin
                    Palletline."Item Label No. of Copies" := round(Palletline.Quantity, 1) *
                        ItemUOM."Sticker Note Relation";
                    Palletline.modify;
                end;
            until palletline.next = 0;
    end;

    procedure GetLastEntryPacking(var pPalletHeader: Record "Pallet Header"): Integer
    var
        PackingMaterialLine: Record "Packing Material Line";
    begin
        PackingMaterialLine.reset;
        PackingMaterialLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        if PackingMaterialLine.findlast then
            exit(PackingMaterialLine."Line No." + 1)
        else
            exit(1);
    end;

    //Get First Purchase Header
    procedure GetFirstPO(var pPalletHeader: Record "Pallet Header"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PalletLines.Reset();
        PalletLines.SetRange("Pallet ID", pPalletHeader."Pallet ID");
        PalletLines.SetFilter("Purchase Order No.", '<>%1', '');
        if PalletLines.findfirst then begin
            exit(PalletLines."Purchase Order No.");
        end else
            exit('');
    end;

    //Get Vendor Shipment No.
    procedure GetVendorShipmentNoFromPalletLine(var pPalletLine: Record "pallet line"): code[35]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.reset;
        PurchaseHeader.setrange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.setrange("Batch Number", pPalletLine."Lot Number");
        if PurchaseHeader.findfirst then
            exit(PurchaseHeader."Vendor Shipment No.");
    end;

    Procedure CreateNegAdjustmentToPackingMaterials(pPalletHeader: Record "Pallet Header"; Lot: code[20])
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        PalletFunctionUI: Codeunit "UI Pallet Functions";
        LineNumber: Integer;
        LpurchaseHeader: Record "Purchase Header";
        LpalletLine: Record "Pallet Line";
        PackingMaterials: Record "Packing Material Line";
        ReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        PalletLedgerType: Enum "Pallet Ledger Type";
        POFunctionsUI: Codeunit "Purch. UI Functions";
        maxEntry: Integer;
        RecItem: Record Item;
        boolMW: Boolean;
    begin
        /*  boolMW := false;
          LpalletLine.Reset();
          LpalletLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
          if LpalletLine.FindSet() then
              repeat
                  LpurchaseHeader.Reset();
                  LpurchaseHeader.SetRange("Document Type", LpurchaseHeader."Document Type"::Order);
                  LpurchaseHeader.SetRange("No.", LpalletLine."Purchase Order No.");
                  LpurchaseHeader.SetRange("Microwave Process PO", true);
                  if LpurchaseHeader.FindSet() then
                      boolMW := true;
              until LpalletLine.Next() = 0;

          if boolMW then begin*/

        PurchaseProcessSetup.Get();

        PackingMaterials.Reset();
        PackingMaterials.Setrange("Pallet ID", pPalletHeader."Pallet ID");
        PackingMaterials.SetRange("Reusable Item", true);
        if PackingMaterials.FindSet() then begin
            ItemJournalLine.reset;
            ItemJournalLine.setrange("Journal Template Name", 'ITEM');
            ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
            if ItemJournalLine.FindLast() then
                LineNumber := ItemJournalLine."Line No." + 10000
            else
                LineNumber := 10000;
            repeat
                ItemJournalLine.init;
                ItemJournalLine.validate("Journal Template Name", 'ITEM');
                ItemJournalLine.validate("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                ItemJournalLine.validate("Line No.", LineNumber);
                ItemJournalLine."Source Code" := 'ITEMJNL';
                ItemJournalLine.insert(true);
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
                ItemJournalLine.validate("Posting Date", PalletFunctionUI.GetCurrTime);
                ItemJournalLine."Document No." := pPalletHeader."Pallet ID";
                ItemJournalLine."Document Date" := PalletFunctionUI.GetCurrTime;

                ItemJournalLine.validate("Item No.", PackingMaterials."Item No.");
                // ItemJournalLine.validate("Variant Code", PackingMaterials.v);
                ItemJournalLine.validate("Location Code", PackingMaterials."Location Code");
                ItemJournalLine.validate(Quantity, PackingMaterials.Quantity);
                ItemJournalLine.validate("Pallet ID", pPalletHeader."Pallet ID");
                ItemJournalLine."Pallet Type" := pPalletHeader."Pallet Type";
                ItemJournalLine.modify;

                if RecItem.get(PackingMaterials."Item No.") then
                    if RecItem."Lot Nos." <> '' then begin
                        PurchaseProcessSetup.get;
                        ReservationEntry2.reset;
                        if ReservationEntry2.findlast then
                            maxEntry := ReservationEntry2."Entry No." + 1;
                        ItemJournalLine."Lot No." := Lot;
                        ItemJournalLine.Modify();

                        RecGReservationEntry.init;
                        RecGReservationEntry."Entry No." := MaxEntry;
                        RecGReservationEntry."Reservation Status" := RecGReservationEntry."Reservation Status"::Prospect;
                        RecGReservationEntry."Creation Date" := PalletFunctionUI.GetCurrTime;
                        RecGReservationEntry."Created By" := UserId;
                        RecGReservationEntry."Expected Receipt Date" := PalletFunctionUI.GetCurrTime;
                        RecGReservationEntry."Source Type" := 83;
                        RecGReservationEntry."Source Subtype" := 2;
                        RecGReservationEntry."Source ID" := 'ITEM';
                        RecGReservationEntry."Source Ref. No." := LineNumber;
                        RecGReservationEntry."Source Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        RecGReservationEntry.validate("Location Code", PackingMaterials."Location Code");
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        RecGReservationEntry.validate("Item No.", PackingMaterials."Item No.");
                        RecGReservationEntry.validate("Quantity (Base)", PackingMaterials."Quantity");
                        RecGReservationEntry.validate(Quantity, PackingMaterials."Quantity");
                        RecGReservationEntry.Positive := true;
                        RecGReservationEntry."Lot No." := Lot;
                        RecGReservationEntry.insert;

                    end;
                PalletLedgerFunctions.PosPalletLedgerEntryItem(ItemJournalLine, PalletLedgerType::"Return Packing Materials");
                LineNumber += 10000;

            until PackingMaterials.Next() = 0;
        end;

    end;

    procedure ExportToExcelPODetials(PONumber: Code[20]; var
                                                             PORec: Record "Purchase Header");
    var
        LPalletLine: Record "Pallet Line";
        LPalletHeader: Record "Pallet Header";
        LPurchaseLine: Record "Purchase Line";
        LPurchaseHeader: Record "Purchase Header";
        LSalesLine: Record "Sales Line";
        LWarehousePallet: Record "Warehouse Pallet";
        LPostedWarehousePallet: Record "Posted Warehouse Pallet";
        ExcelBuffer: Record "Excel Buffer" temporary;
        LInStr: InStream;
        LOutStr: OutStream;
        LPath: Text;
    begin
        CLEARALL;
        IF ExcelBuffer.FINDSET THEN
            ExcelBuffer.DELETEALL;

        ExcelBuffer.AddColumn('Purchase Order No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Purchase Order Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet ID', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet Type', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet Status', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sales Order No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sales Order Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Warehose Shipment No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Warehose Shipment Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Posted Warehose Shipment No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Posted Warehose Shipment Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.NewRow;

        LPurchaseHeader.Reset();
        LPurchaseHeader.SetRange("Document Type", LPurchaseHeader."Document Type"::Order);
        if PONumber <> '' then
            LPurchaseHeader.SetRange("No.", PONumber)
        else
            LPurchaseHeader.CopyFilters(PORec);
        if LPurchaseHeader.FindSet() then
            repeat
                LPurchaseLine.Reset();
                LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                LPurchaseLine.SetRange("Document No.", LPurchaseHeader."No.");
                if LPurchaseLine.FindSet() then
                    repeat
                        LPalletLine.Reset();
                        LPalletLine.SetCurrentKey("Purchase Order No.", "Purchase Order Line No.");
                        LPalletLine.SetRange("Purchase Order No.", LPurchaseLine."Document No.");
                        LPalletLine.SetRange("Purchase Order Line No.", LPurchaseLine."Line No.");
                        IF LPalletLine.FindSet() then begin
                            repeat
                                ExcelBuffer.AddColumn(LPalletLine."Purchase Order No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPalletLine."Purchase Order Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(LPalletLine."Pallet ID", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPalletLine."Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                LPalletHeader.Get(LPalletLine."Pallet ID");
                                ExcelBuffer.AddColumn(LPalletHeader."Pallet Type", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPalletHeader."Pallet Status"), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                LPostedWarehousePallet.Reset();
                                LPostedWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                                LPostedWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                                If LPostedWarehousePallet.FindLast() then begin
                                    if LPalletHeader."Exist in warehouse shipment" then begin
                                        ExcelBuffer.AddColumn(LPostedWarehousePallet."Sales Order No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        ExcelBuffer.AddColumn(format(LPostedWarehousePallet."Sales Order Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    end else begin
                                        ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    end;
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn(LPostedWarehousePallet."Whse Shipment No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn(format(LPostedWarehousePallet."Whse Shipment Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                end else begin
                                    LWarehousePallet.Reset();
                                    LWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                                    LWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                                    If LWarehousePallet.FindLast() then begin
                                        if LPalletHeader."Exist in warehouse shipment" then begin
                                            ExcelBuffer.AddColumn(LWarehousePallet."Sales Order No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                            ExcelBuffer.AddColumn(format(LWarehousePallet."Sales Order Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        end else begin
                                            ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                            ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        end;
                                        ExcelBuffer.AddColumn(LWarehousePallet."Whse Shipment No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        ExcelBuffer.AddColumn(format(LWarehousePallet."Whse Shipment Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    end;
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                end;

                                ExcelBuffer.NewRow;
                            until LPalletLine.Next() = 0;
                        end else begin
                            ExcelBuffer.AddColumn(LPurchaseLine."Document No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(format(LPurchaseLine."Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.NewRow;
                        end;
                    until LPurchaseLine.Next() = 0;
            until LPurchaseHeader.Next() = 0;

        LPath := StrSubstNo('PO - %1', PONumber) + Format(Today());
        ExcelBuffer.CreateNewBook(LPath);
        ExcelBuffer.WriteSheet(LPath, CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();

    end;

    procedure ExportToExcelPurchaseItemsStatistic(PONumber: Code[20]; var PORec: Record "Purchase Header");
    var
        Rec: Record "Purchase Items Statistic";
        ExcelBuffer: Record "Excel Buffer" temporary;
        LInStr: InStream;
        LOutStr: OutStream;
        LPath: Text;
        LPurchaseLine: Record "Purchase Line";
        LItemAttribute: Record "Item Attribute";
        LItemAttributeValue: Record "Item Attribute Value";
        LItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        LSizeItemAttributeID: Integer;
        LGradeItemAttributeID: Integer;
        LSizeItemAttributeValue: Text;
        LGradeItemAttributeValue: Text;
        LRecPurchaseItemsStatistic: Record "Purchase Items Statistic";
        LPurchaseHeader: Record "Purchase Header";
        LItemUnitofMeasure: Record "Item Unit of Measure";
        LQuantityLine: Decimal;
        LTotal: Decimal;
        LCurrentGrade: Text;
        LPreviousGrade: Text;
    begin
        Rec.Reset();
        Rec.SetRange("User", UserId);
        if Rec.FindSet() then Rec.DeleteAll();
        CLEARALL;
        IF ExcelBuffer.FINDSET THEN
            ExcelBuffer.DELETEALL;

        LItemAttribute.Reset();
        LItemAttribute.SetRange(Name, 'Size');
        LItemAttribute.FindFirst();
        LSizeItemAttributeID := LItemAttribute.ID;
        LItemAttribute.SetRange(Name, 'Grade');
        LItemAttribute.FindFirst();
        LGradeItemAttributeID := LItemAttribute.ID;

        LPurchaseHeader.Reset();
        LPurchaseHeader.SetRange("Document Type", LPurchaseHeader."Document Type"::Order);
        if PONumber <> '' then
            LPurchaseHeader.SetRange("No.", PONumber)
        else
            LPurchaseHeader.CopyFilters(PORec);
        if LPurchaseHeader.FindSet() then
            repeat
                LTotal := 0;
                LPurchaseLine.Reset();
                LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                LPurchaseLine.SetRange("Document No.", LPurchaseHeader."No.");
                LPurchaseLine.SetRange(Type, LPurchaseLine.Type::Item);
                LPurchaseLine.SetFilter("Quantity Received", '<>%1', 0);
                LPurchaseLine.SetFilter("Line Discount %", '<>%1', 100);
                if LPurchaseLine.FindSet() then begin
                    repeat
                        LSizeItemAttributeValue := '';
                        LGradeItemAttributeValue := '';
                        LQuantityLine := 0;
                        if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LSizeItemAttributeID) then begin
                            if LItemAttributeValue.Get(LSizeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID") then
                                LSizeItemAttributeValue := LItemAttributeValue.Value;
                        end;

                        if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LGradeItemAttributeID) then begin
                            LItemAttributeValue.Get(LGradeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID");
                            LGradeItemAttributeValue := LItemAttributeValue.Value;
                        end;

                        if LGradeItemAttributeValue <> '' then begin
                            LQuantityLine := LPurchaseLine."Quantity Received";
                            if LPurchaseLine."Unit of Measure Code" <> 'KG' then begin
                                LItemUnitofMeasure.Reset();
                                LItemUnitofMeasure.SetRange("Item No.", LPurchaseLine."No.");
                                LItemUnitofMeasure.SetRange(Code, 'KG');
                                LItemUnitofMeasure.FindFirst();
                                LQuantityLine *= LItemUnitofMeasure."Qty. per Unit of Measure";
                            end;

                            IF not Rec.Get(LGradeItemAttributeValue, LSizeItemAttributeValue, LPurchaseLine."Document No.", UserId) then begin
                                Rec.Init();
                                Rec."User" := UserId;
                                Rec."Purchase Number" := LPurchaseHeader."No.";
                                Rec.Grade := LGradeItemAttributeValue;
                                Rec.Size := LSizeItemAttributeValue;
                                Rec.TotalSize := LQuantityLine;
                                Rec."PO Line Amount" := (LPurchaseLine."Unit Cost (LCY)" * LQuantityLine);
                                if not Rec.Insert() then Rec.Modify();
                            end else begin
                                Rec.TotalSize += LQuantityLine;
                                Rec."PO Line Amount" += (LPurchaseLine."Unit Cost (LCY)" * LQuantityLine);
                                Rec.Modify();
                            end;
                        end;
                    until LPurchaseLine.Next() = 0;

                    Rec.Reset();
                    Rec.SetRange(User, UserId);
                    Rec.SetRange("Purchase Number", LPurchaseHeader."No.");
                    if Rec.FindSet() then
                        repeat
                            LRecPurchaseItemsStatistic.Reset();
                            LRecPurchaseItemsStatistic.SetRange(User, UserId);
                            LRecPurchaseItemsStatistic.SetRange(Grade, Rec.Grade);
                            LRecPurchaseItemsStatistic.SetRange("Purchase Number", LPurchaseHeader."No.");
                            if LRecPurchaseItemsStatistic.FindSet() then
                                repeat
                                    Rec.TotalGrade += LRecPurchaseItemsStatistic.TotalSize;
                                until LRecPurchaseItemsStatistic.Next() = 0;
                            LTotal += Rec.TotalSize;
                            Rec.Modify();
                        until Rec.Next() = 0;

                    Rec.Reset();
                    Rec.SetRange(User, UserId);
                    Rec.SetRange("Purchase Number", LPurchaseHeader."No.");
                    if Rec.FindSet() then begin
                        ExcelBuffer.NewRow();
                        ExcelBuffer.AddColumn('Purchase Order No. ' + LPurchaseHeader."No.", FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.NewRow();
                        ExcelBuffer.NewRow();
                        ExcelBuffer.AddColumn('Grade', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Size', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Total Size', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Total Grade', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Proportion(%)', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Amount $', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.NewRow;
                        Rec.Ascending;
                        LCurrentGrade := '';
                        repeat
                            Rec.Proportion := Rec.TotalSize / LTotal * 100;
                            Rec.Modify();
                            ExcelBuffer.AddColumn(Rec.Grade, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(Rec.Size, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(Rec.TotalSize, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.AddColumn(Rec.TotalGrade, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.AddColumn(Rec.Proportion, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.AddColumn(Rec."PO Line Amount", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.NewRow();
                        until Rec.Next() = 0;
                    end;
                end;
            until LPurchaseHeader.Next() = 0;

        LPath := StrSubstNo('Grading Statistics') + Format(Today());
        ExcelBuffer.CreateNewBook(LPath);
        ExcelBuffer.WriteSheet(LPath, CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
    end;


    procedure ExportToExcelPODetialsArchive(PONumber: Code[20]; var PORec: Record "Purchase Header Archive"; pVersion: Integer);
    var
        LPalletLine: Record "Pallet Line";
        LPalletHeader: Record "Pallet Header";
        LPurchaseLine: Record "Purchase Line Archive";
        LPurchaseHeader: Record "Purchase Header Archive";
        LWarehousePallet: Record "Warehouse Pallet";
        LSalesLine: Record "Sales Line";
        LPostedWarehousePallet: Record "Posted Warehouse Pallet";
        ExcelBuffer: Record "Excel Buffer" temporary;
        LInStr: InStream;
        LOutStr: OutStream;
        LPath: Text;
    begin
        CLEARALL;
        IF ExcelBuffer.FINDSET THEN
            ExcelBuffer.DELETEALL;

        ExcelBuffer.AddColumn('Purchase Order No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Purchase Order Version', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Purchase Order Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet ID', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet Type', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Pallet Status', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sales Order No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Sales Order Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Warehose Shipment No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Warehose Shipment Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Posted Warehose Shipment No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Posted Warehose Shipment Line No.', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.NewRow;

        LPurchaseHeader.Reset();
        LPurchaseHeader.SetRange("Document Type", LPurchaseHeader."Document Type"::Order);
        if PONumber <> '' then
            LPurchaseHeader.SetRange("No.", PONumber)
        else
            LPurchaseHeader.CopyFilters(PORec);
        if pVersion <> 0 then
            LPurchaseHeader.SetRange("Version No.", pVersion);
        if LPurchaseHeader.FindSet() then
            repeat
                LPurchaseLine.Reset();
                LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                LPurchaseLine.SetRange("Document No.", LPurchaseHeader."No.");
                LPurchaseLine.SetRange("Version No.", LPurchaseHeader."Version No.");
                if LPurchaseLine.FindSet() then
                    repeat
                        LPalletLine.Reset();
                        LPalletLine.SetCurrentKey("Purchase Order No.", "Purchase Order Line No.");
                        LPalletLine.SetRange("Purchase Order No.", LPurchaseLine."Document No.");
                        LPalletLine.SetRange("Purchase Order Line No.", LPurchaseLine."Line No.");
                        IF LPalletLine.FindSet() then begin
                            repeat

                                ExcelBuffer.AddColumn(LPalletLine."Purchase Order No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPurchaseHeader."Version No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPalletLine."Purchase Order Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(LPalletLine."Pallet ID", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPalletLine."Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                LPalletHeader.Get(LPalletLine."Pallet ID");
                                ExcelBuffer.AddColumn(LPalletHeader."Pallet Type", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                ExcelBuffer.AddColumn(format(LPalletHeader."Pallet Status"), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                LPostedWarehousePallet.Reset();
                                LPostedWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                                LPostedWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                                If LPostedWarehousePallet.FindLast() then begin
                                    if LPalletHeader."Exist in warehouse shipment" then begin
                                        ExcelBuffer.AddColumn(LPostedWarehousePallet."Sales Order No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        ExcelBuffer.AddColumn(format(LPostedWarehousePallet."Sales Order Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    end else begin
                                        ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    end;

                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn(LPostedWarehousePallet."Whse Shipment No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn(format(LPostedWarehousePallet."Whse Shipment Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                end else begin
                                    LWarehousePallet.Reset();
                                    LWarehousePallet.SetRange("Pallet ID", LPalletLine."Pallet ID");
                                    LWarehousePallet.SetRange("Pallet Line No.", LPalletLine."Line No.");
                                    If LWarehousePallet.FindLast() then begin
                                        if LPalletHeader."Exist in warehouse shipment" then begin
                                            ExcelBuffer.AddColumn(LWarehousePallet."Sales Order No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                            ExcelBuffer.AddColumn(format(LWarehousePallet."Sales Order Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        end else begin
                                            ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                            ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                        end;
                                    end;
                                    ExcelBuffer.AddColumn(LWarehousePallet."Whse Shipment No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn(format(LWarehousePallet."Whse Shipment Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                    ExcelBuffer.AddColumn('', FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                                end;

                                ExcelBuffer.NewRow;
                            until LPalletLine.Next() = 0;
                        end else begin
                            ExcelBuffer.AddColumn(LPurchaseLine."Document No.", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(format(LPurchaseLine."Version No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(format(LPurchaseLine."Line No."), FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.NewRow;
                        end;
                    until LPurchaseLine.Next() = 0;
            until LPurchaseHeader.Next() = 0;

        LPath := StrSubstNo('PO - %1', PONumber) + Format(Today());
        ExcelBuffer.CreateNewBook(LPath);
        ExcelBuffer.WriteSheet(LPath, CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();

    end;

    procedure ExportToExcelPurchaseItemsStatisticArchive(PONumber: Code[20]; var PORec: Record "Purchase Header Archive"; pVersion: Integer);
    var
        Rec: Record "Purchase Items Statistic";
        ExcelBuffer: Record "Excel Buffer" temporary;
        LInStr: InStream;
        LOutStr: OutStream;
        LPath: Text;
        LPurchaseLine: Record "Purchase Line Archive";
        LPostedWarhousePallet: Record "Posted Warehouse Pallet";
        LPalletLine: Record "Pallet Line";
        LItemAttribute: Record "Item Attribute";
        LItemAttributeValue: Record "Item Attribute Value";
        LItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        LSizeItemAttributeID: Integer;
        LGradeItemAttributeID: Integer;
        LSizeItemAttributeValue: Text;
        LGradeItemAttributeValue: Text;
        LRecPurchaseItemsStatistic: Record "Purchase Items Statistic";
        LPurchaseHeader: Record "Purchase Header Archive";
        LItemUnitofMeasure: Record "Item Unit of Measure";
        LQuantityLine: Decimal;
        LTotal: Decimal;
        LCurrentGrade: Text;
        LPreviousGrade: Text;
    begin
        Rec.Reset();
        Rec.SetRange("User", UserId);
        if Rec.FindSet() then Rec.DeleteAll();
        CLEARALL;
        IF ExcelBuffer.FINDSET THEN
            ExcelBuffer.DELETEALL;

        LItemAttribute.Reset();
        LItemAttribute.SetRange(Name, 'Size');
        LItemAttribute.FindFirst();
        LSizeItemAttributeID := LItemAttribute.ID;
        LItemAttribute.SetRange(Name, 'Grade');
        LItemAttribute.FindFirst();
        LGradeItemAttributeID := LItemAttribute.ID;

        LPurchaseHeader.Reset();
        LPurchaseHeader.SetRange("Document Type", LPurchaseHeader."Document Type"::Order);
        if PONumber <> '' then
            LPurchaseHeader.SetRange("No.", PONumber)
        else
            LPurchaseHeader.CopyFilters(PORec);

        if pVersion <> 0 then
            LPurchaseHeader.SetRange("Version No.", pVersion);
        if LPurchaseHeader.FindSet() then
            repeat
                LTotal := 0;
                LPurchaseLine.Reset();
                LPurchaseLine.SetRange("Document Type", LPurchaseLine."Document Type"::Order);
                LPurchaseLine.SetRange("Document No.", LPurchaseHeader."No.");
                LPurchaseLine.SetRange(Type, LPurchaseLine.Type::Item);
                LPurchaseLine.SetFilter("Quantity Received", '<>%1', 0);
                LPurchaseLine.SetFilter("Line Discount %", '<>%1', 100);
                LPurchaseLine.SetRange("Version No.", LPurchaseHeader."Version No.");
                if LPurchaseLine.FindSet() then begin
                    repeat
                        LSizeItemAttributeValue := '';
                        LGradeItemAttributeValue := '';
                        LQuantityLine := 0;
                        if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LSizeItemAttributeID) then begin
                            if LItemAttributeValue.Get(LSizeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID") then
                                LSizeItemAttributeValue := LItemAttributeValue.Value;
                        end;

                        if LItemAttributeValueMapping.Get(27, LPurchaseLine."No.", LGradeItemAttributeID) then begin
                            LItemAttributeValue.Get(LGradeItemAttributeID, LItemAttributeValueMapping."Item Attribute Value ID");
                            LGradeItemAttributeValue := LItemAttributeValue.Value;
                        end;
                        if LGradeItemAttributeValue <> '' then begin
                            LQuantityLine := LPurchaseLine."Quantity Received";
                            if LPurchaseLine."Unit of Measure Code" <> 'KG' then begin
                                LItemUnitofMeasure.Reset();
                                LItemUnitofMeasure.SetRange("Item No.", LPurchaseLine."No.");
                                LItemUnitofMeasure.SetRange(Code, 'KG');
                                LItemUnitofMeasure.FindFirst();
                                LQuantityLine *= LItemUnitofMeasure."Qty. per Unit of Measure";
                            end;
                            IF not Rec.Get(LGradeItemAttributeValue, LSizeItemAttributeValue, LPurchaseLine."Document No.", UserId) then begin
                                Rec.Init();
                                Rec."User" := UserId;
                                Rec."Purchase Number" := LPurchaseHeader."No.";
                                Rec.Grade := LGradeItemAttributeValue;
                                Rec.Size := LSizeItemAttributeValue;
                                Rec.TotalSize := LQuantityLine;
                                Rec."PO Line Amount" := (LPurchaseLine."Unit Cost (LCY)" * LQuantityLine);
                                if not Rec.Insert() then Rec.Modify();
                            end else begin
                                Rec.TotalSize += LQuantityLine;
                                Rec."PO Line Amount" += (LPurchaseLine."Unit Cost (LCY)" * LQuantityLine);
                                Rec.Modify();
                            end;
                        end;
                    until LPurchaseLine.Next() = 0;

                    Rec.Reset();
                    Rec.SetRange(User, UserId);
                    Rec.SetRange("Purchase Number", LPurchaseHeader."No.");
                    if Rec.FindSet() then
                        repeat
                            LRecPurchaseItemsStatistic.Reset();
                            LRecPurchaseItemsStatistic.SetRange(User, UserId);
                            LRecPurchaseItemsStatistic.SetRange(Grade, Rec.Grade);
                            LRecPurchaseItemsStatistic.SetRange("Purchase Number", LPurchaseHeader."No.");
                            if LRecPurchaseItemsStatistic.FindSet() then
                                repeat
                                    Rec.TotalGrade += LRecPurchaseItemsStatistic.TotalSize;
                                until LRecPurchaseItemsStatistic.Next() = 0;
                            LTotal += Rec.TotalSize;

                            Rec.Modify();
                        until Rec.Next() = 0;

                    Rec.Reset();
                    Rec.SetRange(User, UserId);
                    Rec.SetRange("Purchase Number", LPurchaseHeader."No.");
                    if Rec.FindSet() then begin
                        ExcelBuffer.NewRow();
                        ExcelBuffer.AddColumn('Purchase Order No. ' + LPurchaseHeader."No." + ' Version: ' + Format(LPurchaseHeader."Version No."), FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.NewRow();
                        ExcelBuffer.AddColumn('Grade', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Size', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Total Size', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Total Grade', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Proportion(%)', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.AddColumn('Amount $', FALSE, '', TRUE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                        ExcelBuffer.NewRow;
                        Rec.Ascending;
                        repeat
                            Rec.Proportion := Rec.TotalSize / LTotal * 100;
                            Rec.Modify();
                            ExcelBuffer.AddColumn(Rec.Grade, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(Rec.Size, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Text);
                            ExcelBuffer.AddColumn(Rec.TotalSize, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.AddColumn(Rec.TotalGrade, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.AddColumn(Rec.Proportion, FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.AddColumn(Rec."PO Line Amount", FALSE, '', FALSE, FALSE, FALSE, '', ExcelBuffer."Cell Type"::Number);
                            ExcelBuffer.NewRow();
                        until Rec.Next() = 0;
                    end;
                end;
            until LPurchaseHeader.Next() = 0;

        LPath := StrSubstNo('Grading Statistics') + Format(Today());
        ExcelBuffer.CreateNewBook(LPath);
        ExcelBuffer.WriteSheet(LPath, CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
    end;

    procedure CancelPallet(pPalletHeader: Record "Pallet Header");
    var
        ConfirmCancelPallet: Label 'Are you sure you want to cancel this pallet? pallet id: %1';
        Err10: Label 'Canceled status is allowed only for open or close status pallet and if the pallet not exist in warehouse shipment';
        Err11: Label 'The pallet can not be cancelled as it is allocated to an open document (shipment, transfer order atc.)';
        LPalletLedgerEntry: Record "Pallet Ledger Entry";
        LPurchaseHeader: Record "Purchase Header";
        LPurchaseLine: Record "Purchase Line";
        LPalletLine: Record "Pallet Line";
        LCommentsonPurchLine: Record "Purch. Comment Line";
        LCommentsonPurchLineLineNo: Integer;
        RecLItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "Pallet Process Setup";
        DocmentStatusMgmt: Codeunit "Release Purchase Document";
        isReleased: Boolean;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        LineNumber: Integer;
        RecGReservationEntry: Record "Pallet Reservation Entry";
        ReservationEntry: Record "Reservation Entry";
        PalletLedgerType: Enum "Pallet Ledger Type";
        ReservationEntry2: Record "Reservation Entry";
        MaxEntry: Integer;
        RecItem: Record Item;
        InventorySetup: Record "Inventory Setup";
        PostItemJnlLine: Boolean;
    begin

        if (pPalletHeader."Exist in warehouse shipment") or (pPalletHeader."Exist in Transfer Order") then
            Error(Err11);

        if (pPalletHeader."Pallet Status" in [pPalletHeader."Pallet Status"::Closed, pPalletHeader."Pallet Status"::Open]) and not (pPalletHeader."Exist in warehouse shipment") and not (pPalletHeader."Exist in Transfer Order") then begin
            if Confirm(StrSubstNo(ConfirmCancelPallet, pPalletHeader."Pallet ID")) then begin
                PalletSetup.get();

                ItemJournalLine.reset;
                ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                ItemJournalLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
                if ItemJournalLine.FindSet() then
                    ItemJournalLine.DeleteAll();

                LPalletLine.Reset();
                LPalletLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
                if pPalletHeader."Pallet Status" = pPalletHeader."Pallet Status"::Open then
                    LPalletLine.SetFilter("Lot Number", '<>%1', '');
                if LPalletLine.FindSet() then begin
                    PurchaseProcessSetup.get;
                    ItemJournalLine.reset;
                    ItemJournalLine.setrange("Journal Template Name", 'ITEM');
                    ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                    if ItemJournalLine.findlast then
                        LineNumber := ItemJournalLine."Line No." + 10000
                    else
                        LineNumber := 10000;
                    repeat
                        ItemJournalLine.init;
                        ItemJournalLine."Journal Template Name" := 'ITEM';
                        ItemJournalLine."Journal Batch Name" := PurchaseProcessSetup."Item Journal Batch";
                        ItemJournalLine."Line No." := LineNumber;
                        ItemJournalLine.insert;
                        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Negative Adjmt.";
                        ItemJournalLine.validate("Posting Date", Today);
                        ItemJournalLine.validate("Pallet ID", LPalletLine."Pallet ID");
                        ItemJournalLine."Document No." := LPalletLine."Pallet ID";
                        ItemJournalLine.Description := LPalletLine.Description;
                        ItemJournalLine.validate("Item No.", LPalletLine."Item No.");
                        ItemJournalLine.validate("Variant Code", LPalletLine."Variant Code");
                        ItemJournalLine."Lot No." := LPalletLine."Lot Number";
                        ItemJournalLine.validate("Location Code", LPalletLine."Location Code");
                        ItemJournalLine.Validate("Unit of Measure Code", LPalletLine."Unit of Measure");
                        ItemJournalLine.validate(Quantity, LPalletLine."Quantity");
                        ItemJournalLine.validate("Pallet ID", LPalletLine."Pallet ID");
                        ItemJournalLine.modify;

                        ReservationEntry2.reset;
                        if ReservationEntry2.findlast then
                            maxEntry := ReservationEntry2."Entry No." + 1;

                        ReservationEntry.init;
                        ReservationEntry."Entry No." := MaxEntry;
                        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
                        ReservationEntry."Creation Date" := Today;
                        ReservationEntry."Created By" := UserId;
                        ReservationEntry."Expected Receipt Date" := Today;
                        ReservationEntry."Source Type" := 83;
                        ReservationEntry."Source Subtype" := ItemJournalLine."Entry Type";
                        ReservationEntry."Source ID" := 'ITEM';
                        ReservationEntry."Source Ref. No." := LineNumber;
                        ReservationEntry."Source Batch Name" := PalletSetup."Disposal Batch";
                        ReservationEntry.validate("Location Code", LPalletLine."Location Code");
                        ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
                        ReservationEntry."Lot No." := LPalletLine."Lot Number";
                        ReservationEntry.validate("Item No.", LPalletLine."Item No.");
                        if LPalletLine."Variant Code" <> '' then
                            ReservationEntry.validate("Variant Code", LPalletLine."Variant Code");
                        ReservationEntry.validate("Quantity (Base)", -LPalletLine.Quantity);
                        ReservationEntry.validate(Quantity, -LPalletLine.Quantity);

                        ReservationEntry.insert;
                        lineNumber += 1000;

                        CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", ItemJournalLine);
                        PalletLedgerFunctions.NegPalletLedgerEntryItem(ItemJournalLine, PalletLedgerType::"Pallet Cancelled");
                    until LPalletLine.Next() = 0;
                end;
                TrackingLineFunctions.RemoveTrackingLineFromPO(pPalletHeader); //Remove Tracking Line to PO

                pPalletHeader.validate("Pallet Status", "Pallet Status"::Canceled);
                if pPalletHeader.Modify() then begin
                    LPalletLine.Reset();
                    LPalletLine.SetRange("Pallet ID", pPalletHeader."Pallet ID");
                    LPalletLine.SetFilter("Purchase Order No.", '<>%1', '');
                    if LPalletLine.FindSet() then
                        repeat
                            isReleased := false;
                            IF LPurchaseLine.Get(LPurchaseLine."Document Type"::Order, LPalletLine."Purchase Order No.", LPalletLine."Purchase Order Line No.") then begin
                                LPurchaseHeader.get(LPurchaseHeader."Document Type"::Order, LPurchaseLine."Document No.");
                                if LPurchaseHeader.Status <> LPurchaseHeader.Status::Open then begin
                                    LPurchaseHeader.Status := LPurchaseHeader.Status::Open;
                                    LPurchaseHeader.Modify();
                                    isReleased := true;
                                end;

                                LPurchaseLine.validate("Line Discount %", 100);
                                LPurchaseLine.Modify();
                                LCommentsonPurchLine.Init();
                                LCommentsonPurchLine."Document Type" := LCommentsonPurchLine."Document Type"::Order;
                                LCommentsonPurchLine."No." := LPurchaseLine."Document No.";
                                LCommentsonPurchLine."Document Line No." := LPurchaseLine."Line No.";
                                LCommentsonPurchLine."Line No." := 9999;
                                LCommentsonPurchLine.Date := Today();
                                LCommentsonPurchLine.Comment := StrSubstNo('Pallet %1 Cancelled', pPalletHeader."Pallet ID");
                                if not LCommentsonPurchLine.Insert()
                                then
                                    LCommentsonPurchLine.Modify();

                                if isReleased then begin
                                    LPurchaseHeader.Status := LPurchaseHeader.Status::Released;
                                    LPurchaseHeader.Modify();
                                end;

                            end;

                        until LPalletLine.Next() = 0;
                end;

            end;
        end else
            Error(Err10);

    end;


    Procedure CreatePosAdjustmentToPackingMaterials_PalletLine(pPalletLine: Record "Pallet Line"; pQuantityToReturn: Decimal)
    var
        PurchaseProcessSetup: Record "SPA Purchase Process Setup";
        ItemJournalLine: Record "Item Journal Line";
        PalletFunctionUI: Codeunit "UI Pallet Functions";
        LineNumber: Integer;
        LpurchaseHeader: Record "Purchase Header";
        LpalletLine: Record "Pallet Line";
        BOMComp: Record "BOM Component";
        ReservationEntry2: Record "Reservation Entry";
        RecGReservationEntry: Record "Reservation Entry";
        PalletLedgerType: Enum "Pallet Ledger Type";
        POFunctionsUI: Codeunit "Purch. UI Functions";
        maxEntry: Integer;
        RecItem: Record Item;
        LPackingMaterial: Record "Packing Material Line";
        boolMW: Boolean;
    begin
        PurchaseProcessSetup.Get();

        BOMComp.Reset();
        BOMComp.SetRange("Parent Item No.", pPalletLine."Item No.");
        BOMComp.SetFilter("No.", BOMComp."Parent Item No.");
        if BOMComp.FindSet() then begin

            ItemJournalLine.reset;
            ItemJournalLine.setrange("Journal Template Name", 'ITEM');
            ItemJournalLine.setrange("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
            if ItemJournalLine.FindLast() then
                LineNumber := ItemJournalLine."Line No." + 10000
            else
                LineNumber := 10000;
            repeat
                LPackingMaterial.Reset();
                LPackingMaterial.SetRange("Item No.", BOMComp."No.");
                LPackingMaterial.SetRange("Pallet ID", pPalletLine."Pallet ID");
                if LPackingMaterial.FindFirst() then begin
                    if LPackingMaterial.Quantity = pQuantityToReturn * BOMComp."Quantity per" then
                        LPackingMaterial.Delete()
                    else begin
                        LPackingMaterial.Quantity -= pQuantityToReturn * BOMComp."Quantity per";
                        LPackingMaterial.Modify();
                    end;
                end;
                ItemJournalLine.init;
                ItemJournalLine.validate("Journal Template Name", 'ITEM');
                ItemJournalLine.validate("Journal Batch Name", PurchaseProcessSetup."Item Journal Batch");
                ItemJournalLine.validate("Line No.", LineNumber);
                ItemJournalLine."Source Code" := 'ITEMJNL';
                ItemJournalLine.insert(true);
                ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
                ItemJournalLine.validate("Posting Date", Today);
                ItemJournalLine."Document No." := pPalletLine."Pallet ID";
                ItemJournalLine."Document Date" := Today;
                ItemJournalLine.validate("Item No.", BOMComp."No.");
                ItemJournalLine.validate("Location Code", pPalletLine."Location Code");
                if BOMComp."Fixed Value" then
                    ItemJournalLine.validate(Quantity, BOMComp."Quantity per")
                else
                    ItemJournalLine.validate(Quantity, BOMComp."Quantity per" * pQuantityToReturn);
                ItemJournalLine.validate("Pallet ID", pPalletLine."Pallet ID");
                ItemJournalLine.modify;

                if RecItem.get(BOMComp."No.") then
                    if RecItem."Lot Nos." <> '' then begin
                        PurchaseProcessSetup.get;
                        ReservationEntry2.reset;
                        if ReservationEntry2.findlast then
                            maxEntry := ReservationEntry2."Entry No." + 1;
                        ItemJournalLine."Lot No." := pPalletLine."Lot Number";
                        ItemJournalLine.Modify();

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
                        RecGReservationEntry.validate("Location Code", pPalletLine."Location Code");
                        RecGReservationEntry."Item Tracking" := RecGReservationEntry."Item Tracking"::"Lot No.";
                        RecGReservationEntry.validate("Item No.", BOMComp."No.");
                        RecGReservationEntry.validate("Quantity (Base)", ItemJournalLine.Quantity);
                        RecGReservationEntry.validate(Quantity, ItemJournalLine.Quantity);
                        RecGReservationEntry.Positive := true;
                        RecGReservationEntry."Lot No." := pPalletLine."Lot Number";
                        RecGReservationEntry.insert;

                    end;
                PalletLedgerFunctions.PosPalletLedgerEntryItem(ItemJournalLine, PalletLedgerType::"Return Packing Materials");

                LineNumber += 10000;

            until BOMComp.Next() = 0;



        end;

    end;

    procedure PostJournal(PalletID: code[20]);
    var
        LItemJournalLine: Record "Item Journal Line";
        PalletSetup: Record "SPA Purchase Process Setup";
    begin
        PalletSetup.Get();
        LItemJournalLine.Reset();
        LItemJournalLine.SetRange("Journal Template Name", 'ITEM');
        LItemJournalLine.SetRange("Journal Batch Name", PalletSetup."Item Journal Batch");
        LItemJournalLine.SetRange("Pallet ID", PalletID);
        LItemJournalLine.SetFilter(Quantity, '<>0');
        if LItemJournalLine.FindSet() then
            repeat
                CODEUNIT.RUN(CODEUNIT::"Item Jnl.-Post Line", LItemJournalLine);
            until LItemJournalLine.Next() = 0;

        LItemJournalLine.reset;
        LItemJournalLine.setrange("Journal Template Name", 'ITEM');
        LItemJournalLine.setrange("Journal Batch Name", PalletSetup."Item Journal Batch");
        LItemJournalLine.SetRange("Pallet ID", PalletID);
        if LItemJournalLine.FindSet() then
            LItemJournalLine.DeleteAll();
    end;

    var
        PalletLedgerFunctions: Codeunit "Pallet Ledger Functions";
        ItemLedgerFunctions: Codeunit "Item Ledger Functions";
        GPurchaseHeader: Record "Purchase Header";
        TrackingLineFunctions: Codeunit "Tracking Line Functions";
        UserSetup: Record "User Setup";
        PalletLines: Record "Pallet Line";
        BomComponent: Record "BOM Component";
        PackingMaterials: Record "Packing Material Line";
        GLinesText: Text;
        Err01: label 'User Cannot do the Following Operation - %1 - , Please contact system admin';
        Err02: label 'Cant reopen Pallet, Pallet Shipped';
        Err03: label 'Cant Reopen Pallet, Pulled to warehouse shipment';
        Err04: label 'There are no Lines, nothing to close';
        Err05: label 'There are no Quantities, nothing to close';
        Err06: label 'Lot No. exists in Pallet No. %1, Please remove Lot from the Pallet and Select Again';
        Err07: label 'You cannot enter Pallet ID Manualy';
        Err08: label 'not All lines have lot Numbers, Plea        se enter Tracking line';
        Err09: Label 'Cant reopen - Pallet is in status Consumed/Partially consumed';
}