pageextension 60001 PurchaseOrderSubPageExt extends "Purchase Order Subform"
{
    layout
    {
        modify("No.")
        {

            trigger OnLookup(VAR Text: Text): Boolean
            var
                SPAFunctions: Codeunit "SPA Purchase Functions";
                PurchaseHeader: Record "purchase header";
                PurchasePrice: Record "Purchase Price";
                ItemGot: code[20];
                DirectCostGot: Decimal;
                UOMGot: code[20];
                VariantGot: code[10];
            begin
                //Purchase Order - check Pricelist
                if rec.Type = rec.type::item then
                    if PurchaseHeader.get(rec."Document Type", rec."Document No.") then begin
                        SPAFunctions.LookupItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                            PurchaseHeader."Document Date", PurchasePrice);
                        ItemGot := PurchasePrice."Item No.";
                        DirectCostGot := PurchasePrice."Direct Unit Cost";
                        UOMGot := PurchasePrice."Unit of Measure Code";
                        VariantGot := PurchasePrice."Variant Code";

                        rec.validate("No.", ItemGot);
                        rec.validate("Variant Code", VariantGot);
                        rec.Validate("Unit of Measure Code", UOMGot);
                        rec.validate("Direct Unit Cost", DirectCostGot);
                        CurrPage.update();
                    end;

                //GL Account
                if rec.Type = rec.type::"G/L Account" then begin
                    ItemGot := SPAFunctions.LookupNotItems('GL');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;

                //Resource
                if rec.Type = rec.type::Resource then begin
                    ItemGot := SPAFunctions.LookupNotItems('RES');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;

                //Fixed Asset
                if rec.Type = rec.type::"Fixed Asset" then begin
                    ItemGot := SPAFunctions.LookupNotItems('FA');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;

                //Item Charge
                if rec.Type = rec.type::"Charge (Item)" then begin
                    ItemGot := SPAFunctions.LookupNotItems('CHRG');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;
            end;

            trigger OnAfterValidate()
            var
                SPAFunctions: Codeunit "SPA Purchase Functions";
                PurchaseHeader: Record "purchase header";
                ItemGot: code[20];
                DirectCostGot: Decimal;
                UOMGot: code[20];
                PurchasePrice: Record "Purchase Price";
                VariantGot: code[10];
            begin
                if rec.Type = rec.type::Item then
                    if PurchaseHeader.get(rec."Document Type", rec."Document No.") then begin
                        SPAFunctions.ValidateItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                            PurchaseHeader."Document Date",
                                                            rec."No.", PurchasePrice);
                        ItemGot := PurchasePrice."Item No.";
                        DirectCostGot := PurchasePrice."Direct Unit Cost";
                        UOMGot := PurchasePrice."Unit of Measure Code";
                        VariantGot := PurchasePrice."Variant Code";

                        rec.validate("No.", ItemGot);
                        rec.Validate("Variant Code", VariantGot);
                        rec.validate("Unit of Measure Code", uomgot);
                        rec.validate("Direct Unit Cost", DirectCostGot);
                        CurrPage.update();
                    end;
            end;
        }
        modify("Variant Code")
        {
            caption = 'Variety';
            Visible = true;
        }
        addafter("Bin Code")
        {
            field("Qty. (Base) SPA"; "Qty. (Base) SPA")
            {
                ApplicationArea = all;
                trigger OnValidate()
                begin
                    CurrPage.Update();
                end;
            }
            field("UOM (Base)"; "UOM (Base)")
            {
                ApplicationArea = all;
            }
        }
        /*
        addafter(Quantity)
        {
            field("Quantity (SPA)"; "Quantity (SPA)")
            {
                ApplicationArea = all;
            }
        }
        */
    }
    actions
    {
        addlast("F&unctions")
        {
            action("Fix Qty Base")
            {
                ApplicationArea = All;
                Caption = 'Fix Qty Base';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;


                trigger OnAction()
                var
                    purchaseLines: Record "Purchase Line";
                begin
                    // if not (LowerCase(UserId()) = LowerCase('Prodware1@sweetpotatoesaustralia.com.au')) then
                    //     Error('You are not allowed to run this Action');
                    purchaseLines.Reset();
                    purchaseLines.SetRange("Document Type", purchaseLines."Document Type"::Order);
                    purchaseLines.SetRange("Document No.", Rec."Document No.");
                    purchaseLines.SetFilter("Quantity Received", '=%1', 0);
                    if purchaseLines.FindSet() then
                        repeat
                            purchaseLines."Qty. Rcd. Not Invoiced (Base)" := 0;
                            purchaseLines."Qty. Received (Base)" := 0;
                            purchaseLines."Qty. to Receive (Base)" := purchaseLines."Quantity (Base)";
                            purchaseLines."Outstanding Qty. (Base)" := purchaseLines."Quantity (Base)";
                            purchaseLines.Modify();
                        until purchaseLines.Next() = 0;
                    Message('done');
                end;
            }
        }
    }

    var
        fixVisible: Boolean;
}