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
                ItemGot: code[20];
                DirectCostGot: Decimal;
            begin
                if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                    ItemGot := SPAFunctions.LookupItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                        PurchaseHeader."Document Date");
                DirectCostGot := SPAFunctions.GetSpecialPrice(PurchaseHeader."Buy-from Vendor No.",
                                                    PurchaseHeader."Document Date", ItemGot);

                rec.validate("No.", ItemGot);
                rec.validate("Direct Unit Cost", DirectCostGot);
                CurrPage.update();
            end;

            trigger OnAfterValidate()
            var
                SPAFunctions: Codeunit "SPA Purchase Functions";
                PurchaseHeader: Record "purchase header";
                ItemGot: code[20];
                DirectCostGot: Decimal;
            begin
                if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                    ItemGot := SPAFunctions.ValidateItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                        PurchaseHeader."Document Date",
                                                        rec."No.");
                DirectCostGot := SPAFunctions.GetSpecialPrice(PurchaseHeader."Buy-from Vendor No.",
                                                    PurchaseHeader."Document Date", ItemGot);

                rec.validate("No.", ItemGot);
                rec.validate("Direct Unit Cost", DirectCostGot);
                CurrPage.update();
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
    }

    actions
    {

    }

}