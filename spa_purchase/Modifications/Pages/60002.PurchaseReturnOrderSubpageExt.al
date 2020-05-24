pageextension 60002 PurchaseReturnOrderSubPageExt extends "Purchase Return Order Subform"
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

        addafter(Quantity)
        {
            field("Qty. (Base) SPA"; "Qty. (Base) SPA")
            {
                ApplicationArea = all;
                trigger OnValidate()
                begin
                    RecGItemUnitOfMeasure.reset;
                    RecGItemUnitOfMeasure.setrange("Item No.", rec."No.");
                    RecGItemUnitOfMeasure.setrange(code, rec."Unit of Measure");
                    if RecGItemUnitOfMeasure.findfirst then begin
                        rec.validate(Quantity, rec."Qty. (Base) SPA" * RecGItemUnitOfMeasure."Qty. per Unit of Measure");
                        rec.modify;
                    end;
                    CurrPage.update;
                end;

            }
            field("UOM (Base)"; "UOM (Base)")
            {
                ApplicationArea = all;
                trigger OnValidate()
                begin
                end;

            }

        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        RecGItemUnitOfMeasure: Record "Item Unit of Measure";
}