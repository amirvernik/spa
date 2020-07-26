tableextension 60001 PurchaseLineExt extends "Purchase Line"
{
    fields
    {
        field(60000; "Qty. (Base) SPA"; Decimal)
        {
            trigger OnValidate()
            var
                QtyBefore: Decimal;
                QtyAfter: Decimal;
                PurchaseHeader: Record "Purchase Header";
                DirectCostGot: Decimal;
            begin
                RecGItemUnitOfMeasure.reset;
                RecGItemUnitOfMeasure.setrange("Item No.", rec."No.");
                RecGItemUnitOfMeasure.setrange(code, rec."Unit of Measure Code");
                if RecGItemUnitOfMeasure.findfirst then begin
                    QtyBefore := rec."Qty. (Base) SPA" / RecGItemUnitOfMeasure."Qty. per Unit of Measure";
                    QtyAfter := round(QtyBefore, 0.1, '>');
                    //rec.validate(Quantity, rec."Qty. (Base) SPA" / RecGItemUnitOfMeasure."Qty. per Unit of Measure");
                    //rec.validate(Quantity, QtyAfter);
                    //rec.Validate("Quantity (Base)", QtyAfter);
                    rec.validate(Quantity, QtyBefore);
                    rec."Quantity (SPA)" := QtyAfter;
                    PurchaseHeader.get(rec."Document Type", rec."Document No.");
                    DirectCostGot := SPApurchaseFunctions.GetSpecialPrice(PurchaseHeader."Buy-from Vendor No.",
                                                    PurchaseHeader."Document Date", rec."No.");
                    rec.Validate("Direct Unit Cost", DirectCostGot);
                    rec.CalcLineAmount();
                    //rec.modify;
                end;
            end;

        }
        field(60001; "UOM (Base)"; Code[20])
        {

        }
        field(60002; "Quantity (SPA)"; Decimal)
        {

        }
        field(60003; "Web UI Unit of Measure"; code[20])
        {

        }
        field(60004; "Web UI Quantity"; Decimal)
        {

        }
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                if RecGItem.Get(rec."No.") then begin
                    rec."UOM (Base)" := recgitem."Base Unit of Measure";
                end;
            end;
        }
        modify("Variant Code")
        {
            trigger OnAfterValidate()
            var
                PurchaseHeader: Record "Purchase Header";
                VariantError: Label 'You cannot change the variant code on a Value Add/Grading PO, you need to use lookup';
            begin
                /*if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                    if ((PurchaseHeader."Microwave Process PO" = true) or
                    (PurchaseHeader."Grading Result PO" = true)) then
                        error(VariantError);*/
            end;
        }
    }
    var
        RecGItem: Record Item;
        RecGItemUnitOfMeasure: Record "Item Unit of Measure";
        SPApurchaseFunctions: Codeunit "SPA Purchase Functions";
        DocumentTotals: Codeunit "Document Totals";
}