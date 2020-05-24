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
                ItemGot: code[20];
            begin
                if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                    ItemGot := SPAFunctions.LookupItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                        PurchaseHeader."Document Date");
                rec.validate("No.", ItemGot);
            end;

            trigger OnAfterValidate()
            var
                SPAFunctions: Codeunit "SPA Purchase Functions";
                PurchaseHeader: Record "purchase header";
                ItemGot: code[20];
            begin
                if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                    ItemGot := SPAFunctions.ValidateItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                        PurchaseHeader."Document Date",
                                                        rec."No.");
                rec.validate("No.", ItemGot);
            end;
        }
        modify("Variant Code")
        {
            caption='Variety';
            Visible=true;
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}