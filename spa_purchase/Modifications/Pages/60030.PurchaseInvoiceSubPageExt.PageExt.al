pageextension 60030 PurchaseInvoiceSubPageExt extends "Purch. Invoice Subform"
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
                //Purchase Invoice - check Pricelist
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

                //Purchase Invoice - Browse for G/L Accounts
                if rec.Type = rec.type::"G/L Account" then begin
                    ItemGot := SPAFunctions.LookupNotItems('GL');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;

                //Purchase Invoice - Browse for Resources
                if rec.Type = rec.type::Resource then begin
                    ItemGot := SPAFunctions.LookupNotItems('RES');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;

                //Purchase Invoice - Browse for Fixed Assets
                if rec.Type = rec.type::"Fixed Asset" then begin
                    ItemGot := SPAFunctions.LookupNotItems('FA');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;

                //Purchase Invoice - Browse for Item Charges
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
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}