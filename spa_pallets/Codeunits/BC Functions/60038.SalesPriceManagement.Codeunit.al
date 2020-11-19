codeunit 60038 "Sales Price Management"
{
    procedure LookupItemsForCustomers(var pCustomer: code[20]; var pDate: date; var RetSalesPrice: Record "Sales Price")
    var
        ItemList: Page "Item List";
        ItemRec: Record Item;
        Vendor: Record Vendor;
        ItemSelectByCustomer: Record "Item Select By customer" temporary;
    begin
        SalesPrice.reset;
        SalesPrice.setrange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.setrange("Sales Code", pcustomer);
        SalesPrice.setfilter("Ending Date", '=%1 | >=%2', pdate);
        SalesPrice.setfilter("Starting Date", '<=%1', pdate);
        if SalesPrice.findset then
            repeat
                if not ItemSelectByCustomer.get(SalesPrice."Item No.",
                    SalesPrice."Variant Code", SalesPrice."Unit of Measure Code") then begin
                    ItemSelectByCustomer.init;
                    ItemSelectByCustomer."Item No." := SalesPrice."Item No.";
                    ItemSelectByCustomer."Variant Code" := SalesPrice."Variant Code";
                    ItemSelectByCustomer."Unit of Measure" := SalesPrice."Unit of Measure Code";
                    ItemSelectByCustomer."Direct Unit Cost" := SalesPrice."Unit Price";
                    if ItemRec.get(SalesPrice."Item No.") then
                        ItemSelectByCustomer."Item Description" := ItemRec.Description;
                    ItemSelectByCustomer.insert;
                end;
            until SalesPrice.next = 0;

        IF PAGE.RUNMODAL(0, ItemSelectByCustomer) = ACTION::LookupOK THEN begin
            RetSalesPrice.reset;
            RetSalesPrice.setrange("Sales Type", RetSalesPrice."Sales Type"::Customer);
            RetSalesPrice.setrange("Sales Code", pcustomer);
            RetSalesPrice.setfilter("Ending Date", '=%1 | >=%2', pDate);
            RetSalesPrice.setfilter("Starting Date", '<=%1', pdate);
            RetSalesPrice.setfilter("Item No.", ItemSelectByCustomer."Item No.");
            RetSalesPrice.setfilter("Variant Code", ItemSelectByCustomer."Variant Code");
            RetSalesPrice.SetFilter("Unit of Measure Code", ItemSelectByCustomer."Unit of Measure");
            if RetSalesPrice.findfirst then;
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

    procedure ValidateItemsForCustomers(var pCustomer: code[20]; var pDate: date; var pItem: code[20]; var RetSalesPrice: Record "Sales Price");
    var
        ErrVendorItem: Label 'Item does not Exist on Vendor Price List';
        ItemRec: Record item;
        SalesPrice: Record "Sales Price";
        BoolResult: Boolean;
    begin
        BoolResult := false;
        if ItemRec.get(pItem) then begin
            SalesPrice.reset;
            SalesPrice.setrange("Sales Type", SalesPrice."Sales Type"::Customer);
            SalesPrice.setrange("Sales Code", pcustomer);
            SalesPrice.setfilter("Ending Date", '=%1 | >=%2', pDate);
            SalesPrice.setfilter("Starting Date", '<=%1', pdate);
            SalesPrice.setrange("Item No.", pItem);
            SalesPrice.setfilter("Unit of Measure Code", itemrec."Base Unit of Measure");
            if SalesPrice.findfirst then begin
                RetSalesPrice.Copy(SalesPrice);
                BoolResult := true;
            end
            else begin
                SalesPrice.reset;
                SalesPrice.setrange("Sales Type", SalesPrice."Sales Type"::Customer);
                SalesPrice.setrange("Sales Code", pcustomer);
                SalesPrice.setfilter("Ending Date", '=%1 | >=%2', pDate);
                SalesPrice.setfilter("Starting Date", '<=%1', pdate);
                SalesPrice.setrange("Item No.", pItem);
                SalesPrice.setfilter("Unit of Measure Code", '<>%1', itemrec."Base Unit of Measure");
                if SalesPrice.findfirst then begin
                    RetSalesPrice.copy(SalesPrice);
                    BoolResult := true;
                end;
            end;
        end;
        if not BoolResult then
            error(ErrVendorItem);
    end;

    //Get SPecial Price
    procedure GetSpecialPrice(var pCustomer: code[20]; var pDate: date; var pItem: code[20]): Decimal
    begin
        SalesPrice.reset;
        SalesPrice.setrange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.setrange("Sales Code", pcustomer);
        SalesPrice.setrange("Ending Date", 0D);
        SalesPrice.setfilter("Starting Date", '<=%1', pdate);
        SalesPrice.setrange("Item No.", pItem);
        if SalesPrice.findfirst then
            exit(SalesPrice."Unit Price");
    end;

    var
        SalesPrice: Record "Sales Price"; //Mark for Removal [V16.0]


}