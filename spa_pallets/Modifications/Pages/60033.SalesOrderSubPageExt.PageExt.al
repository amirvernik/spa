pageextension 60033 SalesOrderSubPageExt extends "Sales Order Subform"
{
    layout
    {
        modify("No.")
        {

            trigger OnLookup(VAR Text: Text): Boolean
            var
                SPAFunctions: Codeunit "Sales Price Management";
                SalesHeader: Record "Sales header";
                SalesPrice: Record "Sales Price";
                ItemGot: code[20];
                DirectCostGot: Decimal;
                UOMGot: code[20];
                VariantGot: code[10];
            begin
                //Sales Order - check Pricelist
                if rec.Type = rec.type::item then
                    if SalesHeader.get(rec."Document Type", rec."Document No.") then begin
                        SPAFunctions.LookupItemsForCustomers(SalesHeader."Sell-to Customer No.",
                                                            SalesHeader."Document Date", SalesPrice);
                        ItemGot := SalesPrice."Item No.";
                        DirectCostGot := SalesPrice."Unit Price";
                        UOMGot := SalesPrice."Unit of Measure Code";
                        VariantGot := SalesPrice."Variant Code";

                        rec.validate("No.", ItemGot);
                        rec.validate("Variant Code", VariantGot);
                        rec.Validate("Unit of Measure Code", UOMGot);
                        rec.validate("Unit Price", DirectCostGot);
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
                SPAFunctions: Codeunit "Sales Price Management";
                SalesHeader: Record "Sales header";
                ItemGot: code[20];
                DirectCostGot: Decimal;
                UOMGot: code[20];
                SalesPrice: Record "Sales Price";
                VariantGot: code[10];
            begin
                if rec.Type = rec.type::Item then
                    if SalesHeader.get(rec."Document Type", rec."Document No.") then begin
                        SPAFunctions.ValidateItemsForCustomers(SalesHeader."Sell-to Customer No.",
                                                            SalesHeader."Document Date",
                                                            rec."No.", SalesPrice);
                        ItemGot := SalesPrice."Item No.";
                        DirectCostGot := SalesPrice."Unit Price";
                        UOMGot := SalesPrice."Unit of Measure Code";
                        VariantGot := SalesPrice."Variant Code";

                        rec.validate("No.", ItemGot);
                        rec.Validate("Variant Code", VariantGot);
                        rec.validate("Unit of Measure Code", uomgot);
                        rec.validate("Unit Price", DirectCostGot);
                        CurrPage.update();
                    end;
            end;
        }
        modify("Variant Code")
        {
            Visible = true;
        }
        addafter("Shipment Date")
        {
            field("Dispatch Date"; "Dispatch Date")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}