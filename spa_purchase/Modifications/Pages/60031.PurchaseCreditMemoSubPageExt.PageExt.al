pageextension 60031 PurchaseCreditMemoSubPageExt extends "Purch. Cr. Memo Subform"
{
    layout
    {
        modify("No.")
        {

            trigger OnLookup(VAR Text: Text): Boolean
            var
                SPAFunctions: Codeunit "SPA Purchase Functions";
                PurchaseHeader: Record "purchase header";
                purchaseprice: Record "Purchase Price";
                ItemGot: code[20];
            begin
                if rec.Type = rec.type::item then begin
                    ItemGot := SPAFunctions.LookupNotItems('ITM');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;
                if rec.Type = rec.type::"G/L Account" then begin
                    ItemGot := SPAFunctions.LookupNotItems('GL');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;
                if rec.Type = rec.type::Resource then begin
                    ItemGot := SPAFunctions.LookupNotItems('RES');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;
                if rec.Type = rec.type::"Fixed Asset" then begin
                    ItemGot := SPAFunctions.LookupNotItems('FA');
                    rec.validate("No.", ItemGot);
                    CurrPage.update();
                end;
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
            begin
                /*if rec.Type = rec.type::Item then begin
                    if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                        //ItemGot := SPAFunctions.ValidateItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                        //                                    PurchaseHeader."Document Date",
                        //                                    rec."No.");
                    rec.validate("No.", ItemGot);
                end;*/
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