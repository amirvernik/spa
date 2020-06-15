tableextension 60001 PurchaseLineExt extends "Purchase Line"
{
    fields
    {
        field(60000; "Qty. (Base) SPA"; Integer)
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
                    rec.validate(Quantity, QtyAfter);
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
        modify("No.")
        {

            trigger OnAfterValidate()
            begin
                if RecGItem.Get(rec."No.") then begin
                    rec."UOM (Base)" := recgitem."Base Unit of Measure";
                end;
            end;
        }

    }
    var
        RecGItem: Record Item;
        RecGItemUnitOfMeasure: Record "Item Unit of Measure";
        SPApurchaseFunctions: Codeunit "SPA Purchase Functions";
        DocumentTotals: Codeunit "Document Totals";
}