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
            begin
                //Normal PO
                if rec.Type = rec.type::item then
                    if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                        if ((not PurchaseHeader."Microwave Process PO") and (not PurchaseHeader."Grading Result PO")) then begin
                            ItemGot := SPAFunctions.LookupNotItems('ITM');
                            rec.validate("No.", ItemGot);
                            CurrPage.update();
                        end;

                //Grading or Value Add (Microwave)
                if rec.Type = rec.type::item then
                    if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                        if ((PurchaseHeader."Microwave Process PO") or (PurchaseHeader."Grading Result PO")) then begin
                            SPAFunctions.LookupItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                                PurchaseHeader."Document Date", PurchasePrice);
                            //DirectCostGot := SPAFunctions.GetSpecialPrice(PurchaseHeader."Buy-from Vendor No.",
                            //                                    PurchaseHeader."Document Date", ItemGot);
                            ItemGot := PurchasePrice."Item No.";
                            DirectCostGot := PurchasePrice."Direct Unit Cost";
                            UOMGot := PurchasePrice."Unit of Measure Code";

                            rec.validate("No.", ItemGot);
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
            begin
                if rec.Type = rec.type::Item then
                    if PurchaseHeader.get(rec."Document Type", rec."Document No.") then
                        if ((PurchaseHeader."Microwave Process PO") or (PurchaseHeader."Grading Result PO")) then begin
                            SPAFunctions.ValidateItemsForVendors(PurchaseHeader."Buy-from Vendor No.",
                                                                PurchaseHeader."Document Date",
                                                                rec."No.", PurchasePrice);
                            //DirectCostGot := SPAFunctions.GetSpecialPrice(PurchaseHeader."Buy-from Vendor No.",
                            //                                    PurchaseHeader."Document Date", ItemGot);
                            ItemGot := PurchasePrice."Item No.";
                            DirectCostGot := PurchasePrice."Direct Unit Cost";
                            UOMGot := PurchasePrice."Unit of Measure Code";

                            rec.validate("No.", ItemGot);
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
    }

    actions
    {

    }

}